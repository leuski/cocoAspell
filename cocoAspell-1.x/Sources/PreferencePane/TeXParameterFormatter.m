// ================================================================================
//  TeXParameterFormatter.m
// ================================================================================
//	cocoAspell
//
//  Created by Anton Leuski on Tue Feb 12 2002.
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

#import "TeXParameterFormatter.h"
#import "Preferences.h"

#define kLocalizeMe			@"<<Localize Me>>"

static NSAttributedString*	kTeXParameterString[4] = {nil, nil, nil, nil};

@implementation TeXParameterFormatter

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (NSAttributedString*)getTeXParameterString:(int)index
{
	if (!kTeXParameterString[0]) {
	
		NSAttributedString*	str;
		NSData*				data;
		NSString*			path;
		unsigned			start, end, contEnd, i;
		NSRange				range;
						
		path	= [[NSBundle bundleForClass:[self class]] pathForResource:@"TeXParameters" ofType:@"rtf"];
		data	= [NSData dataWithContentsOfFile:path];
		str 	= [[NSAttributedString alloc] initWithRTF:data documentAttributes:nil];
		
		path	= [str string];
		
		range.location 	= 0;
		for(i = 0; i < 4; ++i) {
			range.length			= 0;
			[path getLineStart:&start end:&end contentsEnd:&contEnd forRange:range];
			range.location			= start;
			range.length			= contEnd - start;
			kTeXParameterString[i]	= [[str attributedSubstringFromRange:range] retain];
			range.location 			= end;
		}
		
		[str release];
	}

	return kTeXParameterString[index];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

enum {
	stNone,
	stParam,
	stParamCheck,
	stOpt,
	stOptCheck
};

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (NSAttributedString *)attributedStringForObjectValue:(id)anObject withDefaultAttributes:(NSDictionary *)attributes
{
	NSArray*	param = (NSArray*)anObject;
	int			i;
	NSMutableAttributedString*	buffer;

	if (![anObject isKindOfClass:[NSArray class]])
		return nil;

	buffer = [[[NSMutableAttributedString alloc] initWithString:@""] autorelease];

	for(i = 0; i < [param count]; ++i) {
		NSDictionary*	obj	= [param objectAtIndex:i];
		int		chk = [[obj objectForKey:kKeyCheck] boolValue] ? 1 : 0;
		int		opt	= [[obj objectForKey:kKeyOptional] boolValue] ? 2 : 0;
		[buffer appendAttributedString:[self getTeXParameterString:(chk+opt)]];
	}
	
//	NSLog(@"%@ == %@", buffer, [buffer string]);
	
	return buffer;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (BOOL)getObjectValue:(id *)anObject forString:(NSString *)string errorDescription:(NSString **)error
{
	unsigned		i, n = [string length];
	int				t;
	NSMutableArray*	params = nil;
	
	if (anObject)
		params = *anObject = [NSMutableArray array];
	
	if (n == 0)
		return YES;
	
	t = stNone;
	
	for(i = 0; i < n; ++i) {
		unichar	ch = [string characterAtIndex:i];
		switch (ch) {
		case '{' : 
		case '[' : 
			if (t != stNone) {
			
				if (error) {
				
					switch (t) {
					
					case stParam:
						*error = [NSString stringWithFormat:[[NSBundle bundleForClass:[self class]] 
							localizedStringForKey:@"keyErrorTeXParamUnexpected2" value:kLocalizeMe table:nil],
							i, ch, 'Ã', '}'];
						break;

					case stParamCheck:
						*error = [NSString stringWithFormat:[[NSBundle bundleForClass:[self class]] 
							localizedStringForKey:@"keyErrorTeXParamUnexpected1" value:kLocalizeMe table:nil],
							i, ch, '}'];
						break;

					case stOpt:
						*error = [NSString stringWithFormat:[[NSBundle bundleForClass:[self class]] 
							localizedStringForKey:@"keyErrorTeXParamUnexpected2" value:kLocalizeMe table:nil],
							i, ch, 'Ã', ']'];
						break;

					case stOptCheck:
						*error = [NSString stringWithFormat:[[NSBundle bundleForClass:[self class]] 
							localizedStringForKey:@"keyErrorTeXParamUnexpected1" value:kLocalizeMe table:nil],
							i, ch, ']'];
						break;
						
					}
				}
			
				return NO; 
			}
			
			t = (ch == '{') ? stParam : stOpt; 
			break;
		
		case '}' : 
			if ( (t != stParam) && (t != stParamCheck) ) {

				if (error) {
					*error = [NSString stringWithFormat:[[NSBundle bundleForClass:[self class]] 
							localizedStringForKey:@"keyErrorTeXParamUnexpected1" value:kLocalizeMe table:nil],
							i, ch, '}'];
				}
				
				return NO; 
			}
			
			[params addObject:[NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithBool:(t == stParamCheck)], kKeyCheck,
					[NSNumber numberWithBool:NO], kKeyOptional,
					nil]];

			t = stNone;
			break;
			
		case 'Ã' :
		case 0x221a :
			if (t == stParam)
				t = stParamCheck;
			else if (t == stOpt)
				t = stOptCheck;
			else {
				if (error) {
				
					switch (t) {
					
					case stNone:
						*error = [NSString stringWithFormat:[[NSBundle bundleForClass:[self class]] 
							localizedStringForKey:@"keyErrorTeXParamUnexpected2" value:kLocalizeMe table:nil],
							i, ch, '{', '['];
						break;

					case stParamCheck:
						*error = [NSString stringWithFormat:[[NSBundle bundleForClass:[self class]] 
							localizedStringForKey:@"keyErrorTeXParamUnexpected1" value:kLocalizeMe table:nil],
							i, ch, '}'];
						break;

					case stOptCheck:
						*error = [NSString stringWithFormat:[[NSBundle bundleForClass:[self class]] 
							localizedStringForKey:@"keyErrorTeXParamUnexpected1" value:kLocalizeMe table:nil],
							i, ch, ']'];
						break;
						
					}
				}

				return NO;
			}
			
			break;
			
		
		case ']' : 
			if ( (t != stOpt) && (t != stOptCheck) ) {

				if (error) {
					*error = [NSString stringWithFormat:[[NSBundle bundleForClass:[self class]] 
							localizedStringForKey:@"keyErrorTeXParamUnexpected1" value:kLocalizeMe table:nil],
							i, ch, ']'];
				}
				
				return NO; 
			}

			[params addObject:[NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithBool:(t == stOptCheck)], kKeyCheck,
					[NSNumber numberWithBool:YES], kKeyOptional,
					nil]];

			t = stNone; 
			break;
		case ' ' :
			break;
		default:
			return i;
		}
		
	}
	
	if (t != stNone) {

		if (error) {
		
			switch (t) {
			
			case stParam:
				*error = [NSString stringWithFormat:[[NSBundle bundleForClass:[self class]] 
					localizedStringForKey:@"keyErrorTeXParamUnexpectedEOL2" value:kLocalizeMe table:nil],
					i, 'Ã', '}'];
				break;

			case stParamCheck:
				*error = [NSString stringWithFormat:[[NSBundle bundleForClass:[self class]] 
					localizedStringForKey:@"keyErrorTeXParamUnexpectedEOL1" value:kLocalizeMe table:nil],
					i, '}'];
				break;

			case stOpt:
				*error = [NSString stringWithFormat:[[NSBundle bundleForClass:[self class]] 
					localizedStringForKey:@"keyErrorTeXParamUnexpectedEOL2" value:kLocalizeMe table:nil],
					i, 'Ã', ']'];
				break;

			case stOptCheck:
				*error = [NSString stringWithFormat:[[NSBundle bundleForClass:[self class]] 
					localizedStringForKey:@"keyErrorTeXParamUnexpectedEOL1" value:kLocalizeMe table:nil],
					i, ']'];
				break;
				
			}
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
	return [[self attributedStringForObjectValue:anObject withDefaultAttributes:nil] string];
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (NSString *)editingStringForObjectValue:(id)anObject
{
	return [[self attributedStringForObjectValue:anObject withDefaultAttributes:nil] string];
}

@end
