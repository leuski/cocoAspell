// ================================================================================
//  SpellDictionary.m
// ================================================================================
//	cocoaspell
//
//  Created by Anton Leuski on Wed Oct 24 2001.
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

#include "pspell/pspell.h"

#import "SpellDictionary.h"
#import "LanguageDesc.h"
#import "Preferences.h"
#import "LanguageManagerASpell.h"

#include <CoreServices/CoreServices.h>

static DictionaryManager*	sDictionaryManager 	= nil;

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

static NSString*
readMasterName(
	NSString*	path)
{
	FILE*	f = fopen([path UTF8String], "r");
	char	buff[1024];
	
	if (!f)
		return @"";
		
	while (fgets(buff, 1024, f)) {
		if (buff[0] != '#') {
			char*	p = buff;
			char*	w;
			for(; *p && isspace(*p); ++p);
			w = p;
			for(; *p && !isspace(*p); ++p);
			*p = 0;
			fclose(f);
			return [NSString stringWithCString:w];
		}
	}
	fclose(f);
	return @"";
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

static NSString*	
stringFromBool(
	id 	inObject)
{
	return ([inObject intValue] ? @"true" : @"false");
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

static NSString*	
stringFromInteger(
	id 	inObject)
{
	return [NSString stringWithFormat:@"%d", [inObject intValue]];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

static NSArray*
translateBool(
	NSString*	key,
	id			val)
{
	return [NSArray arrayWithObjects:key, stringFromBool(val), nil];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

static NSArray*
translateInteger(
	NSString*	key,
	id			val)
{
	return [NSArray arrayWithObjects:key, stringFromInteger(val), nil];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

static NSArray*
translateArray(
	NSString*	key,
	id			val)
{
	NSArray*			a = (NSArray*)val;
	NSMutableArray*		r = [NSMutableArray arrayWithObjects:
		[NSString stringWithFormat:@"rem-all-%@", key], @"", nil];
	unsigned			i, n = [a count];
	NSString*			s = [NSString stringWithFormat:@"add-%@", key];
	
	for(i = 0; i < n; ++i) {
		[r addObject:s];
		[r addObject:[a objectAtIndex:i]];
	}
	
	return r;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

static NSArray*
translateLanguageDesc(
	LanguageDesc*	desc)
{
	NSString*	path 	= [desc dictionaryPath];
	NSString*	master	= readMasterName([[desc dictionaryPath] stringByAppendingPathComponent:[desc fileName]]);
	NSArray*	opts 	= [NSMutableArray arrayWithObjects:
		@"language-tag", 			[desc language],
		@"spelling", 				[desc spelling],
		@"jargon", 					[desc jargon],
		@"encoding", 				@"machine unsigned 16",
		@"personal", 				[desc identifier],
		@"rem-all-word-list-path", 	@"",
		@"add-word-list-path", 		path,
		@"local-data-dir",			path,		
		@"dict-dir", 				path,
		@"master",					master,
		nil];
		
	return opts;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

static NSArray*
translateLanguageOptions(
	NSDictionary*	dict)
{
	NSMutableArray*		opts;
	
	opts = [NSMutableArray arrayWithObjects:
		kIgnoreAccents, 		stringFromBool([dict objectForKey:kIgnoreAccents]),
		kIgnoreCase, 			stringFromBool([dict objectForKey:kIgnoreCase]),
		kRunTogether, 			stringFromBool([dict objectForKey:kRunTogether]),
		kStripAccents, 			stringFromBool([dict objectForKey:kStripAccents]),
		kSuggestionMode, 		[dict objectForKey:kSuggestionMode],
		kRunTogetherLimit,		stringFromInteger([dict objectForKey:kRunTogetherLimit]),
		kRunTogetherMin,		stringFromInteger([dict objectForKey:kRunTogetherMin]),
		nil];
		
	[opts addObjectsFromArray:translateArray(kFilter, [dict objectForKey:kFilter])];
	
	return opts;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------
//	Take our representaion of TeX commands
//	and translate them to into a set of aspell instructions that
//	will set these commands into an aspell config.

static NSArray*
translateTexCommands(
	NSArray*	dict)
{
	unsigned		i, j;
	NSMutableArray*	commands;
	char			buf[1024];
		
	commands = [NSMutableArray arrayWithObjects:
		@"rem-all-tex-command",		@"",
		nil];
	
	for(i = 0; i < [dict count]; ++i) {
		NSDictionary*	cmd 	= [dict objectAtIndex:i];
		NSString*		name	= [cmd objectForKey:kKeyCommandName];
		NSArray*		params	= [cmd objectForKey:kKeyCommandParameters];

		strcpy(buf, [name cString]);
		if ([params count] > 0)
			strcat(buf, " ");
			
		for(j = 0; j < [params count]; ++j) {
			NSDictionary*	p	= [params objectAtIndex:j];
			BOOL			chk	= [[p objectForKey:kKeyCheck] boolValue];
			BOOL			opt	= [[p objectForKey:kKeyOptional] boolValue];
			if (chk) {
				if (opt) 
					strcat(buf, "O");
				else
					strcat(buf, "P");
			} else {
				if (opt) 
					strcat(buf, "o");
				else
					strcat(buf, "p");
			}
		}
		
		[commands addObject:@"add-tex-command"];
		[commands addObject:[NSString stringWithCString:buf]];
	}

	return commands;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

@implementation SpellDictionary 

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (id)initWithLanguage:(LanguageDesc*)desc;
{
	self = [super init];
	if (self) {
		mLanguage 		= desc;
		[mLanguage retain];
		
		mPreferences	= [[Preferences sharedInstance] preferencesForLanguage:[desc identifier]];
		[mPreferences retain];
	}
	return self;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)dealloc
{
	[mLanguage		release];
	mLanguage		= nil;
	[mPreferences	release];
	mPreferences	= nil;
	[super 			dealloc];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (NSString*)languageName
{
	return [mLanguage appleName];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (NSString*)identifier
{
	return [mLanguage identifier];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)spellServer:(NSSpellServer*)sender
	forgetWord:(NSString*)word
{
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)spellServer:(NSSpellServer*)sender
	learnWord:(NSString*)word
{
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (NSRange)spellServer:(NSSpellServer*)sender
	findMisspelledWordInString:(NSString*)stringToCheck 
	wordCount:(int*)wordCount 
	countOnly:(BOOL)countOnly;
{
	return NSMakeRange([stringToCheck length], 0);
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (NSArray *)spellServer:(NSSpellServer*)sender
	suggestGuessesForWord:(NSString*)word
{
	return [NSArray array];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (NSString*)configForKey:(NSString*)key
{
	return @"";
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)setConfig:(NSString*)obj forKey:(NSString*)key
{
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)setConfig:(NSArray*)arr
{
	unsigned	i;
	for(i = 0; i < [arr count]; i += 2) {
		[self setConfig:[arr objectAtIndex:(i+1)] forKey:[arr objectAtIndex:i]]; 
	}
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

#define	CHECK_KEY(key) (val = [dict objectForKey:key], [val isEqual:[mPreferences objectForKey:key]])

- (BOOL)setPreferences:(NSDictionary*)dict withExtraOptions:(NSArray*)extras
{
	BOOL			requireRestart = NO;
	id				val;
	
	if (!CHECK_KEY(kIgnoreAccents)) {
		requireRestart = YES;
	}

	if (!CHECK_KEY(kIgnoreCase)) {
		requireRestart = YES;
	}

	if (!CHECK_KEY(kStripAccents)) {
		requireRestart = YES;
	}
		
	if (!CHECK_KEY(kRunTogether)) {
		[self setConfig:stringFromBool(val) forKey:kRunTogether];
	}

	if (!CHECK_KEY(kSuggestionMode)) {
		[self setConfig:val forKey:kSuggestionMode];
	}
	
	if (!CHECK_KEY(kRunTogetherLimit)) {
		[self setConfig:stringFromInteger(val) forKey:kRunTogetherLimit];
	}

	if (!CHECK_KEY(kRunTogetherMin)) {
		[self setConfig:stringFromInteger(val) forKey:kRunTogetherMin];
	}

	if (!CHECK_KEY(kFilter)) {
		[self setConfig:translateArray(kFilter, val)];
	}
	
	[self setConfig:extras];

	return requireRestart;
}

#undef	CHECK_KEY

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (NSArray*)optionsAsArray
{
	NSMutableArray*		opts = [NSMutableArray array];
	[opts addObjectsFromArray:translateLanguageDesc(mLanguage)];
	[opts addObjectsFromArray:translateLanguageOptions(mPreferences)];
	return opts;
}

@end

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

@implementation DictionaryManager 

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

+ (DictionaryManager*)sharedInstance
{
	if (!sDictionaryManager) {
		sDictionaryManager = [[DictionaryManager alloc] init];
	}
	return sDictionaryManager;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (id)init
{
	self = [super init];
	if (self) {
		mDictionaries = nil;
	}
	return self;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)dealloc
{
	[mDictionaries	release];
	mDictionaries	= nil;
	[super			dealloc];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (NSArray*)systemOptions
{
	NSMutableArray*		opts;
//	NSBundle*			bndl		= [NSBundle bundleForClass:[self class]];
//	NSString*			data_aspell = [Preferences pathFromBundle:bndl to:kPathAspellData];
//	NSString*			data_pspell = [Preferences pathFromBundle:bndl to:kPathPspellData];
//	NSString*			conf 		= [data_aspell stringByAppendingPathComponent:@"aspell.conf"];
	NSString*			personal 	= [Preferences pathUserHomePath];

	opts = [NSMutableArray arrayWithObjects:
//		@"pspell-data-dir", 		data_pspell,
//		@"data-dir", 				data_aspell,		
//		@"conf-dir", 				data_aspell,		
//		@"conf-path", 				conf,		
		@"home-dir", 				personal,
		kKeyCheckTexComments,		stringFromBool([[Preferences sharedInstance] objectForKey:kKeyCheckTexComments]),
		kKeyEmailMargin,			stringFromInteger([[Preferences sharedInstance] objectForKey:kKeyEmailMargin]),
		nil];

	[opts addObjectsFromArray:translateTexCommands([[Preferences sharedInstance] texCommands])];
	[opts addObjectsFromArray:translateArray(kKeyEmailQuote, [[Preferences sharedInstance] objectForKey:kKeyEmailQuote])];

	return opts;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (NSArray*)spellDictionaries
{
	if (!mDictionaries) {
	
		NSMutableArray*	dicts		= [NSMutableArray array];
		NSArray*		langs		= [LanguageDesc allLanguagesWithApplicationBundle:realMainBundle()];
		NSArray*		opts		= [self systemOptions];
		unsigned		i;
		
		for(i = 0; i < [langs count]; ++i) {
			LanguageDesc*		desc = [langs objectAtIndex:i];
			SpellDictionary*	dict = nil;
			
			if ([desc isCompiled] && [desc isEnabled]) {
				dict = [[LanguageManagerASpell alloc] initWithLanguage:desc extraOptions:opts];
			}
			
			if (dict) {
				[dicts addObject:dict];
				[dict release];
			}
		}
		
		// make a non-mutable copy
		mDictionaries = [[NSArray alloc] initWithArray:dicts];	
	}
	
	return mDictionaries;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (SpellDictionary*)spellDictionaryForName:(NSString*)name
{
	NSArray*	dicts = [self spellDictionaries];
	unsigned	i;
	for(i = 0; i < [dicts count]; ++i) {
		SpellDictionary*	d = [dicts objectAtIndex:i];
		if ([name isEqualToString:[d languageName]])
			return d;
	}
	return nil;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------


- (NSArray*)languageNames
{
	NSArray*			dicts	= [self spellDictionaries];
	NSMutableArray*		langs	= [NSMutableArray arrayWithCapacity:[dicts count]];
	unsigned			i;
	
	for(i = 0; i < [dicts count]; ++i)
		[langs addObject:[(SpellDictionary*)[dicts objectAtIndex:i] languageName]];

	return langs;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)preferencesDidChange
{
	NSArray*		changedKeys 	= [[Preferences sharedInstance] update];
	NSMutableArray*	opts 			= [NSMutableArray array];
	NSArray*		dicts 			= [self spellDictionaries];
	BOOL			requireRestart 	= NO;
	unsigned		i;
	
	if ([changedKeys count] == 0)
		return;

	for(i = 0; i < [changedKeys count]; ++i) {
		NSString*	key = [changedKeys objectAtIndex:i];
		
//		NSLog(@"changed: %@", key);
		
		if ([key isEqualToString:kKeyTexCommands]) {
			[opts addObjectsFromArray:translateTexCommands([[Preferences sharedInstance] texCommands])];
		} else if ([key isEqualToString:kKeyCheckTexComments]) {
			[opts addObjectsFromArray:translateBool(kKeyCheckTexComments, [[Preferences sharedInstance] objectForKey:kKeyCheckTexComments])];
		} else if ([key isEqualToString:kKeyEmailMargin]) {
			[opts addObjectsFromArray:translateInteger(kKeyEmailMargin, [[Preferences sharedInstance] objectForKey:kKeyEmailMargin])];
		} else if ([key isEqualToString:kKeyEmailQuote]) {
			[opts addObjectsFromArray:translateArray(kKeyEmailQuote, [[Preferences sharedInstance] objectForKey:kKeyEmailQuote])];
		} 
	}

	[[Preferences sharedInstance] read];
	
	for(i = 0; i < [dicts count]; ++i) {
		SpellDictionary*	sd 		= [dicts objectAtIndex:i];
		NSString*			name	= [sd identifier];
		if ([sd setPreferences:[[Preferences sharedInstance] preferencesForLanguage:name] withExtraOptions:opts])
			requireRestart = YES;
	}
	
	if (requireRestart) {
//		NSLog(@"soft restart of Aspell services");
		[mDictionaries release];
		mDictionaries = nil;
	}
}


@end


// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

@implementation NSString (UniAdditions)

- (const unichar*)UniChars
{
	return ((const unichar*)[[self dataUsingEncoding:NSUnicodeStringEncoding] bytes]) + 1;
}

@end

NSBundle*
realMainBundle()
{
	NSBundle*		theBundle   = [NSBundle mainBundle];
//	NSFileManager*  manager		= [NSFileManager defaultManager];
	while (YES) {
		NSString*		theExec		= [theBundle executablePath];
//		NSString*		newPath		= [manager pathContentOfSymbolicLinkAtPath:theExec];
		NSString*		newPath		= [theExec stringByResolvingSymlinksInPath];
		NSBundle*		newBundle;
		
//		NSLog(@"%@ %@", theExec, newPath);
		
		if (newPath == nil || [theExec isEqualTo:newPath]) {
			return theBundle;
		}
		
		newPath		= [newPath stringByDeletingLastPathComponent];  // bundle/Contents/MacOS/
		newPath		= [newPath stringByDeletingLastPathComponent];  // bundle/Contents/
		newPath		= [newPath stringByDeletingLastPathComponent];  // bundle/
		newBundle   = [NSBundle bundleWithPath:newPath];

//		NSLog(@"%@ %@", newBundle, newPath);

		if (newBundle == nil)
			return theBundle;
		theBundle   = newBundle;
	}

}


