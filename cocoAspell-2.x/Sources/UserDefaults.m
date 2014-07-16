// ============================================================================
//  UserDefaults.m
// ============================================================================
//
//	cocoAspell2
//
//  Created by Anton Leuski on 2/4/05.
//  Copyright (c) 2005-2008 Anton Leuski. All rights reserved.
// ============================================================================

#import "UserDefaults.h"

NSString*	kDefaultsDomain	= @"net.leuski.cocoaspell";

@implementation UserDefaults

+ (NSDictionary*)userDefaults
{
	return [[NSUserDefaults standardUserDefaults] persistentDomainForName:kDefaultsDomain];
}

+ (void)setObject:(NSObject*)inObject forKey:(NSString*)inKey
{
	NSDictionary*			curDefaults	= [UserDefaults userDefaults];
	NSMutableDictionary*	newDefaults	= nil;
	if (curDefaults) {
		newDefaults	= [curDefaults mutableCopy];
	} else {
		newDefaults	= [NSMutableDictionary dictionary];
	}
	newDefaults[inKey] = inObject;
	[[NSUserDefaults standardUserDefaults] setPersistentDomain:newDefaults forName:kDefaultsDomain];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

@end

NSString* LocalizedString(NSString* key, NSString* desc)
{
	return [[NSBundle bundleForClass:[UserDefaults class]] localizedStringForKey:key value:key table:@"Localizable"];
}
