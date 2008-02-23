// ================================================================================
//  Installer.m
// ================================================================================
//	cocoAspell
//
//  Created by Anton Leuski on Sun Mar 17 2002.
//  Copyright (c) 2002 Anton Leuski. All rights reserved.
//		Do not distribute without permission.
//
// ================================================================================

#import "Installer.h"
#import <CoreServices/CoreServices.h>
#import "LanguageUtilities.h"
#include <Security/AuthorizationTags.h>
#include <Security/Authorization.h>

static 	NSString*			kDefaultLanguage 	= @"en";
static	AuthorizationRef	sAuthorizationRef	= nil;

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

static BOOL
canDoPriviligedInstall(
	AuthorizationRef	ioRef,
	BOOL				askUser)
{
	AuthorizationRights	rights;
	AuthorizationFlags 	flags;
	AuthorizationItem	items[1];
	char				toolPath[] 	= "cp";
	OSStatus 			err 		= 0;
	
	items[0].name 			= kAuthorizationRightExecute;
	items[0].value 			= toolPath;
	items[0].valueLength 	= strlen(toolPath);
	items[0].flags 			= 0;
	
	rights.count			= 1;
	rights.items 			= items;
	
	flags = kAuthorizationFlagExtendRights;
	
	if (askUser) {
		flags |= kAuthorizationFlagInteractionAllowed;
	}
	
	err = AuthorizationCopyRights(ioRef, &rights,
								kAuthorizationEmptyEnvironment,
								flags, NULL);
	
	return (errAuthorizationSuccess == err);
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------


@implementation Installer

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (AuthorizationRef)authorization
{
	if (!sAuthorizationRef) {	
		AuthorizationRights	rights;
		AuthorizationFlags 	flags;
		OSStatus 			err 		= 0;
		
		// We just want the user's current authorization environment,
		// so we aren't asking for any additional rights yet.
		
		rights.count	= 0;
		rights.items 	= NULL;
		
		flags	= kAuthorizationFlagDefaults;
		
		err		= AuthorizationCreate(&rights, kAuthorizationEmptyEnvironment, 
								flags, &sAuthorizationRef);
	}
	
	return sAuthorizationRef;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)giveupAuthorization
{
	if (sAuthorizationRef) {
		AuthorizationFree(sAuthorizationRef, kAuthorizationFlagDestroyRights);
		sAuthorizationRef = nil;
	}
	
	if (mLockButton) {
		[mLockButton setState:NSOffState];
	}
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (BOOL)checkAuthorization
{
	BOOL	authorized = canDoPriviligedInstall([self authorization], YES);
	if (mLockButton) {
		[mLockButton setState:(authorized ? NSOnState : NSOffState)];
	}
	return authorized;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (id)init
{
	self = [super initWithWindowNibName:@"Installer" owner:NSApp];
	if (self) {
	}
	return self;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)dealloc
{
	[self giveupAuthorization];
	[super dealloc];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)windowDidLoad
{
	[mUserButton setTitle:[NSString stringWithFormat:[mUserButton title], 
		NSFullUserName()]];
	[mComputerButton setTitle:[NSString stringWithFormat:[mComputerButton title], 
		[[NSHost currentHost] name]]];

	[mComputerButton setEnabled:NO];
	[mNetworkButton setEnabled:NO];
	[mDomainGroup selectCellWithTag:0];
	
	{
		NSString*		prefPanePath 	= [[NSBundle bundleForClass:[self class]] 
							pathForResource:@"Spelling" ofType:@"prefPane"];
		NSBundle*		prefPaneBndl	= [NSBundle bundleWithPath:prefPanePath];
		NSArray*		locs			= [prefPaneBndl localizations];
		unsigned		i;
		
		for(i = 0; i < [locs count]; ++i) {
			NSString*	locName		= [locs objectAtIndex:i];
			NSString*	locLocName	= [LanguageUtilities localizedLanguageName:locName];
			id			theCell;

			if (!locLocName) {
				locLocName = locName;
			}
			
			if (i != 0) {
				[mLocalizationTable addRow];
			}
			
			theCell = [mLocalizationTable cellAtRow:i column:0];
			[theCell setTitle:locLocName];

			if ([kDefaultLanguage isEqualToString:locName]) {
				[theCell setState:NSOnState];
				[theCell setEnabled:NO];
			} else {
				[theCell setState:NSOffState];
				[theCell setEnabled:YES];
			}
		}
		[mLocalizationTable sizeToCells];
		[mLocalizationTable setNeedsDisplay];
	}
	
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[self windowDidLoad];
	[self showWindow:self];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (IBAction)install:(id)sender
{
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (IBAction)toggleLock:(id)sender
{
	int	state = [mLockButton state];

	if (state == NSOffState) {
		[self giveupAuthorization];
		
	} else {
		if (![self checkAuthorization])
			state = NSOffState;
	}
	
	[mComputerButton setEnabled:(state == NSOnState)];
	[mNetworkButton setEnabled:(state == NSOnState)];
	if (state == NSOffState) {
		[mDomainGroup selectCellWithTag:0];
	}
}


@end
