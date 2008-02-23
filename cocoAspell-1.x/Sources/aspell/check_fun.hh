#ifndef check_fun__hh
#define check_fun__hh

#include <vector>

#include "text_chain.hh"

#include "check.hh"

#define MENU_HEIGHT 8

namespace aspell_check_fun {
  using namespace autil;
  using namespace std;

  extern TextChain * file;
  extern aspell::CheckState<TextChain::const_iterator> * state;
  extern const char * last_prompt;
  struct Choice {
    char choice; 
    const char * desc;
    Choice() {}
    Choice(char c, const char * d) : choice(c), desc(d) {}
  };
  typedef vector<Choice> Choices;
  extern Choices * word_choices;
  extern Choices * menu_choices;

  void get_choice(char & choice);
  void get_line(string & line);
  void begin_check();
  void display_misspelled_word();
  void display_menu();
  void prompt(const char * prompt);
  void error(const char * error);

}

#endif
