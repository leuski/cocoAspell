// ============================================================================
//  DictionaryListing.h
// ============================================================================
//
//	cocoAspell2
//
//  Created by Anton Leuski on 4/26/05.
//  Copyright (c) 2005 Anton Leuski. All rights reserved.
// ============================================================================

#import <Foundation/Foundation.h>
#import "DictionaryDescription.h"

enum {
	kStatusInstalled	= 0x01,
	kStatusRecommended	= 0x02
} DictionaryListingStatus;

@interface DictionaryListing : DictionaryDescription {
	NSString*	entry;
	NSString*	fileName;
	int			size;
	NSDate*		created;
	BOOL		preferred;
	int			status;
}

- (id)initWithListEntry:(NSString*)inEntry;

- (NSString *)entry;
- (void)setEntry:(NSString *)newEntry;

- (NSString *)fileName;
- (int)size;
- (NSDate *)created;

- (BOOL)isPreferred;
- (void)setPreferred:(BOOL)newPreferred;

- (int)status;
- (void)setStatus:(int)newStatus;

@end
