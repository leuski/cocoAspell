// ============================================================================
//  lsinfo.m
// ============================================================================
//
//	cocoAspell2
//
//  Created by Anton Leuski on 3/14/05.
//  Copyright (c) 2005 Anton Leuski. All rights reserved.
// ============================================================================

#import <Foundation/Foundation.h>

int main(int argc, char* argv[])
{
	NSAutoreleasePool* pool		= [[NSAutoreleasePool alloc] init];

	NSURL*				url;
	OSStatus	err	= LSGetApplicationForURL([NSURL fileURLWithPath:[NSString stringWithUTF8String:argv[1]]], kLSRolesAll, nil, &url);
	NSLog(@"%d %@", err, url);
	[url release];
	
	
	[pool release];
	return 0;
	
}
