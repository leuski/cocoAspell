// ============================================================================
//  DictionaryDescription.h
// ============================================================================
//
//	cocoAspell2
//
//  Created by Anton Leuski on 4/30/05.
//  Copyright (c) 2005 Anton Leuski. All rights reserved.
// ============================================================================

#import <Foundation/Foundation.h>

@interface DictionaryDescription : NSObject {
}

- (NSString*)version;
- (NSString*)module;
- (NSString*)langCode;
- (NSString*)fileNameNoExtension;
- (NSComparisonResult)compare:(DictionaryDescription*)arg;

@end