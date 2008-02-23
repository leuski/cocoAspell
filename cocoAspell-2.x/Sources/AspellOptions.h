// ============================================================================
//  AspellOptions.h
// ============================================================================
//
//	cocoAspell2
//
//  Created by Anton Leuski on 2/2/05.
//  Copyright (c) 2005 Anton Leuski. All rights reserved.
// ============================================================================

#import <Foundation/Foundation.h>
#import "aspell.h"

extern NSString* kAspellOptionsChangedNotification;

// in addition to the standard set of aspell config keys this class also responds to the following:
//	- useFilter-###				where ### is the filter name string. It is BOOL and defines whether 
//								the filter is included into the filter set.

@interface AspellOptions : NSObject {
	AspellConfig*			aspellConfig;
	BOOL					persistent;
}

+ (NSString*)cocoAspellHomeDir;

+ (AspellOptions*)aspellOptionsWithAspellConfig:(AspellConfig*)inConfig;

- (id)init;
- (id)initWithContentOfFile:(NSString*)inPath;
- (id)initWithAspellConfig:(AspellConfig*)inConfig;
- (id)initWithAspellConfigNoCopy:(AspellConfig*)inConfig;

- (AspellConfig*)aspellConfig;

- (NSArray*)allKeys;

- (int)suggestionModeAsInt;
- (void)setSuggestionModeAsInt:(int)inValue;

- (BOOL)writeToFile:(NSString*)inPath;

- (BOOL)isPersistent;
- (void)setPersistent:(BOOL)newPersistent;

- (NSDictionary*)dictionaryWithAllNondefaultValues;


@end
