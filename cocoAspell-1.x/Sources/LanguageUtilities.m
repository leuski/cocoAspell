// ================================================================================
//  LanguageUtilities.m
// ================================================================================
//	cocoAspell
//
//  Created by Anton Leuski on Sun Mar 17 2002.
//  Copyright (c) 2002-2004 Anton Leuski.
//
//	This file is part of cocoAspell package.
//
//	Redistribution and use of cocoAspell in source and binary forms, with or without 
//	modification, are permitted provided that the following conditions are met:
//
//	1. Redistributions of source code must retain the above copyright notice, this 
//		list of conditions and the following disclaimer.
//	2. Redistributions in binary form must reproduce the above copyright notice, 
//		this list of conditions and the following disclaimer in the documentation 
//		and/or other materials provided with the distribution.
//	3. The name of the author may not be used to endorse or promote products derived 
//		from this software without specific prior written permission.
//
//	THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED 
//	WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
//	MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT 
//	SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
//	EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT 
//	OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
//	INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, 
//	STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY 
//	OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// ================================================================================

#import "LanguageUtilities.h"
#import <CoreServices/CoreServices.h>

static NSString*		kNotFound 		= @"<<NotFound>>";
static NSDictionary*	sLocaleNames	= nil;

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------
// a workaround for yet another apple's bug:
//	the AppleLanguages array contains language name instead of language codes,
//	for example: 'English' instead of 'en'.

static NSString*
fixLocalizationName(
	NSString*	inName)
{
	if ( ([inName length] == 2) || ( ([inName length] == 5) && ([inName characterAtIndex:2] == '_') ) )
		return inName;

	if (!sLocaleNames) {
		sLocaleNames = [[NSDictionary alloc] initWithObjectsAndKeys:
			@"en", @"English", 
			@"jp", @"Japanese", 
			@"fr", @"French", 
			@"de", @"German", 
			@"es", @"Spanish", 
			@"it", @"Italian", 
			@"nl", @"Dutch", 
			nil];
	}
	
	{
		NSString*	code = [sLocaleNames objectForKey:inName];
		if (code)
			return code;
	}
	
	return inName;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

static int
getSystemLanguageName(
	NSString*	key,
	NSString*	localization,
	NSString**	outString)
{
	UniChar			buffer[64];
	UniCharCount	actualNameLen;
	LocaleRef		locale;
	LocaleRef		displayLocale 	= NULL;
	OSStatus		status;

	status	= LocaleRefFromLocaleString([key cString], &locale);
	if (status != 0) {
		return status;
	}
	
//	displayLocale   = locale;
	if (localization) {
		localization 	= fixLocalizationName(localization);
		status			= LocaleRefFromLocaleString([localization cString], &displayLocale);
		if (status != 0)
			return status;
	}

	status	= LocaleGetName(locale, 0, 
		kLocaleNameMask, 
		displayLocale, 64, &actualNameLen, buffer);
	
	*outString = [NSString stringWithCharacters:buffer length:actualNameLen];

	return status;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

static NSString*
makeName(
	NSString*	lang,
	NSString*	region,
	NSString*	spelling,
	NSString*	jargon)
{
	if (region && ([region length] == 0))
		region = nil;
	if (spelling && ([spelling length] == 0))
		spelling = nil;
	if (jargon && ([jargon length] == 0))
		jargon = nil;
		
	if (region && spelling && jargon) 
		return [NSString stringWithFormat:@"%@ (%@, %@, %@)", lang, region, spelling, jargon];
	if (region && spelling) 
		return [NSString stringWithFormat:@"%@ (%@, %@)", lang, region, spelling];
	if (region && jargon) 
		return [NSString stringWithFormat:@"%@ (%@, %@)", lang, region, jargon];
	if (spelling && jargon) 
		return [NSString stringWithFormat:@"%@ (%@, %@)", lang, spelling, jargon];
	if (region) 
		return [NSString stringWithFormat:@"%@ (%@)", lang, region];
	if (spelling) 
		return [NSString stringWithFormat:@"%@ (%@)", lang, spelling];
	if (jargon) 
		return [NSString stringWithFormat:@"%@ (%@)", lang, jargon];

	return [NSString stringWithString:lang];
}

@implementation LanguageUtilities

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------
// this is used to register the dictionary with the system. Ideally we use the code
//  and let the system to name the dictionary...

+ (NSString*)appleDictionaryNameWithLanguageCode:(NSString*)code 
	spelling:	(NSString*)spelling
	jargon:		(NSString*)jargon
{
//	if ((spelling && ([spelling length] > 0)) || (jargon && ([jargon length] > 0))) 
		return [[self class] localizedDictionaryNameWithLanguageCode:code spelling:spelling jargon:jargon];
//	return code;
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

+ (NSString*)localizedDictionaryNameWithLanguageCode:(NSString*)code 
	spelling:	(NSString*)spelling
	jargon:		(NSString*)jargon
{
/*
	NSString*   names[]		= { @"en_CA", @"en_GB", @"en_US", @"en", @"br", 
								@"ca", @"cs", @"da", @"nl", @"de", @"de_DE", 
								@"de_CH", @"eo", @"es", @"fo", @"fr", @"fr_FR", 
								@"fr_CH", @"it", @"no", @"pl", @"pt", @"pt_PT", 
								@"pt_BR", @"ru", @"sv", @"uk", nil};
	NSString**   n;

	for(n = names; *n; ++n) {
		NSString*	l;
		int			s   = getSystemLanguageName(*n, nil, &l);
		NSLog(@"%@ %d %@", *n, s, l);
	}
*/

	//  step 1. check exceptions in our resources
	NSString*	dict_name 	= [code stringByAppendingFormat:@"-%@-%@", (spelling ? spelling : @""), (jargon ? jargon : @"")];
	NSString*	name 		= [[NSBundle bundleForClass:[self class]] localizedStringForKey:dict_name value:kNotFound table:@"Languages"];
	NSBundle*   intlResources;
	
	if (name != kNotFound)
		return name;

	//  step 2. check the resource file in the system private framework
	intlResources   = [NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/IntlPreferences.framework"];
	if (intlResources) {
		name  = [intlResources localizedStringForKey:code value:kNotFound table:@"Language"];
		if (name != kNotFound)
			return makeName(name, nil, spelling, jargon);
	}

	//  step 3. try the system api for language names
	if (0 == getSystemLanguageName(code, code, &name))
		return makeName(name, nil, spelling, jargon);

	name 		= [[NSBundle bundleForClass:[self class]] localizedStringForKey:code value:kNotFound table:@"Languages"];
	if (name != kNotFound)
		return makeName(name, nil, spelling, jargon);

	//  fallback: just use the code
	return makeName(code, nil, spelling, jargon);
}

// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------

+ (NSString*)dictionaryIdentifierWithLanguageCode:(NSString*)code 
	spelling:	(NSString*)spelling 
	jargon:		(NSString*)jargon
{
	return [NSString stringWithFormat:@"%@-%@-%@", code, (spelling ? spelling : @""), (jargon ? jargon : @"")];
}


@end
















