/* Low level terminal interface.  This file will possible use the following
   macros:
     POSIX_TERMIOS
     HAVE_LIBCURSES
       CURSES_INCLUDE_STANDARD
       CURSES_INCLUDE_WORKAROUND_1
       CURSES_ONLY
     HAVE_GETCH
  All these macros need to have a true value and not just be defined
*/

#include "as_config.h"

#ifdef CURSES_NON_POSIX
#define CURSES_ONLY 1
#endif

#include <string>
#include <cstdio>

#include <signal.h>

#include "check_fun.hh"

#if   POSIX_TERMIOS

// Posix headers
#include <termios.h>
#include <unistd.h>

static termios new_attributes;
static termios saved_attributes;

#elif HAVE_GETCH

extern "C" {int getch();}

#endif

#if   HAVE_LIBCURSES

#include <curses.h>

#if   CURSES_INCLUDE_STANDARD

  #include <term.h>

#elif CURSES_INCLUDE_WORKAROUND_1

  // including <term.h> on solaris causes problems
  extern "C" {char * tigetstr(char * capname);}

#endif

static bool use_curses = true;
static WINDOW * text_w = 0;
static WINDOW * menu_w = 0;
enum MenuText {StdMenu, ReplMenu};
static MenuText menu_text = StdMenu;
static WINDOW * choice_w = 0;
//static int beg_x = -1;
static int end_x = -1;
static int max_x;
static char * choice_text;
static int choice_text_size;
static int cur_x = 0;
static int cur_y = 0;
static volatile int last_signal = 0;

#ifdef CURSES_ONLY

char * tigetstr(char *) {return "";}

#else

static SCREEN * term;

#endif

#endif

void cleanup (void) {
#if   HAVE_LIBCURSES
  if (use_curses) {
    endwin();
  } else
#endif
  {
#if   POSIX_TERMIOS
    tcsetattr (STDIN_FILENO, TCSANOW, &saved_attributes);
#endif
  }
}

namespace aspell_check_fun {

#if   HAVE_LIBCURSES

  void do_nothing(int) {}

  void layout_screen();

#ifdef CURSES_ONLY

  inline void handle_last_signal() {}

#else

  void save_state() {
    getyx(choice_w,cur_y,cur_x);
    choice_text_size = COLS;
    choice_text = new char[choice_text_size];
    for (int i = 0; i != choice_text_size; ++i) {
      choice_text[i] = mvwinch(choice_w, 0, i) & A_CHARTEXT;
    }
    endwin();
  }

  void restore_state() {
    delscreen(term);
    term = newterm(0,stdout,stdin);
    set_term(term);
    layout_screen();
    display_menu();
    display_misspelled_word();
    wmove(choice_w,0,0);
    if (COLS <= choice_text_size)
      choice_text_size = COLS - 1;
    for (int i=0; i < choice_text_size; ++i)
      waddch(choice_w,choice_text[i]);
    delete[] choice_text;
    max_x = COLS - 1;
    if (cur_x > max_x)
      cur_x = max_x;
    if (end_x > max_x-1)
      end_x = max_x;
    wmove(choice_w,cur_y,cur_x);
    wnoutrefresh(choice_w);
    doupdate();
  }


  void suspend_handler(int) {
    last_signal = SIGTSTP;
  }
  
  void continue_handler(int) {
    restore_state();
    signal(SIGTSTP, suspend_handler);
    signal(SIGCONT,  continue_handler),
    last_signal = 0;
  }

  void resize_handler(int ) {
    last_signal = SIGWINCH;
  }
  
  void resize() {
    save_state();
    restore_state();
    last_signal = 0;
  }

  void suspend() {
    save_state();
    signal(SIGTSTP, SIG_DFL);
    raise(SIGTSTP);
    last_signal = 0;
  }

  inline void handle_last_signal() {
    switch (last_signal) {
    case SIGWINCH:
      resize();
      signal(SIGWINCH, resize_handler);
      break;
    case SIGTSTP:
      suspend();
      break;
    }
  }

#endif

  void layout_screen() {
    text_w = 0;
    menu_w = 0;
    choice_w = 0;
    nonl();
    noecho();
    halfdelay(1);
    keypad(stdscr, true);
    clear();
    int height, width;
    getmaxyx(stdscr, height, width);
    int text_height = height - MENU_HEIGHT - 3;
    if (text_height >= 1) {
      text_w = newwin(text_height, width, 0, 0);
      scrollok(text_w,false);
      move(text_height, 0);
      hline((unsigned char)' '|A_REVERSE, width);
      menu_w = newwin(MENU_HEIGHT, width, text_height+1, 0);
      scrollok(menu_w,false);
    }
    if (height >= 2) {
      move(height-2,0);
      hline((unsigned char)' '|A_REVERSE, width);
    }
    choice_w = newwin(1, width, height-1, 0);
    keypad(choice_w,true);
    scrollok(menu_w,true);
    wnoutrefresh(stdscr);
  }

#endif
  void begin_check() {
#if   HAVE_LIBCURSES
#if   CURSES_ONLY
    use_curses=true;
    initscr();
#else
    term = newterm(0,stdout,stdin);
    if (term == 0) {
      use_curses = false;
    } else {
      set_term(term);
      if ((tigetstr(const_cast<char *>("cup") /*move*/) != 0 
	   || (tigetstr(const_cast<char *>("cuf1") /*right*/) != 0 
	       && tigetstr(const_cast<char *>("cub1") /*left*/)  != 0 
	       && tigetstr(const_cast<char *>("cuu1") /*up  */)  != 0 
	       && tigetstr(const_cast<char *>("cud1") /*down*/)  != 0))
	  && (tigetstr(const_cast<char *>("rev")) != 0))
      {
	use_curses = true;
      } else {
	use_curses = false;
	endwin();
	delscreen(term);
      }
    }
    if (use_curses) {
      signal(SIGWINCH, resize_handler);
      signal(SIGTSTP,  suspend_handler);
      signal(SIGCONT,  continue_handler);
    }
#endif
    if (use_curses) {
      layout_screen();
      atexit(cleanup);
    } else
#endif
    {
#if   POSIX_TERMIOS
      if (!isatty (STDIN_FILENO)) {
	puts("Error: Stdin not a terminal.");
	exit (-1);
      }
      
      //
      // Save the terminal attributes so we can restore them later.
      //
      tcgetattr (STDIN_FILENO, &saved_attributes);
      atexit(cleanup);
      
      //
      // Set up the terminal to read in a line character at a time
      //
      tcgetattr (STDIN_FILENO, &new_attributes);
      new_attributes.c_lflag &= ~(ICANON); // Clear ICANON 
      new_attributes.c_cc[VMIN] = 1;
      new_attributes.c_cc[VTIME] = 0;
      tcsetattr (STDIN_FILENO, TCSAFLUSH, &new_attributes);
#endif
    }
  }

#define control(key) (1 + (key-'a'))
  
  void get_line(string & line) {
#if   HAVE_LIBCURSES
    if (use_curses) {
      menu_text = ReplMenu;
      display_menu();
      wnoutrefresh(choice_w);
      doupdate();
      line.resize(0);
      int c;
      noecho();
      int begin_x;
      {int junk; getyx(choice_w, junk, begin_x);}
      int max_x = COLS - 1;
      int end_x = begin_x;
      while (true) {
	handle_last_signal();
	c = wgetch(choice_w);
	if (c == ERR) continue;
	if (c == '\r' || c == '\n' || c == KEY_ENTER) 
	  break;
	int y,x;
	getyx(choice_w,y,x);
	if ((c == KEY_LEFT || c == control('b')) && begin_x < x) {
	  wmove(choice_w, y,x-1);
	} else if ((c == KEY_RIGHT || c == control('f')) && x < end_x) {
	  wmove(choice_w, y,x+1);
	} else if (c == KEY_HOME || c == control('a')) {
	  wmove(choice_w, y, begin_x);
	} else if (c == KEY_END  || c == control('e')) {
	  wmove(choice_w, y, end_x);
	} else if ((c == KEY_BACKSPACE || c == control('h') || c == '\x7F') 
		   && begin_x < x) {
	  wmove(choice_w, y,x-1);
	  wdelch(choice_w);
	  --end_x;
	} else if (c == KEY_DC || c == control('d')) {
	  wdelch(choice_w);
	  --end_x;
	} else if (c == KEY_EOL || c == control('k')) {
	  wclrtoeol(choice_w);
	  end_x = x;
	} else if (x < max_x && 32 <= c && c != '\x7F' && c < 256) {
	  winsch(choice_w, c);
	  wmove(choice_w, y, x+1);
	  ++end_x;
	}
	wrefresh(choice_w);
      }
      for (int i = begin_x; i < end_x; ++i) {
	line += mvwinch(choice_w, 0, i) & A_CHARTEXT;
      }
      menu_text = StdMenu;
      display_menu();
      doupdate();
    } else 
#endif
    {
#if   POSIX_TERMIOS
      tcsetattr (STDIN_FILENO, TCSANOW, &saved_attributes);
#endif
      line.resize(0);
      char c;
      while ((c = getchar()) != '\n')
	line += c;
#if   POSIX_TERMIOS
      tcsetattr (STDIN_FILENO, TCSANOW, &new_attributes);
#endif
    }
  }
    
  void get_choice(char & c) {
#if   HAVE_LIBCURSES
    if (use_curses) {
      doupdate();
      int c0;
      do {
	handle_last_signal();
	c0 = wgetch(choice_w);
      } while (c0 == ERR);
      if (32 <= c0 && c0 < 128) {
	c = static_cast<char>(c0);
	waddch(choice_w,c);
	wrefresh(choice_w);
      } else {
	c = 0;
      }
    } else
#endif
    {
#if   POSIX_TERMIOS
      read (STDIN_FILENO, &c, 1);
      putchar('\n');
#elif HAVE_GETCH
      c = getch();
      putchar(c);
      putchar('\n');
#else
      c = getchar();
      char d = c;
      while (d != '\n') d = getchar();
      putchar('\n');
#endif
    }
  }

#if   HAVE_LIBCURSES
  void new_line(int & l, int y, int height) {
    --l;
    if (y == height - 1) {
      wmove(text_w, 0, 0);
      wdeleteln(text_w);
      wmove(text_w, height-1, 0);
    } else {
      wmove(text_w,y+1,0);
    }
  }
  void new_line(int & l, int height) {
    int y,x;
    getyx(text_w,y,x);
    new_line(l,y,height);
  }
#endif

  void display_misspelled_word() {
    TextChain::const_iterator begin        = file->begin();
    TextChain::const_iterator end          = file->end();
    TextChain::const_iterator word_begin = state->word_begin();
    TextChain::const_iterator word_end   = state->word_end();

#if   HAVE_LIBCURSES

    if (use_curses && text_w) {
      int height, width;
      werase(text_w);
      getmaxyx(text_w,height,width);
      assert(height > 0 && width > 0);

      TextChain::const_iterator i = word_begin;
      
      //
      // backup height/3 lines
      //
      int l = height/3;
      while (true) {
	if (*i == '\n') {
	  --l;
	  if (l == 0)
	    break;
	}
	if (i == begin) break;
	--i;
      }
      
      int last_space_pos = 0;
      TextChain::const_iterator last_space = i;
      
      while (l != 0)
	new_line(l,height);

      int y, x;
      l = -1;
      int attr = A_NORMAL;
      
      while (true) {
	if (i == end) 
	  break;
	getyx(text_w,y,x);
	if (x == width-1 || *i == '\n') {
	  if (*i != '\n') {
	    if (dist(last_space, i) < width/3) {
	      wmove(text_w, y, last_space_pos);
	      wclrtoeol(text_w);
	      i = last_space;
	      ++i;
	    } 
	    wmove(text_w, y, width-1);
	    waddch(text_w,'\\');
	  } 
	  last_space = i;
	  last_space_pos = 0;
	  if (l == 0) break;
	  new_line(l,y,height);
	} else {
	  if (isspace(*i)) {
	    getyx(text_w,y,last_space_pos);
	    last_space = i;
	  }
	}
	if (i == word_begin) {
	  attr = A_REVERSE;
	  l = height*2/3;
	} else if (i == word_end) {
	  attr = A_NORMAL;
	}
	if (*i != '\n')
	  waddch(text_w, (unsigned char)*i | attr);
	++i;
      }

      while (l != 0) {
	new_line(l,height);
      }
      
      wnoutrefresh(text_w);
    } else if (use_curses && !text_w) {
      // do nothing
    } else
#endif
    {
      TextChain::const_iterator  i, line_begin, line_end;
      for (line_begin = word_begin; 
	   line_begin != begin && *line_begin != '\n';
	   --line_begin);
      if (line_begin != begin)
	++line_begin;
      for (line_end = word_end;
	 line_end != end && *line_end != '\n';
	   ++line_end);
      for(i = line_begin; i != word_begin; ++i)
	cout << *i;
      cout << '*';
      for(; i != word_end; ++i)
	cout << *i;
      cout << '*';
      for(; i != line_end; ++i) 
	cout << *i;
      cout << '\n';
    }
  }

  template <class O>
  static void print_truncate(O *out, const char * word, int width) {
    int i;
    for (i = 0; i < width-1 && word[i]; ++i)
      put(out,word[i]);
    if (i == width-1) {
      if (word[i] == '\0')
	put(out,' ');
      else if (word[i+1] == '\0')
	put(out,word[i]);
      else
	put(out,'$');
      ++i;
    }
    for (;i < width; ++i)
      put(out,' ');
  }

  template <class O>
  static void display_menu(O * out, const Choices * choices, int width) {
    if (width <= 11) return;
    Choices::const_iterator i = choices->begin();
    while (i != choices->end()) {
      put(out,i->choice);
      put(out,") ");
      print_truncate(out, i->desc, width/2 - 4);
      put(out,' ');
      ++i;
      if (i != choices->end()) {
	put(out,i->choice);
	put(out,") ");
	print_truncate(out, i->desc, width/2 - 4);
	++i;
      }
      new_line(out);
    }
  }

  static inline void put (ostream * out, char c) {*out << c;}
  static inline void put (ostream * out, const char * c) {*out << c;}
  static inline void new_line(ostream * out) {*out << '\n';}

#if   HAVE_LIBCURSES

  static inline void put (WINDOW * w, char c) 
  {
    waddch(w,static_cast<unsigned char>(c));
  }
  static inline void put (WINDOW * w, const char * c) 
  {
    waddstr(w,const_cast<char *>(c));
  }
  static inline void new_line(WINDOW * w) 
  {
    int y,x;
    getyx(w,y,x);
    wmove(w,y+1,0);
  } 

#endif
  
  void display_menu() {
#if   HAVE_LIBCURSES
    if (use_curses && menu_w) {
      if (menu_text == StdMenu) {
        scrollok(menu_w,false);
	int height,width;
	getmaxyx(menu_w,height,width);
	werase(menu_w);
	wmove(menu_w,0,0);
	display_menu(menu_w, word_choices, width);
	wmove(menu_w,5,0);
	display_menu(menu_w, menu_choices, width);
	wnoutrefresh(menu_w);
      } else {
	//ostream str;
	int height,width;
 	getmaxyx(menu_w,height,width);
	struct MenuLine {
	  const char * capname;
	  const char * fun_key;
	  const char * control_key;
	  const char * desc;
	};
	static MenuLine menu_items[8] = {
	  {0, "Enter", "", "Accept Changes"} 
	  , {0, "Backspace", "Control-H", "Delete the previous character"}
	  , {"kcub1", "Left", "Control-B", "Move Back 1 space"}
	  , {"kcuf1", "Right", "Control-F", "Move Forward 1 space"}
	  , {"khome", "Home", "Control-A", "Move to the beginning of the line"}
	  , {"kend" , "End",  "Control-E", "Move to the end of the line"}
	  , {"kdch1", "Delete", "Control-D", "Delete the next charcter"}
	  , {0, "", "Control-K", "Kill all characters to the EOL"}
	};
        scrollok(menu_w,false);
	werase(menu_w);
	for (int i = 0; i != 8; ++i) {
	  wmove(menu_w, i, 0);
	  int w = width;
	  int fun_key_desc_width = 12;
	  int control_key_desc_width = 12;
	  if (w < fun_key_desc_width) fun_key_desc_width = w;
	  if (menu_items[i].capname == 0 
	      || tigetstr(const_cast<char *>(menu_items[i].capname)) != 0) 
	    print_truncate(menu_w, menu_items[i].fun_key, fun_key_desc_width);
	  else
	    print_truncate(menu_w, "", fun_key_desc_width);
	  w -= fun_key_desc_width;
	  if (w < control_key_desc_width) control_key_desc_width = w;
	  print_truncate(menu_w, menu_items[i].control_key, 
			 control_key_desc_width);
	  w -= control_key_desc_width;
	  print_truncate(menu_w, menu_items[i].desc, w);
	}
	wnoutrefresh(menu_w);
      }
    } else if (use_curses && !menu_w) {
      // do nothing
    } else 
#endif
    {
      display_menu(&cout, word_choices, 80);
      display_menu(&cout, menu_choices, 80);
    }
  }

  void prompt(const char * prompt) {
    last_prompt = prompt;
#if   HAVE_LIBCURSES
    if (use_curses) {
      werase(choice_w);
      waddstr(choice_w, const_cast<char *>(prompt));
      wnoutrefresh(choice_w);
    } else
#endif
    {
      cout << prompt << flush;
    }
  }
  
  void error(const char * error) {
#if   HAVE_LIBCURSES 
    if (use_curses) {
      werase(choice_w);
      waddstr(choice_w, const_cast<char *>(error));
      wnoutrefresh(choice_w);
    } else 
#endif
    {
      cout << error << endl;
      cout << last_prompt << flush;
    }
  }
}

