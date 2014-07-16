#ifdef __multilingual__

// ============================================================================
//  MultilingualDictionary.h
// ============================================================================
//
//	cocoAspell2
//
//  Created by Anton Leuski on 2/23/08.
//  Copyright (c) 2008 Anton Leuski. All rights reserved.
// ============================================================================

#import <Foundation/Foundation.h>
#import "Dictionary.h"

@interface MultilingualDictionary : Dictionary {
	NSArray*	_dictionaries;
}

@property(strong) NSArray*	dictionaries;

- (id)initWithDictionaries:(NSArray*)dicts;

@end

#endif