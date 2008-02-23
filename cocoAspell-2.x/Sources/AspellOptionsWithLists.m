// ============================================================================
//  AspellOptionsWithLists.m
// ============================================================================
//
//	cocoAspell2
//
//  Created by Anton Leuski on 2/13/05.
//  Copyright (c) 2005 Anton Leuski. All rights reserved.
// ============================================================================

#import "AspellOptionsWithLists.h"
#import "MutableAspellList.h"

@interface AspellOptionsWithLists (MutableLists)
- (MutableAspellList*)mutableListForKey:(NSString*)inKey;
@end


@implementation AspellOptionsWithLists

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (id)initWithAspellConfigNoCopy:(AspellConfig*)inConfig
{
	if (self = [super initWithAspellConfigNoCopy:inConfig]) {
		[self setListCaches:[NSMutableDictionary dictionary]];
	}
	return self;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)dealloc
{
	[self setListCaches:nil];
	[super dealloc];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSMutableDictionary *)listCaches
{
	return [[listCaches retain] autorelease];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setListCaches:(NSMutableDictionary *)newListCaches
{
    if (listCaches != newListCaches) {
		[listCaches release];
		listCaches = [newListCaches retain];
    }
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (id)valueForKey:(NSString*)inKey
{
	if ([inKey hasPrefix:kMutableListPrefix]) {
		return [self mutableListForKey:inKey];
	} else {
		return [super valueForKey:inKey];
	}
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (MutableAspellList*)mutableListForKey:(NSString*)inKey
{
	MutableAspellList*	list	= [[self listCaches] objectForKey:inKey];
	if (!list) {
		Class	cc	= [StringController class];
		if ([inKey isEqualToString:[kMutableListPrefix stringByAppendingString:@"f_tex_command"]]) {
			cc	= [TeXCommandController class];
		}
		
		list	= [[[MutableAspellList alloc] 
					initWithAspellOptions:self 
					key:inKey 
					controllerClass:cc] autorelease];
		[[self listCaches] setObject:list forKey:inKey];
	}
	return list;
}

@end
