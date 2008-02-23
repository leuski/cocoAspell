// ============================================================================
//  DictionaryInstaller.h
// ============================================================================
//
//	cocoAspell2
//
//  Created by Anton Leuski on 4/25/05.
//  Copyright (c) 2005 Anton Leuski. All rights reserved.
// ============================================================================

#import <AppKit/AppKit.h>


@interface DictionaryInstaller : NSObject {
	IBOutlet NSWindow*				window;
	IBOutlet NSProgressIndicator*	progress;
	IBOutlet NSTextField*			message;
	
	NSArray*						languages;
	NSArray*						domains;
	NSDictionary*					selectedDomain;
	BOOL							installing;
	BOOL							detailsVisible;
}

- (NSWindow*)window;

- (NSArray *)languages;
- (void)setLanguages:(NSArray *)newLanguages;

- (NSArray *)domains;
- (void)setDomains:(NSArray *)newDomains;

- (NSDictionary *)selectedDomain;
- (void)setSelectedDomain:(NSDictionary *)newSelectedDomain;

- (BOOL)isDetailsVisible;
- (void)setDetailsVisible:(BOOL)newDetailsVisible;

- (BOOL)isInstalling;
- (void)setInstalling:(BOOL)newInstalling;

@end
