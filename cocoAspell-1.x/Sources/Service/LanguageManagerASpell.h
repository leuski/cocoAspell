// ================================================================================
//  LanguageManagerASpell.h
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

#import "SpellDictionary.h"

#ifndef __aspell_manager__
typedef struct Manager 			Manager;
typedef struct PspellConvert 	PspellConvert;
#endif // __aspell_manager__

#ifdef __cplusplus
class NSStringIterator;
class NSStringIteratorEndF;
typedef CheckState<NSStringIterator, NSStringIteratorEndF> NSStringCheckState;
#endif

@interface LanguageManagerASpell : SpellDictionary {
	Manager*			mManager;
	PspellConvert*		to_internal_;
	PspellConvert*		from_internal_;	

#ifdef __cplusplus
	NSStringCheckState*	mState;
#else
	void*				mState;
#endif
}

- (id)initWithLanguage:(LanguageDesc*)desc extraOptions:(NSArray*)opts;

- (NSRange)spellServer:(NSSpellServer*)sender
	findMisspelledWordInString:(NSString*)stringToCheck 
	wordCount:(int*)wordCount 
	countOnly:(BOOL)countOnly;

- (NSArray*)spellServer:(NSSpellServer*)sender
	suggestGuessesForWord:(NSString*)word;

// this one is not implemeted as Aspell doesn't know how to remove words

//- (void)spellServer:(NSSpellServer*)sender
//	forgetWord:(NSString*)word;

- (void)spellServer:(NSSpellServer*)sender
	learnWord:(NSString*)word;

- (NSString*)configForKey:(NSString*)key;
- (void)setConfig:(NSString*)obj forKey:(NSString*)key;

@end
