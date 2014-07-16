// ============================================================================
//  Utilities.m
// ============================================================================
//
//	cocoAspell2
//
//  Created by Anton Leuski on 4/26/05.
//  Copyright (c) 2005-2008 Anton Leuski. All rights reserved.
// ============================================================================

#import "Utilities.h"


// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

DictionaryDirectoryFlag dictionaryDirectoryType(NSString* inPath)
{
	NSDirectoryEnumerator*	enumerator = [[NSFileManager defaultManager]
											enumeratorAtPath:inPath];

	NSString*				file;
	DictionaryDirectoryFlag	result	= kNoDictionary;

	while (file = [enumerator nextObject]) {
		if ([[file pathExtension] isEqualToString:@"rws"]) {
			result	= kCompiledDictionary;
			break;
		} else if ([[file pathExtension] isEqualToString:@"multi"]) {
			result	= kUncompiledDictionary;
		}
	}
	
	return result;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

NSString* cocoAspellFolderForLibraryFolder(NSString* libPath)
{
	return [[libPath stringByAppendingPathComponent:@"Application Support"] 
								stringByAppendingPathComponent:@"cocoAspell"];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

NSArray* allDictionaryDirectories(DictionaryDirectoryFlag flag)
{
	NSArray*			paths		= NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, 
		NSUserDomainMask | NSLocalDomainMask, true);
	NSUInteger			i;
	NSMutableArray*		a			= [NSMutableArray array];
	NSFileManager*		manager		= [NSFileManager defaultManager];
	BOOL				isDir;

	for(i = 0; i < [paths count]; ++i) {
		NSString*	dirPath	= paths[i];

		dirPath				= cocoAspellFolderForLibraryFolder(dirPath);

//			NSLog(@"%@", dirPath);


		if (![manager fileExistsAtPath:dirPath isDirectory:&isDir] || !isDir)
			continue;
			
		NSError*		error;
		NSArray*		subPaths	= [manager contentsOfDirectoryAtPath:dirPath error:&error]; // TODO check error

		for(NSUInteger j = 0, n = subPaths.count; j < n; ++j) {
			NSString*	subPath		= [dirPath stringByAppendingPathComponent:subPaths[j]];
			
//			NSLog(@"%@", subPath);
			
			if ([manager fileExistsAtPath:subPath isDirectory:&isDir] && isDir) {
				DictionaryDirectoryFlag	kind	= dictionaryDirectoryType(subPath);
				if (kind & flag) {
					[a addObject:subPath];
				}
			}
		}
	}
	return a;
}

#define NameBufferSize	128

NSString*
getSystemLanguageName(
	NSString*	inName,
	BOOL		inEnglish)
{
	if (!inName) return inName;
	
	NSLocale*		locale = [NSLocale localeWithLocaleIdentifier:inName];
	if (!locale) return inName;
	
	NSLocale*		displayLocale = locale;
	if (inEnglish) {
		displayLocale = [NSLocale localeWithLocaleIdentifier:@"en"];
		if (!displayLocale) return inName;
	}
	
	NSString* displayNameString = [displayLocale displayNameForKey:NSLocaleIdentifier value:[locale localeIdentifier]];
	return displayNameString ? displayNameString : inName;
}
