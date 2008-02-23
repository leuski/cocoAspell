// ================================================================================
//  CAPPBase.h
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

#import <PreferencePanes/PreferencePanes.h>
#import "Preferences.h"
#import "Dictionary.h"

@interface CAPPBase : NSPreferencePane <CompileProgress>
{
	NSString*						mApplPath;
	NSArray*						mLanguages;
	NSConnection*					mConnection;
	
	IBOutlet NSPopUpButton*			mAccentsMode;
	IBOutlet NSTextField*			mAccentsModeLabel;
	IBOutlet NSButton*				mAddDictionary;
	IBOutlet NSTextField*			mAddDictionaryMessage;
	IBOutlet NSButton*				mAddTexCommand;
	IBOutlet NSButton*				mCheckTexComments;
	IBOutlet NSTextView*			mCredits;
	IBOutlet NSFormCell*			mEmailMargin;
	IBOutlet NSFormCell*			mEmailQuote;
	IBOutlet NSTextField*			mFiltersLabel;
	IBOutlet NSButtonCell*			mFilterEmail;
	IBOutlet NSButtonCell*			mFilterSgml;
	IBOutlet NSButtonCell*			mFilterTex;
	IBOutlet NSButtonCell*			mFilterURL;
	IBOutlet NSButton*				mIgnoreCase;
	IBOutlet NSButton*				mInfoButton;
	IBOutlet NSButton*				mInfoDoneButton;
	IBOutlet NSTextField*			mInfoLanguage;
	IBOutlet NSTextView*			mInfoText;
	IBOutlet NSPanel*				mInfoWindow;
	IBOutlet NSBox*					mNote;
	IBOutlet NSView*				mOpenPanelAuxView;
	IBOutlet NSTextField*			mOpenPanelAuxViewMessage;
	IBOutlet NSProgressIndicator*	mProgressBar;
	IBOutlet NSButton*				mProgressDoneButton;
	IBOutlet NSTextField*			mProgressMessage;
	IBOutlet NSPanel*				mProgressWindow;
	IBOutlet NSButton*				mRemoveTexCommand;
	IBOutlet NSButton*				mRunTogether;
	IBOutlet NSFormCell*			mRunTogetherLimit;
	IBOutlet NSFormCell*			mRunTogetherMin;
	IBOutlet NSPopUpButton*			mSuggestionMode;
	IBOutlet NSTextField*			mSuggestionModeLabel;
	IBOutlet NSTableView*			mTexCommands;
}

- (id)initWithBundle:(NSBundle *)bundle;
- (void)mainViewDidLoad;

- (NSArray*)allLanguages;
- (NSArray*)enabledNames;

- (IBAction)addDictionary:(id)sender;
- (IBAction)addDictionaryDone:(id)sender;
- (IBAction)addTexCommand:(id)sender;
- (IBAction)emailOptionsChanged:(id)sender;
- (IBAction)hideDictionaryInfo:(id)sender;
- (IBAction)loadEditArea:(id)sender;
- (IBAction)removeTexCommand:(id)sender;
- (IBAction)runTogetherChanged:(id)sender;
- (IBAction)saveEditArea:(id)sender;
- (IBAction)showDictionaryInfo:(id)sender;
- (IBAction)toggleCheckTexComments:(id)sender;
- (IBAction)toggleDictionaryStatus:(id)sender;

- (void)editorLoadDictionaryWithID:(Dictionary*)row;
- (void)editorSaveDictionaryWithID:(Dictionary*)row;

- (Dictionary*)selectedDictionary;
- (void)setSelectedDictionary:(Dictionary*)value;
- (void)reloadDictionarySet;

- (NSMutableArray*)texCommands;

@end
