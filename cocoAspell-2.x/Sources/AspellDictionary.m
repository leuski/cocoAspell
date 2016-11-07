// ============================================================================
//  AspellDictionary.m
// ============================================================================
//
//	cocoAspell2
//
//  Created by Anton Leuski on 2/23/08.
//  Copyright (c) 2008 Anton Leuski. All rights reserved.
//
//	Redistribution and use in source and binary forms, with or without
//	modification, are permitted provided that the following conditions are met:
//
//	1. Redistributions of source code must retain the above copyright notice, this
//	list of conditions and the following disclaimer.
//	2. Redistributions in binary form must reproduce the above copyright notice,
//	this list of conditions and the following disclaimer in the documentation
//	and/or other materials provided with the distribution.
//
//	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//	ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//	WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//	DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
//	ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//	(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//	 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//	ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//	(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//	SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// ============================================================================

#import "AspellDictionary.h"
#import "AspellOptions.h"
#import "DictionaryManager.h"
#import "Utilities.h"

#import "aspell.h"
#import "aspell_extras.h"
#import "cocoa_document_checker.h"
#import "clip_int.h"

@interface AspellDictionary ()
@property (nonatomic, assign)	AspellSpeller*			speller;
@end

@implementation AspellDictionary

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (id)initWithFilePath:(NSString*)inPath persistent:(BOOL)flag
{
	if (self = [super init]) {		

		self.identifier	= [[inPath lastPathComponent] stringByDeletingPathExtension];
		
		NSRange		rng	= [self.identifier rangeOfString:@"-"];
		NSString*	langCode;
		NSString*	langJargon;
		
		if (rng.location != NSNotFound) {
			langCode	= [self.identifier substringToIndex:rng.location];
			langJargon	= [self.identifier substringFromIndex:rng.location+1];
		} else {
			langCode	= self.identifier;
			langJargon	= @"";
		}

		AspellOptions*	opts		= nil;
		NSString*		optsFile	= [self.identifier stringByAppendingPathExtension:@"conf"];
		NSString*		optsPath	= [[AspellOptions cocoAspellHomeDir] stringByAppendingPathComponent:optsFile];
		
		opts	= [[AspellOptions alloc] initWithContentOfFile:optsPath];
		if (!opts) {
//			NSLog(@"no file %@", optsPath);
			opts	= [[AspellOptions alloc] init];
			if (opts) {
				NSString*		home_dir	= [AspellOptions cocoAspellHomeDir];
				opts[@"home_dir"] = home_dir;
				opts[@"encoding"] = @"ucs-2";
				opts[@"per-conf"] = @"cocoAspell.conf";
			}
		}
		
		self.options	= opts;
		self.options.persistent	= flag; 

		self.options[@"lang"] = langCode;
		self.options[@"jargon"] = langJargon;
		self.options[@"dict-dir"] = [inPath stringByDeletingLastPathComponent];
		self.options[@"repl"] = [self.identifier stringByAppendingPathExtension:@"prepl"];
		self.options[@"personal"] = [self.identifier stringByAppendingPathExtension:@"pws"];
		self.options[@"per-conf"] = optsFile;

		
		NSString*	fixedName	= getSystemLanguageName(langCode, YES);
		if (fixedName != langCode) {
			if ([langJargon length] > 0) {
				fixedName	= [fixedName stringByAppendingFormat:@" [%@]", langJargon];
			}
//			fixedName	= [fixedName stringByAppendingFormat:@" -- %@", langCode];
			self.name	= fixedName;
		}
	}
	return self;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)addDataFileContent:(NSString*)fileName inDir:(NSString*)dir intoArray:(NSMutableArray*)array
{
	NSStringEncoding	encoding;
	NSString*			content	= [NSString stringWithContentsOfFile:[dir stringByAppendingPathComponent:fileName] usedEncoding:&encoding error:nil];
	if (!content) return;
	for (__strong NSString* line in [content componentsSeparatedByString:@"\n"]) {
		line	= [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		if ([line hasPrefix:@"add"]) {
			line	= [line substringFromIndex:[@"add" length]];
			line	= [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			if ([line hasSuffix:@"rws"]) {
				[array addObject:line];
			} else if ([line hasSuffix:@"multi"]) {
				[self addDataFileContent:line inDir:dir intoArray:array];
			}
		}
	}
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSString*)dataFiles
{
	NSMutableArray*	array	= [NSMutableArray array];
	[self addDataFileContent:[self.identifier stringByAppendingPathExtension:@"multi"] inDir:[self.options valueForKey:@"actual-dict-dir"] intoArray:array];
	return [array componentsJoinedByString:@"\n"];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setSpeller:(AspellSpeller*)newSpeller
{
	if (self->_speller == newSpeller) return;
	
	if (self->_speller) {
		delete_aspell_speller(self->_speller);
	}
	self->_speller	= newSpeller;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)dealloc
{
	self.speller	= nil;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSString*)copyright
{
	NSString*		path	= [self.options valueForKey:@"actual-dict-dir"];
	BOOL			isDir;
	path					= [path stringByAppendingPathComponent:@"Copyright"];
	if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && !isDir) {
		NSStringEncoding	encoding;
		return [NSString stringWithContentsOfFile:path usedEncoding:&encoding error:nil];
	}
	return [super copyright];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (BOOL)caseSensitive
{
	return ![self.options valueForKey:@"ignore-case"];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setFilterConfig:(AspellConfig*)filterConfig
{
//		NSLog(@"%@", [AspellOptions aspellOptionsWithAspellConfig:filterConfig]); 
//		NSLog(@"%@", [AspellOptions aspellOptionsWithAspellConfig:dictConfig]); 

	AspellConfig*	config			= aspell_config_clone(filterConfig);

//		NSLog(@"%@", [AspellOptions aspellOptionsWithAspellConfig:config]); 

	if (!aspell_config_merge(config, [self.options aspellConfig])) {
		NSLog(@"failed to merge dictionary for language %@ and filter descriptions", self.name);
		return ;
	}
	
//		NSLog(@"%@", [AspellOptions aspellOptionsWithAspellConfig:config]); 	

	AspellCanHaveError*	possible_err	= new_aspell_speller(config);
	delete_aspell_config(config);

	if (aspell_error_number(possible_err) != 0) {
		NSLog(@"failed to initialize speller: %s", aspell_error_message(possible_err));
		delete_aspell_can_have_error(possible_err);
		return ;
	}

	self.speller	= to_aspell_speller(possible_err);
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)forgetWord:(NSString *)word 
{
	if (!self.speller) return;
	
	int       textSize	= CLIP_TO_INT(sizeof(unichar) * [word length]);
	unichar*	textData	= (unichar*)malloc(textSize);
	if (textData) {
		[word getCharacters:textData];
#ifdef __debug__
		int		x = 
#endif
		aspell_speller_remove_from_personal(self.speller, (const char*)textData, textSize);
#ifdef __debug__
		NSLog(@"%d %s", x, aspell_speller_error_message(self.speller));
#endif
		free(textData);
		aspell_speller_save_all_word_lists(self.speller);
	}
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (void)learnWord:(NSString *)word 
{
	if (!self.speller) return;
	
	int       textSize	= CLIP_TO_INT(sizeof(unichar) * [word length]);
	unichar*  textData	= (unichar*)malloc(textSize);
	if (textData) {
		[word getCharacters:textData];
#ifdef __debug__
		int		x = 
#endif
		aspell_speller_add_to_personal(self.speller, (const char*)textData, textSize);
#ifdef __debug__
		NSLog(@"%d %s", x, aspell_speller_error_message(self.speller));
#endif
		free(textData);
		aspell_speller_save_all_word_lists(self.speller);
	}
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (NSRange)findMisspelledWordInBuffer:(unichar*)buffer size:(unsigned int)size wordCount:(int*)wordCount countOnly:(BOOL)countOnly
{
	*wordCount	= 0;
	NSRange		result	= NSMakeRange(NSNotFound, 0);
	if (!self.speller) return result;

	unsigned int	offset;
	unsigned int	length;
	aspell_speller_check_spelling(self.speller, (const char*)buffer, size, wordCount, countOnly, &offset, &length);
	return length ? NSMakeRange(offset, length) : NSMakeRange(NSNotFound, 0);
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (NSArray *)suggestGuessesForWord:(NSString*)word 
{
	NSMutableArray*	result	= [NSMutableArray array];
	if (!self.speller) return result;
	
	int       textSize	= CLIP_TO_INT(sizeof(unichar) * [word length]);
	unichar*	textData	= (unichar*)malloc(textSize);
	if (textData) {
		[word getCharacters:textData];
		const AspellWordList*		suggestions = aspell_speller_suggest(self.speller, (const char*)textData, textSize);
		AspellStringEnumeration*	elements	= aspell_word_list_elements(suggestions);
		const char * word;
		while ( (word = aspell_string_enumeration_next(elements)) != NULL ) {
			const unichar*	w	= (const unichar*)word;
			for(; *w; ++w);
			[result addObject:[NSString stringWithCharacters:(const unichar*)word length:(w - (const unichar*)word)]];
		}
		delete_aspell_string_enumeration(elements);
		free(textData);
	}
	return result;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (NSArray*)suggestCompletionsForPartialWordRange:(NSRange)inRange inString:(NSString*)str 
{
	NSMutableArray*	result	= [NSMutableArray array];
	if (!self.speller) return result;

	NSString*	prefix		= [str substringWithRange:inRange];
	NSString*	word		= prefix;
	NSUInteger	longTextSize	= sizeof(unichar) * [word length];
  int textSize = (int)MIN(longTextSize, INT_MAX);
	unichar*	textData	= (unichar*)malloc(textSize);
	if (textData) {
		[word getCharacters:textData];
		const AspellWordList*		suggestions = aspell_speller_suggest(self.speller, (const char*)textData, textSize);
		AspellStringEnumeration*	elements	= aspell_word_list_elements(suggestions);
		const char*					word;
		while ( (word = aspell_string_enumeration_next(elements)) != NULL ) {
			const unichar*	w	= (const unichar*)word;
			for(; *w; ++w);
			NSString*		tw	= [NSString stringWithCharacters:(const unichar*)word length:(w - (const unichar*)word)];
			if ([tw hasPrefix:prefix]) {
				[result addObject:tw];
			}
		}
		delete_aspell_string_enumeration(elements);
		free(textData);
	}

	return result;
}

/*
- (AspellConfig*)configForLanguage:(NSString*)inLanguage caseSensitive:(BOOL*)cs
{
	if (cs)	
		*cs	= YES;

	Dictionary*		theDict		= [self dictionaryForName:inLanguage];
	if (!theDict) {
		NSLog(@"no dictionary for language %@", inLanguage);
		return nil;
	}

	AspellConfig*	filterConfig	= [[[self dictionaryManager] filters] aspellConfig];
	AspellConfig*	dictConfig		= [[theDict options] aspellConfig];
	
	if (cs)
		*cs	= ![[theDict options] valueForKey:@"ignore-case"];
		
//		NSLog(@"%@", [AspellOptions aspellOptionsWithAspellConfig:filterConfig]); 
//		NSLog(@"%@", [AspellOptions aspellOptionsWithAspellConfig:dictConfig]); 

	AspellConfig*	config			= aspell_config_clone(filterConfig);

//		NSLog(@"%@", [AspellOptions aspellOptionsWithAspellConfig:config]); 

	if (!aspell_config_merge(config, dictConfig)) {
		NSLog(@"failed to merge dictionary for language %@ and filter descriptions", inLanguage);
		return nil;
	}

//		NSLog(@"%@", [AspellOptions aspellOptionsWithAspellConfig:config]); 
	
	return config;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

- (AspellSpeller*)spellerForLanguage:(NSString*)inLanguage caseSensitive:(BOOL*)cs
{	
	AspellConfig*		config			= [self configForLanguage:inLanguage caseSensitive:cs];
	if (!config) return nil;
	
//		NSLog(@"%@", [AspellOptions aspellOptionsWithAspellConfig:config]); 	

	AspellCanHaveError*	possible_err	= new_aspell_speller(config);
	delete_aspell_config(config);

	if (aspell_error_number(possible_err) != 0) {
		NSLog(@"failed to initialize speller for language %@: %s", inLanguage, aspell_error_message(possible_err));
		delete_aspell_can_have_error(possible_err);
		return nil;
	}

	return to_aspell_speller(possible_err);
}

*/

@end
