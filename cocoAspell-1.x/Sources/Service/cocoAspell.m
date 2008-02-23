// ================================================================================
//  cocoAspell.m
// ================================================================================
//	cocoAspell
//
//  Created by Anton Leuski on Sun Nov 18 2001.
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

#import "cocoAspell.h"
#import "SpellDictionary.h"
#import "Preferences.h"


// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

@implementation cocoAspell 

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)userDefaultsChanged:(NSNotification*)notification
{
//	NSLog(@"notification");
	mPreferencesChanged = YES;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (id)init
{
	self = [super init];

	mPreferencesChanged = NO;

	[[NSDistributedNotificationCenter defaultCenter] 
		addObserver:	self
		selector:		@selector(userDefaultsChanged:)
		name:			kPreferencesChangedNotification 
		object:			kPreferencesChangedObject];
		
	return self;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)dealloc
{	
	[[NSDistributedNotificationCenter defaultCenter] 
		removeObserver:	self 
		name:			kPreferencesChangedNotification 
		object:			kPreferencesChangedObject];
	
	[super dealloc];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)spellServer:(NSSpellServer *)sender 
	didForgetWord:(NSString *)word 
	inLanguage:(NSString *)language
{
	SpellDictionary*		theDict		= [[DictionaryManager sharedInstance] spellDictionaryForName:language];
	if (!theDict)
		return;
		
	[theDict spellServer:sender forgetWord:word];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)spellServer:(NSSpellServer *)sender 
	didLearnWord:(NSString *)word 
	inLanguage:(NSString *)language
{
	SpellDictionary*		theDict		= [[DictionaryManager sharedInstance] spellDictionaryForName:language];
	if (!theDict)
		return;
		
	[theDict spellServer:sender learnWord:word];
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
	SpellDictionary*		theDict;
	
	if (mPreferencesChanged) {
		[[DictionaryManager sharedInstance] preferencesDidChange];
		mPreferencesChanged = NO;
	}
	
	theDict		= [[DictionaryManager sharedInstance] spellDictionaryForName:language];

	*wordCount = 0;
	
	if (!theDict)
		return NSMakeRange([stringToCheck length], 0);
		
	return [theDict spellServer:sender findMisspelledWordInString:stringToCheck wordCount:wordCount countOnly:countOnly];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (NSArray *)spellServer:(NSSpellServer *)sender 
	suggestGuessesForWord:	(NSString *)word 
	inLanguage:				(NSString *)language
{
	SpellDictionary*		theDict;

	if (mPreferencesChanged) {
		[[DictionaryManager sharedInstance] preferencesDidChange];
		mPreferencesChanged = NO;
	}
	
	theDict		= [[DictionaryManager sharedInstance] spellDictionaryForName:language];

	if (!theDict)
		return [NSArray array];

	return [theDict spellServer:sender suggestGuessesForWord:word];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

@end


// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

static void
serverMain()
{
	NSSpellServer*		aServer = [[NSSpellServer alloc] init];
	NSArray*			dicts	= [[DictionaryManager sharedInstance] languageNames];
	int					i, nregistered = 0;
	
	
	for(i = 0; i < [dicts count]; ++i) {
		NSString*	name = [dicts objectAtIndex:i];
		if (![aServer registerLanguage:name byVendor:@"Aspell"]) {
			NSLog(@"Aspell failed to register %@\n", name); 
		} else {
			++nregistered;
			NSLog(@"Aspell registered %@\n", name); 		
		}
	}
	
	if (nregistered > 0) {

		NSLog(@"Starting Aspell SpellChecker.\n");

		NS_DURING
			[aServer setDelegate:[[cocoAspell alloc] init]];
			[aServer run];
		NS_HANDLER
			NSLog(@"%@", localException);
		NS_ENDHANDLER

	} else {
	
		NSLog(@"There are no languages enabled. Canceling Aspell SpellChecker.\n");
		
	}

	[aServer release];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

/* 
int 
cocoAspellMain(
	int			argc,
	const char*	argv[])
{
	NSAutoreleasePool*	pool	= [[NSAutoreleasePool alloc] init];
	BOOL				handled	= [SpellDictionary handleUtilityCall:argc withArgs:argv];

	if (!handled) {
		serverMain();
	}

	[pool release];

	return 0;
}
*/

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

int 
cocoAspellMainServerOnly(
	int			argc,
	const char*	argv[])
{
	NSAutoreleasePool*	pool	= [[NSAutoreleasePool alloc] init];
//	NSLog(@"%s", argv[0]);
	serverMain();

	[pool release];

	return 0;
}

