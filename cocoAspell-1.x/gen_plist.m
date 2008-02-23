// ============================================================================
//  gen_plist.m
// ============================================================================
//
//	cocoAspell
//
//  Created by Anton Leuski on Mon Jan 26 2004.
//  Copyright (c) 2004 Anton Leuski. All rights reserved.
// ============================================================================

#import <Foundation/Foundation.h>
#import "LanguageDesc.h"

int main(int argc, char* argv[])
{
	NSAutoreleasePool*		pool		= [[NSAutoreleasePool alloc] init];
	NSString*				dir			= [NSString stringWithCString:argv[1]];
	NSDirectoryEnumerator*	enumerator 	= [[NSFileManager defaultManager] enumeratorAtPath:dir];
	NSString*				file;
	
	while (file = [enumerator nextObject]) {
		if ([[file pathExtension] isEqualToString:@"pwli"]) {
			NSString*		lang_file   = [dir stringByAppendingPathComponent:file];
			NSString*		plist_file  = [[lang_file stringByDeletingPathExtension] stringByAppendingPathExtension:@"plist"];
			LanguageDesc*   desc		= [LanguageDesc languageDescWithDictionaryFile:lang_file];
			NSDictionary*   dict		= [NSDictionary dictionaryWithObjectsAndKeys:[desc appleName], @"AppleName", 
												[desc displayName], @"DisplayName",
												[desc identifier], @"Identifier", nil];
			[dict writeToFile:plist_file atomically:NO];
		}
	}	

	[pool release];
}