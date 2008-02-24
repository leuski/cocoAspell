// ============================================================================
//  AspellOptions.h
// ============================================================================
//
//	cocoAspell2
//
//  Created by Anton Leuski on 2/2/05.
//  Copyright (c) 2005-2008 Anton Leuski. All rights reserved.
// ============================================================================

#import <Foundation/Foundation.h>
#import "aspell.h"

extern NSString* kAspellOptionsChangedNotification;

// in addition to the standard set of aspell config keys this class also responds to the following:
//	- useFilter-###				where ### is the filter name string. It is BOOL and defines whether 
//								the filter is included into the filter set.

@interface AspellOptions : NSObject {
	AspellConfig*			_aspellConfig;
	BOOL					_persistent;
}
@property(assign,readonly)	AspellConfig*		aspellConfig;
@property(assign)			BOOL				persistent;

+ (NSString*)cocoAspellHomeDir;

+ (AspellOptions*)aspellOptionsWithAspellConfig:(AspellConfig*)inConfig;

- (id)init;
- (id)initWithContentOfFile:(NSString*)inPath;
- (id)initWithAspellConfig:(AspellConfig*)inConfig;
- (id)initWithAspellConfigNoCopy:(AspellConfig*)inConfig;

- (NSArray*)allKeys;

- (int)suggestionModeAsInt;
- (void)setSuggestionModeAsInt:(int)inValue;

- (BOOL)writeToFile:(NSString*)inPath;

- (NSDictionary*)dictionaryWithAllNondefaultValues;


@end
