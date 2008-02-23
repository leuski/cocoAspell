// ============================================================================
//  InstalledDictionary.h
// ============================================================================
//
//	cocoAspell2
//
//  Created by Anton Leuski on 4/30/05.
//  Copyright (c) 2005 Anton Leuski. All rights reserved.
// ============================================================================

#import "DictionaryDescription.h"

@interface InstalledDictionary : DictionaryDescription {
	NSString*	path;
	NSString*	version;
	NSString*	module;
	NSString*	langCode;
}

- (id)initWithDirectoryPath:(NSString*)inPath;


- (NSString *)path;
- (void)setPath:(NSString *)newPath;

- (NSString *)version;
- (void)setVersion:(NSString *)newVersion;

- (NSString *)module;
- (void)setModule:(NSString *)newModule;

- (NSString *)langCode;
- (void)setLangCode:(NSString *)newLangCode;

@end

