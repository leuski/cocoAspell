// ================================================================================
//  ProcessInfo.m
// ================================================================================
//  cocoAspell
//
//  Created by Anton Leuski on Tue May 21 2002.
//  Copyright (c) 2002-2004 Anton Leuski. All rights reserved.
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

#import "ProcessInfo.h"

#include <sys/types.h>
#include <unistd.h>

// Returns a list of all BSD processes on the system.  This routine
// allocates the list and puts it in *procList and a count of the
// number of entries in *procCount.  You are responsible for freeing
// this list (use "free" from System framework).
// On success, the function returns 0.
// On error, the function returns a BSD errno value.

static int 
GetBSDProcessList(
	kinfo_proc**	procList, 
	size_t*			procCount,
	int				onlyUser)	
{
    int                 err;
    kinfo_proc *        result;
    bool                done;
	int					name[]		= { CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0 };
	size_t				nameSize	= 3;
    // Declaring name as const requires us to cast it when passing it to
    // sysctl because the prototype doesn't include the const modifier.
    size_t              length;

    assert( procList != NULL);
    assert(*procList == NULL);
    assert(procCount != NULL);

	if (onlyUser) {
		name[2]		=   KERN_PROC_RUID;
		name[3]		=   getuid();
		nameSize	= 4;
	}

    *procCount = 0;

    // We start by calling sysctl with result == NULL and length == 0.
    // That will succeed, and set length to the appropriate length.
    // We then allocate a buffer of that size and call sysctl again
    // with that buffer.  If that succeeds, we're done.  If that fails
    // with ENOMEM, we have to throw away our buffer and loop.  Note
    // that the loop causes use to call sysctl with NULL again; this
    // is necessary because the ENOMEM failure case sets length to
    // the amount of data returned, not the amount of data that
    // could have been returned.

    result = NULL;
    done = false;
    do {
        assert(result == NULL);

        // Call sysctl with a NULL buffer.

        length = 0;
        err = sysctl( (int *) name, nameSize,
                      NULL, &length,
                      NULL, 0);
        if (err == -1) {
            err = errno;
        }

        // Allocate an appropriately sized buffer based on the results
        // from the previous call.

        if (err == 0) {
            result = malloc(length);
            if (result == NULL) {
                err = ENOMEM;
            }
        }

        // Call sysctl again with the new buffer.  If we get an ENOMEM
        // error, toss away our buffer and start again.

        if (err == 0) {
            err = sysctl( (int *) name, nameSize,
                          result, &length,
                          NULL, 0);
            if (err == -1) {
                err = errno;
            }
            if (err == 0) {
                done = true;
            } else if (err == ENOMEM) {
                assert(result != NULL);
                free(result);
                result = NULL;
                err = 0;
            }
        }
    } while (err == 0 && ! done);

    // Clean up and establish post conditions.

    if (err != 0 && result != NULL) {
        free(result);
        result = NULL;
    }
    *procList = result;
    if (err == 0) {
        *procCount = length / sizeof(kinfo_proc);
    }

    assert( (err == 0) == (*procList != NULL) );

    return err;
}

// --------------------------------------------------------------------------------
//
// --------------------------------------------------------------------------------


@implementation ProcessInfo

// --------------------------------------------------------------------------------
//
// --------------------------------------------------------------------------------

- (id)initWithKInfo:(kinfo_proc*)inProc
{
	self = [super init];
	if (self) {
		mData = *inProc;
	}
	return self;
}

// --------------------------------------------------------------------------------
//
// --------------------------------------------------------------------------------

- (NSString *)processName
{
	return [NSString stringWithCString:mData.kp_proc.p_comm];
}

// --------------------------------------------------------------------------------
//
// --------------------------------------------------------------------------------

+ (ProcessInfo*)processWithName:(NSString*)inName
{
	ProcessInfo*		p;
	ProcessIterator*	i   = [ProcessIterator iterator];
	while ([i hasNext]) {
		p   = [i next];
		if ([inName isEqualToString:[p processName]])
			return p;
	}
	return nil;
}

// --------------------------------------------------------------------------------
//
// --------------------------------------------------------------------------------

- (pid_t)processIdentifier
{
	return mData.kp_proc.p_pid;
}

// --------------------------------------------------------------------------------
//
// --------------------------------------------------------------------------------

- (NSBundle*)processBundle
{
	FSRef				ref;
	UInt8				path[4001];
	ProcessSerialNumber psn;
	
	GetProcessForPID([self processIdentifier], &psn);
	GetProcessBundleLocation(&psn, &ref);
	FSRefMakePath(&ref, path, 4000);
	return [[[NSBundle alloc] initWithPath:[NSString stringWithCString:path]] autorelease];
}

// --------------------------------------------------------------------------------
//
// --------------------------------------------------------------------------------

- (int)kill:(int)s
{
	return kill(mData.kp_proc.p_pid, s);
}

// --------------------------------------------------------------------------------
//
// --------------------------------------------------------------------------------

- (int)kill
{
	return [self kill:SIGKILL];
}

@end

// --------------------------------------------------------------------------------
//
// --------------------------------------------------------------------------------

@implementation ProcessIterator 

+ (ProcessIterator*)iterator
{
	return [[[ProcessIterator alloc] init] autorelease];
}

// --------------------------------------------------------------------------------
//
// --------------------------------------------------------------------------------

- (id)init
{
	GetBSDProcessList(&mProcesses, &mCount, 1);
	mIndex  = 0;
	return self;
}

// --------------------------------------------------------------------------------
//
// --------------------------------------------------------------------------------

- (BOOL)hasNext
{
	return mIndex < mCount;
}

// --------------------------------------------------------------------------------
//
// --------------------------------------------------------------------------------

- (ProcessInfo*)next
{
	if (mIndex >= mCount) return nil;
	ProcessInfo*		p   = [[[ProcessInfo alloc] initWithKInfo:&mProcesses[mIndex]] autorelease];
	++mIndex;	
//	NSLog(@"%ld %@", [p processIdentifier], [p processName]);
	return p;
}

// --------------------------------------------------------------------------------
//
// --------------------------------------------------------------------------------

- (void)dealloc 
{
	free(mProcesses);
	[super dealloc];
}

@end


