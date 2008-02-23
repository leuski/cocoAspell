// ============================================================================
//  Dictionary.h
// ============================================================================
//
//	cocoAspell
//
//  Created by Anton Leuski on Wed Jan 14 2004.
//  Copyright (c) 2004 Anton Leuski. All rights reserved.
// ============================================================================

#import <Foundation/Foundation.h>

@class Dictionary;

@protocol CompileProgress
- (void)progressCompileDictionary:(Dictionary*)dict messageKey:(NSString*)key;
- (void)stoppedCompileDictionary:(Dictionary*)dict successfully:(BOOL)success;
- (void)startedCompileDictionary:(Dictionary*)dict;
@end

@interface Dictionary : NSObject {
@private
//	NSString*	mDisplayName;
//	NSString*	mIdentifier;
//	NSString*   mAppleName;
	BOOL		mEnabled;
}

- (id)init;

- (NSString*)displayName;
- (NSString*)identifier;
- (NSString*)appleName;
- (NSString*)info;

- (BOOL)isEnabled;
- (void)setEnabled:(BOOL)enabled;

// returns 0 if we can compile
// returns 1 if no write access
// returns x < 0 if additional x bytes of disk space required 
- (long)canCompile;
- (BOOL)isCompiled;
- (BOOL)compileWithBundle:(NSBundle*)appBundle andProgressCallback:(id<CompileProgress>)callback;

@end
