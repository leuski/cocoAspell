// ================================================================================
//  CAPPTable.h
// ================================================================================
//	cocoaspell
//
//  Created by Anton Leuski on Mon Nov 12 2001.
//  Copyright (c) 2001 Anton Leuski. All rights reserved.
//
// ================================================================================

#import "CAPPBase.h"


@interface CAPPTable : CAPPBase 
{
	IBOutlet NSTextField*	mDictionaryName;
	IBOutlet NSTableView*	mDictionaryTable;
}

- (void)mainViewDidLoad;

- (IBAction)dictionaryCellClicked:(id)sender;

- (void)editorLoadDictionaryWithID:(int)row;

- (int)selectedDictionary;
- (void)setSelectedDictionary:(int)value;
- (void)reloadDictionarySet;

- (NSString*)mainNibName;

@end
