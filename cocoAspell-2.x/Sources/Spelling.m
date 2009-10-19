// ================================================================================
//  Spelling.m
// ================================================================================
//  cocoAspell2
//
//  Created by Anton Leuski on 2/2/05.
//  Copyright (c) 2005-2008 Anton Leuski.
//
// ================================================================================

// patches for aspell
//	1. config.cpp Config::write_to_stream. move String obuf inside the loop

#import "Spelling.h"
#import "NSTextViewWithLinks.h"
#import "AspellOptionsWithLists.h"
#import "Dictionary.h"
#import "DictionaryManager.h"
#import "UserDefaults.h"

@interface Spelling (Compiler)
- (void)compileDictionaries:(NSArray*)dirs;
@end

@interface Spelling (Private)
- (void)finishedCompiling;
- (void)sheetDidEndShouldClose:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
@end

@interface Spelling (Registration)
- (NSString *)registrationName;
- (NSString *)registrationNumber;
- (void)setValidRegistration:(BOOL)flag;
@end

@interface EditableDictionaryManager : DictionaryManager {
}
@end

@implementation Spelling


// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)dealloc
{
	[self setDictionaryManager:nil];
	[super dealloc];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)finishedCompiling
{
	[[self dictionaryManager] setDictionaries:[[self dictionaryManager] allDictionaries]];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)runDictionaryInstaller:(id)sender
{
	NSString*	path	= [[NSBundle bundleForClass:[self class]] pathForResource:@"DictionaryInstaller" ofType:@"app"];
	if (path) {
		[[NSWorkspace sharedWorkspace] launchApplication:path];
	}
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void) mainViewDidLoad
{
	NSString*	path	= [[NSBundle bundleForClass:[self class]] pathForResource:@"DictionaryInstaller" ofType:@"app"];
	if (!path) {
		for (NSTabViewItem* it in [mTabView tabViewItems]) {
			if ([[it identifier] isEqual:@"installer"]) {
				[mTabView removeTabViewItem:it];
				break;
			}
		}
	}

	[mCreditsView setDrawsBackground:NO];
	[mCreditsView setEditable:NO];
	[[mCreditsView enclosingScrollView] setDrawsBackground:NO];
	[mCreditsView setDelegate:self];
	
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)beginCompiling
{
	NSArray*	dicts	= [[self dictionaryManager] allUncompiledDictionaryDirectories];

	if ([dicts count] > 0 && ![UserDefaults cocoAspellExpired]) {
		[NSApplication detachDrawingThread:@selector(compileDictionaries:) toTarget:self withObject:dicts];
	} else {
		[self finishedCompiling];
	}
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)alertSheetDidDismiss:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	[sheet close];
	[self beginCompiling];
}

- (void)closeAlertPanel:(id)sender
{
	[NSApp endSheet:mAlertPanel];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)didSelect
{	
//	NSLog(@"%@", dicts);

	if ([UserDefaults cocoAspellExpired]) {
		[mAlertTitle setStringValue:LocalizedString(@"keyExpiredTitle",nil)];
		[mAlertMessage setStringValue:LocalizedString(@"keyExpired",nil)];
		[NSApp beginSheet:mAlertPanel modalForWindow:[[self mainView] window]
			modalDelegate:self didEndSelector:@selector(alertSheetDidDismiss:returnCode:contextInfo:) contextInfo:nil];
		return;
	} 
	
	if ([UserDefaults cocoAspellTimeLimit] != NULL) {
		NSNumber*	notifiedAboutExiration	= [[UserDefaults userDefaults] objectForKey:@"notifiedAboutExiration"];
		if (notifiedAboutExiration == NULL || ![notifiedAboutExiration boolValue]) {
			[mAlertTitle setStringValue:LocalizedString(@"keyWillExpireTitle",nil)];
			[mAlertMessage setStringValue:[NSString stringWithFormat:LocalizedString(@"keyWillExpire",nil), [[UserDefaults cocoAspellTimeLimit] descriptionWithCalendarFormat:@"%x" timeZone:nil locale:nil]]];
			[NSApp beginSheet:mAlertPanel modalForWindow:[[self mainView] window]
				modalDelegate:self didEndSelector:@selector(alertSheetDidDismiss:returnCode:contextInfo:) contextInfo:nil];
			[UserDefaults setObject:[NSNumber numberWithBool:YES] forKey:@"notifiedAboutExiration"];
			return;
		}
	}
	
	[self beginCompiling];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSString*)creditsPath
{
	return [[NSBundle bundleForClass:[self class]] pathForResource:@"credits" ofType:@"html"];
}


// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (BOOL)isCompiling
{
	return compiling;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setCompiling:(BOOL)newCompiling
{
    if (compiling != newCompiling) {
		compiling = newCompiling;
    }
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)displayAboutDictionaryInfo:(Dictionary*)inDict
{
	[NSApp beginSheet:mCopyrightPanel modalForWindow:[[self mainView] window]
		modalDelegate:self didEndSelector:@selector(sheetDidEndShouldClose:returnCode:contextInfo:) contextInfo:nil];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)sheetDidEndShouldClose: (NSWindow *)sheet
	returnCode: (int)returnCode
	contextInfo: (void *)contextInfo
{
	[sheet close];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (IBAction)closeCopyrightPanel:(id)sender
{
	[NSApp endSheet:mCopyrightPanel];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (DictionaryManager *)dictionaryManager
{
	if (!dictionaryManager) {
		dictionaryManager	= [[[EditableDictionaryManager alloc] initPersistent:YES] autorelease];
	}
	return [[dictionaryManager retain] autorelease];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setDictionaryManager:(DictionaryManager *)newDictionaryManager
{
    if (dictionaryManager != newDictionaryManager) {
		[dictionaryManager release];
		dictionaryManager = [newDictionaryManager retain];
    }
}

@end


@implementation Spelling (Compiler)

- (void)beginCompilation:(NSArray*)arg
{
	[self setCompiling:YES];

	[NSApp beginSheet:mProgressPanel modalForWindow:[[self mainView] window]
		modalDelegate:self didEndSelector:@selector(sheetDidEndShouldClose:returnCode:contextInfo:) contextInfo:nil];
		
	[mProgressBar setMinValue:0];
	[mProgressBar setMaxValue:[arg count]+1];
	[mProgressBar setDoubleValue:1];
}

- (void)endCompilation:(id)arg
{
	[mProgressBar setDoubleValue:[mProgressBar maxValue]];
	[self setCompiling:NO];
	[self finishedCompiling];
//	[mProgressPanel display];
}

- (void)failedCompilation:(NSArray*)arg
{
	[NSApp endSheet:mProgressPanel];

	NSString*	title	= [NSString stringWithFormat:LocalizedString(@"keyCantCompile",nil), [arg objectAtIndex:0]];
	NSBeginCriticalAlertSheet(title, nil, nil, nil, [[self mainView] window],
		self, @selector(sheetDidEndShouldClose:returnCode:contextInfo:), nil, nil, [arg objectAtIndex:1]);
}

- (void)progressCompilation:(NSArray*)arg
{
	[mProgressTitle	setStringValue:[arg objectAtIndex:0]];
	[mProgressBar setDoubleValue:[[arg objectAtIndex:1] intValue]+1];
}

- (void)compileDictionaries:(NSArray*)dirs
{
	if ([dirs count] == 0) 
		return;

	[self performSelectorOnMainThread:@selector(beginCompilation:) withObject:dirs waitUntilDone:YES];

	NSUInteger			i;
	DictionaryManager*	dm	= [self dictionaryManager];
	
	for(i = 0; i < [dirs count]; ++i) {
		NSString*	d		= [dirs objectAtIndex:i];
		NSString*	error;
		NSString*	dirName	= [d lastPathComponent];
		
		[self performSelectorOnMainThread:@selector(progressCompilation:) withObject:[NSArray arrayWithObjects:
				[NSString stringWithFormat:LocalizedString(@"keyInfoMake", nil), dirName], 
				[NSNumber numberWithInt:i], nil] waitUntilDone:YES];
		
		if (![dm canCompileDictionaryAt:d error:&error] || ![dm compileDictionaryAt:d error:&error]) {
			[self performSelectorOnMainThread:@selector(failedCompilation:) withObject:[NSArray arrayWithObjects:dirName, error, nil] waitUntilDone:YES];
			break;
		}

		[mProgressTitle	setStringValue:[NSString stringWithFormat:LocalizedString(@"keyInfoDone", nil), dirName]];

	}
	
	[self performSelectorOnMainThread:@selector(endCompilation:) withObject:nil waitUntilDone:YES];
}

- (IBAction)closeProgressPanel:(id)sender
{
	[NSApp endSheet:mProgressPanel];
}

@end


@implementation EditableDictionaryManager

- (AspellOptions*)createFilterOptions
{
	return [self createFilterOptionsWithClass:[AspellOptionsWithLists class]];
}

@end

@implementation Spelling (Registration)

- (void)checkRegistration
{
	[self setValidRegistration:[[self registrationName] length] && [[self registrationNumber] length]];
	[self willChangeValueForKey:@"registrationInfo"];
	[self didChangeValueForKey:@"registrationInfo"];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (IBAction)closeRegistrationPanel:(id)sender
{
	[NSApp endSheet:mRegistrationPanel];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)displayRegistrationPanel
{
	[NSApp beginSheet:mRegistrationPanel modalForWindow:[[self mainView] window]
		modalDelegate:self didEndSelector:@selector(sheetDidEndShouldClose:returnCode:contextInfo:) contextInfo:nil];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (BOOL)isRegistrable
{
	return NO;
}

- (BOOL)isRegistered
{
	return NO;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (BOOL)isValidRegistration
{
	return validRegistration;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setValidRegistration:(BOOL)newValidRegistration
{
    if (validRegistration != newValidRegistration) {
		validRegistration = newValidRegistration;
    }
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSString *)registrationName
{
	return [[registrationName retain] autorelease];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setRegistrationName:(NSString *)newRegistrationName
{
    if (registrationName != newRegistrationName) {
		[registrationName release];
		registrationName = [newRegistrationName copy];
		[self checkRegistration];
    }
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSString *)registrationNumber
{
	return [[registrationNumber retain] autorelease];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setRegistrationNumber:(NSString *)newRegistrationNumber
{
    if (registrationNumber != newRegistrationNumber) {
		[registrationNumber release];
		registrationNumber = [newRegistrationNumber copy];
		[self checkRegistration];
    }
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSString *)registrationInfo
{
	if ([self isValidRegistration]) 
		return [NSString stringWithFormat:LocalizedString(@"keyRegistered",nil), [self registrationName]];
	else 
		return LocalizedString(@"keyUnregistered",nil);
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSString *)version
{
	return [NSString stringWithFormat:LocalizedString(@"keyVersion",nil), [[[NSBundle bundleForClass:[Spelling class]] infoDictionary] objectForKey:@"CFBundleVersion"]];
}

@end

