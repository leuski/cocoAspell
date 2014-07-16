// ============================================================================
//  MutableAspellList.h
// ============================================================================
//
//	cocoAspell2
//
//  Created by Anton Leuski on 2/6/05.
//  Copyright (c) 2005-2008 Anton Leuski. All rights reserved.
// ============================================================================

#import <Foundation/Foundation.h>

extern NSString*	kMutableListPrefix;

@class AspellOptions;

@class StringController;

@interface MutableAspellList : NSObject
@property (nonatomic, strong, readonly)	AspellOptions*		options;
@property (nonatomic, copy, readonly)	NSString*			key;
@property (nonatomic, strong, readonly)	NSMutableArray*		objects;

- (id)initWithAspellOptions:(AspellOptions*)inOptions key:(NSString*)inKey controllerClass:(Class)inControllerClass;

- (AspellOptions *)options;

- (NSString *)key;
- (NSString *)dataKey;

- (NSUInteger)countOfObjects;
- (StringController*)objectInObjectsAtIndex:(NSUInteger)inIndex;
- (void)insertObject:(StringController*)inObject inObjectsAtIndex:(NSUInteger)inIndex;
- (void)removeObjectFromObjectsAtIndex:(NSUInteger)inIndex;
- (void)replaceObjectInObjectsAtIndex:(NSUInteger)inIndex withObject:(StringController*)inObject;

@end

@protocol AspellListElement
- (id)initWithAspellList:(MutableAspellList*)inList value:(NSString*)inValue;
@end

@interface StringController : NSObject <AspellListElement>
@property (nonatomic, strong) NSString* value;
@property (nonatomic, weak) MutableAspellList* array;
@end

@interface TeXCommandController : StringController
@property (nonatomic, strong) NSString* command;
@property (nonatomic, strong) NSString* arguments;
@end

