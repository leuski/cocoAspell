// ============================================================================
//  LanguageListing.h
// ============================================================================
//
//	cocoAspell2
//
//  Created by Anton Leuski on 4/26/05.
//  Copyright (c) 2005 Anton Leuski. All rights reserved.
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

@class DictionaryListing;
@class DictionaryDescription;

@interface LanguageListing : NSObject {
	NSString*				langCode;
	NSString*				localName;
	NSString*				nativeName;
	NSArray*				dictionaries;
	DictionaryDescription*	installedDictionary;
	BOOL					selected;
	DictionaryListing*		selectedDictionary;
}

- (id)initWithLanguageCode:(NSString*)langCode;
- (id)initWithLanguageCode:(NSString*)langCode dictionaries:(NSArray*)inDictionaries;

- (NSString *)langCode;
- (void)setLangCode:(NSString *)newLangCode;

- (NSString *)localName;
- (void)setLocalName:(NSString *)newLocalName;

- (NSString *)nativeName;
- (void)setNativeName:(NSString *)newNativeName;

- (NSArray *)dictionaries;
- (void)setDictionaries:(NSArray *)newDictionaries;

- (DictionaryDescription *)installedDictionary;
- (void)setInstalledDictionary:(DictionaryDescription *)newInstalledDictionary;

- (DictionaryListing *)selectedDictionary;
- (void)setSelectedDictionary:(DictionaryListing *)newSelectedDictionary;

- (BOOL)isSelected;
- (void)setSelected:(BOOL)newSelected;

@end
