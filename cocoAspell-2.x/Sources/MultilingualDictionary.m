#ifdef __multilingual__

// ============================================================================
//  MultilingualDictionary.m
// ============================================================================
//
//	cocoAspell2
//
//  Created by Anton Leuski on 2/23/08.
//  Copyright (c) 2008 Anton Leuski. All rights reserved.
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

#import "MultilingualDictionary.h"
#import "clip_int.h"

@implementation MultilingualDictionary

- (id)initWithDictionaries:(NSArray*)dicts
{
	if (self = [super init]) {
		self.dictionaries	= dicts;
	}
	return self;
}


- (void)setFilterConfig:(AspellConfig*)filterConfig 
{
	for(Dictionary* d in self.dictionaries) {
		[d setFilterConfig:filterConfig];
	}
}

- (void)forgetWord:(NSString *)word
{
	for(Dictionary* d in self.dictionaries) {
		[d forgetWord:word];
	}
}

- (void)learnWord:(NSString *)word
{
	for(Dictionary* d in self.dictionaries) {
		[d learnWord:word];
	}
}

- (NSRange)findMisspelledWordInBuffer:(unichar*)buffer size:(unsigned int)size wordCount:(int*)wordCount countOnly:(BOOL)countOnly
{
	NSRange		result	= NSMakeRange(NSNotFound, 0);
	NSUInteger	offset	= 0;
	NSUInteger	n		= [self.dictionaries count];
	NSUInteger	i		= 0;
	NSUInteger	bestDictionaryIndex	= NSNotFound;
		
	*wordCount			= 0;
	while (1) {

		if (i == bestDictionaryIndex) {
			break;
		}

		int			wc	= 0;
		NSRange rng	= [(self.dictionaries)[i] findMisspelledWordInBuffer:buffer+offset
                                                                size:size-CLIP_TO_UINT(offset*sizeof(unichar))
                                                           wordCount:&wc
                                                           countOnly:countOnly];

		if (rng.location == NSNotFound) {
			*wordCount	+= wc;
			result		= rng;
			break;
		} else if (wc) {
			*wordCount	+= wc;
			offset		+= rng.location;
			result		= NSMakeRange(offset, rng.length);
			bestDictionaryIndex	= i;
		} else if (bestDictionaryIndex == NSNotFound) {
			bestDictionaryIndex	= i;
			result		= rng;
		}

		i++; if (i >= n) i = 0;
	}
	
	return result;
}

- (NSArray*)suggestGuessesForWord:(NSString*)word
{
	NSMutableArray*	result	= [NSMutableArray array];
	for(Dictionary* d in self.dictionaries) {
		[result addObjectsFromArray:[d suggestGuessesForWord:word]];
	}
	return result;
}

- (NSArray*)suggestCompletionsForPartialWordRange:(NSRange)inRange inString:(NSString*)str
{
	NSMutableArray*	result	= [NSMutableArray array];
	for(Dictionary* d in self.dictionaries) {
		[result addObjectsFromArray:[d suggestCompletionsForPartialWordRange:inRange inString:str]];
	}
	return result;
}

- (BOOL)caseSensitive
{
	for(Dictionary* d in self.dictionaries) {
		if (d.caseSensitive) return YES;
	}
	return NO;
}

@end




#endif //__multilingual__

































