// ============================================================================
//  Dictionary.m
// ============================================================================
//
//	cocoAspell2
//
//  Created by Anton Leuski on 2/4/05.
//  Copyright (c) 2005 Anton Leuski. All rights reserved.
// ============================================================================

#import "UserDefaults.h"
#import "Dictionary.h"
#import "AspellOptions.h"
#import "DictionaryManager.h"
#import "Utilities.h"

static NSArray*	kStorableKeys		= nil;

@implementation Dictionary

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

+ (void)initialize
{
	kStorableKeys	= [[NSArray alloc] initWithObjects:
		@"name", @"identifier",@"enabled", 
		nil];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (id)initWithFilePath:(NSString*)inPath
{
	if (self = [super init]) {		

		identifier	= [[[inPath lastPathComponent] stringByDeletingPathExtension] retain];
		
		NSRange		rng	= [[self identifier] rangeOfString:@"-"];
		NSString*	langCode;
		NSString*	langJargon;
		
		if (rng.location != NSNotFound) {
			langCode	= [[self identifier] substringToIndex:rng.location];
			langJargon	= [[self identifier] substringFromIndex:rng.location+1];
		} else {
			langCode	= [self identifier];
			langJargon	= @"";
		}

		AspellOptions*	opts		= nil;
		NSString*		optsFile	= [[self identifier] stringByAppendingPathExtension:@"conf"];
		NSString*		optsPath	= [[AspellOptions cocoAspellHomeDir] stringByAppendingPathComponent:optsFile];
		
		opts	= [[[AspellOptions alloc] initWithContentOfFile:optsPath] autorelease];
		if (!opts) {
//			NSLog(@"no file %@", optsPath);
			opts	= [[[AspellOptions alloc] init] autorelease];
			if (opts) {
				NSString*		home_dir	= [AspellOptions cocoAspellHomeDir];
				[opts setValue:home_dir				forKey:@"home_dir"];
				[opts setValue:@"ucs-2"				forKey:@"encoding"];
				[opts setValue:@"cocoAspell.conf"	forKey:@"per-conf"];
			}
		}
		
		[self setOptions:opts];
		
		[[self options] setValue:langCode forKey:@"lang"];
		[[self options] setValue:langJargon forKey:@"jargon"];
		[[self options] setValue:[inPath stringByDeletingLastPathComponent] forKey:@"dict-dir"];
		[[self options] setValue:[[self identifier] stringByAppendingPathExtension:@"prepl"] forKey:@"repl"];
		[[self options] setValue:[[self identifier] stringByAppendingPathExtension:@"pws"] forKey:@"personal"];
		[[self options] setValue:optsFile forKey:@"per-conf"];
		
		NSString*	fixedName	= getSystemLanguageName(langCode, YES);
		if (fixedName != langCode) {
			if ([langJargon length] > 0) {
				fixedName	= [fixedName stringByAppendingFormat:@" [%@]", langJargon];
			}
//			fixedName	= [fixedName stringByAppendingFormat:@" -- %@", langCode];
			[self setName:fixedName];
		}
	}
	return self;
}

- (void)addDataFileContent:(NSString*)fileName inDir:(NSString*)dir intoArray:(NSMutableArray*)array
{
	NSString*		content	= [NSString stringWithContentsOfFile:[dir stringByAppendingPathComponent:fileName]];
	if (!content) return;
	NSArray*		lines	= [content componentsSeparatedByString:@"\n"];
	NSEnumerator*	iter	= [lines objectEnumerator];
	NSString*		line;
	while (line = [iter nextObject]) {
		line	= [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		if ([line hasPrefix:@"add"]) {
			line	= [line substringFromIndex:[@"add" length]];
			line	= [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			if ([line hasSuffix:@"rws"]) {
				[array addObject:line];
			} else if ([line hasSuffix:@"multi"]) {
				[self addDataFileContent:line inDir:dir intoArray:array];
			}
		}
	}
}

- (NSString*)dataFiles
{
	NSMutableArray*	array	= [NSMutableArray array];
	[self addDataFileContent:[[self identifier] stringByAppendingPathExtension:@"multi"] inDir:[[self options] valueForKey:@"actual-dict-dir"] intoArray:array];
	return [array componentsJoinedByString:@"\n"];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)dealloc
{
	[name release];
	name	= nil;
	[identifier	release];
	identifier	= nil;

	[self setOptions:nil];
	[super dealloc];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSString *)readableName
{
	return [self name];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setReadableName:(NSString *)newReadableName
{
	[self setName:newReadableName];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSString *)name
{
	return name ? [[name retain] autorelease] : [self identifier];
}


// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setName:(NSString *)newName
{
	if (newName && [newName isEqualToString:[self identifier]]) {
		newName	= nil;
	}

    if (![[self name] isEqualToString:newName]) {
		[name release];
		name = [newName copy];
    }
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSString *)identifier
{
	return [[identifier retain] autorelease];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (BOOL)isEnabled
{
	return enabled;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setEnabled:(BOOL)newEnabled
{
    if ([self isEnabled] != newEnabled) {
		enabled = newEnabled;
    }
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (AspellOptions *)options
{
	return [[options retain] autorelease];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setOptions:(AspellOptions *)newOptions
{
    if (options != newOptions) {
		[options release];
		options = [newOptions retain];
    }
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSString*)copyright
{
	NSString*		path	= [[self options] valueForKey:@"actual-dict-dir"];
	BOOL			isDir;
	path					= [path stringByAppendingPathComponent:@"Copyright"];
	if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && !isDir) {
		return [NSString stringWithContentsOfFile:path];
	}
	return LocalizedString(@"keyNoDictInfo",nil);
}


@end
