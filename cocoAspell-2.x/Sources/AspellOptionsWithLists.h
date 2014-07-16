// ============================================================================
//  AspellOptionsWithLists.h
// ============================================================================
//
//	cocoAspell2
//
//  Created by Anton Leuski on 2/13/05.
//  Copyright (c) 2005-2008 Anton Leuski. All rights reserved.
// ============================================================================

#import "AspellOptions.h"


@interface AspellOptionsWithLists : AspellOptions
@property(nonatomic, strong) NSMutableDictionary* listCaches;
@end
