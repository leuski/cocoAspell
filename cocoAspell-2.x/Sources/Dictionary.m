// ============================================================================
//  Dictionary.m
// ============================================================================
//
//	cocoAspell2
//
//  Created by Anton Leuski on 2/4/05.
//  Copyright (c) 2005-2008 Anton Leuski. All rights reserved.
//
//	Redistribution and use in source and binary forms, with or without
//	modification, are permitted provided that the following conditions are met:
//
//	1. Redistributions of source code must retain the above copyright notice, this
//	list of conditions and the following disclaimer.
//	2. Redistributions in binary form must reproduce the above copyright notice,
//	this list of conditions and the following disclaimer in the documentation
//	and/or other materials provided with the distribution.
//
//	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//	ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//	WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//	DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
//	ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//	(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//	 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//	ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//	(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//	SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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
