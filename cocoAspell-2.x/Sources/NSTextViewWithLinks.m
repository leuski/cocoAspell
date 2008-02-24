// ================================================================================
//  NSTextViewWithLinks.m
// ================================================================================
//	cocoAspell
//
//  Created by Anton Leuski on Wed Feb 13 2003.
//  Copyright (c) 2003-2008 Anton Leuski.
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


#import "NSTextViewWithLinks.h"


//	Informal protocol for extending NSTextView's delegate
@interface NSObject (NSTextViewWithLinks_Delegate)
- (NSCursor *) cursorForLink: (NSObject *) linkObject
    atIndex: (unsigned) charIndex
    ofTextView: (NSTextView *) aTextView;
@end



@implementation NSTextViewWithLinks

#pragma mark PRIVATE CLASS METHODS

+ (NSCursor *) fingerCursor;			// really should be in a category on NSCursor
{
    static NSCursor	*fingerCursor = nil;

    if (fingerCursor == nil)
    {
        fingerCursor = [[NSCursor alloc] initWithImage: [NSImage imageNamed: @"fingerCursor"]
            hotSpot: NSMakePoint (0, 0)];
		
		if (!fingerCursor) {
			fingerCursor	= [NSCursor arrowCursor];
		}
    }

    return fingerCursor;
}


#pragma mark PUBLIC CLASS METHODS -- NSObject OVERRIDES

//	Make all NSTextView instances into instances of this class, even if we didn't create them.
//	(We could instead selectively make some instances in nib files belong to this class,
//	 but then it's hard to enter the initial text using Interface Builder.)
//+ (void) load
//{
//    [self poseAsClass: [self superclass]];
//}
//

#pragma mark PRIVATE INSTANCE METHODS

- (NSCursor *) cursorForLink: (NSObject *) linkObject
    atIndex: (unsigned) charIndex
{
    NSCursor 	*result = nil;

    //	If the delegate implements the method, consult it.
    if ([[self delegate] respondsToSelector: @selector(cursorForLink:atIndex:ofTextView:)])
        result = [[self delegate] cursorForLink: linkObject  atIndex: charIndex  ofTextView: self];

    //	If the delegate didn't implement it, or it did but returned nil, substitute a guess.
    if (result == nil)
        result = [NSCursor pointingHandCursor];

    return result;
}


#pragma mark PUBLIC INSTANCE METHODS -- NSView OVERRIDES

- (void) resetCursorRects
{
    NSAttributedString	*attrString;
    NSPoint				containerOrigin;
    NSRect				visRect;
    NSRange				visibleGlyphRange, visibleCharRange, attrsRange;

    //	Get the attributed text inside us
    attrString = [self textStorage];

    //	Figure what part of us is visible (we're typically inside a scrollview)
    containerOrigin = [self textContainerOrigin];
    visRect = NSOffsetRect ([self visibleRect], -containerOrigin.x, -containerOrigin.y);

    //	Figure the range of characters which is visible
    visibleGlyphRange = [[self layoutManager] glyphRangeForBoundingRect:visRect inTextContainer:[self textContainer]];
    visibleCharRange = [[self layoutManager] characterRangeForGlyphRange:visibleGlyphRange actualGlyphRange:NULL];

    //	Prime for the loop
    attrsRange = NSMakeRange (visibleCharRange.location, 0);


    //	Loop until we reach the end of the visible range of characters
    while (NSMaxRange(attrsRange) < NSMaxRange(visibleCharRange)) // find all visible URLs and set up cursor rects
    {
        NSString *linkObject;

        //	Find the next link inside the range
        linkObject = [attrString attribute: NSLinkAttributeName 
            atIndex: NSMaxRange(attrsRange)
            effectiveRange: &attrsRange];

        if (linkObject != nil)
        {
            NSCursor		*cursor;
            NSRectArray		rects;
            unsigned int	rectCount, rectIndex;
            NSRect			oneRect;

            //	Figure what cursor to show over this link.
            cursor = [self cursorForLink: linkObject  atIndex: attrsRange.location];

            //	Find the rectangles where this range falls. (We could use -boundingRectForGlyphRange:...,
            //	but that gives a single rectangle, which might be overly large when a link runs
            //	through more than one line.)
            rects = [[self layoutManager] rectArrayForCharacterRange: attrsRange
                withinSelectedCharacterRange: NSMakeRange (NSNotFound, 0)
                inTextContainer: [self textContainer]
                rectCount: &rectCount];

            //	For each rectangle, find its visible portion and ask for the cursor to appear
            //	when they're over that rectangle.
            for (rectIndex = 0; rectIndex < rectCount; rectIndex++)
            {
                oneRect = NSIntersectionRect (rects[rectIndex], [self visibleRect]);
                [self addCursorRect: oneRect  cursor: cursor];
//				NSLog(@"%@", NSStringFromRect(oneRect));
            }
       }
    }

//	[self addCursorRect: [self visibleRect]  cursor: [NSCursor arrowCursor]];
}

@end

