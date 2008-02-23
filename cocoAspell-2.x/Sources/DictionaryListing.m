// ============================================================================
//  DictionaryListing.m
// ============================================================================
//
//	cocoAspell2
//
//  Created by Anton Leuski on 4/26/05.
//  Copyright (c) 2005 Anton Leuski. All rights reserved.
// ============================================================================

#import "DictionaryListing.h"
#import "UserDefaults.h"

@implementation DictionaryListing

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

+ (void)initialize
{
	static BOOL tooLate = NO;
    if (!tooLate) {
        tooLate = YES;
		NSArray*	tmp	= [NSArray arrayWithObject:@"entry"];
		[self setKeys:tmp triggerChangeNotificationsForDependentKey:@"module"];
		[self setKeys:tmp triggerChangeNotificationsForDependentKey:@"version"];
		[self setKeys:tmp triggerChangeNotificationsForDependentKey:@"langCode"];
		[self setKeys:tmp triggerChangeNotificationsForDependentKey:@"fileNameNoExtension"];
    }
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (id)initWithListEntry:(NSString*)inEntry
{
	if (self = [super init]) {
		[self setEntry:inEntry];
	}
	return self;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void) dealloc 
{
	[self setEntry:nil];
	[super dealloc];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSString*)description
{
	return [self entry];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSString *)entry
{
	return [[entry retain] autorelease];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setCreated:(NSDate *)newCreated
{
    if (created != newCreated) {
		[created release];
		created = [newCreated copy];
    }
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setFileName:(NSString *)newFileName
{
    if (fileName != newFileName) {
		[fileName release];
		fileName = [newFileName copy];
    }
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setSize:(int)newSize
{
    if (size != newSize) {
		size = newSize;
    }
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setEntry:(NSString *)newEntry
{
    if (entry != newEntry) {
		[entry release];
		entry			= [newEntry copy];
		NSArray*	tmp	= [entry componentsSeparatedByString:@" "];
		[self setFileName:[tmp lastObject]];
		int		i, j = 0, k = 0;
		for(i = 0; i < [tmp count]-1; ++i) {
			if ([[tmp objectAtIndex:i] length]) {
				++j;
				if (j == 5) {
					[self setSize:[[tmp objectAtIndex:i] intValue]];
				}
				if (j == 6) {
					k	 = i;
				}
			}
		}
		NSString*	timeString	= [[tmp subarrayWithRange:NSMakeRange(k,[tmp count]-1-k)] componentsJoinedByString:@" "];
		[self setCreated:[NSDate dateWithNaturalLanguageString:timeString]];
    }
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSString *)fileNameNoExtension
{
	NSString*	tmp	= [self fileName];
	if ([tmp hasSuffix:@".bz2"])
		tmp	= [tmp substringToIndex:[tmp length] - [@".bz2" length]];
	if ([tmp hasSuffix:@".tar"])
		tmp	= [tmp substringToIndex:[tmp length] - [@".tar" length]];
	return tmp;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSString *)fileName
{
	return [[fileName retain] autorelease];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (int)size
{
	return size;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSDate *)created
{
	return [[created retain] autorelease];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSString*)statusText
{
	NSString*	text	= @"";
	if ([self status] & kStatusInstalled) {
		text	= LocalizedString(@"Installed",nil);
	} else {
		text	= LocalizedString(@"Not Installed",nil);
	}
	return text;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (int)status
{
	return status;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setStatus:(int)newStatus
{
    if (status != newStatus) {
		status = newStatus;
    }
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (BOOL)isPreferred
{
	return preferred;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setPreferred:(BOOL)newPreferred
{
    if (preferred != newPreferred) {
		preferred = newPreferred;
    }
}


@end
