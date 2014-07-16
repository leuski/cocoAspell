// ============================================================================
//  AspellDictionary.h
// ============================================================================
//
//	cocoAspell2
//
//  Created by Anton Leuski on 2/23/08.
//  Copyright (c) 2008 Anton Leuski. All rights reserved.
// ============================================================================

#import <Foundation/Foundation.h>
#import "Dictionary.h"

@interface AspellDictionary : Dictionary

@property (nonatomic, strong)			AspellOptions*			options;
@property (nonatomic, assign, readonly)	AspellSpeller*			speller;

- (id)initWithFilePath:(NSString*)inPath persistent:(BOOL)flag;

@end
