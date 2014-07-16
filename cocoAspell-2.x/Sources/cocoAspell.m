// ============================================================================
//  cocoAspell.m
// ============================================================================
//
//	cocoAspell2
//
//  Created by Anton Leuski on 2/13/05.
//  Copyright (c) 2005-2008 Anton Leuski. All rights reserved.
// ============================================================================

#import <Foundation/Foundation.h>
#import "DictionaryManager.h"
#import "AspellDictionary.h"
#import "MultilingualDictionary.h"
#import "AspellOptions.h"
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
		dictionaryManager	= dm;

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
	
	dictionaryManager	= nil;
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
	Dictionary*		d	= nil;

#ifdef __multilingual__	
	if ([kMultilingualDictionaryName isEqualToString:inName]) {
		d	= [[MultilingualDictionary alloc] initWithDictionaries:[[self dictionaryManager] enabledDictionaries]];
		[d setFilterConfig:[[[self dictionaryManager] filters] aspellConfig]];
		return d;
	} 
#endif // __multilingual__

	for (Dictionary* dd in [[self dictionaryManager] dictionaries]) {
		if ([inName isEqualToString:dd.name]) {
			d	= dd;
			break;
		}
	}
	[d setFilterConfig:[[[self dictionaryManager] filters] aspellConfig]];
	return d;
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

- (void)spellServer:(NSSpellServer *)sender 
	didForgetWord:				(NSString *)word 
	inLanguage:					(NSString *)language
{
#ifdef __debug__
	NSLog(@"forget |%@| for language %@", word, language);
#endif

	[[self dictionaryForName:language] forgetWord:word];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)spellServer:(NSSpellServer *)sender 
	didLearnWord:				(NSString *)word 
	inLanguage:					(NSString *)language
{
#ifdef __debug__
	NSLog(@"learn |%@| for language %@", word, language);
#endif

	[[self dictionaryForName:language] learnWord:word];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (NSRange)spellServer:(NSSpellServer *)sender 
	findMisspelledWordInString:	(NSString *)stringToCheck 
	language:					(NSString *)language 
	wordCount:					(NSInteger *)wordCount 
	countOnly:					(BOOL)countOnly
{
#ifdef __debug__
	NSLog(@"check |%@| for language %@, count only: %d", stringToCheck, language, (int)countOnly);
#endif

	Dictionary*		dict	= [self dictionaryForName:language];
	NSRange			result	= NSMakeRange(NSNotFound, 0);
	BOOL			cs		= dict.caseSensitive;

	NSUInteger				textSize	= sizeof(unichar) * [stringToCheck length];
	unichar*				textData	= (unichar*)malloc(textSize);
	if (textData) {
		NSUInteger	start	= 0;
		[stringToCheck getCharacters:textData];
		while (1) {
			int			wc;
			result		= [dict findMisspelledWordInBuffer:textData+start size:textSize-start*sizeof(unichar) wordCount:&wc countOnly:countOnly];
			*wordCount += wc;
			if (result.location == NSNotFound) 
				break;

			result				= NSMakeRange(result.location+start, result.length);
			NSString*	word	= [stringToCheck substringWithRange:result];
			if (![sender isWordInUserDictionaries:word caseSensitive:cs])
				break;

#ifdef __debug__
			NSLog(@"word |%@| is in user's dictionary", word);
#endif

			start = result.location + result.length;
			*wordCount += 1;
		}
		free(textData);
	}
	
#ifdef __debug__
	NSLog(@"found misspeling at %@ and word count %d : |%@|", NSStringFromRange(result), *wordCount, ((result.location == NSNotFound) ? @"" : [stringToCheck substringWithRange:result]));
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
	NSLog(@"suggestions for word |%@| for language %@", word, language);
#endif

	NSMutableArray*	result	= [NSMutableArray array];
	
	if (![UserDefaults cocoAspellIsRegistered]) {
		[result addObject:kPleaseRegister];
	}

	[result addObjectsFromArray:[[self dictionaryForName:language] suggestGuessesForWord:word]];

#ifdef __debug__
	NSLog(@"suggestions: %@", result);
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
	NSLog(@"completions for word |%@| in string |%@| for language %@", [str substringWithRange:inRange], str, language);
#endif

	NSMutableArray*	result	= [NSMutableArray array];

	if (![UserDefaults cocoAspellIsRegistered]) {
		[result addObject:kPleaseRegister];
	}

	[result addObjectsFromArray:[[self dictionaryForName:language] suggestCompletionsForPartialWordRange:inRange inString:str]];

#ifdef __debug__
	NSLog(@"completions: %@", result);
#endif
	return result;
}

@end

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

int main(int argc, char** argv)
{
	@autoreleasepool {

		if (![UserDefaults cocoAspellExpired]) {

			NSSpellServer*		aServer = [[NSSpellServer alloc] init];
			
			DictionaryManager*	dm		= [[DictionaryManager alloc] init];
			[dm setDictionaries:[dm allDictionaries]];
			
			NSUInteger			nregistered = 0;
			
			NSLog(@"Attempting to regirster %d dictionaries", [[dm dictionaries] count]);
			
			for (Dictionary* d in [dm dictionaries]) {
				if (d.enabled) {
					NSString*	name	= d.name;
					NSString*	path	= [d isKindOfClass:[AspellDictionary class]] ? [((AspellDictionary*)d).options valueForKey:@"dict-dir"] : nil;
					if (![aServer registerLanguage:name byVendor:@"Aspell"]) {
						NSLog(@"cocoAspell failed to register %@ from %@/%@\n", name, path, d.identifier); 
					} else {
						++nregistered;
						NSLog(@"cocoAspell registered %@ from %@/%@\n", name, path, d.identifier); 		
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


		} else {
		
			NSLog(@"This version of cocoAspell has expired");

		}

	}
	return 0;
}
