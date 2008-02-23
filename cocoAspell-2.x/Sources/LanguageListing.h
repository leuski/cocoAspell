// ============================================================================
//  LanguageListing.h
// ============================================================================
//
//	cocoAspell2
//
//  Created by Anton Leuski on 4/26/05.
//  Copyright (c) 2005 Anton Leuski. All rights reserved.
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
