// ================================================================================
//  Spelling.h
// ================================================================================
//  cocoAspell2
//
//  Created by Anton Leuski on 2/2/05.
//  Copyright (c) 2002-2005 Anton Leuski.
//
// ================================================================================

#import <PreferencePanes/PreferencePanes.h>

@class NSTextViewWithLinks;
@class DictionaryManager;

@interface Spelling : NSPreferencePane 
{
    IBOutlet NSTextField*			mProgressTitle;
    IBOutlet NSWindow*				mProgressPanel;
    IBOutlet NSWindow*				mCopyrightPanel;
    IBOutlet NSWindow*				mAlertPanel;
    IBOutlet NSWindow*				mRegistrationPanel;
	IBOutlet NSProgressIndicator*	mProgressBar;
	IBOutlet NSTabView*				mTabView;
	IBOutlet NSTextViewWithLinks*	mCreditsView;
	IBOutlet NSTextField*			mAlertTitle;
	IBOutlet NSTextField*			mAlertMessage;
	
	BOOL							compiling;
	DictionaryManager*				dictionaryManager;
	
	BOOL							validRegistration;
	NSString*						registrationName;
	NSString*						registrationNumber;
}

- (void)mainViewDidLoad;

- (BOOL)isCompiling;
- (void)setCompiling:(BOOL)newCompiling;

- (DictionaryManager *)dictionaryManager;
- (void)setDictionaryManager:(DictionaryManager *)newDictionaryManager;

@end
