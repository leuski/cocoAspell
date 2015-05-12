// ============================================================================
//  aspell_extras.cpp
// ============================================================================
//
//	cocoAspell2
//
//  Created by Anton Leuski on 2/12/05.
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

#include "aspell_extras.h"

#include "fstream.hpp"
#include "config.hpp"
#include "error.hpp"
#include "posib_err.hpp"
#include "string.hpp"
#include "speller.hpp"

#include "stack_ptr.hpp"
#include "convert.hpp"
#include "tokenizer.hpp"
#include "document_checker.hpp"

namespace acommon {

static int aspell_config_read_in_file(Config * ths, const char * file_name)
{
	PosibErr<void>	ret	= ths->read_in_file(file_name);
	ths->err_.reset(ret.release_err());
	if (ths->err_ != 0) return 0;
	return 1;
}

static int aspell_config_write_out_file(Config * ths, const char * file_name)
{
    FStream out;
	PosibErr<void>	ret	= out.open(file_name, "w");
	ths->err_.reset(ret.release_err());
	if (ths->err_ != 0) return 0;
    ths->write_to_stream(out, true);
	return 1;
}

static int aspell_config_merge(Config * ths, const Config * other)
{
	PosibErr<void>	ret	= ths->merge(*other);
	ths->err_.reset(ret.release_err());
	if (ths->err_ != 0) return 0;
	return 1;
}

}

extern "C" int aspell_config_read_in_file(struct AspellConfig * ths, const char * file_name)
{
	return acommon::aspell_config_read_in_file(reinterpret_cast<acommon::Config*>(ths), file_name);
}

extern "C" int aspell_config_write_out_file(struct AspellConfig * ths, const char * file_name)
{
	return acommon::aspell_config_write_out_file(reinterpret_cast<acommon::Config*>(ths), file_name);
}

extern "C" int aspell_config_merge(struct AspellConfig * ths, const struct AspellConfig * other)
{
	return acommon::aspell_config_merge(reinterpret_cast<acommon::Config*>(ths), reinterpret_cast<const acommon::Config*>(other));
}