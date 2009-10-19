#ifdef __multilingual__

// ============================================================================
//  MultilingualDictionary.m
// ============================================================================
//
//	cocoAspell2
//
//  Created by Anton Leuski on 2/23/08.
//  Copyright (c) 2008 Anton Leuski. All rights reserved.
// ============================================================================

#import "MultilingualDictionary.h"


@implementation MultilingualDictionary
@synthesize dictionaries	= _dictionaries;

- (id)initWithDictionaries:(NSArray*)dicts
{
	if (self = [super init]) {
		self.dictionaries	= dicts;
	}
	return self;
}

- (void)dealloc
{
	self.dictionaries	= nil;
	[super dealloc];
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
		NSRange		rng	= [[self.dictionaries objectAtIndex:i] findMisspelledWordInBuffer:buffer+offset size:size-offset*sizeof(unichar) wordCount:&wc countOnly:countOnly];

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

































