// ============================================================================
//  DictionaryInstaller.m
// ============================================================================
//
//	cocoAspell2
//
//  Created by Anton Leuski on 4/25/05.
//  Copyright (c) 2005 Anton Leuski. All rights reserved.
// ============================================================================

#import "DictionaryInstaller.h"
#import "UserDefaults.h"
#import "Utilities.h"
#import "LanguageListing.h"
#import "InstalledDictionary.h"
#include <curl/curl.h>

static size_t function(void *ptr, size_t size, size_t nmemb, NSMutableData *stream)
{
	[stream appendBytes:ptr length:(size * nmemb)];
	return (size * nmemb);
}

static NSString* curl_NSString(CURL* curl, NSString* inURL)
{
	NSString*		str		= NULL;
	NSMutableData*	data	= [[NSMutableData alloc] init];
	curl_easy_setopt(curl, CURLOPT_URL, [inURL UTF8String]);
	curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, function);
	curl_easy_setopt(curl, CURLOPT_WRITEDATA, data);
	CURLcode	code	= curl_easy_perform(curl);
	if (code == 0) {
		str		= [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	}
	[data release];
	return str;
}

@interface FileSizeTransformer : NSValueTransformer {
}
@end

@implementation FileSizeTransformer 
+ (Class)transformedValueClass { return [NSString self]; }
+ (BOOL)allowsReverseTransformation { return NO; }
- (id)transformedValue:(id)value {
	if (value == nil) return nil;
	int	val	= [value intValue];

	if (val < 1000) {
		return [NSString stringWithFormat:LocalizedString(@"%f Bytes",nil), val];
	} else if (val < 1000000) {
		return [NSString stringWithFormat:LocalizedString(@"%.1f KB",nil), (float)val / 1000.0];
	} else {
		return [NSString stringWithFormat:LocalizedString(@"%.1f MB",nil), (float)val / 1000000.0];
	}
}
@end

@interface drawerButtonTransformer : NSValueTransformer {
}
@end

@implementation drawerButtonTransformer 
+ (Class)transformedValueClass { return [NSString self]; }
+ (BOOL)allowsReverseTransformation { return NO; }
- (id)transformedValue:(id)value {
	if (value == nil) return nil;
	if (![value boolValue]) 
		return LocalizedString(@"Show Dictionary Details",nil);
	else
		return LocalizedString(@"Hide Dictionary Details",nil);
}
@end


@implementation DictionaryInstaller

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

+ (void)initialize
{
	static BOOL tooLate = NO;
    if (!tooLate) {
		[NSValueTransformer setValueTransformer:[[[FileSizeTransformer alloc] init] autorelease] forName:@"fileSizeTransformer"];
		[NSValueTransformer setValueTransformer:[[[drawerButtonTransformer alloc] init] autorelease] forName:@"drawerButtonTransformer"];
        tooLate = YES;
    }
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void) dealloc 
{
	[self setLanguages:nil];
	[super dealloc];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSArray*)languagesAsPlist
{
	NSMutableArray*		arr		= [NSMutableArray array];
	NSArray*			keys	= [NSArray arrayWithObjects:@"langCode", @"dictionaries", nil];
	
	for (LanguageListing* ll in [self languages]) {
		[arr addObject:[ll dictionaryWithValuesForKeys:keys]];
	}
	return arr;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSMutableArray*)languagesFromPlist:(NSArray*)plist
{
	NSMutableArray*		arr		= [NSMutableArray array];
	for (NSDictionary* ll in plist) {
		[arr addObject:[[[LanguageListing alloc] 
							initWithLanguageCode:[ll objectForKey:@"langCode"] 
							dictionaries:[ll objectForKey:@"dictionaries"]] autorelease]];
	}
	return arr;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSWindow*)window
{
	return window;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)loadDictionaryListings:(id)arg
{
	CURL*	curl			= curl_easy_init();

	NSString*			base_url	= @"ftp://ftp.gnu.org/gnu/aspell/dict/";

	[self performSelectorOnMainThread:@selector(progressAnimate:) withObject:[NSString stringWithFormat:LocalizedString(@"Accessing ftp site %@...",nil), base_url] waitUntilDone:YES];

	NSString*			str			= curl_NSString(curl, base_url);
	
	if (str == NULL) {
		[self performSelectorOnMainThread:@selector(progressStop:) withObject:[NSString stringWithFormat:LocalizedString(@"Failed to access the dictionary ftp site %@. Try again later.",nil), base_url] waitUntilDone:YES];
		curl_easy_cleanup(curl);
		return;
	}
	
	NSMutableArray*		langs		= [NSMutableArray array];

	for (NSString* dir_line in [str componentsSeparatedByString:@"\n"]) {
		dir_line	= [dir_line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		if ([dir_line hasPrefix:@"d"]) {
			NSArray*	tmp			= [dir_line componentsSeparatedByString:@" "];
			NSString*	langCode	= [tmp lastObject];
			[langs addObject:langCode];
		}
	}

	[self performSelectorOnMainThread:@selector(setLanguageCodes:) withObject:langs waitUntilDone:YES];

	int					count	= 0;
	for (NSString* langCode in langs) {
		
		[self performSelectorOnMainThread:@selector(progressShow:) withObject:[NSArray arrayWithObjects:langCode, [NSNumber numberWithInt:count], nil] waitUntilDone:YES];
		++count;
					
		NSString*		langDir	= curl_NSString(curl, [base_url stringByAppendingFormat:@"%@/", langCode]);
		NSMutableArray*	buff	= [NSMutableArray array];
		for (NSString* file_line in [langDir componentsSeparatedByString:@"\n"]) {
			file_line	= [file_line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			if ([file_line length] && ![file_line hasSuffix:@".sig"]) {
				[buff addObject:file_line];
			}
		}

		[self performSelectorOnMainThread:@selector(setLanguageListing:) withObject:[NSArray arrayWithObjects:langCode, buff, nil] waitUntilDone:YES];
	}
	
	[self performSelectorOnMainThread:@selector(progressStop:) withObject:[NSString stringWithFormat:LocalizedString(@"Dictionary list loaded",nil), base_url] waitUntilDone:YES];

	curl_easy_cleanup(curl);
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)progressAnimate:(NSString*)inMessage
{
	[progress startAnimation:self];
	[progress setIndeterminate:YES];
	[progress setHidden:NO];
	[message setStringValue:inMessage];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)progressStop:(NSString*)inMessage
{
	[progress stopAnimation:self];
	[progress setHidden:YES];
	[message setStringValue:inMessage];
	
	NSArray*	arr	= [self languagesAsPlist];
	[arr writeToFile:@"/Users/leuski/aspell_languages_list.plist" atomically:YES];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)updateDictionaryStatus
{
	for (NSString* dir in allDictionaryDirectories(kCompiledDictionary | kUncompiledDictionary)) {
		InstalledDictionary*	dict	= [[[InstalledDictionary alloc] initWithDirectoryPath:dir] autorelease];
		for (LanguageListing* ll in [self languages]) {
			if ([[ll langCode] isEqual:[dict langCode]]) {
				[ll setInstalledDictionary:dict];
				break;
			}
		}
	}
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setLanguageCodes:(NSArray*)inLanguageCodes
{
	[progress stopAnimation:self];
	[progress setIndeterminate:NO];
	[progress setMaxValue:[inLanguageCodes count]];
	[progress setMinValue:0];
	[progress setDoubleValue:0];
	
	NSMutableArray*	langs	= [NSMutableArray array];
	for (NSString* code in inLanguageCodes) {
		[langs addObject:[[[LanguageListing alloc] initWithLanguageCode:code] autorelease]];
	}
	[self setLanguages:langs];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)progressShow:(NSArray*)args
{
	NSString*	langCode	= [args objectAtIndex:0];
	NSNumber*	count		= [args objectAtIndex:1];
	[progress setDoubleValue:[count doubleValue]];
	
	NSString*	langName	= getSystemLanguageName(langCode, YES);
	[message setStringValue:[NSString stringWithFormat:LocalizedString(@"Loading dictionary listing for %@...",nil), langName]];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setLanguageListing:(NSArray*)args
{
	NSString*	langCode	= [args objectAtIndex:0];
	NSArray*	dictList	= [args objectAtIndex:1];
	
	for (LanguageListing* ll in [self languages]) {
		if ([langCode isEqual:[ll langCode]]) {
			[ll setDictionaries:dictList];
			break;
		}
	}
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)addDomainWithName:(NSString*)key mask:(NSSearchPathDomainMask)mask intoArray:(NSMutableArray*)doms
{
	NSArray*	paths		= NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, mask, true);
	if ([[NSFileManager defaultManager] isWritableFileAtPath:[paths objectAtIndex:0]]) {
		NSString*	path	= cocoAspellFolderForLibraryFolder([paths objectAtIndex:0]);
		[doms addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							path, @"path",
							[NSString stringWithFormat:LocalizedString(key,nil), path], @"name",
							nil]];
	}
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)awakeFromNib
{
	[self setLanguages:[NSMutableArray array]];

	if ([[self superclass] instancesRespondToSelector:@selector(awakeFromNib)]) {
		[super awakeFromNib];
	}
	
	NSMutableArray*		doms	= [NSMutableArray array];
	
	[self addDomainWithName:@"All Users" mask:NSLocalDomainMask intoArray:doms];
	[self addDomainWithName:NSFullUserName() mask:NSUserDomainMask intoArray:doms];
	
	[self setDomains:doms];
	[self setSelectedDomain:[doms objectAtIndex:0]];
	
	NSArray*	arr	= [NSArray arrayWithContentsOfFile:@"/Users/leuski/aspell_languages_list.plist"];
	if (arr) {
		[self setLanguages:[self languagesFromPlist:arr]];
	} else {
//		[NSApplication detachDrawingThread:@selector(loadDictionaryListings:) toTarget:self withObject:nil];
	}
}


// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSDictionary *)selectedDomain
{
	return selectedDomain;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setSelectedDomain:(NSDictionary *)newSelectedDomain
{
    if (selectedDomain != newSelectedDomain) {
		selectedDomain = newSelectedDomain;
    }
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSArray *)domains
{
	return [[domains retain] autorelease];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setDomains:(NSArray *)newDomains
{
    if (domains != newDomains) {
		[domains release];
		domains = [newDomains copy];
    }
}
// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSArray *)languages
{
	return [[languages retain] autorelease];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setLanguages:(NSArray *)newLanguages
{
    if (languages != newLanguages) {
		if (languages) {
			[languages removeObserver:self fromObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,[languages count])] forKeyPath:@"selected"];
		}
		[languages release];
		languages = [newLanguages retain];
		if (languages) {
			[languages addObserver:self toObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,[languages count])] forKeyPath:@"selected" options:NSKeyValueObservingOptionNew context:nil];
		}
		[self updateDictionaryStatus];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqual:@"selected"]) {
		[self willChangeValueForKey:@"hasEnabledLanguages"];
		[self didChangeValueForKey:@"hasEnabledLanguages"];
		[self willChangeValueForKey:@"installButtonText"];
		[self didChangeValueForKey:@"installButtonText"];
	}
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (int)countEnabledLanguages
{
	int					count	= 0;
	for (LanguageListing* ll in [self languages]) {
		if ([ll isSelected])
			++count;
	}
	return count;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (BOOL)hasEnabledLanguages
{
	return [self countEnabledLanguages] > 0;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSString*)installButtonText
{
	int			count	= [self countEnabledLanguages];
	if (count == 0) {
		return LocalizedString(@"Install",nil);
	} else if (count == 1) {
		return LocalizedString(@"Install 1 Item",nil);
	} else {
		return [NSString stringWithFormat:LocalizedString(@"Install %d Items",nil), count];
	}
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (BOOL)isInstalling
{
	return installing;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setInstalling:(BOOL)newInstalling
{
    if (installing != newInstalling) {
		installing = newInstalling;
    }
}

- (void)install:(id)sender
{
	[self setInstalling:YES];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (BOOL)isDetailsVisible
{
	return detailsVisible;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setDetailsVisible:(BOOL)newDetailsVisible
{
    if (detailsVisible != newDetailsVisible) {
		detailsVisible = newDetailsVisible;
    }
}

- (void)toggleDetailsVisible:(id)sender
{
	[self setDetailsVisible:![self isDetailsVisible]];
}


@end
