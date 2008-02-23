// ================================================================================
//  LanguageManagerASpell.M
// ================================================================================
//	cocoAspell
//
//  Created by Anton Leuski on Fri Nov 16 2001.
//  Copyright (c) 2002-2004 Anton Leuski.
//
//	This file is part of cocoAspell package.
//
//	Redistribution and use of cocoAspell in source and binary forms, with or without 
//	modification, are permitted provided that the following conditions are met:
//
//	1. Redistributions of source code must retain the above copyright notice, this 
//		list of conditions and the following disclaimer.
//	2. Redistributions in binary form must reproduce the above copyright notice, 
//		this list of conditions and the following disclaimer in the documentation 
//		and/or other materials provided with the distribution.
//	3. The name of the author may not be used to endorse or promote products derived 
//		from this software without specific prior written permission.
//
//	THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED 
//	WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
//	MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT 
//	SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
//	EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT 
//	OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
//	INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, 
//	STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY 
//	OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// ================================================================================

//	The idea here is to combine aspell and pspell code: aspell has filters and other
//	advanced features, pspell has different languages.

#ifdef check
#undef check
#endif

#include "aspell/check.hh"
#include "aspell/suggest.hh"
#include "aspell/config.hh"
#include "aspell/app_string.hh"
#include "pspell/convert.hh"

using namespace std;
using namespace autil;
using namespace aspell;

#import "LanguageManagerASpell.h"
#import "Preferences.h"

#ifdef check
#undef check
#endif

#ifndef __cocoAspell__
#error "__cocoAspell__ is not enabled!"
#endif

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------
//	theoretically, we ought to be nice and retain/release the string, but it 
//	will never be destroyed before we die anyway, so we do not grab the ownership.

class NSStringIterator {

	class CharString : public PspellAppendableString {
	public:
		void 	append(const char * c, unsigned int) { mChar = *c; }
		char	mChar;
	};

public:
						NSStringIterator(
							PspellConvert*	inConvert	= NULL,
							NSString* 		inString	= nil, 
							unsigned 		inStart 	= 0)
							:	mConvert	(inConvert),
								mString		(inString),
								mPosition	(inStart)
						{
//							[mString retain];
						}
						
						NSStringIterator(
							const NSStringIterator& inOrigin)
							:	mConvert	(inOrigin.mConvert),
								mString		(inOrigin.mString),
								mPosition	(inOrigin.mPosition)
						{
//							[mString retain];
						}
						
						~NSStringIterator()
						{
//							[mString release];
						}
						
	const NSStringIterator&	operator = (
							const NSStringIterator& inOrigin)
						{
//							[inOrigin.mString retain];
//							[mString release];
							mConvert 	= inOrigin.mConvert;
							mString 	= inOrigin.mString;
							mPosition 	= inOrigin.mPosition;
							return *this;
						}
						
	unsigned			getPosition() const { return mPosition; }

	const char&			operator *() const 
						{ 
							CharString		b;
							if (mPosition >= [mString length]) {
#ifdef __log_words__
								NSLog(@"**** Asking for %u in %u", mPosition, [mString length]);
#endif
								b.mChar = 0;
//								Debugger();
							} else {
								unichar 		c = [mString characterAtIndex:mPosition];
								const char*		pc = (const char*)&c;
								mConvert->convert_until(pc, pc+sizeof(unichar), b);
							}
							return b.mChar; 
						}

	NSStringIterator&	operator++() { ++mPosition; return *this; }
//	NSStringIterator&	operator--() { --mPosition; return *this; }
	NSStringIterator	operator++(int) { NSStringIterator tmp(*this); ++mPosition; return tmp; }
//	NSStringIterator	operator--(int) { NSStringIterator tmp(*this); --mPosition; return tmp; }
	
protected:
	PspellConvert*	mConvert;
	NSString*		mString;
	unsigned		mPosition;

	friend bool operator == (const NSStringIterator& a, const NSStringIterator& b);
	friend bool operator != (const NSStringIterator& a, const NSStringIterator& b);
	friend bool operator >= (const NSStringIterator& a, const NSStringIterator& b);
	friend unsigned int dist(const NSStringIterator& a, const NSStringIterator& b);
};

bool 
operator == (
	const NSStringIterator& 	a, 
	const NSStringIterator& 	b)
{
	return (a.mPosition == b.mPosition);
}

bool 
operator != (
	const NSStringIterator& 	a, 
	const NSStringIterator& 	b)
{
	return (a.mPosition != b.mPosition);
}

bool 
operator >= (
	const NSStringIterator& 	a, 
	const NSStringIterator& 	b)
{
	return (a.mPosition >= b.mPosition);
}

unsigned int 
dist(
	const NSStringIterator& 	a, 
	const NSStringIterator& 	b)
{
	return (b.mPosition - a.mPosition);
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

class NSStringIteratorEndFException : public exception {

};

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------
//	this is to get around a bug in aspell that does not stop checking after
//	the of the string. It happens when sgml or tex filter is enabled.

class NSStringIteratorEndF
{
public:		
						NSStringIteratorEndF() {}
						NSStringIteratorEndF(const NSStringIterator& i) : mIter(i) {}
	bool	operator()	(const NSStringIterator& i) const 
	{ 
		if (i.getPosition() > mIter.getPosition()) {
#ifdef __log_words__
			NSLog(@"---------------- %u > %u", i.getPosition(), mIter.getPosition());
#endif
			throw NSStringIteratorEndFException();
		}
		return (i >= mIter); 
	}
	
protected:
	NSStringIterator	mIter;
};

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

struct WordCounter {
	int* wordCount;
	WordCounter(int* p) : wordCount (p) {}
	void operator() () const { ++*wordCount; }
};


@implementation LanguageManagerASpell


// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (id)initWithLanguage:(LanguageDesc*)desc extraOptions:(NSArray*)opts
{
	LanguageManagerASpell*	theReturn = nil;
	
	mManager 		= NULL;
	to_internal_	= NULL;
	from_internal_	= NULL;
	mState			= NULL;
	
	self = [super initWithLanguage:desc];
	if (!self) {
		return theReturn;
	}


	PspellConfig*	config = makeMyPspellConfig();	
	
	for(unsigned i = 0; i < [opts count]; i += 2) {
		pspell_config_replace(config, 
			[[opts objectAtIndex:i] cString], [[opts objectAtIndex:(i+1)] UTF8String]);
	}

	NSArray*		localOpts = [self optionsAsArray];

//	NSLog(@"%@", localOpts);
	
	for(unsigned i = 0; i < [localOpts count]; i += 2) {
		pspell_config_replace(config, 
			[[localOpts objectAtIndex:i] cString], [[localOpts objectAtIndex:(i+1)] UTF8String]);
	}
		
	mManager = NULL;
	
	try {
		mManager 			= new Manager;

// +++ begin adopted from pspell_aspell/manager.cc

		mManager->init_config();
		mManager->config().set_extra(pspell_config_impl_keys_begin,
										pspell_config_impl_keys_end);
    
		PspellConfigImpl*	realConfig = dynamic_cast<PspellConfigImpl*>(config);
		string	encoding 	= realConfig->retrieve("encoding");
		
		assert(realConfig != 0);

//		realConfig->write_to_stream(cout);

		mManager->setup(*realConfig);

#ifdef __log_words__
//		mManager->config().real_config().write_to_stream(cout);
#endif
//		mManager->config().write_to_stream(cout);

		const char* charset = mManager->lang().charset();
	
		PspellCanHaveError* temp;
	
		temp = new_pspell_convert(*config, encoding.c_str(), charset);
		if (temp->error_number() != 0) {
			throw temp->error_message();
		}
		to_internal_ 		= static_cast<PspellConvert*>(temp);
		
		temp = new_pspell_convert(*config, charset, encoding.c_str());
		if (temp->error_number() != 0) {
			throw temp->error_message();
		}
		from_internal_ 		= static_cast<PspellConvert*>(temp);

// +++ end adopted from pspell_aspell/manager.cc

		mState 		= new NSStringCheckState(*mManager);
		theReturn 	= self;

	} catch (const char* e) {
		NSLog(@"Aspell initilialization failed for language %@: %s", [self languageName], e);
		[self release];
	} catch (exception& e) {
		NSLog(@"Aspell initilialization failed for language %@: %s", [self languageName], e.what());
		[self release];
	}
	
	delete_pspell_config(config);

	return theReturn;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)dealloc
{
	delete mState;
	delete from_internal_;
	delete to_internal_;
	delete mManager;
	[super dealloc];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (NSRange)spellServer:(NSSpellServer*)sender
	findMisspelledWordInString:(NSString*)stringToCheck 
	wordCount:(int*)wordCount 
	countOnly:(BOOL)countOnly
{
	NSRange		allRange = NSMakeRange([stringToCheck length], 0);

	try {

		WordCounter	wc(wordCount);
		*wordCount = 0;
	
		NSStringIterator	i(to_internal_, stringToCheck, 0);
		NSStringIterator	end(to_internal_, stringToCheck, [stringToCheck length]);
	
		mState->restart(i, end);
		mState->advance();
	
#ifdef __log_words__
		NSLog(@"Check: |%u chars|", [stringToCheck length]);
//		mManager->config().real_config().write_to_stream(cout);
#endif
	
		
		while (YES) {
		
			check(*mState, wc);
	
			if (mState->at_end())
				break;
	
			unsigned	b = mState->word_begin().getPosition();
	
			if (b >= [stringToCheck length])
				break;
	
			if (!countOnly) {
				unsigned	e 			= mState->word_end().getPosition();
				NSRange		theRange	= NSMakeRange(b, e-b);
				BOOL		hasWord		= NO;
				
				// Apple's BUG!!!
				// isWordInUserDictionaries crashes with non-latin words (Russian words)
				// it should be fixed in OS 10.2
				
				NSString*	ss 			= [stringToCheck substringWithRange:theRange];
				
				NS_DURING
					hasWord = [sender isWordInUserDictionaries:ss caseSensitive:NO];
				NS_HANDLER
					hasWord = NO;
				NS_ENDHANDLER
				
				if (!hasWord) {
#ifdef __log_words__
					NSLog(@"Unknown word! Location: %d|Length: %d|Word: %@", theRange.location, theRange.length, ss);
#endif
					return theRange;
				}
			}
			
			++*wordCount;
			mState->advance();
		}
	
	} catch (NSStringIteratorEndFException e) {
		mState->start_over();
	} catch (...) {
		mState->start_over();
	}

	return allRange;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (NSString*)fromInternal:(const char*)word
{
	string		realBuf;
	AppString 	buf(&realBuf);
	try {
		from_internal_->convert(word, buf);
		return [NSString stringWithCharacters:(const unichar*)realBuf.data() 
					length:(realBuf.length()/sizeof(unichar))];
	} catch (exception& e) {
		NSLog(@"Aspell conversion of word |%s| from internal representaion failed for language %@: %s", word, [self languageName], e.what());
		return [NSString string];
	}
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (NSArray*)spellServer:(NSSpellServer*)sender
	suggestGuessesForWord:(NSString*)word
{
	string		realBuf;
	AppString 	buf(&realBuf);
	
	try {
		to_internal_->convert((const char*)[word UniChars], (int)([word length] * sizeof(unichar)), buf);
	
	#ifdef __log_words__
		NSLog(@"Find guesses for: %@", word);
	#endif
	
		const SuggestionList* suggestions = &mManager->suggest(realBuf);
		
		if (!suggestions->size()) {
			return [NSArray array];
		}
		
		NSMutableArray*	sugg = [NSMutableArray arrayWithCapacity:suggestions->size()];
		
		Emulation<const char *> els = suggestions->elements();
		const char*		 		w;
		while ((w = els.next()) != 0) {
	//		NSLog(@"%s", w);
			[sugg addObject:[self fromInternal:w]];
		}
		
		return sugg;
	} catch (exception& e) {
		NSLog(@"Aspell suggestion search for word |%@| failed for language %@: %s", word, [self languageName], e.what());
		return [NSArray array];
	}
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (BOOL)setPreferences:(NSDictionary*)dict withExtraOptions:(NSArray*)extra
{
	BOOL	res = [super setPreferences:dict withExtraOptions:extra];
	if (mState)	
		mState->start_over();
	return res;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (NSString*)configForKey:(NSString*)key;
{
	const char*	value = mManager->config().real_config().retrieve([key cString]);
	return [NSString stringWithCString:value];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)setConfig:(NSString*)obj forKey:(NSString*)key;
{
	mManager->config().real_config().replace([key cString], [obj UTF8String]);
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)spellServer:(NSSpellServer*)sender
	learnWord:(NSString*)word
{
	string		realBuf;
	AppString 	buf(&realBuf);
	unsigned	len		= [word length];
	
	try {	
		to_internal_->convert((const char*)[word UniChars], (int)(len * sizeof(unichar)), buf);
	
		mManager->add_to_personal(realBuf);
		mManager->save_all_wls();
	} catch (exception& e) {
		NSLog(@"Aspell learning of word |%@| failed for language %@: %s", word, [self languageName], e.what());
	}
}

@end


#ifdef __cocoAspell_app__
#include "SpellingController.h"
#define TheMain				cocoAspellApplicationMain
#else
#include "cocoAspell.h"
#define	TheMain				cocoAspellMainServerOnly
#endif

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------


int 	cocoAspell_mainWithOptions(int argc, const char* argv[], Config& options);

int 
cocoAspell_mainWithOptions(
	int 		argc, 
	const char* argv[], 
	Config& 	options)
{
	int		result = 0;
		
	if ((argc == 1) || ((argc == 2) && (!strncmp(argv[1], "-psn", 4))) ) {

		TheMain(argc, argv);
		result = 1;	

	} else {
	
		NSAutoreleasePool*	pool		= [[NSAutoreleasePool alloc] init];

		if ((argc == 2) && (!strcmp(argv[1], "pkgdatadir"))) {
		
			printf("%s\n", [[Preferences pathFromBundle:realMainBundle() to:kPathPspellData] UTF8String]);
			result = 1;	
	
		} else {
		
//			NSString*	data_aspell = [Preferences pathFromBundle:[NSBundle mainBundle] to:kPathAspellData];
//			NSString*	data_pspell = [Preferences pathFromBundle:[NSBundle mainBundle] to:kPathPspellData];
	
/*
			int		i;
			BOOL	creatingMaster = NO;
			
			for(i = 1; i < argc; ++i) {
				if (!strcmp(argv[i], "create") && !strcmp(argv[i+1], "master")) {
					creatingMaster = YES;
					break;
				}
			}
*/

//			PspellKeyInfo	extra = {"pspell-data-dir", PspellKeyInfoString, "", ""}; 
//			options.set_extra(&extra, (&extra)+1);
			
//			options.replace("local-data-dir", 	(creatingMaster ? "." : [data_aspell UTF8String]));
			options.replace("prefix", [[realMainBundle() resourcePath] UTF8String]);
//			options.replace("data-dir", 		[data_aspell UTF8String]);
//			options.replace("pspell-data-dir",	[data_pspell UTF8String]);
//			options.replace("dict-dir", 		[data_pspell UTF8String]);
			
		}
	
		[pool release];
		
	}

	return result;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------
//	this is the default config that is a combination of pspell and aspell configs
//	We need it here to set the path prefix to our location. 
//	This way we can get around a restrcition in aspell code that declares 
//	prefix as a read-only field.
 
#define CANT_CHANGE 1

#define HOME_DIR	"<$HOME|./>"
#define PERSONAL	".aspell.<language-tag>.pws"
#define REPL     	".aspell.<language-tag>.prepl"
#define PREFIX 		"/usr/local/aspell"
#define DICT_DIR 	"<prefix:lib/aspell>"
#define DATA_DIR	"<prefix:share/aspell>"
#define CONF_DIR	"<prefix:etc>"
#define PSPELL_DATA	"<prefix:share/pspell>"

  static PspellKeyInfo config_keys[] = {

	{"language-tag", PspellKeyInfoString, "en", "language code"}
	, {"encoding",   PspellKeyInfoString, "iso8859-1", "encoding to expect data to be in"}
	, {"spelling",   PspellKeyInfoString, "", "spelling for languages with more than one"}
	, {"jargon",     PspellKeyInfoString, "", "extra information for the word list"}
//	, {"ignore",     PspellKeyInfoInt,    "(default)", "ignore words <= n chars"}
//	, {"sug-mode",   PspellKeyInfoString, "(default)", "suggestion mode"}
//	, {"run-together",     PspellKeyInfoBool, "(default)", "consider run-together words legal"}
//	, {"personal",      PspellKeyInfoString, "(default)", "personal word list to use"}
//	, {"ignore-repl", PspellKeyInfoBool  , "(default)", "ignore commands to store replacement pairs"}
//	, {"save-repl",   PspellKeyInfoBool  , "(default)", "save replacement pairs on save all"}
//	, {"repl",        PspellKeyInfoString, "(default)", "replacements list file name"}
	, {"word-list-path", PspellKeyInfoList, PSPELL_DATA, "Search path for word list information files"}
	, {"module-search-order", PspellKeyInfoList, "aspell", ""}
//	, {"master",        PspellKeyInfoString, "", 0}
	, {"master-flags",  PspellKeyInfoString, "", 0}
	, {"module",        PspellKeyInfoString, "", 0}
//	, {"data-dir",      PspellKeyInfoString, DATADIR, "", ""}
//	, {"pspell-data-dir",      PspellKeyInfoString, DATADIR, "", ""}
	

    , {"charset",  PspellKeyInfoString, "iso8859-1",0}
    , {"conf",     PspellKeyInfoString, "aspell.conf",  "main configuration file"             , {0, CANT_CHANGE}}
    , {"conf-dir", PspellKeyInfoString, CONF_DIR,      "location of main configuration file" ,{0, CANT_CHANGE}}
    , {"conf-path",     PspellKeyInfoString, "<conf-dir/conf>",     0}
    , {"data-dir", PspellKeyInfoString, DATA_DIR,        "location of language data files"     }
    , {"dict-dir", PspellKeyInfoString, DICT_DIR,        "location of the main word list"      }
    , {"extra-dicts", PspellKeyInfoList, "", "extra dictionaries to use"}
    , {"filter",   PspellKeyInfoList  , "url",             "add or removes a filter"}
    , {"fm-email", PspellKeyInfoList  , "url,email",                         0}
    , {"fm-none",  PspellKeyInfoList  , "",                                  0}
    , {"fm-sgml",  PspellKeyInfoList  , "url,sgml,SGML&<charset>/<charset>", 0}
    , {"fm-tex",   PspellKeyInfoList  , "url,tex",                           0}
    , {"fm-url",   PspellKeyInfoList  , "url",                               0}
    , {"home-dir", PspellKeyInfoString, HOME_DIR,   "location for personal files" }
    , {"ignore",   PspellKeyInfoInt   , "1",            "ignore words <= n chars"             }
    , {"ignore-accents" , PspellKeyInfoBool, "false", "ignore accents when checking words"}
    , {"ignore-case", PspellKeyInfoBool  , "false",     "ignore case when checking words"}
    , {"ignore-repl", PspellKeyInfoBool  , "false",     "ignore commands to store replacement pairs"}
    , {"keyboard", PspellKeyInfoString, "standard", "keyboard definition to use for typo analysis"}
    , {"lang",     PspellKeyInfoString, "english",      "default language to use when all else fails", {0, CANT_CHANGE}}
    , {"language-tag", PspellKeyInfoString, "<$LANG|en>", "language code to use when selecting a dictionary", {0, CANT_CHANGE}}
    , {"local-data-dir", PspellKeyInfoString, DATA_DIR,        "location of local language data files"     }
    , {"master",   PspellKeyInfoString, "",             "base name of the main dictionary to use",           }
    , {"master-path",   PspellKeyInfoString, "<dict-dir/master>",   0}
    , {"minimal-specified-component", PspellKeyInfoInt, "255", 0}
    , {"mode",     PspellKeyInfoString, "",             "filter mode = " }
    , {"per-conf", PspellKeyInfoString, ".aspell.conf", "personal configuration file",{0, CANT_CHANGE}}
    , {"per-conf-path", PspellKeyInfoString, "<home-dir/per-conf>", 0}
    , {"personal", PspellKeyInfoString, PERSONAL,   "personal word list file name"}
    , {"personal-path", PspellKeyInfoString, "<home-dir/personal>", 0}
    , {"prefix",   PspellKeyInfoString, PREFIX, "prefix directory", {0, CANT_CHANGE}}
	, {"pspell-data-dir", PspellKeyInfoString, PSPELL_DATA, "location of language data files"} 
    , {"set-prefix", PspellKeyInfoBool, "true", "set the prefix based on executable location", {0, CANT_CHANGE}} 
    , {"repl",     PspellKeyInfoString, REPL, "replacements list file name" }
    , {"repl-path",     PspellKeyInfoString, "<home-dir/repl>",     0}
    , {"run-together",        PspellKeyInfoBool,  "false", "consider run-together words legal"}
    , {"run-together-limit",  PspellKeyInfoInt,   "8", "maxium numbers that can be strung together"}
    , {"run-together-min",    PspellKeyInfoInt,   "3", "minimal length of interior words"}
    , {"run-together-specified", PspellKeyInfoBool, "false", 0}
    , {"save-repl", PspellKeyInfoBool  , "true", "save replacement pairs on save all"}
    , {"strip-accents" , PspellKeyInfoBool, "false", "strip accents from word lists"}
    , {"sug-mode",    PspellKeyInfoString, "normal",    "suggestion mode = ultra|fast|normal|bad-spellers"}

	, {"email-quote", PspellKeyInfoList, ">,|", "email quote characters"}
	, {"email-margin", KeyInfoInt, "10",  "num chars that can appear before the quote char"}	
	, {"sgml-check", KeyInfoList, "alt", "sgml tags to always check."}
	, {"tex-check-comments", KeyInfoBool, "false", "check comments" }
	, {"tex-command", KeyInfoList, "", "tex-commands" }
  };

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

static char*	sPrefix = NULL;

PspellConfig*
makeMyPspellConfig()
{
	PspellConfig*		config;
	unsigned			i, n = sizeof(config_keys) / sizeof(PspellKeyInfo);

	if (!sPrefix) {
		const char*		path = [[realMainBundle() resourcePath] UTF8String];
		sPrefix = (char*)malloc(strlen(path)+1);
		strcpy(sPrefix, path);
//		NSLog(@"%@",[realMainBundle() resourcePath]); 
	}

	for(i = 0; i < n; ++i) {
		if (!strcmp(config_keys[i].name, "prefix")) {
			config_keys[i].def = sPrefix;
		}
	}
	
	config = new PspellConfigImpl("pspell",
			      config_keys, 
			      config_keys + n); // new_pspell_config();

//	pspell_config_set_extra(config, config_keys, config_keys + sizeof(config_keys) / sizeof(PspellKeyInfo));
	return config;
}


