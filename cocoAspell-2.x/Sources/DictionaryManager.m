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

#ifdef __multilingual__
NSString*	kMultilingualDictionaryName		= @"Multilingual";
#endif // __multilingual__

@interface DictionaryManager (Private)
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
		self.persistent		= inPersistent;
		self.filters		= [self createFilterOptions];
		self.dictionaries	= @[];
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
	AspellOptions*	fltrs	= [[inClass alloc] 
								initWithContentOfFile:[homeDir 
								stringByAppendingPathComponent:kFiltersConfigFileName]];
	if (!fltrs) {
		fltrs	= [[inClass alloc] init];
		fltrs[@"per-conf"] = kFiltersConfigFileName;
		fltrs[@"home_dir"] = homeDir;
		fltrs[@"encoding"] = @"ucs-2";
	}
	[fltrs setPersistent:self.persistent];
	return fltrs;
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
			NSLog(@"%@", execMake);
			NSLog(@"make failed");
			if (errorMessage) {
				*errorMessage	= [NSString stringWithFormat:LocalizedString(@"keyInfoFailMake",nil), dict];
			}
		}
		
	} else {
		NSLog(@"%@", execConfig);
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
		NSError*				error;
		
		enumerator 	= [[NSFileManager defaultManager] enumeratorAtPath:dictionaryPath];

		while (file = [enumerator nextObject]) {
			if ([[file pathExtension] isEqualToString:@"cwl"]) {
				fattrs		= [fm attributesOfItemAtPath:[[dictionaryPath stringByAppendingPathComponent:file] stringByResolvingSymlinksInPath] error:&error]; // TODO check error
				if ((fsize = fattrs[NSFileSize])) {
					neededSpace += [fsize floatValue];
				}
			}
		}
		
		neededSpace *= 10;
		
		fattrs		= [fm attributesOfFileSystemForPath:[dictionaryPath stringByResolvingSymlinksInPath] error:&error]; // TODO check error
		if ((fsize = fattrs[NSFileSystemFreeSize])) {
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

- (NSURL*)serviceFileURL
{
	return [[[NSURL fileURLWithPath:[@"~/Library" stringByStandardizingPath]]
				URLByAppendingPathComponent:@"Services"]
				URLByAppendingPathComponent:kCocoAspellServiceName];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (NSURL*)serviceInfoFileURL:(NSURL*)serviceFileURL
{
	return [[serviceFileURL URLByAppendingPathComponent:@"Contents"]
				URLByAppendingPathComponent:@"Info.plist"];
}


// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (NSArray*)loadEnabledDictionaryNames
{
	NSURL*			dstURL		= [self serviceInfoFileURL:[self serviceFileURL]];
	NSFileManager*	manager		= [NSFileManager defaultManager];
	
	if ([manager fileExistsAtPath:dstURL.path]) {
		NSDictionary*	info			= [NSDictionary dictionaryWithContentsOfURL:dstURL];
		NSDictionary*	languagesDict	= ((NSArray*)info[@"NSServices"])[0];
		NSArray*		langNames		= languagesDict[@"NSLanguages"];
		if (langNames) {
			return langNames;
		}
	}
		
	return @[];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (BOOL)copyServiceBundleFrom:(NSURL*)srcURL to:(NSURL*)dstURL
{
	NSFileManager*			manager		= [NSFileManager defaultManager];
	NSError*				error;
	
	if (![manager fileExistsAtPath:dstURL.path]) {
		return [manager copyItemAtURL:srcURL toURL:dstURL error:&error]; // TODO check error
	}

	NSURL*	dstInfoURL	= [self serviceInfoFileURL:dstURL];
	NSURL*	srcInfoURL	= [self serviceInfoFileURL:srcURL];

	NSDictionary*	srcInfo	= [NSDictionary dictionaryWithContentsOfURL:srcInfoURL];
	NSDictionary*	dstInfo	= [NSDictionary dictionaryWithContentsOfURL:dstInfoURL];
	
	NSString*		srcVersion	= srcInfo[@"CFBundleVersion"];
	NSString*		dstVersion	= dstInfo[@"CFBundleVersion"];
	
	if (srcVersion && [srcVersion isEqualToString:dstVersion])
		return YES;
		
	[manager removeItemAtURL:dstURL error:&error]; // TODO check error
	return [manager copyItemAtURL:srcURL toURL:dstURL error:&error]; // TODO check error
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)removeServiceBundle
{
	NSError* error;
	[self notifyDictionarySetChanged];
	NSURL*					dstURL 	= [self serviceFileURL];
	NSFileManager*			manager		= [NSFileManager defaultManager];
	if ([manager fileExistsAtPath:dstURL.path]) {
		[manager removeItemAtURL:dstURL error:&error]; // TODO check error
	}
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (BOOL)storeEnabledDictionaryNames:(NSArray*)inArray
{	
	NSFileManager*			manager		= [NSFileManager defaultManager];
	NSMutableDictionary*	info;
	NSMutableDictionary*	languagesDict;
//	NSString*				execPath;
	NSBundle*				thisBundle	= [NSBundle bundleForClass:[Dictionary class]];
	NSError*				error;
	
	NSURL* dstURL = [[NSURL fileURLWithPath:[@"~/Library" stringByStandardizingPath]] URLByAppendingPathComponent:@"Services"];
	
	if (![manager createDirectoryAtURL:dstURL withIntermediateDirectories:YES attributes:nil error:&error]) {
		return NO;
	}
	
	dstURL = [dstURL URLByAppendingPathComponent:kCocoAspellServiceName];
//	NSURL*		serviceURL			= [NSURL fileURLWithPath:destPath];

	NSURL*	srcURL		= [[thisBundle resourceURL] URLByAppendingPathComponent:kCocoAspellServiceName];

	[self copyServiceBundleFrom:srcURL to:dstURL];

	NSURL*	dstInfoURL	= [self serviceInfoFileURL:dstURL];
	info		= [NSMutableDictionary dictionaryWithContentsOfURL:dstInfoURL];

	if (!info) {
		NSLog(@"no Info.plist file in cocoAspell.service");
		return NO;
	}
	
	languagesDict 	= ((NSArray*)info[@"NSServices"])[0];
	if (!languagesDict) {
		NSLog(@"no language dictionary");
		return NO;
	}
	
#ifdef __multilingual__
	if ([inArray count] > 1) {
		NSMutableArray*	a	= [NSMutableArray arrayWithArray:inArray];
		[a addObject:kMultilingualDictionaryName];
		inArray	= a;
	}
#endif // __multilingual__
	
	languagesDict[@"NSLanguages"] = inArray;

//	execPath	= [[[thisBundle executablePath] 
//								stringByDeletingLastPathComponent] 
//								stringByAppendingPathComponent:@"cocoAspell"];
//								
//	[languagesDict setObject:execPath forKey:@"NSExecutable"];
//	[info setObject:execPath forKey:@"CFBundleExecutable"];

	if (![info writeToURL:dstInfoURL atomically:YES]) {
		NSLog(@"failed to write language dictionary to %@", dstInfoURL);
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
	NSDictionary*	nameMap					= [UserDefaults userDefaults][@"names"];
	for(NSString* dictDir in dirs) {
		NSDirectoryEnumerator*	enumerator	= [[NSFileManager defaultManager] enumeratorAtPath:dictDir];
		NSString*				file;
		while (file = [enumerator nextObject]) {
			if ([[file pathExtension] isEqualToString:@"multi"]) {
				Dictionary*	d	= [[AspellDictionary alloc] initWithFilePath:[dictDir stringByAppendingPathComponent:file] persistent:self.persistent];
				if (d) {
					NSString*	n	= nameMap[d.identifier];
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
    if (self->_dictionaries != newDictionaries) {
		if (self->_dictionaries) {
			NSIndexSet*	idxs	= [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self->_dictionaries count])];
			[self->_dictionaries removeObserver:self fromObjectsAtIndexes:idxs forKeyPath:@"enabled"];
			[self->_dictionaries removeObserver:self fromObjectsAtIndexes:idxs forKeyPath:@"name"];
		}
		
		self->_dictionaries = newDictionaries;

		if (self->_dictionaries) {
			NSIndexSet*	idxs	= [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self->_dictionaries count])];
			[self->_dictionaries addObserver:self toObjectsAtIndexes:idxs forKeyPath:@"enabled" options:NSKeyValueObservingOptionNew context:nil];
			[self->_dictionaries addObserver:self toObjectsAtIndexes:idxs forKeyPath:@"name" options:NSKeyValueObservingOptionNew context:nil];
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
			[self notifyDictionarySetChanged];
		}
		
		if ([keyPath isEqualToString:@"name"]) {
			NSMutableDictionary*	nameMap			= [[NSMutableDictionary alloc] init];
			for (Dictionary* d in self.dictionaries) {
				if (d.name != d.identifier) {
					nameMap[d.identifier] = d.name;
				}
			}
			[UserDefaults setObject:nameMap forKey:@"names"];
			[self notifyDictionarySetChanged];
		}
		
	}
}

@end
