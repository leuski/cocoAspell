// ============================================================================
//  AspellOptions.m
// ============================================================================
//
//	cocoAspell2
//
//  Created by Anton Leuski on 2/2/05.
//  Copyright (c) 2005 Anton Leuski. All rights reserved.
// ============================================================================

#import "AspellOptions.h"
#import "MutableAspellList.h"
#import "aspell_extras.h"

static NSArray*		kSuggestionsModes	= nil;
static NSString*	kFilterSetPrefix	= @"useFilter_";


NSString*	kAspellOptionsChangedNotification		= @"net.leuski.cocoaspell.OptionsChangedNotification";

@interface AspellOptions (Private)
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
	[AspellOptions setKeys:[NSArray arrayWithObject:@"sug-mode"] triggerChangeNotificationsForDependentKey:@"suggestionModeAsInt"];
	NSString*	hd	= [AspellOptions cocoAspellHomeDir];
	if (![[NSFileManager defaultManager] fileExistsAtPath:hd]) {
		[[NSFileManager defaultManager] createDirectoryAtPath:hd attributes:nil];
	}
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

+ (NSString*)cocoAspellHomeDir
{
	if (!kHomeDir) {
		kHomeDir	= [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, true) objectAtIndex:0];
		kHomeDir	= [[kHomeDir stringByAppendingPathComponent:@"Preferences"] stringByAppendingPathComponent:@"cocoAspell"];
		[kHomeDir retain];
	}
	return kHomeDir;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

+ (AspellOptions*)aspellOptionsWithAspellConfig:(AspellConfig*)inConfig
{
	return [[[AspellOptions alloc] initWithAspellConfig:inConfig] autorelease];
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
	aspellConfig				= inConfig;		
	persistent					= NO;
	[self addObserver:self forKeyPath:@"filter" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:nil];
	return self;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)dealloc
{
	[self removeObserver:self forKeyPath:@"filter"];
	delete_aspell_config(aspellConfig);
	[super dealloc];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
//	NSLog(@"observed %@ %@ %@ %@", keyPath, object, change, context);
	
	if ([keyPath isEqualToString:@"filter"]) {
		int		chFlag	= [[change objectForKey:NSKeyValueChangeKindKey] intValue];
		if (chFlag == NSKeyValueChangeSetting) {
			NSArray*		oldValue	= [change objectForKey:NSKeyValueChangeOldKey];
			NSArray*		newValue	= [change objectForKey:NSKeyValueChangeNewKey];
			NSEnumerator*	values;
			NSString*		v;
			values						= [oldValue objectEnumerator];
			while (v = [values nextObject]) {
				if (![newValue containsObject:v]) {
					v	= [kFilterSetPrefix stringByAppendingString:v];
					[self willChangeValueForKey:v];
					[self didChangeValueForKey:v];
				}
			}
			values						= [newValue objectEnumerator];
			while (v = [values nextObject]) {
				if (![oldValue containsObject:v]) {
					v	= [kFilterSetPrefix stringByAppendingString:v];
					[self willChangeValueForKey:v];
					[self didChangeValueForKey:v];
				}
			}
		}
	}
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (AspellConfig*)aspellConfig
{
	return aspellConfig;
}


// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (id)valueForKey:(NSString*)inKey
{
//	NSLog(@"%@", inKey);
	if ([inKey hasPrefix:kFilterSetPrefix]) {
		return [NSNumber numberWithBool:[self usingFilter:[inKey substringFromIndex:[kFilterSetPrefix length]]]];
	} else {
		const struct AspellKeyInfo*	ki;
		ki	= aspell_config_keyinfo([self aspellConfig], [inKey UTF8String]);
		if (!ki) {
			inKey	= [[inKey componentsSeparatedByString:@"_"] componentsJoinedByString:@"-"];
			ki	= aspell_config_keyinfo([self aspellConfig], [inKey UTF8String]);
		}
		if (ki) { 
			switch (ki->type) {
				case AspellKeyInfoInt:		return [NSNumber numberWithInt:[self intForKey:inKey]];
				case AspellKeyInfoBool:		return [NSNumber numberWithBool:[self boolForKey:inKey]];
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
		ki	= aspell_config_keyinfo([self aspellConfig], [inKey UTF8String]);
		if (!ki) {
			inKey	= [[inKey componentsSeparatedByString:@"_"] componentsJoinedByString:@"-"];
			ki	= aspell_config_keyinfo([self aspellConfig], [inKey UTF8String]);
		}
		if (ki) { 
			switch (ki->type) {
				case AspellKeyInfoInt:		[self setInt:[inValue intValue] forKey:inKey]; break;
				case AspellKeyInfoBool:		[self setBool:[inValue boolValue] forKey:inKey]; break;
				case AspellKeyInfoList:		[self setArray:inValue forKey:inKey]; break;
				case AspellKeyInfoString:	[self setString:inValue forKey:inKey]; break;
			}
			if ([self isPersistent]) {
				NSString*	to	= [self valueForKey:@"per-conf-path"];
				[self writeToFile:to];
				[self notifyOptionsChanged:to];
//				NSLog(@"write %d %@", x, to);
			}
			return;
		}
		[super setValue:inValue forKey:inKey];
	}
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSArray*)allKeys
{
	NSMutableArray*				res		= [NSMutableArray array];
	AspellKeyInfoEnumeration*	keys	= aspell_config_possible_elements([self aspellConfig], 1);
	const AspellKeyInfo*		ki;
	while (ki = aspell_key_info_enumeration_next(keys)) {
		[res addObject:[NSString stringWithUTF8String:ki->name]];
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
	unsigned	idx		= [[AspellOptions suggestionModes] indexOfObject:mode];
	if (idx == NSNotFound) idx	= 2;
	return idx;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setSuggestionModeAsInt:(int)inValue
{
	[self setValue:[[AspellOptions suggestionModes] objectAtIndex:inValue] forKey:@"sug-mode"];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (BOOL)writeToFile:(NSString*)inPath
{
	return aspell_config_write_out_file([self aspellConfig],[inPath UTF8String]);
//	return [self dumpToFile:inPath];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (BOOL)isPersistent
{
	return persistent;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setPersistent:(BOOL)newPersistent
{
    if (persistent != newPersistent) {
		persistent = newPersistent;
    }
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSDictionary*)dictionaryWithAllNondefaultValues
{
	NSMutableDictionary*			result	= [NSMutableDictionary dictionary];
	AspellStringPairEnumeration*	e		= aspell_config_elements([self aspellConfig]);
	if (!e) return result;
	AspellStringPair				p;
	while (!aspell_string_pair_enumeration_at_end(e)) {
		p = aspell_string_pair_enumeration_next(e);
		NSString*	key	= [NSString stringWithUTF8String:p.first];
		[result setObject:[self valueForKey:key] forKey:key];
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

@end

@implementation AspellOptions (Private)

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

+ (NSArray*)suggestionModes
{
	if (kSuggestionsModes == nil) {
		kSuggestionsModes	= [[NSArray alloc] initWithObjects:@"ultra", @"fast", @"normal", @"bad-spellers", nil];
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
		[self setValue:set forKey:@"filter"];
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
	aspell_config_replace([self aspellConfig], [inKey UTF8String], [inValue UTF8String]);
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
	aspell_config_replace([self aspellConfig], [inKey UTF8String], inValue ? "true" : "false");
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
	aspell_config_replace([self aspellConfig], [inKey UTF8String], buff);
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

	aspell_config_replace([self aspellConfig], [[@"clear-" stringByAppendingString:inKey] UTF8String], "");

	unsigned	i;
	const char*	add_key	= [[@"add-" stringByAppendingString:inKey] UTF8String];
	for(i = 0; i < [inValue count]; ++i) {
		aspell_config_replace([self aspellConfig], add_key, [[inValue objectAtIndex:i] UTF8String]);
	}

	[self didChangeValueForKey:inKey];
	if (altKey) [self didChangeValueForKey:altKey];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSString*)stringForKey:(NSString*)inKey
{
	return [NSString stringWithUTF8String:aspell_config_retrieve([self aspellConfig],[inKey UTF8String])];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (BOOL)boolForKey:(NSString*)inKey
{
	return aspell_config_retrieve_bool([self aspellConfig],[inKey UTF8String]) != 0;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (int)intForKey:(NSString*)inKey
{
	return aspell_config_retrieve_int([self aspellConfig],[inKey UTF8String]);
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSArray*)arrayForKey:(NSString*)inKey
{

	NSMutableArray*		arr		= [NSMutableArray array];
	AspellStringList*	lst		= new_aspell_string_list();
	aspell_config_retrieve_list(aspellConfig,[inKey UTF8String],(AspellMutableContainer*)lst);

	const char* el;
	AspellStringEnumeration * en = aspell_string_list_elements(lst);
	while (el = aspell_string_enumeration_next(en)) {
		[arr addObject:[NSMutableString stringWithUTF8String:el]];
	}
	delete_aspell_string_enumeration(en);
	delete_aspell_string_list(lst);

//	NSLog(@"get array %@ %@", inKey, arr);

	return arr;
}

@end


