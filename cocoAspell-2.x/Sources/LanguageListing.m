// ============================================================================
//  LanguageListing.m
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
