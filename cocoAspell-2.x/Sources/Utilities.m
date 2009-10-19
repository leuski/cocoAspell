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
		NSString*	dirPath	= [paths objectAtIndex:i];

		dirPath				= cocoAspellFolderForLibraryFolder(dirPath);

//			NSLog(@"%@", dirPath);


		if (![manager fileExistsAtPath:dirPath isDirectory:&isDir] || !isDir)
			continue;
			
		NSArray*		subPaths	= [manager directoryContentsAtPath:dirPath];
		NSUInteger		j;

		for(j = 0; j < [subPaths count]; ++j) {
			NSString*	subPath		= [dirPath stringByAppendingPathComponent:[subPaths objectAtIndex:j]];
			
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
	UniChar			buffer[NameBufferSize];
	UniCharCount	actualNameLen;
	LocaleRef		locale;
	OSStatus		status;
	LocaleRef		displayLocale;
	
	if (!inName)
		return inName;
	
	status	= LocaleRefFromLocaleString([inName UTF8String], &locale);
	if (status != 0) {
		return inName;
	}
	
	displayLocale	= locale;
	if (inEnglish) {
		status = LocaleRefFromLocaleString("en", &displayLocale);
		if (status != 0) {
			return inName;
		}
	}
	
	status	= LocaleGetName(locale, 0, 
		kLocaleNameMask, 
		displayLocale, NameBufferSize, &actualNameLen, buffer);
	
	if (status != 0) {
		return inName;
	}

	return [NSString stringWithCharacters:buffer length:actualNameLen];
}

NSDictionary*	
infoForDirectoryPath(NSString* inPath)
{
	NSString*				content	= [NSString stringWithContentsOfFile:[inPath stringByAppendingPathComponent:@"info"]];
	NSMutableDictionary*	dict	= [NSMutableDictionary dictionary];
	for (NSString* line in [content componentsSeparatedByString:@"\n"]) {
		if ([line hasPrefix:@" "] || [line hasPrefix:@"\t"]) 
			continue;
		line		= [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		if ([line hasSuffix:@":"])
			continue;
		NSArray*	tmp	= [line componentsSeparatedByString:@" "];
		NSString*	key	= [tmp count] > 0 ? [tmp objectAtIndex:0] : nil;
		NSString*	val	= [tmp count] > 1 ? [[tmp subarrayWithRange:NSMakeRange(1,[tmp count]-1)] componentsJoinedByString:@" "] : @"";
		if (key)
			[dict setObject:val forKey:key];
	}
	return dict;
}
