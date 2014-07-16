// ================================================================================
//  Spelling.h
// ================================================================================
//  cocoAspell2
//
//  Created by Anton Leuski on 2/2/05.
//  Copyright (c) 2005-2008 Anton Leuski.
//
// ================================================================================

#import <PreferencePanes/PreferencePanes.h>

@class NSTextViewWithLinks;
@class DictionaryManager;

@interface Spelling : NSPreferencePane 

- (void)mainViewDidLoad;


@property (nonatomic, strong)	IBOutlet NSWindow*				mProgressPanel;
@property (nonatomic, strong)	IBOutlet NSWindow*				mCopyrightPanel;
@property (nonatomic, strong)	IBOutlet NSWindow*				mAlertPanel;
@property (nonatomic, strong)	IBOutlet NSWindow*				mRegistrationPanel;

@property (nonatomic, strong)	IBOutlet NSTextField*			mProgressTitle;
@property (nonatomic, strong)	IBOutlet NSProgressIndicator*	mProgressBar;
@property (nonatomic, strong)	IBOutlet NSTabView*				mTabView;
@property (nonatomic, strong)	IBOutlet NSTextViewWithLinks*	mCreditsView;
@property (nonatomic, strong)	IBOutlet NSTextField*			mAlertTitle;
@property (nonatomic, strong)	IBOutlet NSTextField*			mAlertMessage;

@property (nonatomic, assign)	BOOL							compiling;
@property (nonatomic, strong)	DictionaryManager*				dictionaryManager;

@property (nonatomic, strong, readonly)	NSString*						version;

@end
