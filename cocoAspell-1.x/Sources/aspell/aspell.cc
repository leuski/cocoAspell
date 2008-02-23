// Aspell test program
// Copyright 2000 by Kevin Atkinson under the terms of the LGPL

#include <string>
#include <algorithm>
#include <iterator>
#include <deque>
#include <vector>
#include <iostream>
#include <iomanip>
#include <fstream>
#include <strstream>
#include <exception>
#include <ctime>
#include <strstream>

// temp includes
#include <unistd.h>
#include <sys/types.h>

#include "as_config.h"

#include "manager.hh"
#include "check.hh"
#include "data.hh"
#include "suggest.hh"
#include "hash_string.hh"
#include "config.hh"
#include "clone_ptr-t.hh"
#include "string_map.hh"
#include "language.hh"
#include "trim_space.hh"
#include "string_map.hh"
#include "file_util.hh"

#include "check_fun.hh"

using namespace std;
using namespace autil;
using namespace aspell;

// action functions declarations

void pipe();
void print_ver();
void check(bool interactive);
void master();
void personal();
void repl();
void suggest();
void print_help();
void config();
void soundslike();
void filter();

/////////////////////////////////////////////////////////
//
// Command line options functions and classes
// (including main)
//

typedef deque<string> Args;
typedef Config        Options;
enum Action {do_create, do_merge, do_dump, do_test, do_other};

Args     args;
Options  options;
Action   action = do_other;

struct PossibleOption {
  const char * name;
  char         abrv;
  int          num_arg;
  bool         is_command;
};

#define OPTION(name,abrv,num)         {name,abrv,num,false}
#define COMMAND(name,abrv,num)        {name,abrv,num,true}
#define ISPELL_COMP(abrv,num)         {"",abrv,num,false}

const PossibleOption possible_options[] = {
  OPTION("master",           'd',  1),
  OPTION("personal",         'p',  1),
  OPTION("ignore",            'W', 1),
  OPTION("backup",           'b' , 0),
  OPTION("dont-backup",      'x' , 0),
  OPTION("run-together",     'C',  0),
  OPTION("dont-run-together",'B',  0),

  COMMAND("check",     'c', 0),
  COMMAND("pipe",      'a', 0),
  COMMAND("list",      'l', 0),
  COMMAND("version",   'v', 0), // Note: special hack for vv in code
  COMMAND("help",      '?', 0),
  COMMAND("soundslike",'\0', 0),
  COMMAND("config",    '\0', 0),
  COMMAND("filter",    '\0', 0),

  COMMAND("dump",   '\0', 1),
  COMMAND("create", '\0', 1),
  COMMAND("merge",  '\0', 1),

  ISPELL_COMP('n',0), ISPELL_COMP('P',0), ISPELL_COMP('m',0), 
  ISPELL_COMP('S',0), ISPELL_COMP('w',1), ISPELL_COMP('T',1),

  {"",'\0'}, {"",'\0'}
};

const PossibleOption * possible_options_end = possible_options + sizeof(possible_options)/sizeof(PossibleOption) - 2;

struct ModeAbrv {
  char abrv;
  const char * mode;
  const char * desc;
};

static const ModeAbrv mode_abrvs[] = {
  {'e', "mode=email","enter Email mode."},
  {'H', "mode=sgml", "enter Html/Sgml mode."},
  {'t', "mode=tex",  "enter TeX mode."},
};

static const ModeAbrv *  mode_abrvs_end = mode_abrvs + 3;

static const KeyInfo extra[] = {
  {"backup",  KeyInfoBool, "true", "create a backup file by appending \".bak\""},
  {"reverse", KeyInfoBool, "false", "reverse the order of the suggest list"},
  {"time"   , KeyInfoBool, "false", "time load time and suggest time in pipe mode"}
};

const PossibleOption * find_option(char c) {
  const PossibleOption * i = possible_options;
  while (i != possible_options_end && i->abrv != c) 
    ++i;
  return i;
}

inline bool str_equal(const char * begin, const char * end, 
		      const char * other) 
{
  while(begin != end && *begin == *other)
    ++begin, ++other;
  return (begin == end && *other == '\0');
}

const PossibleOption * find_option(const char * begin, const char * end) {
  const PossibleOption * i = possible_options;
  while (i != possible_options_end 
	 && !str_equal(begin, end, i->name))
    ++i;
  return i;
}

const PossibleOption * find_option(const char * str) {
  const PossibleOption * i = possible_options;
  while (i != possible_options_end 
	 && !strcmp(str, i->name) == 0)
    ++i;
  return i;
}


#ifdef DEBUG_LOG
ofstream log;
#endif

#ifdef __cocoAspell__
extern int 		cocoAspell_mainWithOptions(int argc, const char* argv[], Config& options);
#else
#error __cocoAspell__ must be defined
#endif

int main (int argc, const char *argv[]) 
try {
  options.set_extra(extra, extra+sizeof(extra)/sizeof(KeyInfo));

#ifdef DEBUG_LOG
  {
    pid_t pid = getpid();
    strstream fn;
    fn << "aspell." << pid << ".log" << '\0';
    log.open(fn.str());

    log << "PARMS: " << flush;
    for (int i = 0; i != argc; ++i) {
      log << argv[i] << ' ' << flush;
    }
    log << endl;
  }
#endif

#ifdef __cocoAspell__
if (cocoAspell_mainWithOptions(argc, argv, options)) return 0;
#endif

  if (argc == 1) {print_help(); return 0;}

  int i = 1;
  const PossibleOption * o;
  const char           * parm;

  //
  // process command line options by setting the oprepreate options
  // in "options" and/or pushing non-options onto "argv"
  //
  PossibleOption other_opt = OPTION("",'\0',0);
  string option_name;
  while (i != argc) {
    if (argv[i][0] == '-') {
      if (argv[i][1] == '-') {
	// a long arg
	const char * c = argv[i] + 2;
	while(*c != '=' && *c != '\0') ++c;
	o = find_option(argv[i] + 2, c);
	if (o == possible_options_end) try {
	  option_name.assign(argv[i] + 2, 0, c - argv[i] - 2);
	  const char * base_name = ConfigData::base_name(option_name.c_str());
	  const KeyInfo * ki = options.keyinfo(base_name);
	  other_opt.name    = option_name.c_str();
	  other_opt.num_arg = ki->type == KeyInfoBool ? 0 : 1;
	  o = &other_opt;
	} catch (UnknownKey) {}
	if (*c == '=') ++c;
	parm = c;
      } else {
	// a short arg
	const ModeAbrv * j = mode_abrvs;
	while (j != mode_abrvs_end && j->abrv != argv[i][1]) ++j;
	if (j == mode_abrvs_end) {
	  o = find_option(argv[i][1]);
	  if (argv[i][1] == 'v' && argv[i][2] == 'v') 
	    // Hack for -vv
	    parm = argv[i] + 3;
	  else
	    parm = argv[i] + 2;
	} else {
	  other_opt.name = "mode";
	  other_opt.num_arg = 1;
	  o = &other_opt;
	  parm = j->mode + 5;
	}
      }
      if (o == possible_options_end) {
	cerr << "Error: Invalid Option: " << argv[i] << endl;
	return -1;
      }
      if (o->num_arg == 0) {
	if (parm[0] != '\0') {
	  cerr << "Error: " << string(argv[i], parm - argv[i])
	       << " does not take any parameters." << endl;
	  return -1;
	}
	i += 1;
      } else { // o->num_arg == 1
	if (parm[0] == '\0') {
	  if (i + 1 == argc) {
	    cerr << "Error: You must specify a parameter for " 
		 << argv[i] << endl;
	    return -1;
	  }
	  parm = argv[i + 1];
	  i += 2;
	} else {
	  i += 1;
	}
      }
      if (o->is_command) {
	args.push_back(o->name);
	if (o->num_arg == 1)
	  args.push_back(parm);
      } else {
	if (o->name[0] != '\0') {
	  options.replace(o->name, parm);
	}
      }
    } else {
      args.push_back(argv[i]);
      i += 1;
    }
  }

  if (args.empty()) {
    cerr << "Error: You must specify an action" << endl;
    return -1;
  }

  //
  // perform the requisted action
  //
  string action_str = args.front();
  args.pop_front();
  if (action_str == "help")
    print_help();
  else if (action_str == "version")
    print_ver();
  else if (action_str == "check")
    check(true);
  else if (action_str == "pipe") 
    pipe();
  else if (action_str == "list") 
    check(false);
  else if (action_str == "config")
    config();
  else if (action_str == "soundslike")
    soundslike();
  else if (action_str == "filter")
    filter();
  else if (action_str == "dump")
    action = do_dump;
  else if (action_str == "create")
    action = do_create;
  else if (action_str == "merge")
    action = do_merge;
  else {
    cerr << "Error: Unknown Action: " << action_str << endl;
    return -1;
  }

  if (action != do_other) {
    if (args.empty()) {
      cerr << "Error: Unknown Action: " << action_str << endl;
      return -1;
    }
    string what_str = args.front();
    args.pop_front();
    if (what_str == "config")
      config();
    else if (what_str == "master")
      master();
    else if (what_str == "personal")
      personal();
    else if (what_str == "repl")
      repl();
    else {
      cerr << "Error: Unknown Action: " << action_str 
	   << " " << what_str << endl;
      return -1;
    }
  }

  return 0;

} catch (exception & e) {

  cerr << e.what() << endl;
  return -1;

}

/////////////////////////////////////////////////////////
//
// Utility functions and classes
//

class bad_cin {};

class Ccin {
public:
  char get() 
  {
    char c = cin.get(); 
    if (!cin) throw bad_cin(); 
#ifdef DEBUG_LOG
    log << "GET: " << c << endl; 
#endif
    return c;
  }
  void unget() 
  {
    cin.unget(); 
#ifdef DEBUG_LOG
    log << "UNGET" << endl;
#endif
  }
  bool eof() {return cin.eof();}
};

Ccin& operator >> (Ccin &in, string &str) {
  cin >> str;
  if (!cin) throw bad_cin();
#ifdef DEBUG_LOG
  log << "<<:" << str << endl;
#endif
  return in;
}

void getline(Ccin, string &str) {
  getline(cin, str);
  if (!cin) throw bad_cin();
#ifdef DEBUG_LOG
  log << "GETLINE: " << str << endl;;
#endif
}

void getline(Ccin, string &str, char d) {
  getline(cin, str, d);
  if (!cin) throw bad_cin();
#ifdef DEBUG_LOG
  log << "GTELINE alt-delem: " << str << endl;
#endif
}

static Ccin ccin;

struct PrintStatus {
  bool print_star;
  PrintStatus() : print_star (true) {}
  void operator() () const {if (print_star) cout << "*" << endl;}
};

void get_word_pair(string &w1, string &w2, char sep = ',') {
  getline(ccin, w1, sep);
  w1 = trim_space(w1);
  getline(ccin, w2);
  w2 = trim_space(w2);
}

void ignore_rest() {
  cin.ignore(32767,'\n');
}

void print_elements(VirEmulation<const char *> * els) {
  int count = 0;
  const char * w;
  string line;
  while ( (w = els->next()) != 0 ) {
    ++count;
    line += w;
    line += ", ";
  }
  line.resize(line.size() - 2);
  cout << count << ": " << line << endl;
  delete els;
}

void print_elements(VirEmulation<BasicWordInfo> * els) {
  int count = 0;
  BasicWordInfo w;
  string line;
  while ( (w = els->next()) != 0 ) {
    ++count;
    line += w.word;
    line += ", ";
  }
  line.resize(line.size() - 2);
  cout << count << ": " << line << endl;
  delete els;
}

/////////////////////////////////////////////////////////
//
// Action Functions
//
//

///////////////////////////
//
// config
//

void config () {
  Config config;
  config.read_in(&options);
  config.write_to_stream(cout);
}

//////////////////////////
//
// pipe
//

void pipe () {
  bool         terse_mode = true;
  bool do_time = false;
  if (options.retrieve_bool("time"))
    do_time = true;
  clock_t start,finish;
  start = clock();
  Manager manager(options);
  if (do_time)
    cout << "Time to load word list: " 
         << (clock() - start)/(double)CLOCKS_PER_SEC << endl;
  typedef CheckState<string::iterator> CS;
  CS state(manager);
  const SuggestionList * suggestions;
  string::iterator i;
  string::iterator j;
  string::iterator end;
  const char * w;
  string line;
  string word;
  string word2;
  int    ignore;
  PrintStatus print_status;

  print_ver();
       
  char c;
  try {
    // break out of the loop on EOF via exceptions
    for (;;) {
      c = ccin.get();
      ignore = 0;
      switch (c) {
      case '*':
	ccin >> word;
	manager.add_to_personal(word);
	ignore_rest();
	break;
      case '&':
	ccin >> word;
	try {
	  manager.add_to_personal(to_lower(manager.lang(),word));
	} catch (...) {
	  cerr << "\nWord '" << word << "' contains illegal characters\n";
	}
	ignore_rest();
	break;
      case '@':
	ccin >> word;
	try {
	  manager.add_to_session(word);
	} catch (...) {
	  cerr << "\nWord '" << word << "' contains illegal characters\n";
	}
	ignore_rest();
	break;
      case '#':
	manager.save_all_wls();
	ignore_rest();
	break;
      case '+':
	getline(ccin, word);
	try {
	  manager.config().replace("mode", word.c_str());
	} catch (...) {
	  manager.config().replace("mode", "tex");
	}
	state.start_over();
	break;
      case '-':
	manager.config().remove("filter");
	state.start_over();
	ignore_rest();
	break;
      case '~':
	ignore_rest();
	break;
      case '!':
	terse_mode = true;
	print_status.print_star = false;
	ignore_rest();
	break;
      case '%':
	terse_mode = false;
	print_status.print_star = true;
	ignore_rest();
	break;
      case '$':
	if (ccin.get() == '$') {
	  switch(ccin.get()) {
	  case 's':
	    get_word_pair(word,word2);
	    cout << "Sorry not implemented." << endl;
#if 0
	    cout << manager.score(word.c_str(),word2.c_str()) << endl;
#endif
	    break;
	  case 'S':
	    switch(ccin.get()) {
	    case 'W':
	    case 'w':
	      ccin >> word;
	      cout << manager.lang().to_soundslike(word) << endl;
	      ignore_rest();
	      break;
	    default:
	      ignore_rest();
	    }
	    break;
	  case 'P':
	    switch(ccin.get()) {
	    case 'W':
	    case 'w':
	      ccin >> word;
	      cout << manager.lang().to_phoneme(word) << endl;
	      ignore_rest();
	      break;
	    default:
	      ignore_rest();
	    }
	    break;
	  case 'r':
 	    switch(ccin.get()) {
	    case 'a':
	      get_word_pair(word,word2);
	      manager.store_repl(word,word2);
	      break;
	    default:
	      ignore_rest();
	    }
	    break;
	  case 'c':
	    try {
	      switch (ccin.get()) {
	      case 's':
		get_word_pair(word,word2);
		manager.config().replace(word.c_str(), word2.c_str());
		break;
	      case 'r':
		ccin >> word;
		ignore_rest();
		cout << manager.config().retrieve(word.c_str()) << endl;
		break;
	      }
	    } catch (exception & e) {
	      cerr << "Error: " << e.what() << endl;
	    }
	    break;
	  case 'p':
	    switch (ccin.get()) {
	    case 'p':
	      print_elements(manager.personal_wl().elements());
	      break;
	    case 's':
	      print_elements(manager.session_wl().elements());
	      break;
	    }
	    ignore_rest();
	    break;
	  case 'l':
	    cout << manager.lang_name() << endl;
	    ignore_rest();
	    break;
	  default:
	    ignore_rest();
	  }
	  break;
	} else {
	  ccin.unget();
	  // continue on (no break)
	}
      case '^':
	ignore = 1;
      default:
	ccin.unget();
	getline(ccin, line);
	line += '\n';
	i = line.begin() + ignore;
	end = line.end();
	state.restart(i, CS::EndFun(end));
	state.advance();
	while (check(state, print_status), !state.at_end()) {
	  word.resize(0);
	  for(j = state.word_begin(); j != state.word_end(); ++j) 
	    word +=*j;
          start = clock();
          suggestions = &manager.suggest(word);
          finish = clock();
	  if (suggestions->size()) {
	    cout << "& " << word 
		 << " " << suggestions->size() 
		 << " " << state.word_begin() - line.begin()
		 << ":";
	    if (options.retrieve_bool("reverse")) {
	      vector<const char *> sugs;
	      sugs.reserve(suggestions->size());
              Emulation<const char *> els = suggestions->elements();
              while ( ( w = els.next()) != 0)
		sugs.push_back(w);
	      vector<const char *>::reverse_iterator i = sugs.rbegin();
	      while (true) {
                cout << " " << *i;
		++i;
                if (i == sugs.rend()) break;
		cout << ",";
	      }
	      cout << endl;
	    } else {
              Emulation<const char *> els = suggestions->elements();
              while ( ( w = els.next()) != 0) {
                cout << " " << w;
                if (!els.at_end())
                  cout << ",";
              }
              cout << endl;
	    }
	  } else {
	    cout << "# " << word << " " 
		 << state.word_begin() - line.begin() 
		 << endl;
	  }
	  if (do_time)
	    cout << "Suggestion Time: " 
		 << (finish-start)/(double)CLOCKS_PER_SEC << endl;
	  state.advance();
	}
	cout << endl;
      }
    }
  } catch (bad_cin){
    //
  }
}

///////////////////////////
//
// check
//

namespace aspell_check_fun {
  bool use_curses = false;
  TextChain * file = 0;
  CheckState<TextChain::const_iterator> * state = 0;
  const char * last_prompt = 0;
  Choices * word_choices;
  Choices * menu_choices;
}


void check (bool interactive) {

  using namespace aspell_check_fun;

  istream * in;
  string file_name;

  if (interactive) {
    if (args.size() == 0) {
      cout << "Error: You must specify a file name.\n";
      exit(-1);
    }
    
    file_name = args[0];
  
    in = new ifstream(file_name.c_str());
    if (!*in) {
      cerr << "Error: Could not open the file \"" << file_name
	   << "\" for reading.\n";
      exit(-1);
    }

  } else {
    in = &cin;
  }
  
  file = new TextChain;
  file->read(*in);

  if (interactive)
    delete in;

  Manager manager(options);
 
  state = new CheckState<TextChain::const_iterator>(manager, file_name);
  word_choices = new vector<Choice>;

  menu_choices = new vector<Choice>;
  menu_choices->push_back(Choice('i', "Ignore"));
  menu_choices->push_back(Choice('I', "Ignore all"));
  menu_choices->push_back(Choice('r', "Replace"));
  menu_choices->push_back(Choice('R', "Replace all"));
  menu_choices->push_back(Choice('a', "Add"));
  menu_choices->push_back(Choice('x', "Exit"));

  TextChain::const_iterator                      i,k;
  TextChain::const_iterator                      new_begin;
  string word, new_word;
  char choice;
  const SuggestionList * suggestions;
  vector<string> sug_con;
  Emulation<const char *> els;
  const char * w;
  SuggestionList::Size suggestions_mid, suggestions_size;
  SuggestionList::Size j;

  StringMap replace_list;

  i = file->begin();
  state->restart(i, file->end());
  state->advance();

  if (interactive)
    begin_check();

  while (check(*state), !state->at_end()) {
    word.resize(0);
    for (k = state->word_begin(); k != state->word_end(); ++k)
      word += *k;

    if (interactive) {

      //
      // check if it is in the replace list
      //

      if (replace_list.have(word.c_str())) {
	new_begin = 
	  file->replace(static_cast<TextChain::iterator>(state->word_begin()), 
			static_cast<TextChain::iterator>(state->word_end()), 
			replace_list.lookup(word.c_str()));
	state->backup();
	state->restart(new_begin, file->end());
	state->advance();
	continue;
      }

      //
      // print the line with the misspelled word highlighted;
      //

      display_misspelled_word();

      //
      // print the suggestions and menu choices
      //

      suggestions = &manager.suggest(word);
      els = suggestions->elements();
      sug_con.resize(0);
      while (sug_con.size() != 10 && (w = els.next()) != 0) {
	sug_con.push_back(w);
      }

      // disable suspend
      suggestions_size = sug_con.size();
      suggestions_mid = suggestions_size / 2;
      if (suggestions_size % 2) suggestions_mid++; // if odd
      word_choices->resize(0);
      for (j = 0; j != suggestions_mid; ++j) {
	word_choices->push_back(Choice('0' + j+1, sug_con[j].c_str()));
	if (j + suggestions_mid != suggestions_size) 
	  word_choices
	    ->push_back(Choice(j+suggestions_mid+1 == 10 
			       ? '0' 
			       : '0' + j+suggestions_mid+1,
			       sug_con[j+suggestions_mid].c_str()));
      }
      //enable suspend
      display_menu();

      prompt("? ");

    choice_loop:

      //
      // Handle the users choice
      //

      get_choice(choice);

      if (choice == '0') choice = '9' + 1;
    
      switch (choice) {
      case 'X':
      case 'x':
	goto exit_loop;
      case ' ':
      case '\n':
      case 'i':
	state->advance();
	break;
      case 'I':
	manager.add_to_session(word);
	state->advance();
	break;
      case 'a':
	manager.add_to_personal(word);
	state->advance();
	break;
      case 'R':
      case 'r':
	prompt("With: ");
	get_line(new_word);
	if (new_word[0] >= '1' && new_word[0] < suggestions_size + '1')
	  new_word = sug_con[new_word[0]-'1'].c_str();
	new_begin = 
	  file->replace(static_cast<TextChain::iterator>(state->word_begin()),
			static_cast<TextChain::iterator>(state->word_end()),
			new_word.c_str());
	manager.store_repl(word,new_word.c_str());
	if (choice == 'R')
	  replace_list.replace(word.c_str(), new_word.c_str());
	state->backup();
	state->restart(new_begin, file->end());
	state->advance();
	break;
      default:
	if (choice >= '1' && choice < suggestions_size + '1') { 
	  new_begin = 
	    file->replace(static_cast<TextChain::iterator>(state->word_begin()),
			  static_cast<TextChain::iterator>(state->word_end()),
			  sug_con[choice-'1'].c_str());
	  manager.store_repl(word,sug_con[choice-'1'].c_str());
	  state->backup();
	  state->restart(new_begin, file->end());
	  state->advance();
	} else {
	  error("Sorry that is an invalid choice!");
	  goto choice_loop;
	}
      }

    } else { // !interactive
      
      cout << word << "\n";
      state->advance();
      
    }
  }
 exit_loop:
  
  //end_check();
  
  if (interactive) {
    if (options.retrieve_bool("backup")) {
      string backup_name = file_name;
      backup_name += ".bak";
      if (! rename_file(file_name, backup_name) ) {
        cerr << "Error: Could not rename the file \"" << file_name 
             << "\" to \"" << backup_name << "\".  File not saved.\n";
        exit(-1);
      }
    }

    ofstream FILE((file_name).c_str());
    if (!FILE) {
      cerr << "Error: Could not open the file \"" << file_name
           << "\" for writing.  File not saved.\n";
      exit(-1);
    }
    file->write(FILE);
    manager.save_all_wls();
  }
}

///////////////////////////
//
// master
//

class IstreamVirEmulation : public VirEmulation<char *> {
  istream * in;
  PspellString data;
public:
  IstreamVirEmulation(istream & i) : in(&i) {}
  IstreamVirEmulation * clone() const {
    return new IstreamVirEmulation(*this);
  }
  void assign (const VirEmulation<char *> * other) {
    *this = *static_cast<const IstreamVirEmulation *>(other);
  }
  Value next() {
    // 
    // Note: retriving the words with "operator>> (isteam &cin, string &)"
    // should work but there is a bug which will cause it to fail
    // on some machines with 8-bit data so I used PspellString as a
    // workaround.
    //
    data.clear();
    int c;
    while (c = in->peek(), c != EOF && isspace(c) ) 
      in->get();
    if (c == EOF) return 0;
    do {
      data += static_cast<char>(in->get());
    } while (c = in->peek(), c != EOF && !isspace(c));
    if (c == EOF) return 0;
    else return data.mutable_data();
  }
  bool at_end() const {return *in;}
};

void dump (LocalWordSet lws) 
{
  switch (lws.word_set->basic_type) {
  case DataSet::basic_word_set:
    {
      BasicWordSet  * ws = static_cast<BasicWordSet *>(lws.word_set);
      BasicWordSet::Emul els = ws->elements();
      BasicWordInfo wi;
      while (wi = els.next(), wi)
	wi.write(cout,*(ws->lang()), lws.local_info.convert) << endl;
    }
    break;
  case DataSet::basic_multi_set:
    {
      BasicMultiSet::Emul els 
	= static_cast<BasicMultiSet *>(lws.word_set)->elements();
      LocalWordSet ws;
      while (ws = els.next(), ws) 
	dump (ws);
    }
    break;
  default:
    abort();
  }
}

void master () {
  if (args.size() != 0) {
    options.replace("master", args[0].c_str());
  }

  Config config;
  config.read_in(&options);

  if (action == do_create) {
    
    create_default_readonly_word_set(new IstreamVirEmulation(cin),
				     config);

  } else if (action == do_merge) {
    
    cerr << "Can't merge a master word list yet.  Sorry\n";
    exit (-1);
  
  } else if (action == do_dump) {

    LoadableDataSet * mas = add_data_set(config.retrieve("master-path"), 
					 config);
    LocalWordSetInfo wsi;
    wsi.set(mas->lang(), &config);
    dump(LocalWordSet(mas,wsi));
    delete mas;
    
  }
}

///////////////////////////
//
// personal
//

void personal () {
  if (args.size() != 0) {
    options.replace("personal", args[0].c_str());
  }
  if (action == do_create || action == do_merge) {
    Manager manager(options);

    if (action == do_create) {
      if (file_exists(manager.config().retrieve("personal-path"))) {
        cerr << "Sorry I won't overwrite \"" 
             << manager.config().retrieve("personal-path") << "\"" << endl;
        exit (-1);
      }
      manager.personal_wl().clear();
    }

    string word;
    while (cin >> word) 
      manager.add_to_personal(word);

    manager.personal_wl().synchronize();

  } else { // action == do_dump

    Config config;
    config.read_in(&options);

    WritableWordSet * per = new_default_writable_word_set();
    per->load(config.retrieve("personal-path"), &config);
    WritableWordSet::Emul els = per->elements();
    LocalWordSetInfo wsi;
    wsi.set(per->lang(), &config);
    BasicWordInfo wi;
    while (wi = els.next(), wi) {
      wi.write(cout,*(per->lang()), wsi.convert);
      cout << endl;
    }
    delete per;
  }
}

///////////////////////////
//
// repl
//

void repl() {

  if (args.size() != 0) {
    options.replace("repl", args[0].c_str());
  }

  if (action == do_create || action == do_merge) {
    Manager manager(options);

    if (action == do_create) {
      if (file_exists(manager.config().retrieve("repl-path"))) {
        cerr << "Sorry I won't overwrite \"" 
             << manager.config().retrieve("repl-path") << "\"" << endl;
        exit (-1);
      }
      manager.personal_repl().clear();
    }
    
    try {
      string word,repl;

      while (true) {
	get_word_pair(word,repl,':');
	manager.store_repl(word,repl,false);
      }

    } catch (bad_cin) {}

    manager.personal_repl().synchronize();
  
  } else if (action == do_dump) {

    Config config;
    config.read_in();

    WritableReplacementSet * repl = new_default_writable_replacement_set();
    repl->load(config.retrieve("repl-path"), &config);
    WritableReplacementSet::Emul els = repl->elements();
 
    ReplacementList rl;
    while ( !(rl = els.next()).empty() ) {
      while (!rl.elements->at_end()) {
	cout << rl.misspelled_word << ": " << rl.elements->next() << endl;
      }
      delete rl.elements;
    }
    delete repl;
  }

}

//////////////////////////
//
// soundslike
//

void soundslike() {
  Language lang(options);
  string word;
  while (cin >> word) {
    cout << word << '\t' << lang.to_soundslike(word) << endl;
  } 
}

//////////////////////////
//
// filter
//

void filter() {
  Config config;
  config.read_in(&options);
  string line;
  FilterItrPart * i = new FilterItrRootClass<string::const_iterator>;
  StringMap filters;
  options.retrieve_list("filter", filters);
  StringMap::Emul els = filters.elements();
  while (!els.at_end())
    i = add(i, get_filter_itr_throw(els.next().first, config));
	    
  while (getline(cin, line), cin) {
    line += '\n';
    i->root()->restart
      (FilterItrRootClass<string::const_iterator>(line.begin(),line.end()));
    for (char c = i->first(); c; c = i->next()) {
      if (c != '\n')
	cout << c;
    }
    cout << "\n";
  }
}

///////////////////////////
//
// print_ver
//

void print_ver () {
  cout << "@(#) International Ispell Version 3.1.20 (but really Aspell " 
       << VERSION << " alpha)" << endl;
}

///////////////////////////
//
// print_help
//

void print_help_line(char abrv, char dont_abrv, const char * name, 
		     KeyInfoType type, const char * desc, bool no_dont = false) 
{
  string command;
  if (abrv != '\0') {
    command += '-';
    command += abrv;
    if (dont_abrv != '\0') {
      command += '|';
      command += '-';
      command += dont_abrv;
    }
    command += ',';
  }
  command += "--";
  if (type == KeyInfoBool && !no_dont) command += "[dont-]";
  if (type == KeyInfoList) command += "add|rem-";
  command += name;
  if (type == KeyInfoString || type == KeyInfoList) 
    command += "=<str>";
  if (type == KeyInfoInt)
    command += "=<int>";
  cout << "  " << setw(27) << command.c_str() << " " << desc << endl;
}

void print_help () {
  cout.setf(ios::left);
  cout << 
    "\n"
    "Aspell " VERSION " alpha.  Copyright 2000 by Kevin Atkinson.\n"
    "\n"
    "Usage: aspell [options] <command>\n"
    "\n"
    "<command> is one of:\n"
    "  -?|help          display this help message\n"
    "  -c|check <file>  to check a file\n"
    "  -a|pipe          \"ispell -a\" compatibility mode\n"
    "  -l|list          produce a list of misspelled words from standard input\n"
    "  [dump] config    dumps the current configuration to stdout\n"
    "  soundslike       returns the soundslike equivalent for each word entered\n"
    "  filter           passes standard input through filters\n"
    "  -v|version       prints a version line\n"
    "  dump|create|merge master|personal|repl [word list]\n"
    "    dumps, creates or merges a master, personal, or replacement word list.\n"
    "\n"
    "[options] is any of the following:\n"
    "\n";
  Options::PossibleElementsEmul els = options.possible_elements();
  const KeyInfo * k;
  while (k = els.next(), k) {
    if (k->desc == 0) continue;
    const PossibleOption * o = find_option(k->name);
    print_help_line(o->abrv, 
		    strncmp((o+1)->name, "dont-", 5) == 0 ? (o+1)->abrv : '\0',
		    k->name, k->type, k->desc);
    if (strcmp(k->name, "mode") == 0) {
      for (const ModeAbrv * j = mode_abrvs;
           j != mode_abrvs_end;
           ++j)
      {
        print_help_line(j->abrv, '\0', j->mode, KeyInfoBool, j->desc, true);
      }
    }
  }

  cout << 
    "\n"
    "The following options will be ignored for compatabilty with ispell:\n"
    "  -m -n -P -S -w ARG -T ARG\n"
    "\n";
}

