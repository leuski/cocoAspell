// ============================================================================
//  cocoAspell.m
// ============================================================================
//
//	cocoAspell2
//
//  Created by Anton Leuski on 2/13/05.
//  Copyright (c) 2005 Anton Leuski. All rights reserved.
// ============================================================================

#import <Foundation/Foundation.h>
#import "DictionaryManager.h"
#import "Dictionary.h"
#import "AspellOptions.h"
#import "aspell.h"
#import "aspell_extras.h"
#import "cocoa_document_checker.h"
#import "UserDefaults.h"

//#define __debug__

@interface cocoAspell : NSObject {
	DictionaryManager*	dictionaryManager;
}

- (id)initWithDictionaryManager:(DictionaryManager*)dm;

@end

static NSString*	kPleaseRegister	= @"Register your cocoAspell";

@implementation cocoAspell

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (id)initWithDictionaryManager:(DictionaryManager*)dm
{
	if (self = [super init]) {
		dictionaryManager	= [dm retain];

		[(NSNotificationCenter*)[NSDistributedNotificationCenter defaultCenter] 
			addObserver:	self
			selector:		@selector(aspellOptionsChanged:)
			name:			kAspellOptionsChangedNotification 
			object:			nil];

		[(NSNotificationCenter*)[NSDistributedNotificationCenter defaultCenter] 
			addObserver:	self
			selector:		@selector(dictionarySetChanged:)
			name:			kAspellDictionarySetChangedNotification 
			object:			nil];
	}
	return self;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)dealloc
{
	[(NSNotificationCenter*)[NSDistributedNotificationCenter defaultCenter] 
		removeObserver:	self 
		name:			kAspellOptionsChangedNotification 
		object:			nil];
	
	[(NSNotificationCenter*)[NSDistributedNotificationCenter defaultCenter] 
		removeObserver:	self 
		name:			kAspellDictionarySetChangedNotification 
		object:			nil];
	
	[dictionaryManager release];
	dictionaryManager	= nil;
	[super dealloc];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (DictionaryManager*)dictionaryManager
{
	return dictionaryManager;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (Dictionary*)dictionaryForName:(NSString*)inName
{
	NSEnumerator*	i	= [[[self dictionaryManager] dictionaries] objectEnumerator];
	Dictionary*		d;
	while (d = [i nextObject]) {
		if ([inName isEqualToString:[d name]])
			return d;
	}
	return nil;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)aspellOptionsChanged:(NSNotification*)notification
{
	exit(0);
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)dictionarySetChanged:(NSNotification*)notification
{
	exit(0);
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (AspellConfig*)configForLanguage:(NSString*)inLanguage caseSensitive:(BOOL*)cs
{
	if (cs)	
		*cs	= YES;

	Dictionary*		theDict		= [self dictionaryForName:inLanguage];
	if (!theDict) {
		NSLog(@"no dictionary for language %@", inLanguage);
		return nil;
	}

	AspellConfig*	filterConfig	= [[[self dictionaryManager] filters] aspellConfig];
	AspellConfig*	dictConfig		= [[theDict options] aspellConfig];
	
	if (cs)
		*cs	= ![[theDict options] valueForKey:@"ignore-case"];
		
//		NSLog(@"%@", [AspellOptions aspellOptionsWithAspellConfig:filterConfig]); 
//		NSLog(@"%@", [AspellOptions aspellOptionsWithAspellConfig:dictConfig]); 

	AspellConfig*	config			= aspell_config_clone(filterConfig);

//		NSLog(@"%@", [AspellOptions aspellOptionsWithAspellConfig:config]); 

	if (!aspell_config_merge(config, dictConfig)) {
		NSLog(@"failed to merge dictionary for language %@ and filter descriptions", inLanguage);
		return nil;
	}

//		NSLog(@"%@", [AspellOptions aspellOptionsWithAspellConfig:config]); 
	
	return config;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (AspellSpeller*)spellerForLanguage:(NSString*)inLanguage caseSensitive:(BOOL*)cs
{	
	AspellConfig*		config			= [self configForLanguage:inLanguage caseSensitive:cs];
	if (!config) return nil;
	
//		NSLog(@"%@", [AspellOptions aspellOptionsWithAspellConfig:config]); 	

	AspellCanHaveError*	possible_err	= new_aspell_speller(config);
	delete_aspell_config(config);

	if (aspell_error_number(possible_err) != 0) {
		NSLog(@"failed to initialize speller for language %@: %s", inLanguage, aspell_error_message(possible_err));
		delete_aspell_can_have_error(possible_err);
		return nil;
	}

	return to_aspell_speller(possible_err);
}
	   
// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)spellServer:(NSSpellServer *)sender 
	didForgetWord:				(NSString *)word 
	inLanguage:					(NSString *)language
{
#ifdef __debug__
	NSLog(@"forget |%@| for %@", word, language);
#endif

	AspellSpeller*	speller	= [self spellerForLanguage:language caseSensitive:nil];
	if (speller) {
		unsigned	textSize	= sizeof(unichar) * [word length];
		unichar*	textData	= (unichar*)malloc(textSize);
		if (textData) {
			[word getCharacters:textData];
#ifdef __debug__
			int		x = 
#endif
			aspell_speller_remove_from_personal(speller, (const char*)textData, textSize);
#ifdef __debug__
			NSLog(@"%d %s", x, aspell_speller_error_message(speller));
#endif
			free(textData);
			aspell_speller_save_all_word_lists(speller);
		}
		delete_aspell_speller(speller);
	} 
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)spellServer:(NSSpellServer *)sender 
	didLearnWord:				(NSString *)word 
	inLanguage:					(NSString *)language
{
#ifdef __debug__
	NSLog(@"learn |%@| for %@", word, language);
#endif

	AspellSpeller*	speller	= [self spellerForLanguage:language caseSensitive:nil];
	if (speller) {
		unsigned	textSize	= sizeof(unichar) * [word length];
		unichar*	textData	= (unichar*)malloc(textSize);
		if (textData) {
			[word getCharacters:textData];
#ifdef __debug__
			int		x = 
#endif
			aspell_speller_add_to_personal(speller, (const char*)textData, textSize);
#ifdef __debug__
			NSLog(@"%d %s", x, aspell_speller_error_message(speller));
#endif
			free(textData);
			aspell_speller_save_all_word_lists(speller);
		}
		delete_aspell_speller(speller);
	} 
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (NSRange)spellServer:(NSSpellServer *)sender 
	findMisspelledWordInString:	(NSString *)stringToCheck 
	language:					(NSString *)language 
	wordCount:					(int *)wordCount 
	countOnly:					(BOOL)countOnly
{
#ifdef __debug__
	NSLog(@"check |%@| for %@, %d", stringToCheck, language, (int)countOnly);
#endif

	NSRange			result	= NSMakeRange(NSNotFound, 0);
	BOOL			caseSensitive;
	AspellSpeller*	speller	= [self spellerForLanguage:language caseSensitive:&caseSensitive];
	if (speller) {
		unsigned				textSize	= sizeof(unichar) * [stringToCheck length];
		unichar*				textData	= (unichar*)malloc(textSize);
		if (textData) {
			unsigned	start	= 0;
			unsigned	offset;
			unsigned	length;
			[stringToCheck getCharacters:textData];
			while (1) {
				int		wc;
				aspell_speller_check_spelling(speller, (const char*)(textData+start), textSize-start*sizeof(unichar), &wc, countOnly, &offset, &length);
				*wordCount += wc;
				if (length) {
	//				result	= NSMakeRange(offset / sizeof(unichar), length / sizeof(unichar));
					result	= NSMakeRange(offset+start, length);
					NSString*	word	= [stringToCheck substringWithRange:result];
					if (![sender isWordInUserDictionaries:word caseSensitive:caseSensitive])
						break;
					start += offset + length;
					*wordCount += 1;
				} else {
					result	= NSMakeRange(NSNotFound, 0);
					break;
				}
			}
			free(textData);
		}
		delete_aspell_speller(speller);
	}

#ifdef __debug__
	NSLog(@"found |%@| at %d : |%@|", NSStringFromRange(result), *wordCount, ((result.location == NSNotFound) ? @"" : [stringToCheck substringWithRange:result]));
#endif

	return result;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (NSArray *)spellServer:(NSSpellServer *)sender 
	suggestGuessesForWord:		(NSString *)word 
	inLanguage:					(NSString *)language
{
#ifdef __debug__
	NSLog(@"suggestions |%@| for %@", word, language);
#endif

	NSMutableArray*	result	= [NSMutableArray array];
	
	if (![UserDefaults cocoAspellIsRegistered]) {
		[result addObject:kPleaseRegister];
	}
	
	AspellSpeller*	speller	= [self spellerForLanguage:language caseSensitive:nil];
	if (speller) {
		unsigned	textSize	= sizeof(unichar) * [word length];
		unichar*	textData	= (unichar*)malloc(textSize);
		if (textData) {
			[word getCharacters:textData];
			const AspellWordList*		suggestions = aspell_speller_suggest(speller, (const char*)textData, textSize);
			AspellStringEnumeration*	elements	= aspell_word_list_elements(suggestions);
			const char * word;
			while ( (word = aspell_string_enumeration_next(elements)) != NULL ) {
				const unichar*	w	= (const unichar*)word;
				for(; *w; ++w);
				[result addObject:[NSString stringWithCharacters:(const unichar*)word length:(w - (const unichar*)word)]];
			}
			delete_aspell_string_enumeration(elements);
			free(textData);
		}
		delete_aspell_speller(speller);
	} 
#ifdef __debug__
	NSLog(@"suggestions |%@|", result);
#endif
	return result;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (NSArray*)spellServer:(NSSpellServer*)sender
	suggestCompletionsForPartialWordRange:(NSRange)inRange 
	inString:					(NSString*)str 
	language:					(NSString*)language
{
#ifdef __debug__
	NSLog(@"completions |%@| in |%@| for %@", [str substringWithRange:inRange], str, language);
#endif

	NSMutableArray*	result	= [NSMutableArray array];

	if (![UserDefaults cocoAspellIsRegistered]) {
		[result addObject:kPleaseRegister];
	}

	AspellSpeller*	speller	= [self spellerForLanguage:language caseSensitive:nil];
	if (speller) {
		NSString*	prefix		= [str substringWithRange:inRange];
		NSString*	word		= prefix;
		unsigned	textSize	= sizeof(unichar) * [word length];
		unichar*	textData	= (unichar*)malloc(textSize);
		if (textData) {
			[word getCharacters:textData];
			const AspellWordList*		suggestions = aspell_speller_suggest(speller, (const char*)textData, textSize);
			AspellStringEnumeration*	elements	= aspell_word_list_elements(suggestions);
			const char*					word;
			while ( (word = aspell_string_enumeration_next(elements)) != NULL ) {
				const unichar*	w	= (const unichar*)word;
				for(; *w; ++w);
				NSString*		tw	= [NSString stringWithCharacters:(const unichar*)word length:(w - (const unichar*)word)];
				if ([tw hasPrefix:prefix]) {
					[result addObject:tw];
				}
			}
			delete_aspell_string_enumeration(elements);
			free(textData);
		}
		delete_aspell_speller(speller);
	} 
#ifdef __debug__
	NSLog(@"completions |%@|", result);
#endif
	return result;
}

@end

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

int main(int argc, char** argv)
{
	NSAutoreleasePool*	pool	= [[NSAutoreleasePool alloc] init];

	if (![UserDefaults cocoAspellExpired]) {

		NSSpellServer*		aServer = [[NSSpellServer alloc] init];
		
		DictionaryManager*	dm		= [[[DictionaryManager alloc] init] autorelease];
		[dm setDictionaries:[dm allDictionaries]];
		
		unsigned			nregistered = 0;
		
		NSLog(@"Attempting to regirster %d dictionaries", [[dm dictionaries] count]);
		
		NSEnumerator*		i		= [[dm dictionaries] objectEnumerator];
		Dictionary*			d;
		while (d = [i nextObject]) {
			if ([d isEnabled]) {
				NSString*	name = [d name];
				if (![aServer registerLanguage:name byVendor:@"Aspell"]) {
					NSLog(@"cocoAspell failed to register %@ from %@/%@\n", name, [[d options] valueForKey:@"dict-dir"], [d identifier]); 
				} else {
					++nregistered;
					NSLog(@"cocoAspell registered %@ from %@/%@\n", name, [[d options] valueForKey:@"dict-dir"], [d identifier]); 		
				}
			}
		}
		
		if (nregistered > 0) {

			NSLog(@"Starting Aspell SpellChecker.\n");

			cocoAspell*	server	= [[cocoAspell alloc] initWithDictionaryManager:dm];
	//		@try {
				[aServer setDelegate:server];
				[aServer run];
	//		} @catch (NSException* ex) {
	//			NSLog(@"%@", ex);
	//		} @finally {
	//			[server release];
	//		}

		} else {
		
			NSLog(@"There are no languages enabled. Canceling cocoAspell SpellChecker.\n");
			
		}

		[aServer release];

	} else {
	
		NSLog(@"This version of cocoAspell has expired");

	}

	[pool release];
	return 0;
}
