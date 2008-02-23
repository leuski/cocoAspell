// ================================================================================
//  SpellDictionary.h
// ================================================================================
//	cocoaspell
//
//  Created by Anton Leuski on Wed Oct 24 2001.
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

#ifndef __SpellDictionary_h__
#define __SpellDictionary_h__

#import <Cocoa/Cocoa.h>

@class SpellDictionary;
@class LanguageDesc;

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

@interface DictionaryManager : NSObject {
@private
	NSArray*		mDictionaries;
}

+ (DictionaryManager*)sharedInstance;

- (NSArray*)systemOptions;
- (NSArray*)spellDictionaries;
- (SpellDictionary*)spellDictionaryForName:(NSString*)name;
- (NSArray*)languageNames;
- (void)preferencesDidChange;

@end

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

@interface SpellDictionary : NSObject {
@private
	LanguageDesc*	mLanguage;
	NSDictionary*	mPreferences;
}

- (id)initWithLanguage:(LanguageDesc*)desc;

- (NSString*)languageName;
- (NSString*)identifier;

- (BOOL)setPreferences:(NSDictionary*)dict withExtraOptions:(NSArray*)extra;	// YES == require restart

- (NSArray*)optionsAsArray;

- (NSString*)configForKey:(NSString*)key;
- (void)setConfig:(NSString*)obj forKey:(NSString*)key;

- (NSRange)spellServer:(NSSpellServer*)sender
	findMisspelledWordInString:(NSString*)stringToCheck 
	wordCount:(int*)wordCount 
	countOnly:(BOOL)countOnly;

- (NSArray*)spellServer:(NSSpellServer*)sender
	suggestGuessesForWord:(NSString*)word;

- (void)spellServer:(NSSpellServer*)sender
	forgetWord:(NSString*)word;
- (void)spellServer:(NSSpellServer*)sender
	learnWord:(NSString*)word;
@end

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

@interface NSString (UniAdditions)
- (const unichar*)UniChars;
@end


// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

#ifndef PSELLL_PSPELL__H
typedef struct PspellConfig 	PspellConfig;
#endif

#ifdef __cplusplus
extern "C" {
#endif
 
PspellConfig*	makeMyPspellConfig();
NSBundle*		realMainBundle();

#ifdef __cplusplus
}
#endif

#endif // __SpellDictionary_h__
