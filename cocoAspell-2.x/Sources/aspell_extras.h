// ============================================================================
//  aspell_extras.h
// ============================================================================
//
//	cocoAspell2
//
//  Created by Anton Leuski on 2/12/05.
//  Copyright (c) 2005 Anton Leuski. All rights reserved.
// ============================================================================

#ifndef __aspell_extras__
#define __aspell_extras__

#include "aspell.h"

#ifdef __cplusplus
extern "C" {
#endif

int aspell_config_read_in_file(struct AspellConfig * ths, const char * file_name);
int aspell_config_write_out_file(struct AspellConfig * ths, const char * file_name);
int aspell_config_merge(struct AspellConfig * ths, const struct AspellConfig * other);

#ifdef __cplusplus
}
#endif
#endif /* __aspell_extras__ */
