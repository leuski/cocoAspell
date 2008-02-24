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

@interface MutableAspellList : NSObject {
	AspellOptions*		options;
	NSString*			key;
	NSMutableArray*		objects;
	Class				controllerClass;
}

- (id)initWithAspellOptions:(AspellOptions*)inOptions key:(NSString*)inKey controllerClass:(Class)inControllerClass;

- (AspellOptions *)options;

- (NSString *)key;
- (NSString *)dataKey;

- (unsigned int)countOfObjects;
- (id)objectInObjectsAtIndex:(unsigned int)inIndex;
- (void)insertObject:(id)inObject inObjectsAtIndex:(unsigned int)inIndex;
- (void)removeObjectFromObjectsAtIndex:(unsigned int)inIndex;
- (void)replaceObjectInObjectsAtIndex:(unsigned int)inIndex withObject:(id)inObject;

@end

@protocol AspellListElement
- (id)initWithAspellList:(MutableAspellList*)inList value:(NSString*)inValue;
@end

@interface StringController : NSObject <AspellListElement> {
	NSString*			value;
	MutableAspellList*	array;
}

- (NSString *)value;
- (void)setValue:(NSString *)newValue;

- (MutableAspellList *)array;
- (void)setArray:(MutableAspellList *)newArray;
@end

@interface TeXCommandController : StringController {
}

- (NSString *)command;
- (void)setCommand:(NSString *)newCommand;

- (NSString *)arguments;
- (void)setArguments:(NSString *)newArguments;
@end

