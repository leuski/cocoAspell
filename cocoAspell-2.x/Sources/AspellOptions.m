// ============================================================================
//  AspellOptions.m
// ============================================================================
//
//	cocoAspell2
//
//  Created by Anton Leuski on 2/2/05.
//  Copyright (c) 2005-2008 Anton Leuski. All rights reserved.
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

#import "AspellOptions.h"
#import "MutableAspellList.h"
#import "aspell_extras.h"

static NSArray*		kSuggestionsModes	= nil;
static NSString*	kFilterSetPrefix	= @"useFilter_";


NSString*	kAspellOptionsChangedNotification		= @"net.leuski.cocoaspell.OptionsChangedNotification";

@interface AspellOptions ()

@property (nonatomic, assign) int suggestionModeAsInt;
@property (assign)	AspellConfig*		aspellConfig;

+ (NSArray*)suggestionModes;
- (BOOL)usingFilter:(NSString*)filter;
- (void)setUsing:(BOOL)inValue filter:(NSString*)filter;
@end

static NSString*	makeAltKey(NSString* inKey)
{
	NSArray*	parts	= [inKey componentsSeparatedByString:@"-"];
	if ([parts count] <= 1) 
		return nil;
	return [parts componentsJoinedByString:@"_"];
}

@interface AspellOptions (Accessors)
- (void)setString:(NSString*)inValue forKey:(NSString*)inKey;
- (void)setArray:(NSArray*)inValue forKey:(NSString*)inKey;
- (void)setBool:(BOOL)inValue forKey:(NSString*)inKey;
- (void)setInt:(int)inValue forKey:(NSString*)inKey;

- (NSString*)stringForKey:(NSString*)inKey;
- (NSArray*)arrayForKey:(NSString*)inKey;
- (BOOL)boolForKey:(NSString*)inKey;
- (int)intForKey:(NSString*)inKey;
@end

static NSString*	kHomeDir	= nil;

@implementation AspellOptions

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

+ (void)initialize
{
	NSString*	hd	= [AspellOptions cocoAspellHomeDir];
	if (![[NSFileManager defaultManager] fileExistsAtPath:hd]) {
		[[NSFileManager defaultManager] createDirectoryAtURL:[NSURL fileURLWithPath:hd isDirectory:YES] withIntermediateDirectories:YES attributes:nil error:nil]; // TODO check error
	}
}

+ (NSSet*)keyPathsForValuesAffectingSuggestionModeAsInt
{
	return [NSSet setWithObject:@"sug-mode"];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

+ (NSString*)cocoAspellHomeDir
{
	if (!kHomeDir) {
		kHomeDir	= NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, true)[0];
		kHomeDir	= [[kHomeDir stringByAppendingPathComponent:@"Preferences"] stringByAppendingPathComponent:@"cocoAspell"];
	}
	return kHomeDir;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

+ (AspellOptions*)aspellOptionsWithAspellConfig:(AspellConfig*)inConfig
{
	return [[AspellOptions alloc] initWithAspellConfig:inConfig];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (id)init
{
	return [self initWithAspellConfigNoCopy:new_aspell_config()];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (id)initWithAspellConfig:(AspellConfig*)inConfig
{
	return [self initWithAspellConfigNoCopy:aspell_config_clone(inConfig)];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (id)initWithContentOfFile:(NSString*)inPath
{
	AspellConfig*	config		= new_aspell_config();
	if (aspell_config_read_in_file(config, [inPath UTF8String])) {
		self	= [self initWithAspellConfigNoCopy:config];
	} else {
		delete_aspell_config(config);
		self	= nil;
	}
	return self;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (id)initWithAspellConfigNoCopy:(AspellConfig*)inConfig
{
	if (self = [super init]) {
		self->_aspellConfig			= inConfig;
		self.persistent				= NO;
		[self addObserver:self forKeyPath:@"filter" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:nil];
	}
	return self;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)dealloc
{
	if (self->_aspellConfig) {
		[self removeObserver:self forKeyPath:@"filter"];
		delete_aspell_config(self->_aspellConfig);
		self->_aspellConfig	= nil;
	}
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
//	NSLog(@"observed %@ %@ %@ %@", keyPath, object, change, context);
	
	if ([keyPath isEqualToString:@"filter"]) {
		int		chFlag	= [change[NSKeyValueChangeKindKey] intValue];
		if (chFlag == NSKeyValueChangeSetting) {
			NSArray*		oldValue	= change[NSKeyValueChangeOldKey];
			NSArray*		newValue	= change[NSKeyValueChangeNewKey];
			for (NSString* v in oldValue) {
				if (![newValue containsObject:v]) {
					NSString* s	= [kFilterSetPrefix stringByAppendingString:v];
					[self willChangeValueForKey:s];
					[self didChangeValueForKey:s];
				}
			}
			for (NSString* v in newValue) {
				if (![oldValue containsObject:v]) {
					NSString* s	= [kFilterSetPrefix stringByAppendingString:v];
					[self willChangeValueForKey:s];
					[self didChangeValueForKey:s];
				}
			}
		}
	}
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (id)valueForKey:(NSString*)inKey
{
//	NSLog(@"%@", inKey);
	if ([inKey hasPrefix:kFilterSetPrefix]) {
		return @([self usingFilter:[inKey substringFromIndex:[kFilterSetPrefix length]]]);
	} else {
		const struct AspellKeyInfo*	ki;
		ki	= aspell_config_keyinfo(self.aspellConfig, [inKey UTF8String]);
		if (!ki) {
			inKey	= [[inKey componentsSeparatedByString:@"_"] componentsJoinedByString:@"-"];
			ki	= aspell_config_keyinfo(self.aspellConfig, [inKey UTF8String]);
		}
		if (ki) { 
			switch (ki->type) {
				case AspellKeyInfoInt:		return @([self intForKey:inKey]);
				case AspellKeyInfoBool:		return @([self boolForKey:inKey]);
				case AspellKeyInfoList:		return [self arrayForKey:inKey];
				case AspellKeyInfoString:	return [self stringForKey:inKey];
			}
		}
		return [super valueForKey:inKey];
	}
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)notifyOptionsChanged:(NSString*)path
{
	[[NSDistributedNotificationCenter defaultCenter] 
			postNotificationName:	kAspellOptionsChangedNotification
			object: 				path
			userInfo: 				nil /* no dictionary */
			deliverImmediately: 	YES];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setValue:(id)inValue forKey:(NSString*)inKey
{
	if ([inKey hasPrefix:kFilterSetPrefix]) {
		[self setUsing:[inValue boolValue] filter:[inKey substringFromIndex:[kFilterSetPrefix length]]];
	} else {
		const struct AspellKeyInfo*	ki;
		ki	= aspell_config_keyinfo(self.aspellConfig, [inKey UTF8String]);
		if (!ki) {
			inKey	= [[inKey componentsSeparatedByString:@"_"] componentsJoinedByString:@"-"];
			ki	= aspell_config_keyinfo(self.aspellConfig, [inKey UTF8String]);
		}
		if (ki) { 
			switch (ki->type) {
				case AspellKeyInfoInt:		[self setInt:[inValue intValue] forKey:inKey]; break;
				case AspellKeyInfoBool:		[self setBool:[inValue boolValue] forKey:inKey]; break;
				case AspellKeyInfoList:		[self setArray:inValue forKey:inKey]; break;
				case AspellKeyInfoString:	[self setString:inValue forKey:inKey]; break;
			}
			if (self.persistent) {
				NSString*	to	= [self valueForKey:@"per-conf-path"];
				[self writeToFile:to];
				[self notifyOptionsChanged:to];
//				NSLog(@"write %d %@", x, to);
			}
			return;
		}
		[super setValue:inValue forKeyPath:inKey];
	}
}

- (id)objectForKeyedSubscript:(NSString*)key
{
	return [self valueForKey:key];
}

- (void)setObject:(id)obj forKeyedSubscript:(NSString*)key
{
	[self setValue:obj forKeyPath:key];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSArray*)allKeys
{
	NSMutableArray*				res		= [NSMutableArray array];
	AspellKeyInfoEnumeration*	keys	= aspell_config_possible_elements(self.aspellConfig, 1);
	const AspellKeyInfo*		ki;
	while ((ki = aspell_key_info_enumeration_next(keys))) {
		[res addObject:@(ki->name)];
	}
	delete_aspell_key_info_enumeration(keys);
	return res;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (int)suggestionModeAsInt
{
	NSString*	mode	= [self stringForKey:@"sug-mode"];
	NSUInteger	idx		= [[AspellOptions suggestionModes] indexOfObject:mode];
	if (idx == NSNotFound) idx	= 2;
	return idx;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setSuggestionModeAsInt:(int)inValue
{
	self[@"sug-mode"] = [AspellOptions suggestionModes][inValue];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (BOOL)writeToFile:(NSString*)inPath
{
	return aspell_config_write_out_file(self.aspellConfig,[inPath UTF8String]);
//	return [self dumpToFile:inPath];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSDictionary*)dictionaryWithAllNondefaultValues
{
	NSMutableDictionary*			result	= [NSMutableDictionary dictionary];
	AspellStringPairEnumeration*	e		= aspell_config_elements(self.aspellConfig);
	if (!e) return result;
	AspellStringPair				p;
	while (!aspell_string_pair_enumeration_at_end(e)) {
		p = aspell_string_pair_enumeration_next(e);
		NSString*	key	= @(p.first);
		result[key] = [self valueForKey:key];
	}
	delete_aspell_string_pair_enumeration(e);
	return result;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSString*)description
{
	return [[self dictionaryWithValuesForKeys:[self allKeys]] description];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

+ (NSArray*)suggestionModes
{
	if (kSuggestionsModes == nil) {
		kSuggestionsModes	= @[@"ultra", @"fast", @"normal", @"bad-spellers"];
	}
	return kSuggestionsModes;
}

- (BOOL)usingFilter:(NSString*)filter
{
	return [[self arrayForKey:@"filter"] indexOfObject:filter] != NSNotFound;
}

- (void)setUsing:(BOOL)inValue filter:(NSString*)filter
{
	if ([self usingFilter:filter] != inValue) {
		NSArray*	set	= [self arrayForKey:@"filter"];
		if (inValue) {
			set	= [set arrayByAddingObject:filter];
		} else {
			set = [set mutableCopy];
			[(NSMutableArray*)set removeObject:filter];
		}
		self[@"filter"] = set;
	}
}

@end

@interface NSMutableString (accessors)
- (NSString*)get;
- (void)set:(NSString*)s;
@end

@implementation NSMutableString (accessors)
- (NSString*)get
{
	return [NSString stringWithString:self];
}

- (void)set:(NSString*)s
{
	[self setString:s];
}

@end

@implementation AspellOptions (Accessors)

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setString:(NSString*)inValue forKey:(NSString*)inKey
{
	NSString*	altKey	= makeAltKey(inKey);
	if (altKey) [self willChangeValueForKey:altKey];
	[self willChangeValueForKey:inKey];
	aspell_config_replace(self.aspellConfig, [inKey UTF8String], [inValue UTF8String]);
	[self didChangeValueForKey:inKey];
	if (altKey) [self didChangeValueForKey:altKey];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setBool:(BOOL)inValue forKey:(NSString*)inKey
{
	NSString*	altKey	= makeAltKey(inKey);
	if (altKey) [self willChangeValueForKey:altKey];
	[self willChangeValueForKey:inKey];
	aspell_config_replace(self.aspellConfig, [inKey UTF8String], inValue ? "true" : "false");
	[self didChangeValueForKey:inKey];
	if (altKey) [self didChangeValueForKey:altKey];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setInt:(int)inValue forKey:(NSString*)inKey;
{
	char	buff[64];
	sprintf(buff, "%d", inValue);
	NSString*	altKey	= makeAltKey(inKey);
	if (altKey) [self willChangeValueForKey:altKey];
	[self willChangeValueForKey:inKey];
	aspell_config_replace(self.aspellConfig, [inKey UTF8String], buff);
	[self didChangeValueForKey:inKey];
	if (altKey) [self didChangeValueForKey:altKey];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------


- (void)setArray:(NSArray*)inValue forKey:(NSString*)inKey
{
//	NSLog(@"set array %@ %@", inKey, inValue);

	if (![inValue isKindOfClass:[NSArray class]]) {
		NSLog(@"attempt to set array from a non array: %@ %@", inValue, inKey);
		return;
	}

	NSString*	altKey	= makeAltKey(inKey);
	if (altKey) [self willChangeValueForKey:altKey];
	[self willChangeValueForKey:inKey];

	aspell_config_replace(self.aspellConfig, [[@"clear-" stringByAppendingString:inKey] UTF8String], "");

	NSUInteger	i;
	const char*	add_key	= [[@"add-" stringByAppendingString:inKey] UTF8String];
	for(i = 0; i < [inValue count]; ++i) {
		aspell_config_replace(self.aspellConfig, add_key, [inValue[i] UTF8String]);
	}

	[self didChangeValueForKey:inKey];
	if (altKey) [self didChangeValueForKey:altKey];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSString*)stringForKey:(NSString*)inKey
{
	return @(aspell_config_retrieve(self.aspellConfig,[inKey UTF8String]));
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (BOOL)boolForKey:(NSString*)inKey
{
	return aspell_config_retrieve_bool(self.aspellConfig,[inKey UTF8String]) != 0;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (int)intForKey:(NSString*)inKey
{
	return aspell_config_retrieve_int(self.aspellConfig,[inKey UTF8String]);
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSArray*)arrayForKey:(NSString*)inKey
{

	NSMutableArray*		arr		= [NSMutableArray array];
	AspellStringList*	lst		= new_aspell_string_list();
	aspell_config_retrieve_list(self.aspellConfig,[inKey UTF8String],(AspellMutableContainer*)lst);

	const char* el;
	AspellStringEnumeration * en = aspell_string_list_elements(lst);
	while ((el = aspell_string_enumeration_next(en))) {
		[arr addObject:[NSMutableString stringWithUTF8String:el]];
	}
	delete_aspell_string_enumeration(en);
	delete_aspell_string_list(lst);

//	NSLog(@"get array %@ %@", inKey, arr);

	return arr;
}

@end


