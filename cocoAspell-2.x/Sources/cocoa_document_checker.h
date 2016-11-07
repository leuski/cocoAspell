// ============================================================================
//  cocoa_document_checker.h
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

#ifndef __cocoa_document_checker__
#define __cocoa_document_checker__

#ifdef __cplusplus

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wshorten-64-to-32"

#include "filter.hpp"
#include "char_vector.hpp"
#include "copy_ptr.hpp"
#include "can_have_error.hpp"
#include "filter_char.hpp"
#include "filter_char_vector.hpp"

#pragma clang diagnostic pop


namespace acommon {

	class Config;
	class Speller;
	class Tokenizer;
	class Convert;

	struct Token {
		unsigned int offset;
		unsigned int len;
		operator bool () const {return len != 0;}
	};


	class CocoaDocumentChecker : public CanHaveError {
		public:
		// will take ownership of tokenizer and filter (even if there is an error)
		// config only used for this method.
		// speller expected to stick around.
			PosibErr<void> setup(Tokenizer *, Speller *, Filter *);
			void reset();
			void process(const char * str, int size);
			Token next_misspelling(int * ioWordCount);
			void count_words(int * ioWordCount);

			Filter * filter() {return filter_;}

			CocoaDocumentChecker();
			~CocoaDocumentChecker();

		private:
			CopyPtr<Filter> filter_;
			CopyPtr<Tokenizer> tokenizer_;
			Speller * speller_;
			Convert * conv_;
			FilterCharVector proc_str_;
	};

	PosibErr<CocoaDocumentChecker *> new_cocoa_document_checker(Speller *);

}

extern "C" {
#endif

int aspell_speller_check_spelling(struct AspellSpeller * speller, const char * textData, 
	int textSize, int * wordCount, int countOnly, unsigned int * offset, unsigned  int * length);
int aspell_speller_remove_from_personal(struct AspellSpeller * ths, const char * word, int word_size);

#ifdef __cplusplus
}
#endif



#endif /* __cocoa_document_checker__ */
