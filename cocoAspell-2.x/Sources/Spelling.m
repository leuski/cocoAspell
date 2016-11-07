// ================================================================================
//  Spelling.m
// ================================================================================
//  cocoAspell2
//
//  Created by Anton Leuski on 2/2/05.
//  Copyright (c) 2005-2008 Anton Leuski. All rights reserved.
//
//	Redistribution and use in source and binary forms, with or without
//	modification, are permitted provided that the following conditions are met:
//
//	1. Redistributions of source code must retain the above copyright notice, this
//	list of conditions and the following disclaimer.
//	2. Redistributions in binary form must reproduce the above copyright notice,
//	this list of conditions and the following disclaimer in the documentation
//	and/or other materials provided with the distribution.
//
//	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//	ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//	WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//	DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
//	ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//	(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//	 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//	ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//	(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//	SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// ================================================================================

// patches for aspell
//	1. config.cpp Config::write_to_stream. move String obuf inside the loop

#import "Spelling.h"
#import "AspellOptionsWithLists.h"
#import "Dictionary.h"
#import "DictionaryManager.h"
#import "UserDefaults.h"

@interface Spelling (Compiler)
- (void)compileDictionaries:(NSArray*)dirs;
@end

@interface Spelling () <WebPolicyDelegate>
- (void)finishedCompiling;
- (void)sheetDidEndShouldClose:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
@end

@interface EditableDictionaryManager : DictionaryManager
@end

@implementation Spelling


// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)finishedCompiling
{
	self.dictionaryManager.dictionaries = [self.dictionaryManager allDictionaries];
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
		for (NSTabViewItem* it in [self.mTabView tabViewItems]) {
			if ([[it identifier] isEqual:@"installer"]) {
				[self.mTabView removeTabViewItem:it];
				break;
			}
		}
	}

	[self.creditsView setDrawsBackground:NO];
	[self.creditsView setEditable:NO];
	[[self.creditsView enclosingScrollView] setDrawsBackground:NO];

	[self.creditsView.mainFrame loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[self creditsPath]]]];
	self.creditsView.policyDelegate = self;
	
//	[self.creditsView setMainFrameURL:[NSURL fileURLWithPath:[self creditsPath]]];
}

- (void)webView:(WebView *)webView
decidePolicyForNavigationAction:(NSDictionary *)actionInformation
		request:(NSURLRequest *)request frame:(WebFrame *)frame
decisionListener:(id < WebPolicyDecisionListener >)listener
{
	[[NSWorkspace sharedWorkspace] openURL:[request URL]];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)beginCompiling
{
	NSArray*	dicts	= [[self dictionaryManager] allUncompiledDictionaryDirectories];

	if ([dicts count] > 0) {
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
	[NSApp endSheet:self.mAlertPanel];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)didSelect
{	
//	NSLog(@"%@", dicts);
	
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

- (void)displayAboutDictionaryInfo:(Dictionary*)inDict
{
  [self.mainView.window beginSheet:self.mCopyrightPanel
                 completionHandler:^(NSModalResponse returnCode)
  {
    [self.mCopyrightPanel close];
  }];
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
	[NSApp endSheet:self.mCopyrightPanel];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (DictionaryManager *)dictionaryManager
{
	if (!_dictionaryManager) {
		_dictionaryManager	= [[EditableDictionaryManager alloc] initPersistent:YES];
	}
	return _dictionaryManager;
}

- (NSString *)version
{
	return [NSString stringWithFormat:LocalizedString(@"keyVersion",nil), [[NSBundle bundleForClass:[Spelling class]] infoDictionary][@"CFBundleVersion"]];
}

@end


@implementation Spelling (Compiler)

- (void)beginCompilation:(NSArray*)arg
{
	[self setCompiling:YES];

  [self.mainView.window beginSheet:self.mProgressPanel
                 completionHandler:^(NSModalResponse returnCode)
   {
     [self.mProgressPanel close];
   }];

  [self.mProgressBar setMinValue:0];
	[self.mProgressBar setMaxValue:[arg count]+1];
	[self.mProgressBar setDoubleValue:1];
}

- (void)endCompilation:(id)arg
{
	[self.mProgressBar setDoubleValue:[self.mProgressBar maxValue]];
	[self setCompiling:NO];
	[self finishedCompiling];
//	[mProgressPanel display];
}

- (void)failedCompilation:(NSArray*)arg
{
	[NSApp endSheet:self.mProgressPanel];

  NSAlert* alert = [NSAlert new];
  alert.alertStyle = NSAlertStyleCritical;
  alert.messageText = [NSString stringWithFormat:LocalizedString(@"keyCantCompile",nil), arg[0]];
  alert.informativeText = [NSString stringWithFormat:@"%@", arg[1]];
  
  [alert beginSheetModalForWindow:self.mainView.window
                completionHandler:^(NSModalResponse returnCode)
  {
    [alert.window close];
  }];
}

- (void)progressCompilation:(NSArray*)arg
{
	[self.mProgressTitle	setStringValue:arg[0]];
	[self.mProgressBar setDoubleValue:[arg[1] intValue]+1];
}

- (void)compileDictionaries:(NSArray*)dirs
{
	if ([dirs count] == 0) 
		return;

	[self performSelectorOnMainThread:@selector(beginCompilation:) withObject:dirs waitUntilDone:YES];

	NSUInteger			i;
	DictionaryManager*	dm	= [self dictionaryManager];
	
	for(i = 0; i < [dirs count]; ++i) {
		NSString*	d		= dirs[i];
		NSString*	error;
		NSString*	dirName	= [d lastPathComponent];
		
		[self performSelectorOnMainThread:@selector(progressCompilation:) withObject:@[[NSString stringWithFormat:LocalizedString(@"keyInfoMake", nil), dirName], 
				[NSNumber numberWithUnsignedInteger:i]] waitUntilDone:YES];
		
		if (![dm canCompileDictionaryAt:d error:&error] || ![dm compileDictionaryAt:d error:&error]) {
			[self performSelectorOnMainThread:@selector(failedCompilation:) withObject:@[dirName, error] waitUntilDone:YES];
			break;
		}

		[self.mProgressTitle	setStringValue:[NSString stringWithFormat:LocalizedString(@"keyInfoDone", nil), dirName]];

	}
	
	[self performSelectorOnMainThread:@selector(endCompilation:) withObject:nil waitUntilDone:YES];
}

- (IBAction)closeProgressPanel:(id)sender
{
	[NSApp endSheet:self.mProgressPanel];
}

@end


@implementation EditableDictionaryManager

- (AspellOptions*)createFilterOptions
{
	return [self createFilterOptionsWithClass:[AspellOptionsWithLists class]];
}

@end

