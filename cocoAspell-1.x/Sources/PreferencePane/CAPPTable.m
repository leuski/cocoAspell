// ================================================================================
//  CAPPTable.m
// ================================================================================
//	cocoaspell
//
//  Created by Anton Leuski on Mon Nov 12 2001.
//  Copyright (c) 2001 Anton Leuski. All rights reserved.
//
// ================================================================================

#import "CAPPTable.h"

@implementation CAPPTable

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (int)selectedDictionary
{
	return [mDictionaryTable selectedRow];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)setSelectedDictionary:(int)value
{
	[mDictionaryTable selectRow:value byExtendingSelection:NO];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)reloadDictionarySet
{
	[mDictionaryTable reloadData];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [[self allLanguageNames] count];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (NSString *)mainNibName
{
	return @"CAPPTable";
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (id)tableView:(NSTableView *)aTableView 
	objectValueForTableColumn:(NSTableColumn *)aTableColumn 
	row:(int)rowIndex
{
	NSParameterAssert(rowIndex >= 0 && rowIndex < [[self allLanguageNames] count]);
	if ([[aTableColumn identifier] isEqualToString:@"Dictionary"])
		return [[self allLanguageNames] objectAtIndex:rowIndex];
	if ([[aTableColumn identifier] isEqualToString:@"On"])
		return [[self allOnStates] objectAtIndex:rowIndex];
	return nil;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)editorLoadDictionaryWithID:(int)row
{
	BOOL		goodRow = ((row >= 0) && (row < [[self allLanguageNames] count]));
	NSString*	name;
	if (goodRow) {
		name = [[self allLanguageNames] objectAtIndex:row];
	} else {
		name = [[NSBundle bundleForClass:[self class]] 
					localizedStringForKey:@"keyDictionaryNone" value:@"none" table:nil];
	}
	[mDictionaryName setStringValue:name];
	
	[super editorLoadDictionaryWithID:row];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void) mainViewDidLoad
{
	NSTableColumn*	onCol 	= [mDictionaryTable tableColumnWithIdentifier:@"On"];
	NSButtonCell*	onCell	= [[NSButtonCell alloc] initTextCell:@""];

	[onCell setButtonType:NSSwitchButton];
	[onCol setDataCell:[onCell autorelease]];

	[super mainViewDidLoad];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (IBAction)dictionaryCellClicked:(id)sender
{
	int		col = [mDictionaryTable clickedColumn];
	
	if (col != [mDictionaryTable columnWithIdentifier:@"On"])
		return;
		
	[self toggleDictionaryStatus:sender];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	[self loadEditArea:self];
}

@end



