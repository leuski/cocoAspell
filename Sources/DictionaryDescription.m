// ============================================================================
//  DictionaryDescription.m
// ============================================================================
//
//	cocoAspell2
//
//  Created by Anton Leuski on 4/30/05.
//  Copyright (c) 2005 Anton Leuski. All rights reserved.
// ============================================================================

#import "DictionaryDescription.h"


@implementation DictionaryDescription

- (NSString*)fileNameNoExtension
{
	return @"";
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSString*)module
{
	NSArray*	tmp	= [[self fileNameNoExtension] componentsSeparatedByString:@"-"];
	return [tmp count] > 0 ? [tmp objectAtIndex:0] : @"";
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSString*)langCode
{
	NSArray*	tmp	= [[self fileNameNoExtension] componentsSeparatedByString:@"-"];
	return [tmp count] > 1 ? [tmp objectAtIndex:1] : @"";
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSString*)version
{
	NSArray*	tmp	= [[self fileNameNoExtension] componentsSeparatedByString:@"-"];
	return [tmp count] > 2 ? [[tmp subarrayWithRange:NSMakeRange(2,[tmp count]-2)] componentsJoinedByString:@"-"] : @"";
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSComparisonResult)compare:(DictionaryDescription*)arg
{
	NSComparisonResult	res;

	res = [[arg langCode] compare:[self langCode]];
	if (res != NSOrderedSame) return res;

	res = [[arg module] compare:[self module]];
	if (res != NSOrderedSame) return res;

	return [[arg version] compare:[self version]];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSString*)fullVersion
{
	NSString*	result	= nil;
	NSString*	mode	= [self module];
	if ([mode hasPrefix:@"aspell"])
		result	= [mode substringFromIndex:[@"aspell" length]];
	if (!result || ![result length])
		result	= @"0";
	NSString*	vers	= [self version];
	if (vers && [vers length])
		result	= [NSString stringWithFormat:@"%@.%@", result, vers];
	else
		result	= [NSString stringWithFormat:@"%@", result];
//	NSLog(@"%@ ## %@ ## %@", result, mode, vers);.
	return result;
}

@end
