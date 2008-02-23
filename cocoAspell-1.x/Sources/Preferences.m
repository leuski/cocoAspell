// ================================================================================
//  Preferences.m
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

#import "Preferences.h"
#import "NSDictionary_Extensions.h"

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

NSString*	kKeyLanguages					= @"Languages";
NSString*	kKeyTexCommands					= @"tex-command";
NSString*	kDomainName						= @"aspell.Spelling";

NSString*	kPathPspellData					= @"share/pspell";
NSString*	kPathAspellData					= @"share/aspell";
NSString*	kPathDictionaries				= @"lib/aspell";

NSString*	kKeyCheckTexComments			= @"tex-check-comments";
NSString*	kKeyEmailQuote					= @"email-quote";
NSString*	kKeyEmailMargin					= @"email-margin";

NSString*	kIgnoreAccents					= @"ignore-accents";
NSString*	kIgnoreCase						= @"ignore-case";
NSString*	kRunTogether					= @"run-together";
NSString*	kRunTogetherLimit				= @"run-together-limit";
NSString*	kRunTogetherMin					= @"run-together-min";
NSString*	kStripAccents					= @"strip-accents";
NSString*	kSuggestionMode					= @"sug-mode";
NSString*	kUltra							= @"ultra";
NSString*	kFast							= @"fast";
NSString*	kNormal							= @"normal";
NSString*	kBadSpellers					= @"bad-spellers";
NSString*	kFilter							= @"filter";
NSString*	kURL							= @"url";
NSString*	kEmail							= @"email";
NSString*	kTeX							= @"tex";
NSString*	kSgml							= @"sgml";

NSString*	kPreferencesChangedNotification	= @"CocoAspellPreferencesChanged";
NSString*	kPreferencesChangedObject		= @"aspell.Spelling";

NSString*	kKeyCommandName					= @"command";
NSString*	kKeyCommandParameters			= @"parameters";
NSString*	kKeyOptional					= @"optional";
NSString*	kKeyCheck						= @"check";

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

static Preferences*			sPreferences			= nil;
static NSDictionary*		sDefaultLanguageParam	= nil;

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

@implementation Preferences

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

+ (Preferences*)sharedInstance
{
	if (!sPreferences) {
		sPreferences = [[Preferences alloc] init];
		[sPreferences read];
	}
	return sPreferences;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (NSDictionary*)defaultLanguagePreferences;
{
	if (!sDefaultLanguageParam) {
		sDefaultLanguageParam = [[NSDictionary alloc] initWithObjectsAndKeys:
				[NSNumber numberWithInt:0], 	kIgnoreAccents,
				[NSNumber numberWithInt:0], 	kIgnoreCase,
				[NSNumber numberWithInt:0], 	kRunTogether,
				[NSNumber numberWithInt:0], 	kStripAccents,
				kNormal, 						kSuggestionMode,
				[NSNumber numberWithInt:8], 	kRunTogetherLimit,
				[NSNumber numberWithInt:3], 	kRunTogetherMin,
				[NSArray array],				kFilter,
				nil];
	}
	
	return sDefaultLanguageParam;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (NSArray*)texCommands;
{
	return (NSArray*)[mData objectForKey:kKeyTexCommands];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (NSMutableArray*)mutableTexCommands;
{
	NSArray*	cmds = [self texCommands];
	if (![cmds isKindOfClass:[NSMutableArray class]]) {
		cmds = [[NSMutableArray alloc] initWithArray:cmds];
		[mData setObject:cmds forKey:kKeyTexCommands];
		[cmds release];
	}
	
	return (NSMutableArray*)cmds;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (NSDictionary*)languagesData;
{
	return (NSDictionary*)[mData objectForKey:kKeyLanguages];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (NSMutableDictionary*)mutableLanguagesData;
{
	NSDictionary*	data = [self languagesData];
	if (![data isKindOfClass:[NSMutableDictionary class]]) {
		data = [[NSMutableDictionary alloc] initWithDictionary:data copyItems:NO];
		[mData setObject:data forKey:kKeyLanguages];
		[data release];
	}
	
	return (NSMutableDictionary*)data;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (id)init
{
	self = [super init];
	if (self) {
		mData = [[NSMutableDictionary alloc] initWithContentsOfFile:
			[[NSBundle bundleForClass:[self class]] 
				pathForResource:@"defaults" ofType:@"plist"]];
	}
	return self;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)dealloc
{
	[mData release];
	mData = nil;
	[super dealloc];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (id)objectForKey:(NSString*)key
{
	return [mData objectForKey:key];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)setObject:(id)val forKey:(NSString*)key
{
	[mData setObject:val forKey:key];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (BOOL)boolForKey:(NSString*)key
{
	return [mData boolForKey:key];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)setBool:(BOOL)val forKey:(NSString*)key
{
	[mData setBool:val forKey:key];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (int)integerForKey:(NSString*)key
{
	return [mData integerForKey:key];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)setInteger:(int)val forKey:(NSString*)key
{
	[mData setInteger:val forKey:key];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------


- (NSDictionary*)preferencesForLanguage:(NSString*)lang
{
	NSDictionary*			dict  = [[self languagesData] objectForKey:lang];

	if (dict)
		return dict;
		
	return [self defaultLanguagePreferences];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)setPreferences:(NSDictionary*)pref forLanguage:(NSString*)lang
{
	if ([pref isEqual:[self defaultLanguagePreferences]]) {
		[[self mutableLanguagesData] removeObjectForKey:lang];
	} else {
		[[self mutableLanguagesData] setObject:pref forKey:lang];
	}
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)read
{
	NSDictionary*	pref;
	[[NSUserDefaults standardUserDefaults] synchronize];
	pref = [[NSUserDefaults standardUserDefaults] persistentDomainForName:kDomainName];
	if (pref) {
		[mData addEntriesFromDictionary:pref];
	}
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (NSArray*)update
{
	NSDictionary*	oldData;
	NSDictionary*	newData;

	oldData = [[[NSDictionary alloc] initWithDictionary:mData copyItems:YES] autorelease];
	[[NSUserDefaults standardUserDefaults] synchronize];
	newData = [[NSUserDefaults standardUserDefaults] persistentDomainForName:kDomainName];

	if (!newData) {
		return [NSArray array];
	} else {
		NSMutableArray*	changes	= [NSMutableArray array];
		NSArray*		keys	= [newData allKeys];
		unsigned		i;
		
		for(i = 0; i < [keys count]; ++i) {
			id	key	= [keys objectAtIndex:i];
			id	old	= [oldData objectForKey:key];
			id	new	= [newData objectForKey:key];
			if (old && new && ![old isEqual:new])
				[changes addObject:key];
		}
		
		[mData addEntriesFromDictionary:newData];
		return changes;
	}
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)write
{
	[[NSUserDefaults standardUserDefaults] setPersistentDomain:mData forName:kDomainName];
	[[NSUserDefaults standardUserDefaults] synchronize];

	[[NSDistributedNotificationCenter defaultCenter] 
			postNotificationName:	kPreferencesChangedNotification
			object: 				kPreferencesChangedObject
			userInfo: 				nil /* no dictionary */
			deliverImmediately: 	YES];
}


// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

+ (NSString*)pathFromBundle:(NSBundle*)bndl to:(NSString*)path
{
	return [[bndl resourcePath] stringByAppendingPathComponent:path];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

+ (NSString*)pathNetworkAspellSupport
{
	return @"/Network/Library/Application Support/Aspell";
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

+ (NSString*)pathGlobalAspellSupport
{
	return @"/Library/Application Support/Aspell";
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

+ (NSString*)pathLocalAspellSupport
{
	NSString*	localPath	= [[[[@"~" stringByStandardizingPath]
		stringByAppendingPathComponent:@"Library"]
		stringByAppendingPathComponent:@"Application Support"]
		stringByAppendingPathComponent:@"Aspell"];
	return localPath;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

+ (NSString*)pathUserHomePath
{
	NSString*				defPath		= [@"~" stringByStandardizingPath];
	NSString*				path 		= defPath;
	NSFileManager*			manager		= [NSFileManager defaultManager];
	
	if (![manager fileExistsAtPath:defPath]) {
		defPath	= [@"." stringByStandardizingPath];
		if (![manager fileExistsAtPath:defPath]) 
			defPath = @"";
	}
	
	path = [path stringByAppendingPathComponent:@"Library"];

	if (![manager fileExistsAtPath:path]) {
		if (![manager createDirectoryAtPath:path attributes:nil])
			return defPath;
	}

	path = [path stringByAppendingPathComponent:@"Spelling"];
			
	if (![manager fileExistsAtPath:path]) {
		if (![manager createDirectoryAtPath:path attributes:nil])
			return defPath;
	}

	path = [path stringByAppendingPathComponent:@"Aspell"];

	if (![manager fileExistsAtPath:path]) {
		if (![manager createDirectoryAtPath:path attributes:nil])
			return defPath;
	}

	return path;
}


@end

