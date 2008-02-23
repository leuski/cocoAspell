// ============================================================================
//  InstalledDictionary.m
// ============================================================================
//
//	cocoAspell2
//
//  Created by Anton Leuski on 4/30/05.
//  Copyright (c) 2005 Anton Leuski. All rights reserved.
// ============================================================================

#import "InstalledDictionary.h"
#import "Utilities.h"

@implementation InstalledDictionary

- (id)initWithDirectoryPath:(NSString*)inPath
{
	if (self = [super init]) {
		[self setPath:inPath];
	}
	return self;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)dealloc
{
	[self setPath:nil];
	[super dealloc];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSString*)fileNameNoExtension
{
	return [[self path] lastPathComponent];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSString *)path
{
	return [[path retain] autorelease];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setPath:(NSString *)newPath
{
    if (path != newPath) {
		[path release];
		path = [newPath copy];
		NSDictionary*	info	= infoForDirectoryPath(path);
		[self setLangCode:[info objectForKey:@"lang"]];
		[self setModule:[info objectForKey:@"mode"]];
		[self setVersion:[info objectForKey:@"version"]];
    }
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSString *)version
{
	if (version) {
		return [[version retain] autorelease];
	} else {
		return [super version];
	}
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setVersion:(NSString *)newVersion
{
    if (version != newVersion) {
		[version release];
		version = [newVersion copy];
    }
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSString *)module
{
	if (module) {
		return [[module retain] autorelease];
	} else {
		return [super module];
	}
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setModule:(NSString *)newModule
{
    if (module != newModule) {
		[module release];
		module = [newModule copy];
    }
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSString *)langCode
{
	if (langCode) {
		return [[langCode retain] autorelease];
	} else {
		return [super langCode];
	}
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setLangCode:(NSString *)newLangCode
{
    if (langCode != newLangCode) {
		[langCode release];
		langCode = [newLangCode copy];
    }
}

@end
