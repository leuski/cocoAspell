// ============================================================================
//  Utilities.h
// ============================================================================
//
//	cocoAspell2
//
//  Created by Anton Leuski on 4/26/05.
//  Copyright (c) 2005-2008 Anton Leuski. All rights reserved.
// ============================================================================

#import <Foundation/Foundation.h>

typedef enum {
	kNoDictionary			= 0x00,
	kCompiledDictionary		= 0x01,
	kUncompiledDictionary	= 0x02
} DictionaryDirectoryFlag;

DictionaryDirectoryFlag dictionaryDirectoryType(NSString* inPath);
NSArray*		allDictionaryDirectories(DictionaryDirectoryFlag flag);
NSString*		getSystemLanguageName(NSString* inName, BOOL inEnglish);
NSString*		cocoAspellFolderForLibraryFolder(NSString* libPath);
NSDictionary*	infoForDirectoryPath(NSString* inPath);
