// ============================================================================
//  Dictionary.m
// ============================================================================
//
//	cocoAspell2
//
//  Created by Anton Leuski on 2/4/05.
//  Copyright (c) 2005-2008 Anton Leuski. All rights reserved.
// ============================================================================

#import "UserDefaults.h"
#import "Dictionary.h"

static NSArray*	kStorableKeys		= nil;

@implementation Dictionary
@synthesize name		= _name;
@synthesize identifier	= _identifier;
@synthesize enabled		= _enabled;

@dynamic readableName;
@dynamic caseSensitive;

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

+ (void)initialize
{
	kStorableKeys	= [[NSArray alloc] initWithObjects:
		@"name", @"identifier",@"enabled", 
		nil];
}


// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)dealloc
{
	self.name		= nil;
	self.identifier	= nil;
	[super dealloc];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSString *)readableName
{
	return self.name;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setReadableName:(NSString *)newReadableName
{
	self.name	= newReadableName;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSString *)name
{
	return self->_name ? [[self->_name retain] autorelease] : self.identifier;
}


// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setName:(NSString *)newName
{
	if (newName && [newName isEqualToString:self.identifier]) {
		newName	= nil;
	}

    if (![self->_name isEqualToString:newName]) {
		[self->_name release];
		self->_name = [newName retain];
    }
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSString*)copyright
{
	return LocalizedString(@"keyNoDictInfo",nil);
}

- (void)setFilterConfig:(AspellConfig*)filterConfig 
{
}

- (void)forgetWord:(NSString *)word
{
}

- (void)learnWord:(NSString *)word
{
}

- (NSRange)findMisspelledWordInBuffer:(unichar*)buffer size:(unsigned)size wordCount:(int*)wordCount countOnly:(BOOL)countOnly
{
	return NSMakeRange(NSNotFound, 0);
}

- (NSArray*)suggestGuessesForWord:(NSString*)word
{
	return [NSArray array];
}

- (NSArray*)suggestCompletionsForPartialWordRange:(NSRange)inRange inString:(NSString*)str
{
	return [NSArray array];
}


@end
