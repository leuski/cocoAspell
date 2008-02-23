// ================================================================================
//  LanguageDesc.m
// ================================================================================
//	cocoAspell
//
//  Created by Anton Leuski on Mon Nov 12 2001.
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

#import <Cocoa/Cocoa.h>
#import "LanguageDesc.h"
#import "Preferences.h"
#import "LanguageUtilities.h"

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------
//
//	The idea here is to have two different strings for identifying a dictionary:
//	the name and identifier. The name can be localized and will be shown in the 
//	Spelling window and in the Spelling prefernce panel. The identifier is used
//	to reference the dictionary in the preferences, so switching the system 
//	language will not affect the preferences. Now the problem of course, that 
//	the system itself uses the NAME to idetify the language and the dictionary.
//	So this idea is frankly of limited use: switching the system display locale will
//	change the language names and effectively disable the dictionaries. The user
//	can reenable the dictionaries in the Preference Panel. The preferences are
//	for dictionaries are preserved.


@implementation LanguageDesc

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

+ (id)languageDescWithDictionaryFile:(NSString*)file
{
	return [[[LanguageDesc alloc] initWithDictionaryFile:file] autorelease];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (id)initWithDictionaryFile:(NSString*)file
{
	const char*		name	= [[file lastPathComponent] UTF8String];
	char*			buffer;
	char*			p;
	char*			q;
	NSDictionary*   allNames	= [NSDictionary dictionaryWithContentsOfFile:[[file stringByDeletingPathExtension] 
										stringByAppendingPathExtension:@"plist"]];
	
	mName				= nil;
	mAppleName			= nil;
	mIdentifier			= nil;
	mDictionaryFilePath = file;
	
	[mDictionaryFilePath retain];
	
	buffer = (char*)malloc(strlen(name)+1);
	assert(buffer);
	strcpy(buffer, name);

	if (p = strrchr(buffer, '.'))						// remove extension
		*p = 0;

	if (p = strrchr(buffer, '-')) 	// remove module name 
		*p = 0;
	
	q = buffer;
	if (p = strchr(q, '-'))
		*p = 0;
	
	mLanguage = [[NSString alloc] initWithCString:q];
	
	if (p) {	
		q = p + 1;
		if (p = strchr(q, '-'))
			*p = 0;

		mSpelling	= [[NSString alloc] initWithCString:q];
	
		if (p) {
			q = p + 1;
			if (p = strchr(q, '-'))
				*p = 0;

			mJargon		= [[NSString alloc] initWithCString:q];
		
		} else {
			mJargon		= [[NSString alloc] init];
		}
	
	} else {
		mSpelling 	= [[NSString alloc] init];
		mJargon		= [[NSString alloc] init];
	}
	
	free(buffer);
	
	mIdentifier		= [allNames objectForKey:@"Identifier"];
	[mIdentifier	retain];

	mName			= [allNames objectForKey:@"DisplayName"];
	[mName			retain];

	if (NSAppKitVersionNumber <= NSAppKitVersionNumber10_2_3) {
		mAppleName		= [allNames objectForKey:@"DisplayName"];
	} else {
		mAppleName		= [allNames objectForKey:@"AppleName"];
	}
	[mAppleName		retain];
	
	return self;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)dealloc
{
	[mIdentifier			release];
	mIdentifier				= nil;
	[mLanguage				release];
	mLanguage				= nil;
	[mSpelling				release];
	mSpelling				= nil;
	[mJargon				release];
	mJargon					= nil;
	[mName					release];
	mName					= nil;
	[mAppleName				release];
	mAppleName				= nil;
	[mDictionaryFilePath	release];
	mDictionaryFilePath		= nil;
	[super dealloc];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (NSString*)displayName
{
	if (!mName) {
		mName = [LanguageUtilities localizedDictionaryNameWithLanguageCode:
					[self language] spelling:[self spelling] jargon:[self jargon]];
		[mName retain];
	}
	
	return mName;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (NSString*)appleName
{
	if (!mAppleName) {
		mAppleName = [LanguageUtilities appleDictionaryNameWithLanguageCode:
					[self language] spelling:[self spelling] jargon:[self jargon]];
		[mAppleName retain];
	}
	
	return mAppleName;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (NSString*)dictionaryPath
{
	return [mDictionaryFilePath stringByDeletingLastPathComponent];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (NSString*)fileName
{
	return [mDictionaryFilePath lastPathComponent];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (NSString*)language
{
	return mLanguage;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (NSString*)spelling
{
	return mSpelling;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (NSString*)jargon
{
	return mJargon;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (NSString*)info
{
	NSString*	path = [[self dictionaryPath] stringByAppendingPathComponent:@"COPYRIGHT"];
	if (!path)
		return nil;
	if (![[NSFileManager defaultManager] fileExistsAtPath:path])
		return nil;
	return [NSString stringWithContentsOfFile:path];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (NSString*)identifier
{
	if (!mIdentifier) {
		mIdentifier = [LanguageUtilities dictionaryIdentifierWithLanguageCode:
					[self language] spelling:[self spelling] jargon:[self jargon]];
		[mIdentifier retain];
	}
	return mIdentifier;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

+ (NSMutableArray*)addDescsFromArray:(NSArray*)src overwritingDuplicatesIn:(NSMutableArray*)dst
{
	unsigned	i, j;
	
	for(i = 0; i < [src count]; ++i) {
		NSString*	name = [[src objectAtIndex:i] identifier];
		for(j = 0; j < [dst count]; ++j) {
			if ([name isEqualToString:[[dst objectAtIndex:j] identifier]])
				break;
		}
		if (j < [dst count]) {
			[dst replaceObjectAtIndex:j withObject:[src objectAtIndex:i]];
		} else {
			[dst addObject:[src objectAtIndex:i]];
		}
	}
	
	return dst;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

+ (NSArray*)allLanguageFilesFromPath:(NSString*)inDirectory;
{
	NSDirectoryEnumerator*	enumerator 	= [[NSFileManager defaultManager] enumeratorAtPath:inDirectory];
	NSString*				file;
	NSMutableArray*			langs		= [NSMutableArray array];
	
	while (file = [enumerator nextObject]) {
		if ([[file pathExtension] isEqualToString:@"pwli"]) {
			[langs addObject:[inDirectory stringByAppendingPathComponent:file]];
		}
	}
	return langs;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

+ (NSArray*)allLanguagesWithApplicationBundle:(NSBundle*)bndl
{
	NSArray*		libDirs		= NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, 
										NSUserDomainMask | NSLocalDomainMask | NSNetworkDomainMask, YES);
	NSMutableArray*	langFiles   = [NSMutableArray array];
	NSMutableArray*	langs		= [NSMutableArray array];
	int				i;
	NSArray*		enabledLangs;
	
	for(i = 0; i < [libDirs count]; ++i) {
		NSString*   dir		= [[(NSString*)[libDirs objectAtIndex:i] 
								stringByAppendingPathComponent:@"Application Support"] 
								stringByAppendingPathComponent:@"Aspell"];
		NSArray*	dicts   = [[self class] allLanguageFilesFromPath:dir];
		[langFiles addObjectsFromArray:dicts];
	}	

	if (bndl) {
		[langFiles addObjectsFromArray:[bndl pathsForResourcesOfType:@"pwli" inDirectory:(NSString*)kPathDictionaries]];
	}
	
	for(i = 0; i < [langFiles count]; ++i) {
		Dictionary*   d	= [LanguageDesc languageDescWithDictionaryFile:[langFiles objectAtIndex:i]];
		if (![langs containsObject:d])
			[langs addObject:d];
	}

	[langs sortUsingSelector:@selector(compareDisplayNames:)];
	
	enabledLangs	= [[self class] userLanguageNames];
	for(i = 0; i < [langs count]; ++i) {
		Dictionary* d   = (Dictionary*)[langs objectAtIndex:i];
		[d setEnabled:[enabledLangs containsObject:[d appleName]]];
	}
	
	return langs;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

+ (NSArray*)selectLanguages:(NSArray*)langs withNames:(NSArray*)names
{
	NSMutableArray*	newLangs = [NSMutableArray arrayWithCapacity:[names count]];
	int	i;
	
	for(i = 0; i < [names count]; ++i) {
		NSString*	ni = [names objectAtIndex:i];
		int			j;
		
		for(j = 0; j < [langs count]; ++j) {
			if ([ni isEqualToString:[[langs objectAtIndex:j] displayName]]) {
				[newLangs addObject:[langs objectAtIndex:j]];
			}
		}
	}
	return newLangs;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

+ (NSArray*)userLanguageNames
{
	NSString*		path 	= 
		[@"~/Library/Services/aspell.service/Contents/Info.plist" stringByStandardizingPath];
	NSFileManager*	manager	= [NSFileManager defaultManager];
	NSDictionary*	info;
	NSDictionary*	languagesDict;
	NSArray*		langNames = nil;
	
	if ([manager fileExistsAtPath:path]) {
		info			= [NSDictionary dictionaryWithContentsOfFile:path];
		languagesDict 	= [((NSArray*)[info objectForKey:@"NSServices"]) objectAtIndex:0];
		langNames		= [languagesDict objectForKey:@"NSLanguages"];
	}
	
	if (!langNames)
		return [NSArray array];
	
	return langNames;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

+ (BOOL)setUserLanguageNames:(NSArray*)names withServerPath:(NSString*)path
{
	NSBundle*	bndl = [NSBundle bundleWithPath:path];
	if (bndl)
		return [LanguageDesc setUserLanguageNames:names withServerBundle:bndl];
	return NO;	
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

+ (BOOL)setUserLanguageNames:(NSArray*)names withServerBundle:(NSBundle*)appl
{
	NSString*				path 	= [@"~/Library" stringByStandardizingPath];
	NSFileManager*			manager	= [NSFileManager defaultManager];
	NSMutableDictionary*	info;
	NSMutableDictionary*	languagesDict;
	NSString*				execPath;
	
	if (![manager fileExistsAtPath:path]) {
		if (![manager createDirectoryAtPath:path attributes:nil])
			return NO;
	}

	path = [path stringByAppendingPathComponent:@"Services"];
	if (![manager fileExistsAtPath:path]) {
		if (![manager createDirectoryAtPath:path attributes:nil])
			return NO;
	}

	path = [path stringByAppendingPathComponent:@"aspell.service"];
	if (![manager fileExistsAtPath:path]) {
		NSString*	exampleSource = [[appl resourcePath] stringByAppendingPathComponent:@"aspell.service"];
		if (![manager copyPath:exampleSource toPath:path handler:nil])
			return NO;
	}

	path = [path stringByAppendingPathComponent:@"Contents"];
	path = [path stringByAppendingPathComponent:@"Info.plist"];
	info = [NSMutableDictionary dictionaryWithContentsOfFile:path];

	if (!info)
		return NO;

	languagesDict 	= [((NSArray*)[info objectForKey:@"NSServices"]) objectAtIndex:0];
	if (!languagesDict)
		return NO;
	
	[languagesDict setObject:names forKey:@"NSLanguages"];

	execPath	= [[[appl executablePath] 
								stringByDeletingLastPathComponent] 
								stringByAppendingPathComponent:@"cocoAspell"];
								
	[languagesDict setObject:execPath forKey:@"NSExecutable"];
	[info setObject:execPath forKey:@"CFBundleExecutable"];

	
	
	[info writeToFile:path atomically:YES];
	NSUpdateDynamicServices();

	return YES;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

static BOOL
compileDictionaryAt(
	LanguageDesc*			dict, 
	NSBundle*				appBundle, 
	id<CompileProgress>		callback)
{
	NSString*			dictionaryPath		= [dict dictionaryPath];
	int					err					= 0;
	NSString*			execPath 			= [[[appBundle executablePath] 
												stringByDeletingLastPathComponent] 
													stringByAppendingPathComponent:@"cocoAspell"];
	NSString*			compressPath		= [[appBundle resourcePath] 
												stringByAppendingPathComponent:@"word-list-compress"];
	NSString*			makePath			= [[appBundle resourcePath] 
												stringByAppendingPathComponent:@"gnumake"];
	NSString*			execConfig			= [NSString stringWithFormat:@"cd \"%@\"; ./configure", dictionaryPath];
	NSString*			execMake			= [NSString stringWithFormat:@"cd \"%@\"; \"%@\"", dictionaryPath, makePath];
	BOOL				success				= NO;
	
	[callback startedCompileDictionary:dict];
	[callback progressCompileDictionary:dict messageKey:@"keyInfoConfiguring"];

	setenv("ASPELL", 				[execPath UTF8String], 1);
	setenv("PSPELL_CONFIG", 		[execPath UTF8String], 1);
	setenv("WORD_LIST_COMPRESS", 	[compressPath UTF8String], 1);

	err = system([execConfig UTF8String]);
	
	if (err == 0) {
		[callback progressCompileDictionary:dict messageKey:@"keyInfoMake"];
	
		err = system([execMake UTF8String]);

		if (err == 0) {
			[callback progressCompileDictionary:dict messageKey:@"keyInfoDone"];
			success = YES;
		} else {
			NSLog(execMake);
			NSLog(@"make failed");
			[callback progressCompileDictionary:dict messageKey:@"keyInfoFailMake"];
		}
		
	} else {
		NSLog(execConfig);
		NSLog(@"configure failed");
		[callback progressCompileDictionary:dict messageKey:@"keyInfoFailConfig"];
	}
	
	[callback stoppedCompileDictionary:dict successfully:success];
	return success;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

static long
canCompileDictionaryAt(
	NSString*   dictionaryPath)
{
	NSFileManager*			fm			= [NSFileManager defaultManager];
	
	// check if we can write into that directory
	
	if (![fm isWritableFileAtPath:dictionaryPath]) {
		return 1;
	}
	
	// check if there is enough space (10 times more than the size of all cwl files)	
		
	{
		NSDirectoryEnumerator*	enumerator;
		NSString*				file;
		NSDictionary*			fattrs;
		float					neededSpace  = 0;
		NSNumber*				fsize;
		
		enumerator 	= [[NSFileManager defaultManager] enumeratorAtPath:dictionaryPath];

		while (file = [enumerator nextObject]) {
			if ([[file pathExtension] isEqualToString:@"cwl"]) {
				fattrs		= [fm fileAttributesAtPath:[dictionaryPath stringByAppendingPathComponent:file] traverseLink:YES];
				if (fsize = [fattrs objectForKey:NSFileSize]) {
					neededSpace += [fsize floatValue];
				}
			}
		}
		
		neededSpace *= 10;
		
		fattrs		= [fm fileSystemAttributesAtPath:dictionaryPath];
		if (fsize = [fattrs objectForKey:NSFileSystemFreeSize]) {
			float   existingSpace   = [fsize floatValue];
			float	delta			= existingSpace - neededSpace;
			if (delta < 0) {
				NSLog(@"needed: %f available: %f", neededSpace, existingSpace);
				return (long)delta;
			}
		}
	}

	return 0;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (long)canCompile
{
	return canCompileDictionaryAt([self dictionaryPath]);
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (BOOL)isCompiled
{
	NSString*				file;
	NSDirectoryEnumerator*	enumerator 	= [[NSFileManager defaultManager] enumeratorAtPath:[self dictionaryPath]];

	while (file = [enumerator nextObject]) {
		if ([[file pathExtension] isEqualToString:@"rws"]) {
			return YES;
		}
	}
	return NO;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (BOOL)compileWithBundle:(NSBundle*)appBundle andProgressCallback:(id<CompileProgress>)callback
{
	return compileDictionaryAt(self, appBundle, callback);
}

@end


