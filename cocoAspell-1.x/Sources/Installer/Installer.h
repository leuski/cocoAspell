// ================================================================================
//  Installer.h
// ================================================================================
//	cocoAspell
//
//  Created by Anton Leuski on Sun Mar 17 2002.
//  Copyright (c) 2002 Anton Leuski. All rights reserved.
//		Do not distribute without permission.
//
// ================================================================================

#import <Cocoa/Cocoa.h>

@interface Installer : NSWindowController
{
    IBOutlet id mComputerButton;
    IBOutlet id mDomainGroup;
	IBOutlet id mLocalizationTable;
    IBOutlet id mLockButton;
    IBOutlet id mNetworkButton;
    IBOutlet id mUserButton;
}
- (IBAction)install:(id)sender;
- (IBAction)toggleLock:(id)sender;
@end
