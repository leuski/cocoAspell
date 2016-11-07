//
//  clip_int.c
//  cocoAspell2
//
//  Created by Anton Leuski on 11/6/16.
//
//

#include "clip_int.h"
#include <limits.h>

int CLIP_TO_INT(unsigned long size)
{
  return size >= INT_MAX ? INT_MAX : (int)size;
}

unsigned int CLIP_TO_UINT(unsigned long size)
{
  return size >= UINT_MAX ? UINT_MAX : (unsigned int)size;
}
