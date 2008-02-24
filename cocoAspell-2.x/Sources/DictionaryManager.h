// ============================================================================
//  DictionaryManager.h
// ============================================================================
//
//	cocoAspell2
//
//  Created by Anton Leuski on 2/12/05.
//  Copyright (c) 2005-2008 Anton Leuski. All rights reserved.
// ============================================================================

#import <Foundation/Foundation.h>

@class AspellOptions;

extern NSString*	kAspellDictionarySetChangedNotification;
extern NSString*	kMultilingualDictionaryName;

@interface DictionaryManager : NSObject {
	NSArray*						_dictionaries;
	AspellOptions*					_filters;
	BOOL							_persistent;
}

@property(retain)	NSArray*		dictionaries;
@property(retain)	AspellOptions*	filters;
@property(assign)	BOOL			persistent;

- (id)init;
- (id)initPersistent:(BOOL)inPersistent;

- (AspellOptions*)createFilterOptionsWithClass:(Class)inClass;

- (BOOL)compileDictionaryAt:(NSString*)dictionaryPath error:(NSString**)errorMessage;
- (BOOL)canCompileDictionaryAt:(NSString*)dictionaryPath error:(NSString**)errorMessage;

- (NSArray*)allDictionaries;
- (NSArray*)enabledDictionaries;
- (NSArray*)allUncompiledDictionaryDirectories;

- (void)removeServiceBundle;

@end
