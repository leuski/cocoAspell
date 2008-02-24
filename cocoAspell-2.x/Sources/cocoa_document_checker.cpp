// ============================================================================
//  cocoa_document_checker.cpp
// ============================================================================
//
//	cocoAspell2
//
//  Created by Anton Leuski on 2/15/05.
//  Copyright (c) 2005-2008 Anton Leuski. All rights reserved.
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

extern "C" int aspell_speller_check_spelling(Speller * speller, const char * textData, 
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
	
extern "C" int aspell_speller_remove_from_personal(Speller * ths, const char * word, int word_size)
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

