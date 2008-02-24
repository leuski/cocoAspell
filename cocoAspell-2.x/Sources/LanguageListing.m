// ============================================================================
//  LanguageListing.m
// ============================================================================
//
//	cocoAspell2
//
//  Created by Anton Leuski on 4/26/05.
//  Copyright (c) 2005 Anton Leuski. All rights reserved.
// ============================================================================

#import "LanguageListing.h"
#import "DictionaryListing.h"
#import "Utilities.h"

@implementation LanguageListing

- (id)initWithLanguageCode:(NSString*)inLangCode dictionaries:(NSArray*)inDictionaries
{
	if (self = [super init]) {
		[self setLangCode:inLangCode];
		[self setDictionaries:inDictionaries];
	}
	return self;
}

- (id)initWithLanguageCode:(NSString*)inLangCode
{
	return [self initWithLanguageCode:inLangCode dictionaries:nil];
}

- (void)dealloc
{
	[self setDictionaries:nil];
	[self setLangCode:nil];
	[super dealloc];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSString *)langCode
{
	return [[langCode retain] autorelease];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setLangCode:(NSString *)newLangCode
{
    if (langCode != newLangCode) {
		[langCode release];
		langCode = [newLangCode copy];
		[self setLocalName:getSystemLanguageName(langCode,YES)];
		[self setNativeName:getSystemLanguageName(langCode,NO)];
    }
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSString *)localName
{
	return [[localName retain] autorelease];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setLocalName:(NSString *)newLocalName
{
    if (localName != newLocalName) {
		[localName release];
		localName = [newLocalName copy];
    }
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSString *)nativeName
{
	return [[nativeName retain] autorelease];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setNativeName:(NSString *)newNativeName
{
    if (nativeName != newNativeName) {
		[nativeName release];
		nativeName = [newNativeName copy];
    }
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSArray *)dictionaries
{
	return [[dictionaries retain] autorelease];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setDictionaries:(NSArray *)newDictionaries
{
    if (dictionaries != newDictionaries) {
		[dictionaries release];
		if (newDictionaries) {
			dictionaries = [[NSMutableArray alloc] init];
			for (NSString* line in newDictionaries) {
				[(NSMutableArray*)dictionaries addObject:[[[DictionaryListing alloc] initWithListEntry:line] autorelease]];
			}
			NSArray*	sorted	= [dictionaries sortedArrayUsingSelector:@selector(compare:)];
			[self setSelectedDictionary:[sorted objectAtIndex:0]];
			[[sorted objectAtIndex:0] setPreferred:YES];
		} else {
			dictionaries	= NULL;
		}
    }
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (DictionaryDescription *)installedDictionary
{
	return [[installedDictionary retain] autorelease];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setInstalledDictionary:(DictionaryDescription *)newInstalledDictionary
{
    if (installedDictionary != newInstalledDictionary) {
		[installedDictionary release];
		installedDictionary = [newInstalledDictionary retain];
    }
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (DictionaryListing *)selectedDictionary
{
	return selectedDictionary;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setSelectedDictionary:(DictionaryListing *)newSelectedDictionary
{
    if (selectedDictionary != newSelectedDictionary) {
		selectedDictionary = newSelectedDictionary;
    }
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (BOOL)isSelected
{
	return selected;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setSelected:(BOOL)newSelected
{
    if (selected != newSelected) {
		selected = newSelected;
    }
}

@end
