// ============================================================================
//  Dictionary.h
// ============================================================================
//
//	cocoAspell2
//
//  Created by Anton Leuski on 2/4/05.
//  Copyright (c) 2005-2008 Anton Leuski. All rights reserved.
// ============================================================================

#import <Foundation/Foundation.h>
#import "aspell.h"

@class AspellOptions;

@interface Dictionary : NSObject {
	NSString*				_name;
	NSString*				_identifier;
	BOOL					_enabled;
}

@property(retain)	NSString*				name;
@property(retain)	NSString*				readableName;
@property(assign)	BOOL					enabled;

@property(retain)	NSString*				identifier;
@property(retain, readonly)	NSString*		copyright;

@property(assign, readonly)	BOOL			caseSensitive;

- (void)setFilterConfig:(AspellConfig*)filterConfig;
- (void)forgetWord:(NSString *)word;
- (void)learnWord:(NSString *)word;
- (NSRange)findMisspelledWordInBuffer:(unichar*)buffer size:(unsigned)size wordCount:(int*)wordCount countOnly:(BOOL)countOnly;
- (NSArray*)suggestGuessesForWord:(NSString*)word;
- (NSArray*)suggestCompletionsForPartialWordRange:(NSRange)inRange inString:(NSString*)str;


@end
