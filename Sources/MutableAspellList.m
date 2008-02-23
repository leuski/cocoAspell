// ============================================================================
//  MutableAspellList.m
// ============================================================================
//
//	cocoAspell2
//
//  Created by Anton Leuski on 2/6/05.
//  Copyright (c) 2005 Anton Leuski. All rights reserved.
// ============================================================================

#import "MutableAspellList.h"
#import "AspellOptions.h"
#import "UserDefaults.h"

NSString*	kMutableListPrefix	= @"mutable_";

@interface StringController (Private)
- (void)assignUniqueValue:(MutableAspellList*)list;
- (NSError*)makeErrorRecord:(NSString*)key;
@end

@interface MutableAspellList (Private)
- (void)reloadData;
- (void)dataChanged;
- (void)setOptions:(AspellOptions *)newOptions;
- (void)setKey:(NSString *)newKey;
- (unsigned)indexOfObject:(id)inObject;

@end

@implementation MutableAspellList

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (id)initWithAspellOptions:(AspellOptions*)inOptions key:(NSString*)inKey controllerClass:(Class)inControllerClass
{
	if (self = [super init]) {
		[self setKey:inKey];
		[self setOptions:inOptions];
		objects	= [[NSMutableArray alloc] init];
		controllerClass	= inControllerClass;
		
		[self reloadData];
		
	}
	return self;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)dealloc
{
	[objects release];
	objects	= nil;
	[self setKey:nil];
	[self setOptions:nil];
	[super dealloc];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSString*)dataKey
{
	return [[self key] substringFromIndex:[kMutableListPrefix length]];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)reloadData
{
	NSArray*	data	= [[self options] valueForKey:[self dataKey]];
	unsigned	i;
	
	[self willChangeValueForKey:@"objects"];
	[objects removeAllObjects];
	for(i = 0; i < [data count]; ++i) {
		[objects addObject:[[[controllerClass alloc] initWithAspellList:self value:[data objectAtIndex:i]] autorelease]];
	}
	[self didChangeValueForKey:@"objects"];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (AspellOptions *)options
{
	return [[options retain] autorelease];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setOptions:(AspellOptions *)newOptions
{
	options	= newOptions;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSString *)key
{
	return [[key retain] autorelease];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setKey:(NSString *)newKey
{
    if (key != newKey) {
		[key release];
		key = [newKey copy];
    }
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (unsigned int)countOfObjects
{
	return [objects count];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (id)objectInObjectsAtIndex:(unsigned int)inIndex
{
	return [objects objectAtIndex:inIndex];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)getObjects:(id*)inBuffer range:(NSRange)inRange
{
	[objects getObjects:inBuffer range:inRange];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)insertObject:(id)inObject inObjectsAtIndex:(unsigned int)inIndex
{
	if ([inObject array] != nil) {
		NSLog(@"attemptng to insert the same object into multiple lists");
		return;
	}
	[inObject assignUniqueValue:self];
	[objects insertObject:inObject atIndex:inIndex];
	[(StringController*)inObject setArray:self]; 
	[self dataChanged];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)removeObjectFromObjectsAtIndex:(unsigned int)inIndex
{
	[(StringController*)[self objectInObjectsAtIndex:inIndex] setArray:nil]; 
	[objects removeObjectAtIndex:inIndex];
	[self dataChanged];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)replaceObjectInObjectsAtIndex:(unsigned int)inIndex withObject:(id)inObject
{
	if ([inObject array] != nil) {
		NSLog(@"attemptng to insert the same object into multiple lists");
		return;
	}
	[(StringController*)[self objectInObjectsAtIndex:inIndex] setArray:nil]; 
	[inObject assignUniqueValue:self];
	[objects replaceObjectAtIndex:inIndex withObject:inObject];
	[(StringController*)inObject setArray:self]; 
	[self dataChanged];
}

- (void)dataChanged
{
	[[self options] setValue:[self valueForKeyPath:@"objects.@unionOfObjects.value"] 
		forKey:[self dataKey]];
}

@end


@implementation StringController

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (id)initWithAspellList:(MutableAspellList*)inArray value:(NSString*)inValue;
{
	if (self = [super init]) {
		[self setValue:inValue];
		[self setArray:inArray];
	}
	return self;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)dealloc
{
	[self setArray:nil];
	[self setValue:nil];
	[super dealloc];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSString*)description
{
	return [self value];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSString *)value
{
	return [[value retain] autorelease];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setValue:(NSString *)newValue
{
    if (value ? ![value isEqualToString:newValue] : value != newValue) {
		[value release];
		value = [newValue copy];
//		NSLog(@"new value: %@", newValue);
		[[self array] dataChanged];
    }
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (MutableAspellList *)array
{
	return array;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setArray:(MutableAspellList *)newArray
{
	array = newArray;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSError*)makeErrorRecord:(NSString*)key
{
	NSString*		errorString		= LocalizedString(key, nil);
	NSDictionary*	userInfoDict	= [NSDictionary dictionaryWithObject:errorString forKey:NSLocalizedDescriptionKey];
	NSError*		error			= [[[NSError alloc] initWithDomain:kDefaultsDomain
										code:0
										userInfo:userInfoDict] autorelease];
	return error;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (BOOL)list:(MutableAspellList*)list hasObject:(NSString*)val 
{
	unsigned	i, n	= [list countOfObjects];
	for(i = 0; i < n; ++i) {
		StringController*	sc	= [list objectInObjectsAtIndex:i];
		if ([val isEqualToString:[sc value]] && sc != self && [sc array]) {
			return YES;
		}
	}
	return NO;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

-(BOOL)validateValue:(id *)ioValue error:(NSError **)outError
{
	if (![self array]) return YES;
	NSString*	val		= [*ioValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if ([val length] == 0) {
		*outError	= [self makeErrorRecord:@"keyErrorEmptyEntry"];
		return NO;
	}
	if ([self list:[self array] hasObject:val]) {
		*outError	= [self makeErrorRecord:@"keyErrorDuplicateEntry"];
		return NO;
	}
	
	*ioValue	= val;
	return YES;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)assignUniqueValue:(MutableAspellList*)list 
{
	NSString*	val		= [[self value] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if ([val length] == 0)
		val	= LocalizedString(@"keyUnknownString", nil);
	unsigned	i;
	NSString*	orgVal	= val;
	for(i = 0; ; ++i) {
		if (![self list:list hasObject:val]) {
			[self setValue:val];
			return;
		}
		val	= [NSString stringWithFormat:LocalizedString(@"keyCopyString", nil), orgVal, i+1];
	}
}

@end

static NSString*	kCheckArg;
static NSString*	kCheckOpt;
static NSArray*		kCheckFSA;

@implementation TeXCommandController

+ (void)initialize 
{
	kCheckArg	= [[NSString alloc] initWithFormat:@"{%C}", 0x221a];
	kCheckOpt	= [[NSString alloc] initWithFormat:@"[%C]", 0x221a];
	kCheckFSA	= [[NSArray alloc] initWithObjects:
		@"[1{2", 
		[NSString stringWithFormat:@"%C3]5", 0x221a], 
		[NSString stringWithFormat:@"%C4}6", 0x221a], 
		@"]7", @"}8", @"o", @"p", @"O", @"P", nil];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSString*)argumentsFromInternalRepresentation:(NSString*)arg 
{
	arg	= [[arg componentsSeparatedByString:@"o"] componentsJoinedByString:@"[]"];
	arg	= [[arg componentsSeparatedByString:@"O"] componentsJoinedByString:kCheckOpt];
	arg	= [[arg componentsSeparatedByString:@"p"] componentsJoinedByString:@"{}"];
	arg	= [[arg componentsSeparatedByString:@"P"] componentsJoinedByString:kCheckArg];
	return arg;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSString*)argumentsToInternalRepresentation:(NSString*)arg error:(NSString**)outError
{
	NSMutableString*	res				= [NSMutableString string];
	unsigned			i, j, state		= 0;
	NSCharacterSet*		whitespace		= [NSCharacterSet whitespaceCharacterSet];
	for(i = 0; i < [arg length]; ++i) {
		unichar		ch	= [arg characterAtIndex:i];
		if ([whitespace characterIsMember:ch]) continue;
		NSString*	rule	= [kCheckFSA objectAtIndex:state];
		for(j = 0; j < [rule length]; j += 2) {
			if (ch == [rule characterAtIndex:j]) {
				state = [rule characterAtIndex:j+1]-'0';
				break;
			}
		}
		if (j >= [rule length]) {
			if (outError) {
				if ([rule length] > 2) {
					*outError	= [NSString stringWithFormat:LocalizedString(@"keyErrorTeXParamUnexpected2",nil), i, ch, [rule characterAtIndex:0], [rule characterAtIndex:2]];
				} else {
					*outError	= [NSString stringWithFormat:LocalizedString(@"keyErrorTeXParamUnexpected1",nil), i, ch, [rule characterAtIndex:0]];
				}
			}
			return nil;
		}
		if (state >= 5) {
			[res appendString:[kCheckFSA objectAtIndex:state]];
			state	= 0;
		}
	}
	if (state != 0) {
		NSString*	rule	= [kCheckFSA objectAtIndex:state];
		if (outError) {
			if ([rule length] > 2) {
				*outError	= [NSString stringWithFormat:LocalizedString(@"keyErrorTeXParamUnexpectedEOL2",nil), i, [rule characterAtIndex:0], [rule characterAtIndex:2]];
			} else {
				*outError	= [NSString stringWithFormat:LocalizedString(@"keyErrorTeXParamUnexpectedEOL1",nil), i, [rule characterAtIndex:0]];
			}
		}
		return nil;
	}
	
	return res;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSString *)commandInternal
{
	NSArray*	parts	= [[self value] componentsSeparatedByString:@" "];
	if ([parts count] <= 1)
		return [self value];
	parts	= [parts subarrayWithRange:NSMakeRange(0,[parts count]-1)];
	return [parts componentsJoinedByString:@" "];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSString *)argumentsInternal
{
	NSArray*	parts	= [[self value] componentsSeparatedByString:@" "];
	if ([parts count] <= 1)
		return @"";
	return [parts lastObject];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setValueWithCommand:(NSString*)c arguments:(NSString*)a
{
	[self setValue:[NSString stringWithFormat:@"%@ %@", c, a]];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSString *)command
{
	return [self commandInternal];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setCommand:(NSString *)newCommand
{
	[self setValueWithCommand:newCommand arguments:[self argumentsInternal]];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (NSString *)arguments
{
	return [self argumentsFromInternalRepresentation:[self argumentsInternal]];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)setArguments:(NSString *)newArguments
{
	NSString*	res	= [self argumentsToInternalRepresentation:newArguments error:nil];
	if (res)
		[self setValueWithCommand:[self commandInternal] arguments:res];
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (BOOL)list:(MutableAspellList*)list hasObject:(NSString*)val 
{
	unsigned	i, n	= [list countOfObjects];
	for(i = 0; i < n; ++i) {
		TeXCommandController*	sc	= [list objectInObjectsAtIndex:i];
		if ([val isEqualToString:[sc command]] && sc != self && [sc array]) {
			return YES;
		}
	}
	return NO;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (BOOL)validateCommand:(id *)ioValue error:(NSError **)outError
{
	if (![self array]) return YES;
	NSString*	val		= [*ioValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if ([val length] == 0) {
		*outError	= [self makeErrorRecord:@"keyErrorEmptyEntry"];
		return NO;
	}
	if ([self list:[self array] hasObject:val]) {
		*outError	= [self makeErrorRecord:@"keyErrorDuplicateEntry"];
		return NO;
	}
	
	*ioValue	= val;
	return YES;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

-(BOOL)validateArguments:(id *)ioValue error:(NSError **)outError
{
	NSString*	errMessage;
	NSString*	val		= [self argumentsToInternalRepresentation:*ioValue error:&errMessage];
	if (val) {
		return YES;
	}
	
	*outError		= [[[NSError alloc] initWithDomain:kDefaultsDomain
						code:0
						userInfo:[NSDictionary dictionaryWithObject:errMessage forKey:NSLocalizedDescriptionKey]] autorelease];
	
	
	return NO;
}

// ----------------------------------------------------------------------------
//	
// ----------------------------------------------------------------------------

- (void)assignUniqueValue:(MutableAspellList*)list 
{
	NSString*	val		= [[self commandInternal] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if ([val length] == 0)
		val	= LocalizedString(@"keyUnknownString", nil);
	unsigned	i;
	NSString*	orgVal	= val;
	for(i = 0; ; ++i) {
		if (![self list:list hasObject:val]) {
			[self setValueWithCommand:val arguments:@"o"];
			return;
		}
		val	= [NSString stringWithFormat:LocalizedString(@"keyCopyString", nil), orgVal, i+1];
	}
}

@end

