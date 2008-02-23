// ============================================================================
//  DisableableTextField.m
// ============================================================================
//
//	cocoAspell
//
//  Created by Anton Leuski on Fri Jan 16 2004.
//  Copyright (c) 2004 Anton Leuski. All rights reserved.
// ============================================================================

#import "DisableableTextField.h"


@implementation DisableableTextField

- (void)setEnabled:(BOOL)enable
{
	[self setTextColor:(enable ? [NSColor blackColor] : [NSColor grayColor])];
//	[self setTextColor:(enable ? [NSColor redColor] : [NSColor greenColor])];
//	[super setEnabled:enable];
}

@end
