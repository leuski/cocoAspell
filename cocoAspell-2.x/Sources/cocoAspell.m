// ============================================================================
//  cocoAspell.m
// ============================================================================
//
//	cocoAspell2
//
//  Created by Anton Leuski on 2/13/05.
//  Copyright (c) 2005-2008 Anton Leuski. All rights reserved.
//
//	Redistribution and use in source and binary forms, with or without
//	modification, are permitted provided that the following conditions are met:
//
//	1. Redistributions of source code must retain the above copyright notice, this
//	list of conditions and the following disclaimer.
//	2. Redistributions in binary form must reproduce the above copyright notice,
//	this list of conditions and the following disclaimer in the documentation
//	and/or other materials provided with the distribution.
//
//	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//	ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//	WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//	DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
//	ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//	(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//	 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//	ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//	(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//	SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// ============================================================================

#import <Foundation/Foundation.h>
#import "DictionaryManager.h"
#import "AspellDictionary.h"
#import "MultilingualDictionary.h"
#import "AspellOptions.h"
#import "UserDefaults.h"
#import "clip_int.h"

//#define __debug__

@interface cocoAspell : NSObject <NSSpellServerDelegate>
@property (nonatomic, strong) DictionaryManager*	dictionaryManager;

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
		self.dictionaryManager	= dm;

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
findMisspelledWordInString:(NSString *)stringToCheck
              language:(NSString *)language
             wordCount:(NSInteger *)wordCount
             countOnly:(BOOL)countOnly
{
#ifdef __debug__
	NSLog(@"check |%@| for language %@, count only: %d", stringToCheck, language, (int)countOnly);
#endif

	Dictionary*		dict	= [self dictionaryForName:language];
	NSRange			result	= NSMakeRange(NSNotFound, 0);
	BOOL			cs		= dict.caseSensitive;

	unsigned int		textSize	= CLIP_TO_UINT(sizeof(unichar) * [stringToCheck length]);
	unichar*				textData	= (unichar*)malloc(textSize);
	if (textData) {
		NSUInteger	start	= 0;
		[stringToCheck getCharacters:textData];
		while (1) {
			int			wc;
      result  = [dict findMisspelledWordInBuffer:textData+start
                                            size:textSize-CLIP_TO_UINT(start*sizeof(unichar))
                                       wordCount:&wc
                                       countOnly:countOnly];
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
	NSLog(@"found misspeling at %@ and word count %ld : |%@|", NSStringFromRange(result), (long)*wordCount, ((result.location == NSNotFound) ? @"" : [stringToCheck substringWithRange:result]));
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

		NSSpellServer*		aServer = [[NSSpellServer alloc] init];
		
		DictionaryManager*	dm		= [[DictionaryManager alloc] init];
		[dm setDictionaries:[dm allDictionaries]];
		
		NSUInteger			nregistered = 0;
		
		NSLog(@"Attempting to regirster %lu dictionaries", (unsigned long)[dm.dictionaries count]);
		
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



	}
	return 0;
}
