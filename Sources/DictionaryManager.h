// ============================================================================
//  DictionaryManager.h
// ============================================================================
//
//	cocoAspell2
//
//  Created by Anton Leuski on 2/12/05.
//  Copyright (c) 2005 Anton Leuski. All rights reserved.
// ============================================================================

#import <Foundation/Foundation.h>

@class AspellOptions;

extern NSString* kAspellDictionarySetChangedNotification;

@interface DictionaryManager : NSObject {
	NSArray*						dictionaries;
	AspellOptions*					filters;
	BOOL							persistent;
}

- (id)init;
- (id)initPersistent:(BOOL)inPersistent;

- (NSArray *)dictionaries;
- (void)setDictionaries:(NSArray *)newDictionaries;

- (AspellOptions*)createFilterOptionsWithClass:(Class)inClass;
- (AspellOptions *)filters;
- (void)setFilters:(AspellOptions *)newFilters;

- (BOOL)compileDictionaryAt:(NSString*)dictionaryPath error:(NSString**)errorMessage;
- (BOOL)canCompileDictionaryAt:(NSString*)dictionaryPath error:(NSString**)errorMessage;

- (NSArray*)allDictionaries;
- (NSArray*)allUncompiledDictionaryDirectories;

- (BOOL)isPersistent;

- (void)removeServiceBundle;

@end
