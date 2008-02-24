// ============================================================================
//  DictionaryManager.m
// ============================================================================
//
//	cocoAspell2
//
//  Created by Anton Leuski on 2/12/05.
//  Copyright (c) 2005-2008 Anton Leuski. All rights reserved.
// ============================================================================

#import "DictionaryManager.h"
#import "UserDefaults.h"
#import "Dictionary.h"
#import "AspellOptions.h"
#import "Utilities.h"
#import "AspellDictionary.h"

NSString* kAspellDictionarySetChangedNotification	= @"net.leuski.cocoaspell.AspellDictionarySetChangedNotification";

static NSString*	kCocoAspellServiceName			= @"cocoAspell.service";
static NSString*	kFiltersConfigFileName			= @"filters.conf";

NSString*	kMultilingualDictionaryName		= @"Multilingual";

@interface DictionaryManager (Private)
- (void)notifyDictionarySetChanged;
@end

@implementation DictionaryManager
@synthesize dictionaries	= _dictionaries;
@synthesize filters			= _filters;
@synthesize persistent		= _persistent;

- (AspellOptions*)createFilterOptions
{
	AspellOptions*	fltrs	= [self createFilterOptionsWithClass:[AspellOptions class]];
	return fltrs;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (id)initPersistent:(BOOL)inPersistent
{
	if (self = [super init]) {
		self.persistent		= inPersistent;
		self.filters		= [self createFilterOptions];
		self.dictionaries	= [NSArray array];
	}
	return self;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (id)init
{
	return [self initPersistent:NO];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (AspellOptions*)createFilterOptionsWithClass:(Class)inClass
{
	NSString*		homeDir	= [AspellOptions cocoAspellHomeDir];
	AspellOptions*	fltrs	= [[[inClass alloc] 
								initWithContentOfFile:[homeDir 
								stringByAppendingPathComponent:kFiltersConfigFileName]] autorelease];
	if (!fltrs) {
		fltrs	= [[[inClass alloc] init] autorelease];
		[fltrs setValue:kFiltersConfigFileName	forKey:@"per-conf"];
		[fltrs setValue:homeDir					forKey:@"home_dir"];
		[fltrs setValue:@"ucs-2"				forKey:@"encoding"];
	}
	[fltrs setPersistent:self.persistent];
	return fltrs;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)dealloc
{
	self.dictionaries	= nil;
	self.filters		= nil;
	[super dealloc];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (BOOL)compileDictionaryAt:(NSString*)dictionaryPath error:(NSString**)errorMessage
{
	NSString*			dict				= [dictionaryPath lastPathComponent];
	int					err					= 0;

	NSString*			makePath			= @"/usr/bin/make";
	NSString*			execConfig			= [NSString stringWithFormat:@"cd \"%@\"; ./configure", dictionaryPath];
	NSString*			execMake			= [NSString stringWithFormat:@"cd \"%@\"; \"%@\"", dictionaryPath, makePath];
	BOOL				success				= NO;
	
	setenv("ASPELL",	"/usr/local/bin/aspell",			1);
	setenv("PATH",		"/bin:/usr/bin:/usr/local/bin:.",	1);	

	err = system([execConfig UTF8String]);
	
	if (err == 0) {
		err = system([execMake UTF8String]);

		if (err == 0) {
			success = YES;
		} else {
			NSLog(execMake);
			NSLog(@"make failed");
			if (errorMessage) {
				*errorMessage	= [NSString stringWithFormat:LocalizedString(@"keyInfoFailMake",nil), dict];
			}
		}
		
	} else {
		NSLog(execConfig);
		NSLog(@"configure failed");
		if (errorMessage) {
			*errorMessage	= [NSString stringWithFormat:LocalizedString(@"keyInfoFailConfig",nil), dict];
		}
	}
	
	return success;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (BOOL)canCompileDictionaryAt:(NSString*)dictionaryPath error:(NSString**)errorMessage
{
	NSFileManager*			fm			= [NSFileManager defaultManager];
	
	// check if we can write into that directory
	
	if (![fm isWritableFileAtPath:dictionaryPath]) {
		if (errorMessage) {
			NSString*   hasTo		= [NSString stringWithFormat:LocalizedString(@"keyHasToCompile", nil), [dictionaryPath lastPathComponent]];
			NSString*   noAccess	= [NSString stringWithFormat:LocalizedString(@"keyCantCompileNoAccess", nil), dictionaryPath];
			if (hasTo) {
				noAccess			= [NSString stringWithFormat:@"%@ %@", hasTo, noAccess];
			}
			*errorMessage	= noAccess;
		}
		return NO;
	}
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/make"]) {
		if (errorMessage) {
			NSString*   hasTo		= [NSString stringWithFormat:LocalizedString(@"keyHasToCompile", nil), [dictionaryPath lastPathComponent]];
			NSString*   noAccess	= [NSString stringWithFormat:LocalizedString(@"keyCantCompileNoMake", nil), dictionaryPath];
			if (hasTo) {
				noAccess			= [NSString stringWithFormat:@"%@ %@", hasTo, noAccess];
			}
			*errorMessage	= noAccess;
		}
		return NO;
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
				if (errorMessage) {
					NSString*   hasTo		= [NSString stringWithFormat:LocalizedString(@"keyHasToCompile", nil), [dictionaryPath lastPathComponent]];
					NSString*   noSpace		= [NSString stringWithFormat:LocalizedString(@"keyCantCompileNoSpace", nil), dictionaryPath, delta];
					if (hasTo) {
						noSpace				= [NSString stringWithFormat:@"%@ %@", hasTo, noSpace];
					}
					*errorMessage	= noSpace;
				}
				return NO;
			}
		}
	}

	return YES;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (NSString*)serviceFilePath
{
	return [[[@"~/Library" stringByStandardizingPath]
				stringByAppendingPathComponent:@"Services"] 
				stringByAppendingPathComponent:kCocoAspellServiceName];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (NSString*)serviceInfoFilePath:(NSString*)serviceFilePath
{
	return [[serviceFilePath stringByAppendingPathComponent:@"Contents"] 
				stringByAppendingPathComponent:@"Info.plist"];
}


// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (NSArray*)loadEnabledDictionaryNames
{
	NSString*		destPath 	= [self serviceInfoFilePath:[self serviceFilePath]];
	NSFileManager*	manager		= [NSFileManager defaultManager];
	
	if ([manager fileExistsAtPath:destPath]) {
		NSDictionary*	info			= [NSDictionary dictionaryWithContentsOfFile:destPath];
		NSDictionary*	languagesDict	= [((NSArray*)[info objectForKey:@"NSServices"]) objectAtIndex:0];
		NSArray*		langNames		= [languagesDict objectForKey:@"NSLanguages"];
		if (langNames) {
			return langNames;
		}
	}
		
	return [NSArray array];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (BOOL)copyServiceBundleFrom:(NSString*)srcPath to:(NSString*)dstPath
{
	NSFileManager*			manager		= [NSFileManager defaultManager];

	if (![manager fileExistsAtPath:dstPath]) {
		return [manager copyPath:srcPath toPath:dstPath handler:nil];
	}

	NSString*	dstInfoPath	= [self serviceInfoFilePath:dstPath];
	NSString*	srcInfoPath	= [self serviceInfoFilePath:srcPath];

	NSDictionary*	srcInfo	= [NSDictionary dictionaryWithContentsOfFile:srcInfoPath];
	NSDictionary*	dstInfo	= [NSDictionary dictionaryWithContentsOfFile:dstInfoPath];
	
	NSString*		srcVersion	= [srcInfo objectForKey:@"CFBundleVersion"];
	NSString*		dstVersion	= [dstInfo objectForKey:@"CFBundleVersion"];
	
	if (srcVersion && [srcVersion isEqualToString:dstVersion])
		return YES;
		
	[manager removeFileAtPath:dstPath handler:nil];
	return [manager copyPath:srcPath toPath:dstPath handler:nil];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)removeServiceBundle
{
	[self notifyDictionarySetChanged];
	NSString*				dstPath 	= [self serviceFilePath];
	NSFileManager*			manager		= [NSFileManager defaultManager];
	if ([manager fileExistsAtPath:dstPath]) {
		[manager removeFileAtPath:dstPath handler:nil];
	}
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (BOOL)storeEnabledDictionaryNames:(NSArray*)inArray
{
	if ([UserDefaults cocoAspellExpired]) {
		[self removeServiceBundle];
		return NO;
	}
	
	NSString*				destPath 	= [@"~/Library" stringByStandardizingPath];
	NSFileManager*			manager		= [NSFileManager defaultManager];
	NSMutableDictionary*	info;
	NSMutableDictionary*	languagesDict;
//	NSString*				execPath;
	NSBundle*				thisBundle	= [NSBundle bundleForClass:[Dictionary class]];
	
	if (![manager fileExistsAtPath:destPath]) {
		if (![manager createDirectoryAtPath:destPath attributes:nil])
			return NO;
	}

	destPath = [destPath stringByAppendingPathComponent:@"Services"];
	if (![manager fileExistsAtPath:destPath]) {
		if (![manager createDirectoryAtPath:destPath attributes:nil])
			return NO;
	}

	destPath = [destPath stringByAppendingPathComponent:kCocoAspellServiceName];
//	NSURL*		serviceURL			= [NSURL fileURLWithPath:destPath];

	NSString*	srcPath		= [[thisBundle resourcePath] stringByAppendingPathComponent:kCocoAspellServiceName];

	[self copyServiceBundleFrom:srcPath to:destPath];

	NSString*	dstInfoPath	= [self serviceInfoFilePath:destPath];
	info		= [NSMutableDictionary dictionaryWithContentsOfFile:dstInfoPath];

	if (!info) {
		NSLog(@"no Info.plist file in cocoAspell.service");
		return NO;
	}
	
	languagesDict 	= [((NSArray*)[info objectForKey:@"NSServices"]) objectAtIndex:0];
	if (!languagesDict) {
		NSLog(@"no language dictionary");
		return NO;
	}
	
	if ([inArray count] > 1) {
		NSMutableArray*	a	= [NSMutableArray arrayWithArray:inArray];
		[a addObject:kMultilingualDictionaryName];
		inArray	= a;
	}
	
	[languagesDict setObject:inArray forKey:@"NSLanguages"];

//	execPath	= [[[thisBundle executablePath] 
//								stringByDeletingLastPathComponent] 
//								stringByAppendingPathComponent:@"cocoAspell"];
//								
//	[languagesDict setObject:execPath forKey:@"NSExecutable"];
//	[info setObject:execPath forKey:@"CFBundleExecutable"];

	if (![info writeToFile:dstInfoPath atomically:YES]) {
		NSLog(@"failed to write language dictionary to %@", dstInfoPath);
	}
	NSUpdateDynamicServices();
	
//	OSStatus	err	= LSRegisterURL((CFURLRef)serviceURL, YES);
//	NSLog(@"updated LS db: %d, %@", err, serviceURL);
	return YES;
}


// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSArray*)allUncompiledDictionaryDirectories
{
	return allDictionaryDirectories(kUncompiledDictionary);
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSArray*)allDictionaries
{
	NSMutableArray*	dicts					= [NSMutableArray array];
	NSArray*		dirs					= allDictionaryDirectories(kCompiledDictionary);
	NSArray*		enabledDictionaryNames	= [self loadEnabledDictionaryNames];
	NSDictionary*	nameMap					= [[UserDefaults userDefaults] objectForKey:@"names"];
	for(NSString* dictDir in dirs) {
		NSDirectoryEnumerator*	enumerator	= [[NSFileManager defaultManager] enumeratorAtPath:dictDir];
		NSString*				file;
		while (file = [enumerator nextObject]) {
			if ([[file pathExtension] isEqualToString:@"multi"]) {
				Dictionary*	d	= [[[AspellDictionary alloc] initWithFilePath:[dictDir stringByAppendingPathComponent:file] persistent:self.persistent] autorelease];
				if (d) {
					NSString*	n	= [nameMap objectForKey:d.identifier];
					if (n) {
						d.name = n;
					}
					if ([enabledDictionaryNames containsObject:d.name]) {
						d.enabled	= YES;
					}
					[dicts addObject:d];
				}
			}
		}
	}
	
	return dicts;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setDictionaries:(NSArray *)newDictionaries
{
    if (self.dictionaries != newDictionaries) {
		if (self.dictionaries) {
			NSIndexSet*	idxs	= [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self.dictionaries count])];
			[self.dictionaries removeObserver:self fromObjectsAtIndexes:idxs forKeyPath:@"enabled"];
			[self.dictionaries removeObserver:self fromObjectsAtIndexes:idxs forKeyPath:@"name"];
		}
		
		[self->_dictionaries release];
		self->_dictionaries = [newDictionaries retain];

		if (self.dictionaries) {
			NSIndexSet*	idxs	= [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self.dictionaries count])];
			[self.dictionaries addObserver:self toObjectsAtIndexes:idxs forKeyPath:@"enabled" options:NSKeyValueObservingOptionNew context:nil];
			[self.dictionaries addObserver:self toObjectsAtIndexes:idxs forKeyPath:@"name" options:NSKeyValueObservingOptionNew context:nil];
		}
    }
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSArray*)enabledDictionaries
{
	NSMutableArray*	result	= [NSMutableArray array];
	for(Dictionary* d in self.dictionaries) {
		if (d.enabled)
			[result addObject:d];
	}
	return result;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)notifyDictionarySetChanged
{
	[[NSDistributedNotificationCenter defaultCenter] 
			postNotificationName:	kAspellDictionarySetChangedNotification
			object: 				nil
			userInfo: 				nil /* no dictionary */
			deliverImmediately: 	YES];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (self.persistent) {

		if ([keyPath isEqualToString:@"enabled"] || [keyPath isEqualToString:@"name"]) {
			NSMutableArray*	enabledDictionaryNames	= [[NSMutableArray alloc] init];
			for (Dictionary* d in self.dictionaries) {
				if (d.enabled) {
					[enabledDictionaryNames addObject:d.name];
				}
			}
			[self storeEnabledDictionaryNames:enabledDictionaryNames];
			[enabledDictionaryNames release];
			[self notifyDictionarySetChanged];
		}
		
		if ([keyPath isEqualToString:@"name"]) {
			NSMutableDictionary*	nameMap			= [[NSMutableDictionary alloc] init];
			for (Dictionary* d in self.dictionaries) {
				if (d.name != d.identifier) {
					[nameMap setObject:d.name forKey:d.identifier];
				}
			}
			[UserDefaults setObject:nameMap forKey:@"names"];
			[nameMap release];
			[self notifyDictionarySetChanged];
		}
		
	}
}

@end
