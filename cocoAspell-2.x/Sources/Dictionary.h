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

@interface Dictionary : NSObject

@property (nonatomic, strong)	NSString*				name;
@property (nonatomic, strong)	NSString*				readableName;
@property (nonatomic, assign)	BOOL					enabled;

@property (nonatomic, strong)	NSString*				identifier;
@property (nonatomic, strong, readonly)	NSString*		copyright;

@property (nonatomic, assign, readonly)	BOOL			caseSensitive;

- (void)setFilterConfig:(AspellConfig*)filterConfig;
- (void)forgetWord:(NSString *)word;
- (void)learnWord:(NSString *)word;
- (NSRange)findMisspelledWordInBuffer:(unichar*)buffer size:(unsigned int)size wordCount:(int*)wordCount countOnly:(BOOL)countOnly;
- (NSArray*)suggestGuessesForWord:(NSString*)word;
- (NSArray*)suggestCompletionsForPartialWordRange:(NSRange)inRange inString:(NSString*)str;


@end
