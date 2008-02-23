// ============================================================================
//  Dictionary.h
// ============================================================================
//
//	cocoAspell2
//
//  Created by Anton Leuski on 2/4/05.
//  Copyright (c) 2005 Anton Leuski. All rights reserved.
// ============================================================================

#import <Foundation/Foundation.h>
#import "aspell.h"
#import "DictionaryDescription.h"

@class AspellOptions;

@interface Dictionary : NSObject {
	AspellOptions*			options;
	NSString*				name;
	NSString*				identifier;
	BOOL					enabled;
}

- (id)initWithFilePath:(NSString*)inPath;

- (NSString *)name;
- (void)setName:(NSString *)newName;

- (NSString *)readableName;
- (void)setReadableName:(NSString *)newReadableName;

- (NSString *)identifier;

- (BOOL)isEnabled;
- (void)setEnabled:(BOOL)newEnabled;

- (AspellOptions *)options;
- (void)setOptions:(AspellOptions *)newOptions;

- (NSString*)copyright;
@end
