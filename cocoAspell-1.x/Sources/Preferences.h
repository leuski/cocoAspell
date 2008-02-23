// ================================================================================
//  Preferences.h
// ================================================================================
//	cocoAspell
//
//  Created by Anton Leuski on Tue Nov 13 2001.
//  Copyright (c) 2002-2004 Anton Leuski.
//
//	This file is part of cocoAspell package.
//
//	Redistribution and use of cocoAspell in source and binary forms, with or without 
//	modification, are permitted provided that the following conditions are met:
//
//	1. Redistributions of source code must retain the above copyright notice, this 
//		list of conditions and the following disclaimer.
//	2. Redistributions in binary form must reproduce the above copyright notice, 
//		this list of conditions and the following disclaimer in the documentation 
//		and/or other materials provided with the distribution.
//	3. The name of the author may not be used to endorse or promote products derived 
//		from this software without specific prior written permission.
//
//	THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED 
//	WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
//	MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT 
//	SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
//	EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT 
//	OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
//	INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, 
//	STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY 
//	OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// ================================================================================

#import <Foundation/Foundation.h>

@interface Preferences : NSObject {
@private
	NSMutableDictionary*	mData;
}

+ (Preferences*)sharedInstance;

// general functions

- (id)objectForKey:(NSString*)key;
- (void)setObject:(id)val forKey:(NSString*)key;

- (BOOL)boolForKey:(NSString*)key;
- (void)setBool:(BOOL)val forKey:(NSString*)key;

- (int)integerForKey:(NSString*)key;
- (void)setInteger:(int)val forKey:(NSString*)key;

// handy shortcuts

- (NSDictionary*)preferencesForLanguage:(NSString*)lang;
- (void)setPreferences:(NSDictionary*)pref forLanguage:(NSString*)lang;

- (NSArray*)texCommands;
- (NSMutableArray*)mutableTexCommands;

// reading & writing

- (void)read;
- (void)write;

// this method updates the data from disk and 
//	returns an array of keys that have new values
- (NSArray*)update;

// static functions that deal with standard paths

+ (NSString*)pathFromBundle:(NSBundle*)bndl to:(NSString*)path;
+ (NSString*)pathNetworkAspellSupport;
+ (NSString*)pathGlobalAspellSupport;
+ (NSString*)pathLocalAspellSupport;
+ (NSString*)pathUserHomePath;

@end

extern NSString*	kPathPspellData;
extern NSString*	kPathAspellData;
extern NSString*	kPathDictionaries;

extern NSString*	kKeyTexCommands;
extern NSString*	kKeyCheckTexComments;
extern NSString*	kKeyEmailQuote;
extern NSString*	kKeyEmailMargin;

extern NSString*	kIgnoreAccents;
extern NSString*	kIgnoreCase;
extern NSString*	kRunTogether;
extern NSString*	kRunTogetherLimit;
extern NSString*	kRunTogetherMin;
extern NSString*	kStripAccents;
extern NSString*	kSuggestionMode;
extern NSString*	kUltra;
extern NSString*	kFast;
extern NSString*	kNormal;
extern NSString*	kBadSpellers;
extern NSString*	kFilter;
extern NSString*	kURL;
extern NSString*	kEmail;
extern NSString*	kTeX;
extern NSString*	kSgml;

extern NSString*	kPreferencesChangedNotification;
extern NSString*	kPreferencesChangedObject;

extern NSString*	kKeyCommandName;
extern NSString*	kKeyCommandParameters;
extern NSString*	kKeyOptional;
extern NSString*	kKeyCheck;

#define LocalizedString(key) [[NSBundle bundleForClass:[self class]] localizedStringForKey:key value:nil table:nil]
#define NonLocalizedString(key) [[NSBundle bundleForClass:[self class]] localizedStringForKey:key value:nil table:@"Nonlocalizable"]
#define LocalizedStringWithValue(key, val) [[NSBundle bundleForClass:[self class]] localizedStringForKey:key value:val table:nil]
#define NonLocalizedStringWithValue(key, val) [[NSBundle bundleForClass:[self class]] localizedStringForKey:key value:val table:@"Nonlocalizable"]


