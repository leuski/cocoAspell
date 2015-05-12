// ============================================================================
//  AspellOptions.h
// ============================================================================
//
//	cocoAspell2
//
//  Created by Anton Leuski on 2/2/05.
//  Copyright (c) 2005-2008 Anton Leuski. All rights reserved.
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
#import "aspell.h"

extern NSString* kAspellOptionsChangedNotification;

// in addition to the standard set of aspell config keys this class also responds to the following:
//	- useFilter-###				where ### is the filter name string. It is BOOL and defines whether 
//								the filter is included into the filter set.

@interface AspellOptions : NSObject

@property (assign, readonly)	AspellConfig*		aspellConfig;
@property (assign)				BOOL				persistent;

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

- (id)objectForKeyedSubscript:(NSString*)key;
- (void)setObject:(id)obj forKeyedSubscript:(NSString*)key;

@end
