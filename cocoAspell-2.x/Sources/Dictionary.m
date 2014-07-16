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
@synthesize name = _name;

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

+ (void)initialize
{
	kStorableKeys	= @[@"name", @"identifier",@"enabled"];
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
	return self->_name ? self->_name : self.identifier;
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
		self->_name = newName;
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

- (NSRange)findMisspelledWordInBuffer:(unichar*)buffer size:(unsigned int)size wordCount:(int*)wordCount countOnly:(BOOL)countOnly
{
	return NSMakeRange(NSNotFound, 0);
}

- (NSArray*)suggestGuessesForWord:(NSString*)word
{
	return @[];
}

- (NSArray*)suggestCompletionsForPartialWordRange:(NSRange)inRange inString:(NSString*)str
{
	return @[];
}


@end
