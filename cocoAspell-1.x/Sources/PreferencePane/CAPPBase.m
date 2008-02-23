// ================================================================================
//  CAPPBase.m
// ================================================================================
//	cocoaspell
//
//  Created by Anton Leuski on Mon Nov 12 2001.
//  Copyright (c) 2002-2004 Anton Leuski.
//
//	This file is part of cocoAspell package.
//
//	Redistribution and use of cocoAspell in source and binary forms, with or without 
//	modification, are permitted provided that the following conditions are met:
//
//	1. Redistributions of source code must retain the above copyright notice, this 
//		list of conditions and the following disclaimer.
//	2. Redistributions in binary form must reproduce the above copyright notice, 
//		this list of conditions and the following disclaimer in the documentation 
//		and/or other materials provided with the distribution.
//	3. The name of the author may not be used to endorse or promote products derived 
//		from this software without specific prior written permission.
//
//	THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED 
//	WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
//	MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT 
//	SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
//	EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT 
//	OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
//	INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, 
//	STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY 
//	OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// ================================================================================

#import "CAPPBase.h"
#import "LanguageDesc.h"
#import "TeXCommandFormatter.h"
#import "TeXParameterFormatter.h"
#import "NSDictionary_Extensions.h"
#import "NSTextViewWithLinks.h"
#import "ProcessInfo.h"

static	NSArray*			kSuggestionModeValues;
static 	NSRect				kDefaultNoteFrameShown;
static 	NSRect				kDefaultNoteFrameHidden;

#define	kStripAccentsID		1
#define	kIgnoreAccentsID	2
#define kLocalizeMe			@"<<Localize Me>>"

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

static int
compareTeXCommands(
	id		a,
	id		b,
	void*	c)
{
	return [(NSString*)[a objectForKey:kKeyCommandName] compare:(NSString*)[b objectForKey:kKeyCommandName]];
}

@implementation CAPPBase

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

+ (void)initialize
{
	kSuggestionModeValues = [[NSArray arrayWithObjects: kUltra, kFast, kNormal, kBadSpellers, nil] retain];
}


// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------


- (id)initWithBundle:(NSBundle *)bundle
{
	mLanguages 				= nil;
	mConnection				= nil;
	mApplPath				= nil;
	
	return [super initWithBundle:bundle];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)dealloc
{
	[mApplPath 			release];
	mApplPath 			= nil;
	[mConnection 		release];
	mConnection 		= nil;
	[mLanguages			release];
	mLanguages 			= nil;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (NSArray*)allLanguages
{
	if (!mLanguages) {
		NSBundle*	bndl	= [NSBundle bundleForClass:[self class]];
		mLanguages = [LanguageDesc allLanguagesWithApplicationBundle:bndl];
		[mLanguages retain];
	}
	
	return mLanguages;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (Dictionary*)selectedDictionary
{
	return nil;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)setSelectedDictionary:(Dictionary*)value
{
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)reloadDictionarySet
{
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

//- (void)dictionarySetChanged
//{
//	Dictionary*	oldSelectedDict	= [self selectedDictionary];
//	Dictionary* newSelectedDict = nil;
//	[oldSelectedDict retain];
//	
//	[mLanguages 	release];
//	mLanguages 		= nil;
//	
//	[self reloadDictionarySet];
//	
//	if (oldSelectedDict) {
//		unsigned	i, n = [[self allLanguages] count];
//		Dictionary* d;
//		for(i = 0; i < n; ++i) {
//			d   = [[self allLanguages] objectAtIndex:i];
//			if ([[d identifier] isEqualToString:[oldSelectedDict identifier]]) {
//				newSelectedDict = d;
//				break;
//			}
//		}
//		[oldSelectedDict release];
//	}
//
//	[self setSelectedDictionary:newSelectedDict];
//	[self loadEditArea:self];
//}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)killService
{
	ProcessIterator*	iter	= [ProcessIterator iterator];
	while ([iter hasNext]) {
		ProcessInfo*	info	= [iter next];
		if ([@"cocoAspell" isEqualTo:[info processName]]) {
			[info kill];
			return;
		}
	}
}


// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (NSArray*)enabledNames
{
	NSArray*		langs 		= [self allLanguages];
	NSMutableArray*	selected 	= [NSMutableArray arrayWithCapacity:[langs count]];
	int				i;
	
	for(i = 0; i < [langs count]; ++i) {
		if ([[langs objectAtIndex:i] isEnabled])
			[selected addObject:[[langs objectAtIndex:i] appleName]];
	}
	return selected;
}


// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)findDirectory:(NSString*)dirPath 
	fromPath:		(NSString*)appPath 
	didEndSelector:	(SEL)didEndSelector
{
	NSOpenPanel*	panel 		= [NSOpenPanel openPanel];
	NSString*		beginDir;
	
	[panel setCanChooseDirectories:	YES];
	[panel setCanChooseFiles:		NO];
	[panel setResolvesAliases:		YES];
	[panel setPrompt:LocalizedString(@"keyAddDictButton")];
									
	[mOpenPanelAuxViewMessage setStringValue:LocalizedString(@"keyAddDictTitle")];
	[panel setAccessoryView:mOpenPanelAuxView];

	if (appPath) {
		beginDir	= [appPath stringByDeletingLastPathComponent];
	} else {
		beginDir	= [@"~" stringByStandardizingPath];
	}

	[panel beginSheetForDirectory:	beginDir
			file:					nil 
			types:					nil 
			modalForWindow:			[[self mainView] window]
			modalDelegate:			self 
			didEndSelector:			didEndSelector
			contextInfo:			nil];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)addDictionary:(Dictionary*)dict completedForUserWithSuccess:(BOOL)success
{
	if ([dict isEqual:[self selectedDictionary]]) {
		NSLog(@"done %@", [dict displayName]);
		[dict setEnabled:success];
		[self editorLoadDictionaryWithID:dict];

		if (success) {
			NSBundle*   bndl	= [NSBundle bundleForClass:[self class]];
			[LanguageDesc setUserLanguageNames:[self enabledNames] withServerBundle:bndl];
			[self killService];
		}
	}
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)setNoteVisible:(BOOL)visible
{
	[mNote 			setFrame:
		(visible ? kDefaultNoteFrameShown : kDefaultNoteFrameHidden)];
	[mNote 			setNeedsDisplay:YES];
	[[mNote window]	display];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)progressCompileDictionary:(Dictionary*)dict messageKey:(NSString*)key
{
	[mProgressMessage 	setStringValue:
		[NSString stringWithFormat:
			LocalizedString(key), 
				[dict displayName]]];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)stoppedCompileDictionary:(Dictionary*)dict successfully:(BOOL)success
{
	[mProgressBar 			stopAnimation:			self];
	[mProgressDoneButton	setEnabled:				YES];
	[self addDictionary:dict completedForUserWithSuccess:success];
}


// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)startedCompileDictionary:(Dictionary*)dict
{
	[mProgressBar 			startAnimation:			self];
	[mAddDictionary 		setEnabled:				NO];
	[mProgressDoneButton	setEnabled:				NO];

	[mProgressWindow setDefaultButtonCell:[mProgressDoneButton cell]];

	[NSApp beginSheet:mProgressWindow modalForWindow:[[self mainView] window] 
		modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)compileDictionary:(NSArray*)dataArray
{
	NSAutoreleasePool*	pool				= [[NSAutoreleasePool alloc] init];

	NSConnection*		serverConnection	= [NSConnection
												connectionWithReceivePort:	[dataArray objectAtIndex:0]
												sendPort:					[dataArray objectAtIndex:1]];

	id					root				= [serverConnection rootProxy];
	Dictionary*			dict				= [dataArray objectAtIndex:2];
	BOOL				success				= NO;
	
	[root setProtocolForProxy:@protocol(CompileProgress)];
	success = [dict compileWithBundle:[dataArray objectAtIndex:3] andProgressCallback:root];
	if ([dataArray count] > 4 && [dataArray objectAtIndex:4]) {
		[self performSelector:(SEL)[dataArray objectAtIndex:4] withObject:dict withObject:[NSNumber numberWithBool:success]];
	}
	[pool release];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)addDictionary:(Dictionary*)dict withBundle:(NSBundle*)appBundle
{
	NSArray*				dataArray;
	long					err			= [dict canCompile];

	// check if we can write into that directory
	
	if (err != 0) {
	
		NSString*   path	= [(LanguageDesc*)dict dictionaryPath];
		NSString*   hasTo   = [NSString stringWithFormat:LocalizedString(@"keyHasToCompile"), [dict displayName]];

		if (!path)
			path			= [dict displayName];
	
		if (err == 1) {
			NSString*   noAccess	= [NSString stringWithFormat:LocalizedString(@"keyCantCompileNoAccess"), path];
			if (hasTo) {
				noAccess			= [NSString stringWithFormat:@"%@ %@", hasTo, noAccess];
			}
			NSBeginAlertSheet(LocalizedString(@"keyCantCompile"), nil, nil, nil,
							[[self mainView] window], nil, nil, nil, nil, 
							noAccess);

			[self addDictionary:dict completedForUserWithSuccess:NO];
			
			return;
		}
			
		// check if there is enough space (10 times more than the size of all cwl files)	
			
		if (err < 0) {
			NSString*   noSpace		= [NSString stringWithFormat:LocalizedString(@"keyCantCompileNoSpace"), path, (-err)];
			if (hasTo) {
				noSpace				= [NSString stringWithFormat:@"%@ %@", hasTo, noSpace];
			}
			NSBeginAlertSheet(LocalizedString(@"keyCantCompile"), nil, nil, nil,
							[[self mainView] window], nil, nil, nil, nil, 
							noSpace);

			[self addDictionary:dict completedForUserWithSuccess:NO];

			return;
		}

	}
	
	// start the thread
		
	if (!mConnection) {
		NSPort*			port1 = [NSPort port];
		NSPort*			port2 = [NSPort port];
		
		mConnection = [[NSConnection alloc] initWithReceivePort:port1 sendPort:port2];
		[mConnection setRootObject:self];
	}

	/* Ports switched here. */
	dataArray = [NSArray arrayWithObjects:[mConnection sendPort], 
					[mConnection receivePort], dict, appBundle, nil];
		
	[NSThread detachNewThreadSelector:@selector(compileDictionary:)
		toTarget:	self 
		withObject:	dataArray];
}


// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)addDirectoryOpenPanelDidEnd:(NSOpenPanel*)sheet returnCode:(int)returnCode contextInfo:(void*)contextInfo
{
	NSString*		dirPath = nil;
	NSBundle*		appBundle;
	NSArray*		dictFiles;

	if ( (returnCode != NSCancelButton) && ([[sheet filenames] count] > 0) ) {
		dirPath = [[sheet filenames] objectAtIndex:0];
	}
	
	[sheet close];
	[sheet setAccessoryView:nil];
	
	if (!dirPath)
		return;
		
	appBundle 	= [NSBundle bundleForClass:[self class]];
	dictFiles   = [LanguageDesc allLanguageFilesFromPath:dirPath];
	
	if ([dictFiles count] > 0) {	
		[self addDictionary:[LanguageDesc languageDescWithDictionaryFile:[dictFiles objectAtIndex:0]] withBundle:appBundle];
	}
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (IBAction)addDictionary:(id)sender
{
	NSOpenPanel*	panel 		= [NSOpenPanel openPanel];
	
	[panel setCanChooseDirectories:YES];
	[panel setCanChooseFiles:YES];
	[panel setResolvesAliases:YES];
	[panel setPrompt:LocalizedString(@"keyAddDictButton")];
									
	[panel setAccessoryView:mOpenPanelAuxView];
	[mOpenPanelAuxViewMessage setStringValue:LocalizedString(@"keyAddDictTitle")];

	[panel beginSheetForDirectory:nil //[@"~" stringByStandardizingPath]
			file:			nil 
			types:			[NSArray arrayWithObject:@"dictionary"] 
			modalForWindow:	[[self mainView] window]
			modalDelegate:	self 
			didEndSelector:	@selector(addDirectoryOpenPanelDidEnd:returnCode:contextInfo:)
			contextInfo:	nil];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)editorRestoreValues:(NSDictionary*)dict
{
	unsigned		idx;
	NSArray*		filters;
	int				accentsValue = 0;

	if ([dict integerForKey:kIgnoreAccents])
		accentsValue = kIgnoreAccentsID;
	else if ([dict integerForKey:kStripAccents])
		accentsValue = kStripAccentsID;

	[mAccentsMode 		selectItemAtIndex:accentsValue];
	
	[mIgnoreCase 		setIntValue:[dict integerForKey:kIgnoreCase]];
	[mRunTogether 		setIntValue:[dict integerForKey:kRunTogether]];
	[mRunTogetherLimit 	setIntValue:[dict integerForKey:kRunTogetherLimit]];
	[mRunTogetherMin 	setIntValue:[dict integerForKey:kRunTogetherMin]];
	
	filters = [dict objectForKey:kFilter];
		
	[mFilterURL 		setIntValue:(([filters indexOfObject:kURL] 	 == NSNotFound) ? 0 : 1)];
	[mFilterEmail 		setIntValue:(([filters indexOfObject:kEmail] == NSNotFound) ? 0 : 1)];
	[mFilterTex 		setIntValue:(([filters indexOfObject:kTeX] 	 == NSNotFound) ? 0 : 1)];
	[mFilterSgml 		setIntValue:(([filters indexOfObject:kSgml]  == NSNotFound) ? 0 : 1)];
	
	idx = [kSuggestionModeValues indexOfObject:[dict objectForKey:kSuggestionMode]];

	if (idx == NSNotFound)
		idx = 0;
	[mSuggestionMode selectItemAtIndex:idx];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)editorLoadDictionaryWithID:(Dictionary*)row
{
	BOOL			goodRow 	= (row != NULL);
	BOOL			enabledRow	= goodRow && [row isEnabled];
	BOOL			enabledRT;
		
	if (goodRow) {
		NSString*		name	= [row identifier];
		NSDictionary*	dict	= [[Preferences sharedInstance] preferencesForLanguage:name];

		[self editorRestoreValues:dict];
	}
	
	enabledRT = ((enabledRow && [mRunTogether intValue]) ? YES : NO);

	[mAccentsMode			setEnabled:enabledRow];
	[mAccentsModeLabel		setEnabled:enabledRow];
	[mIgnoreCase			setEnabled:enabledRow];
	[mRunTogether			setEnabled:enabledRow];
	[mSuggestionMode		setEnabled:enabledRow];
	[mSuggestionModeLabel	setEnabled:enabledRow];
	[mFiltersLabel			setEnabled:enabledRow];
	[mFilterURL				setEnabled:enabledRow];
	[mFilterEmail			setEnabled:enabledRow];
	[mFilterTex				setEnabled:enabledRow];
	[mFilterSgml			setEnabled:enabledRow];
	[mRunTogetherLimit		setEnabled:enabledRT];
	[mRunTogetherMin		setEnabled:enabledRT];
	[mInfoButton			setEnabled:goodRow];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (NSDictionary*)editorCollectValues
{
	NSDictionary*	dict;
	int				idx;
	NSMutableArray*	filters;
	int				ignoreAccentsValue 	= 0;
	int				stripAccentsValue	= 0;
	NSString*		suggMode;

	idx		= [mSuggestionMode indexOfSelectedItem];

	if ( (idx < 0) || (idx >= [kSuggestionModeValues count]))
		idx = 2;

	suggMode = [kSuggestionModeValues objectAtIndex:idx];

	filters = [NSMutableArray array];
	if ([mFilterURL 	intValue])	[filters addObject:kURL];
	if ([mFilterEmail 	intValue])	[filters addObject:kEmail];
	if ([mFilterTex 	intValue])	[filters addObject:kTeX];
	if ([mFilterSgml 	intValue])	[filters addObject:kSgml];
		
	idx		= [mAccentsMode indexOfSelectedItem];
	if (idx == kIgnoreAccentsID)
		ignoreAccentsValue	= 1;
	else if (idx == kStripAccentsID)
		stripAccentsValue	= 1;
		
	dict 	= [NSDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithInt:ignoreAccentsValue], 			kIgnoreAccents,
				[NSNumber numberWithInt:[mIgnoreCase 		intValue]], kIgnoreCase,
				[NSNumber numberWithInt:[mRunTogether 		intValue]], kRunTogether,
				[NSNumber numberWithInt:stripAccentsValue], 			kStripAccents,
				suggMode, 												kSuggestionMode,
				[NSNumber numberWithInt:[mRunTogetherLimit 	intValue]], kRunTogetherLimit,
				[NSNumber numberWithInt:[mRunTogetherMin 	intValue]], kRunTogetherMin,
				filters,												kFilter,
				nil];

	return dict;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)editorSaveDictionaryWithID:(Dictionary*)row
{
	if (row) {
		NSString*		name	= [row identifier];
		NSDictionary*	dict	= [self editorCollectValues];
	
		[[Preferences sharedInstance] setPreferences:dict forLanguage:name];
		[[Preferences sharedInstance] write];
	}
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (IBAction)saveEditArea:(id)sender
{
	[self editorSaveDictionaryWithID:[self selectedDictionary]];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (IBAction)loadEditArea:(id)sender
{
	[self editorLoadDictionaryWithID:[self selectedDictionary]];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------


- (BOOL)textView:(NSTextView *)textView clickedOnLink:(id)link atIndex:(unsigned)charIndex
{
	NSURL*	linkURL = [NSURL URLWithString:link];

	if (!linkURL)
		return NO;
		
	return [[NSWorkspace sharedWorkspace] openURL:linkURL];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)loadFilterOptions
{
	//	TeXCommands will load automatically
	NSArray*			emailQuoteCharacters;
	
	[mCheckTexComments 	setIntValue:[[Preferences sharedInstance] integerForKey:kKeyCheckTexComments]];
	[mEmailMargin 		setIntValue:[[Preferences sharedInstance] integerForKey:kKeyEmailMargin]];
	emailQuoteCharacters	= [[Preferences sharedInstance] objectForKey:kKeyEmailQuote];
	if (emailQuoteCharacters == nil) {
		[mEmailQuote		setStringValue:@""];
	} else {
		[mEmailQuote		setStringValue:[emailQuoteCharacters componentsJoinedByString:@","]];
	}
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void) mainViewDidLoad
{	
	BOOL			hasMake		= YES; // since 1.4.1 we have it [[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/make"];
	
	NSString*		versionStr	= [[NSBundle bundleForClass:[self class]]
										objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
	versionStr					= [NSString stringWithFormat:LocalizedString(@"keyCreditsVersion"), versionStr];

	NSData*			creditsData	= [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"credits" ofType:@"html"]];

//	NSURL*			creditsURL 	= [NSURL fileURLWithPath:
//		[[NSBundle bundleForClass:[self class]] pathForResource:@"credits" ofType:@"html"]];

	NSString*		creditsStr	= [[[NSString alloc] initWithData:creditsData encoding:NSUTF8StringEncoding] autorelease];

//	NSLog(@"%@", [mCredits class]);
	
	creditsStr					= [NSString stringWithFormat:creditsStr, versionStr];
	
	NSAttributedString*	text	= [[[NSAttributedString alloc] initWithHTML:[creditsStr dataUsingEncoding:NSUTF8StringEncoding] documentAttributes:nil] autorelease];
	
	NSTextStorage*	creditsText	= [mCredits textStorage];

	[mCredits setDrawsBackground:NO];
	[[mCredits enclosingScrollView] setDrawsBackground:NO];

	[creditsText beginEditing];	// Bracket with begin/end editing for efficiency
//	[creditsText readFromURL:creditsURL options:nil documentAttributes:nil];	// Read!
	[creditsText setAttributedString:text];	// Read!
	[creditsText endEditing];

	[mCredits setDrawsBackground:NO];	
    [mCredits setDelegate:self];
	
	kDefaultNoteFrameShown 	= [mNote frame];
	kDefaultNoteFrameHidden	= kDefaultNoteFrameShown;
	kDefaultNoteFrameHidden.origin.x = -10000;
	[mNote setFrame:kDefaultNoteFrameHidden];
	[mNote setNeedsDisplay:YES];

	[[[mTexCommands tableColumnWithIdentifier:kKeyCommandParameters] dataCell]
						setFormatter:[[[TeXParameterFormatter alloc] init] autorelease]];
	[[[mTexCommands tableColumnWithIdentifier:kKeyCommandName] dataCell]
						setFormatter:[[[TeXCommandFormatter alloc] init] autorelease]];

	[self reloadDictionarySet];
	
	[self setSelectedDictionary:[[self allLanguages] objectAtIndex:0]];
	[self loadEditArea:self];

	[self loadFilterOptions];
	
	[mAddDictionary setEnabled:hasMake];
	[mAddDictionaryMessage setStringValue:(hasMake ? 
		LocalizedString(@"keyAddDictMessageEnabled") : 
		LocalizedString(@"keyAddDictMessageDisabled"))];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (IBAction)toggleDictionaryStatus:(id)sender
{
	Dictionary*		dict	= [self selectedDictionary];
	if (dict) {
		BOOL		newValue		= ![dict isEnabled];
		NSBundle*   bndl			= [NSBundle bundleForClass:[self class]];

		if (newValue) {
			//  check wether the dictionary is compiled. 
			if (![dict isCompiled]) {
				[self addDictionary:dict withBundle:bndl];
				return;
			}
		}
		
		[dict setEnabled:newValue];
		[self editorLoadDictionaryWithID:dict];
		[LanguageDesc setUserLanguageNames:[self enabledNames] withServerBundle:bndl];
		[self killService];
	}
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (IBAction)runTogetherChanged:(id)sender
{
	BOOL	enabled = ([mRunTogether intValue] ? YES : NO);

	[mRunTogetherLimit	setEnabled:enabled];
	[mRunTogetherMin	setEnabled:enabled];
	
	[self saveEditArea:sender];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (NSMutableArray*)texCommands
{
	return [[Preferences sharedInstance] mutableTexCommands];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)saveTexCommands
{
	[[Preferences sharedInstance] write];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (int)reorderTexCommands:(int)newItemIndex
{
	NSDictionary*	obj = [[self texCommands] objectAtIndex:newItemIndex];
	[[self texCommands] sortUsingFunction:&compareTeXCommands context:nil];
	return [[self texCommands] indexOfObjectIdenticalTo:obj];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (int)getIndexOfTexCommand:(NSString*)inName
{
	NSArray*	comds 	= [self texCommands];
	unsigned	i, n	= [comds count];
	
	for(i = 0; i < n; ++i) {
		if ([inName isEqualToString:[[comds objectAtIndex:i] objectForKey:kKeyCommandName]])
			return i;
	}
	return -1;
}


// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (NSString*)getUniqueTexCommandName
{
	NSString*	name 		= @"aTeXCommand";
	unsigned	i;
	
	if ([self getIndexOfTexCommand:name] < 0)
		return name;
		
	for(i = 1; i < 1000; ++i) {
	
		name = [NSString stringWithFormat:@"aTeXCommand%03d", i];
		
		if ([self getIndexOfTexCommand:name] < 0)
			return name;		
	}
	return name;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [[self texCommands] count];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)rowIndex
{
	return [[[self texCommands] objectAtIndex:rowIndex] objectForKey:[tableColumn identifier]];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)tableColumn row:(int)rowIndex
{
	NSMutableDictionary*	com = [NSMutableDictionary 
								dictionaryWithDictionary:[[self texCommands] objectAtIndex:rowIndex]];
	
	[com setObject:anObject forKey:[tableColumn identifier]];	
	[[self texCommands] replaceObjectAtIndex:rowIndex withObject:com];

	if (rowIndex >= 0) {
		int	newRow	= [self reorderTexCommands:rowIndex];
		if (newRow != rowIndex) {
			[mTexCommands scrollRowToVisible:newRow];
			[mTexCommands selectRow:newRow byExtendingSelection:NO];
			[mTexCommands editColumn:0 row:newRow withEvent:nil select:YES];
		}
	}

	[self saveTexCommands];

	[mTexCommands reloadData];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (BOOL)control:(NSControl *)control didFailToFormatString:(NSString *)string errorDescription:(NSString *)error
{
	NSBeginAlertSheet(nil, nil, nil, nil, [[self mainView] window], self, nil, nil, nil, error);
	return NO;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    return YES;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
	NSString*	text = [fieldEditor string];
	
	if ([mTexCommands editedColumn] == 0) {
		
		int	n = [self getIndexOfTexCommand:text];
		if ((n >= 0) && (n != [mTexCommands editedRow])) {
			NSString*	error 		= LocalizedString(@"keyErrorExistsTexCommand");
			NSBeginAlertSheet(nil, nil, nil, nil, [[self mainView] window], self, nil, nil, nil, error, text);
			return NO;
		}
		
		return YES;
		
	} else if ([mTexCommands editedColumn] == 1) {
	
		return YES;
		
	}
	
	return NO;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	[mRemoveTexCommand setEnabled:([mTexCommands selectedRow] != -1)];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (IBAction)addTexCommand:(id)sender
{
	int			row = [mTexCommands selectedRow];
	NSString*	newName;
	
	if (row == -1) {

		row = [[self texCommands] count];

	} else {
			
		if ([mTexCommands editedRow] != -1) {
	
			if (![mTexCommands textShouldEndEditing:[mTexCommands currentEditor]])
				return;
				
			[[mTexCommands window] endEditingFor:mTexCommands];
		}

	}
	
	newName = [self getUniqueTexCommandName];
	
	[[self texCommands] insertObject:[NSDictionary 
		dictionaryWithObjectsAndKeys:
			newName, kKeyCommandName,
			[NSArray array], kKeyCommandParameters,
			nil] 
		atIndex:row];
	
	[mTexCommands reloadData];
	[mTexCommands scrollRowToVisible:row];
	[mTexCommands selectRow:row byExtendingSelection:NO];

	[mTexCommands editColumn:0 row:row withEvent:nil select:YES];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (IBAction)removeTexCommand:(id)sender
{
	NSArray*	rows 	= [[mTexCommands selectedRowEnumerator] allObjects];
	unsigned	i, n	= [rows count];
	unsigned*	indices	= (unsigned*)malloc(sizeof(unsigned)*n);

	for(i = 0; i < n; ++i) {
		indices[i] = [[rows objectAtIndex:i] unsignedIntValue];
	}
	
	[mTexCommands abortEditing];
	[[self texCommands] removeObjectsFromIndices:indices numIndices:n];
	free(indices);

	[mTexCommands deselectAll:nil];
	[mTexCommands reloadData];	
	[self saveTexCommands];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (IBAction)toggleCheckTexComments:(id)sender
{
	[[Preferences sharedInstance] setInteger:[mCheckTexComments intValue] forKey:kKeyCheckTexComments];
	[[Preferences sharedInstance] write];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (IBAction)emailOptionsChanged:(id)sender
{
	[[Preferences sharedInstance] setInteger:[mEmailMargin intValue] forKey:kKeyEmailMargin];
	[[Preferences sharedInstance] setObject:[[mEmailQuote stringValue] 
									componentsSeparatedByString:@","] forKey:kKeyEmailQuote];
	[[Preferences sharedInstance] write];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (IBAction)showDictionaryInfo:(id)sender
{
	Dictionary*		curDict = [self selectedDictionary];
	if (curDict) {
		NSString*		data 	= [curDict info];
		if (data) {
			[mInfoText setString:data];
		} else {
			[mInfoText setString:LocalizedString(@"keyNoDictInfo")];
		}
		
		[mInfoLanguage setStringValue:[curDict displayName]];
		
		[mInfoWindow setDefaultButtonCell:[mInfoDoneButton cell]];
		
		[NSApp beginSheet:mInfoWindow modalForWindow:[[self mainView] window] 
			modalDelegate:nil didEndSelector:nil contextInfo:nil];
	}
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (IBAction)hideDictionaryInfo:(id)sender
{
	[NSApp endSheet:mInfoWindow];
	[mInfoWindow orderOut:nil];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (IBAction)addDictionaryDone:(id)sender
{
	[NSApp endSheet:mProgressWindow];
	[mProgressWindow orderOut:nil];
	[mAddDictionary setEnabled:YES];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (BOOL)isServiceRunning
{
	ProcessInfo*	p;
	ProcessIterator*	i   = [ProcessIterator iterator];
	while ([i hasNext]) {
		p   = [i next];
//		NSLog(@"%@ %@", [p processName], [[p processBundle] bundleIdentifier]);
//		if ([[[p processBundle] bundleIdentifier] isEqualToString:kServiceBundleIdentifier]) 
		if ([@"cocoAspell" isEqualTo:[p processName]])
			return YES;
	}
	return NO;
}


@end



