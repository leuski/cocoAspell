// ================================================================================
//  CAPPMenu.m
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

#import "CAPPMenu.h"
#import "LanguageDesc.h"

static SEL			kMenuAction	= nil;

@implementation CAPPMenu

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (Dictionary*)selectedDictionary
{
	return [[mDictionaryMenu selectedItem] representedObject];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)setSelectedDictionary:(Dictionary*)value
{
	unsigned	i, n = [mDictionaryMenu numberOfItems];
	for(i = 0; i < n; ++i) {
		Dictionary* d   = [[mDictionaryMenu itemAtIndex:i] representedObject];
		if (d == value)
			[mDictionaryMenu selectItemAtIndex:i];
	}
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)updateMenuStatus
{
	unsigned	i, n = [mDictionaryMenu numberOfItems];
	for(i = 0; i < n; ++i) {
		Dictionary* d   = [[mDictionaryMenu itemAtIndex:i] representedObject];
		[[mDictionaryMenu itemAtIndex:i] setState:([d isEnabled] ? NSMixedState : NSOffState)];
	}
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void) mainViewDidLoad
{
	kMenuAction	= @selector(loadEditArea:);
	[super mainViewDidLoad];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	if ([menuItem action] == kMenuAction) {
		Dictionary* d			= (Dictionary*)[menuItem representedObject];
		BOOL		enabled 	= [d isEnabled];
		BOOL		selected	= (d == [self selectedDictionary]);
		if (selected) {
			[menuItem setState:NSOnState];
		} else if (enabled) {
			[menuItem setState:NSMixedState];
		} else {
			[menuItem setState:NSOffState];
		}
		return YES;
	}
	return YES; //[super validateMenuItem:menuItem];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)reloadDictionarySet
{
	NSArray*	langs = [self allLanguages];
	
	[mDictionaryMenu removeAllItems];

	if ([langs count] > 0) {
		unsigned	i, n = [langs count];
		for(i = 0; i < n; ++i) {
			Dictionary*			d   = [langs objectAtIndex:i];
			
			[mDictionaryMenu addItemWithTitle:[d displayName]];
			[[mDictionaryMenu lastItem] setRepresentedObject:d];			
			[[mDictionaryMenu lastItem] setEnabled:YES];
		}
		[self updateMenuStatus];
	} else {
		[mDictionaryMenu addItemWithTitle:[[NSBundle bundleForClass:[self class]] 
					localizedStringForKey:@"keyDictionaryNone" value:@"none" table:nil]];
		[[mDictionaryMenu itemAtIndex:0] setEnabled:NO];
	}	
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (NSString *)mainNibName
{
	return @"CAPPMenu";
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)updateDictionaryControls:(Dictionary*)row
{
	BOOL		goodRow = (row != nil);
	
	[mDictionaryMenu 	setEnabled:goodRow];
	[mDictionaryEnabled	setEnabled:goodRow];
	
	if (goodRow)
		[mDictionaryEnabled	setIntValue:([row isEnabled] ? 1 : 0)];
	else
		[mDictionaryEnabled	setIntValue:0];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)editorLoadDictionaryWithID:(Dictionary*)row
{
	[self updateDictionaryControls:row];
	[super editorLoadDictionaryWithID:row];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (IBAction)toggleDictionaryStatus:(id)sender
{
	[super toggleDictionaryStatus:sender];
//	[self updateDictionaryControls:[self selectedDictionary]];
	[self updateMenuStatus];
}

@end



