// ================================================================================
//  TeXCommandFormatter.m
// ================================================================================
//	cocoAspell
//
//  Created by Anton Leuski on Wed Feb 13 2002.
//  Copyright (c) 2002-2004 Anton Leuski.
//
//	This file is part of cocoAspell package.
//
//	Redistribution and use of cocoAspell in source and binary forms, with or without 
//	modification, are permitted provided that the following conditions are met:
//
//	1. Redistributions of source code must retain the above copyright notice, this 
//		list of conditions and the following disclaimer.
//	2. Redistributions in binary form must reproduce the above copyright notice, 
//		this list of conditions and the following disclaimer in the documentation 
//		and/or other materials provided with the distribution.
//	3. The name of the author may not be used to endorse or promote products derived 
//		from this software without specific prior written permission.
//
//	THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED 
//	WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
//	MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT 
//	SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
//	EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT 
//	OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
//	INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, 
//	STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY 
//	OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// ================================================================================

#import "TeXCommandFormatter.h"

#define kLocalizeMe			@"<<Localize Me>>"

@implementation TeXCommandFormatter

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (NSString*)normalizedString:(NSString*)inString
{
	int					b, e, n = [inString length];
	NSCharacterSet*		chars	= [NSCharacterSet whitespaceAndNewlineCharacterSet];
	
	if (n == 0)
		return inString;
	
	for(b = 0; b < n; ++b) {
		if (![chars characterIsMember:[inString characterAtIndex:b]]) {
			break;
		}
	}

	if (b >= n)
		return [NSString string];
		
	for(e = n-1; b < e; --e) {
		if (![chars characterIsMember:[inString characterAtIndex:e]]) {
			break;
		}
	}
	
	if ( (b == 0) && (e == (n-1)) )
		return inString;
		
	return [inString substringWithRange:NSMakeRange(b, e-b+1)];
}


// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (BOOL)getObjectValue:(id *)anObject forString:(NSString *)string errorDescription:(NSString **)error
{
	NSString*	text = [self normalizedString:string];

	*anObject	= text;

	if ([text length] == 0) {
		if (error) {
			NSBundle*	thisBundle	= [NSBundle bundleForClass:[self class]];
			*error 	= [thisBundle localizedStringForKey:@"keyErrorEmptyTexCommand" value:kLocalizeMe table:nil];
		}
		return NO;
	}
	
	return YES;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (NSString *)stringForObjectValue:(id)anObject
{
	if (![anObject isKindOfClass:[NSString class]])
		return nil;
	return (NSString*)anObject;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (NSString *)editingStringForObjectValue:(id)anObject
{
	return [self stringForObjectValue:anObject];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------
/*
- (NSAttributedString *)attributedStringForObjectValue:(id)anObject withDefaultAttributes:(NSDictionary *)attributes
{
	if (![anObject isKindOfClass:[NSString class]])
		return nil;	
	return [[[NSAttributedString alloc] initWithString:anObject attributes:attributes] autorelease];
}
*/
@end
