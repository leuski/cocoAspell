// ============================================================================
//  UserDefaults.h
// ============================================================================
//
//	cocoAspell2
//
//  Created by Anton Leuski on 2/4/05.
//  Copyright (c) 2005-2008 Anton Leuski. All rights reserved.
// ============================================================================

#import <Foundation/Foundation.h>

extern NSString*	kDefaultsDomain;

@interface UserDefaults : NSObject {

}

+ (NSDictionary*)userDefaults;
+ (void)setObject:(NSObject*)inObject forKey:(NSString*)inKey;

+ (BOOL)cocoAspellIsRegistered;
+ (BOOL)cocoAspellExpired;
+ (NSDate*)cocoAspellTimeLimit;

@end

NSString* LocalizedString(NSString* key, NSString* desc);
