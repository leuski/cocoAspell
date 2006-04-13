// ============================================================================
//  DictionaryManager.m
// ============================================================================
//
//	cocoAspell2
//
//  Created by Anton Leuski on 2/12/05.
//  Copyright (c) 2005 Anton Leuski. All rights reserved.
// ============================================================================

#import "DictionaryManager.h"
#import "UserDefaults.h"
#import "Dictionary.h"
#import "AspellOptions.h"
#import "Utilities.h"

NSString* kAspellDictionarySetChangedNotification	= @"net.leuski.cocoaspell.AspellDictionarySetChangedNotification";

static NSString*	kCocoAspellServiceName			= @"cocoAspell.service";

@interface DictionaryManager (Private)
- (void)setPersistent:(BOOL)newPersistent;
- (void)notifyDictionarySetChanged;
@end

@implementation DictionaryManager

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
		[self setPersistent:inPersistent];
		[self setFilters:[self createFilterOptions]];
		[self setDictionaries:[NSArray array]];
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
	AspellOptions*	fltrs	= [[[inClass alloc] 
								initWithContentOfFile:[[AspellOptions cocoAspellHomeDir] stringByAppendingPathComponent:@"filters.conf"]] autorelease];
	if (!fltrs) {
		fltrs	= [[[inClass alloc] init] autorelease];
		[fltrs setValue:@"filters.conf" forKey:@"per-conf"];
	}
	[fltrs setPersistent:[self isPersistent]];
	return fltrs;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)dealloc
{
	[self setDictionaries:nil];
	[self setFilters:nil];
	[super dealloc];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (BOOL)isPersistent
{
	return persistent;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setPersistent:(BOOL)newPersistent
{
    if (persistent != newPersistent) {
		persistent = newPersistent;
    }
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

#define NEW_APPKIT  (NSAppKitVersionNumber > NSAppKitVersionNumber10_2_3)

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
	return [[[@"~/Library" stringByStandardizingPath] stringByAppendingPathComponent:@"Services"] stringByAppendingPathComponent:kCocoAspellServiceName];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (NSString*)serviceInfoFilePath:(NSString*)serviceFilePath
{
	return [[serviceFilePath stringByAppendingPathComponent:@"Contents"] stringByAppendingPathComponent:@"Info.plist"];
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
	unsigned		i;
	NSArray*		enabledDictionaryNames	= [self loadEnabledDictionaryNames];
	NSDictionary*	nameMap					= [[UserDefaults userDefaults] objectForKey:@"names"];
	for(i = 0; i < [dirs count]; ++i) {
		NSString*				dictDir		= [dirs objectAtIndex:i];
		NSDirectoryEnumerator*	enumerator	= [[NSFileManager defaultManager] enumeratorAtPath:dictDir];
		NSString*				file;
		while (file = [enumerator nextObject]) {
			if ([[file pathExtension] isEqualToString:@"multi"]) {
				Dictionary*	d	= [[[Dictionary alloc] initWithFilePath:[dictDir stringByAppendingPathComponent:file]] autorelease];
				if (d) {
					NSString*	n	= [nameMap objectForKey:[d identifier]];
					if (n) {
						[d setName:n];
					}
					if ([enabledDictionaryNames containsObject:[d name]]) {
						[d setEnabled:YES];
					}
					[[d options] setPersistent:[self isPersistent]];
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

- (NSArray *)dictionaries
{
	return [[dictionaries retain] autorelease];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setDictionaries:(NSArray *)newDictionaries
{
    if (dictionaries != newDictionaries) {
		if (dictionaries) {
			NSIndexSet*	idxs	= [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [dictionaries count])];
			[dictionaries removeObserver:self fromObjectsAtIndexes:idxs forKeyPath:@"enabled"];
			[dictionaries removeObserver:self fromObjectsAtIndexes:idxs forKeyPath:@"name"];
		}
		
		[dictionaries release];
		dictionaries = [newDictionaries retain];

		if (dictionaries) {
			NSIndexSet*	idxs	= [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [dictionaries count])];
			[dictionaries addObserver:self toObjectsAtIndexes:idxs forKeyPath:@"enabled" options:NSKeyValueObservingOptionNew context:nil];
			[dictionaries addObserver:self toObjectsAtIndexes:idxs forKeyPath:@"name" options:NSKeyValueObservingOptionNew context:nil];
		}
    }
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
	if ([self isPersistent]) {

		if ([keyPath isEqualToString:@"enabled"] || [keyPath isEqualToString:@"name"]) {
			NSMutableArray*	enabledDictionaryNames	= [[NSMutableArray alloc] init];
			NSEnumerator*	i						= [[self dictionaries] objectEnumerator];
			Dictionary*		d;
			while (d = [i nextObject]) {
				if ([d isEnabled]) {
					[enabledDictionaryNames addObject:[d name]];
				}
			}
			[self storeEnabledDictionaryNames:enabledDictionaryNames];
			[enabledDictionaryNames release];
			[self notifyDictionarySetChanged];
		}
		
		if ([keyPath isEqualToString:@"name"]) {
			NSMutableDictionary*	nameMap			= [[NSMutableDictionary alloc] init];
			NSEnumerator*	i						= [[self dictionaries] objectEnumerator];
			Dictionary*		d;
			while (d = [i nextObject]) {
				if ([d name] != [d identifier]) {
					[nameMap setObject:[d name] forKey:[d identifier]];
				}
			}
			[UserDefaults setObject:nameMap forKey:@"names"];
			[nameMap release];
			[self notifyDictionarySetChanged];
		}
		
	}
}


// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (AspellOptions *)filters
{
	if (!filters) {
		[self setFilters:[self createFilterOptions]];
	}
	return [[filters retain] autorelease];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setFilters:(AspellOptions *)newFilters
{
    if (filters != newFilters) {
		[filters release];
		filters = [newFilters retain];
    }
}


@end
