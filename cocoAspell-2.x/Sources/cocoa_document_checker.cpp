// ============================================================================
//  cocoa_document_checker.cpp
// ============================================================================
//
//	cocoAspell2
//
//  Created by Anton Leuski on 2/15/05.
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

#include "cocoa_document_checker.h"

#include "tokenizer.hpp"
#include "convert.hpp"
#include "speller.hpp"
#include "config.hpp"
#include "data.hpp"

namespace acommon {

CocoaDocumentChecker::CocoaDocumentChecker() 
	: speller_(0) 
{
}

CocoaDocumentChecker::~CocoaDocumentChecker() 
{
}

PosibErr<void> CocoaDocumentChecker::setup(Tokenizer * tokenizer, Speller * speller, Filter * filter)
{
	tokenizer_.reset(tokenizer);
	filter_.reset(filter);
	speller_ = speller;
	conv_ = speller->to_internal_;
	return no_err;
}

void CocoaDocumentChecker::reset()
{
	if (filter_)
		filter_->reset();
}

void CocoaDocumentChecker::process(const char * str, int size)
{
	proc_str_.clear();
	conv_->decode(str, size, proc_str_);
	proc_str_.append(0);
	FilterChar * begin = proc_str_.pbegin();
	FilterChar * end   = proc_str_.pend() - 1;
	if (filter_)
		filter_->process(begin, end);
	tokenizer_->reset(begin, end);
}

Token CocoaDocumentChecker::next_misspelling(int * ioWordCount)
{
	bool correct;
	Token tok;
	*ioWordCount	= 0;
	do {
		if (!tokenizer_->advance()) {
			tok.offset = proc_str_.size();
			tok.len = 0;
			return tok;
		}
		++(*ioWordCount);
		correct = speller_->check(MutableString(tokenizer_->word.data(), tokenizer_->word.size() - 1));
		tok.len  = tokenizer_->end_pos - tokenizer_->begin_pos;
		tok.offset = tokenizer_->begin_pos;
	} while (correct);
	return tok;
}

void CocoaDocumentChecker::count_words(int * ioWordCount)
{
	*ioWordCount	= 0;
	while (tokenizer_->advance()) {
		++(*ioWordCount);
	}
}

PosibErr<CocoaDocumentChecker *> new_cocoa_document_checker(Speller * speller)
{
	StackPtr<CocoaDocumentChecker> checker(new CocoaDocumentChecker());
	Tokenizer * tokenizer = new_tokenizer(speller);
	StackPtr<Filter> filter(new Filter);
	setup_filter(*filter, speller->config(), true, true, false);
	RET_ON_ERR(checker->setup(tokenizer, speller, filter.release()));
	return checker.release();
}

static int aspell_speller_check_spelling(Speller * speller, const char * textData,
	int textSize, int * wordCount, int countOnly, unsigned int * offset, unsigned  int * length)
{
	PosibErr<CocoaDocumentChecker *> ret = new_cocoa_document_checker(speller);
	if (ret.has_err()) {
		speller->err_.reset(ret.release_err());
		return 0;
	}

	CocoaDocumentChecker *	checker	= static_cast<CocoaDocumentChecker *>(ret);
	checker->process(textData, textSize);
	if (countOnly) {
		checker->count_words(wordCount);
		*length		= 0;
		*offset		= textSize;
	} else {
		Token	t	= checker->next_misspelling(wordCount);
		*offset		= t.offset;
		*length		= t.len;
	}

	delete checker;
	
	return 1;
}
	
static int aspell_speller_remove_from_personal(Speller * ths, const char * word, int word_size)
{
//	ths->temp_str_0.clear();
//	ths->to_internal_->convert(word, word_size, ths->temp_str_0);
//	unsigned int s0 = ths->temp_str_0.size();
//	PosibErr<void> ret = ths->remove_from_personal(MutableString(ths->temp_str_0.mstr(), s0));
//	ths->err_.reset(ret.release_err());
//	if (ths->err_ != 0) return 0;
	return 1;
}

}

extern "C" int aspell_speller_check_spelling(struct AspellSpeller * speller, const char * textData,
											 int textSize, int * wordCount, int countOnly, unsigned int * offset, unsigned  int * length)
{
	return acommon::aspell_speller_check_spelling(reinterpret_cast<acommon::Speller*>(speller), textData, textSize, wordCount, countOnly, offset, length);
}

extern "C" int aspell_speller_remove_from_personal(struct AspellSpeller * ths, const char * word, int word_size)
{
	return acommon::aspell_speller_remove_from_personal(reinterpret_cast<acommon::Speller*>(ths), word, word_size);
}

