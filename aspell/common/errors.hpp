/* Automatically generated file.  Do not edit directly. */

/* This file is part of The New Aspell
 * Copyright (C) 2001-2002 by Kevin Atkinson under the GNU LGPL
 * license version 2.0 or 2.1.  You should have received a copy of the
 * LGPL license along with this library if you did not you can find it
 * at http://www.gnu.org/.                                              */

#ifndef ASPELL_ERRORS__HPP
#define ASPELL_ERRORS__HPP

#ifndef AL_ASPELL_EXTERN_C
#define AL_ASPELL_EXTERN_C extern "C"
#endif

namespace acommon {

struct ErrorInfo;

AL_ASPELL_EXTERN_C const ErrorInfo * const aerror_other;
AL_ASPELL_EXTERN_C const ErrorInfo * const aerror_operation_not_supported;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_cant_copy;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_unimplemented_method;
AL_ASPELL_EXTERN_C const ErrorInfo * const aerror_file;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_cant_open_file;
AL_ASPELL_EXTERN_C const ErrorInfo * const     aerror_cant_read_file;
AL_ASPELL_EXTERN_C const ErrorInfo * const     aerror_cant_write_file;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_invalid_name;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_bad_file_format;
AL_ASPELL_EXTERN_C const ErrorInfo * const aerror_dir;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_cant_read_dir;
AL_ASPELL_EXTERN_C const ErrorInfo * const aerror_config;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_unknown_key;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_cant_change_value;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_bad_key;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_bad_value;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_duplicate;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_key_not_string;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_key_not_int;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_key_not_bool;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_key_not_list;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_no_value_reset;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_no_value_enable;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_no_value_disable;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_no_value_clear;
AL_ASPELL_EXTERN_C const ErrorInfo * const aerror_language_related;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_unknown_language;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_unknown_soundslike;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_language_not_supported;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_no_wordlist_for_lang;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_mismatched_language;
AL_ASPELL_EXTERN_C const ErrorInfo * const aerror_affix;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_corrupt_affix;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_invalid_cond;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_invalid_cond_strip;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_incorrect_encoding;
AL_ASPELL_EXTERN_C const ErrorInfo * const aerror_encoding;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_unknown_encoding;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_encoding_not_supported;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_conversion_not_supported;
AL_ASPELL_EXTERN_C const ErrorInfo * const aerror_pipe;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_cant_create_pipe;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_process_died;
AL_ASPELL_EXTERN_C const ErrorInfo * const aerror_bad_input;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_invalid_string;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_invalid_word;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_invalid_affix;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_inapplicable_affix;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_unknown_unichar;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_word_list_flags;
AL_ASPELL_EXTERN_C const ErrorInfo * const     aerror_invalid_flag;
AL_ASPELL_EXTERN_C const ErrorInfo * const     aerror_conflicting_flags;
AL_ASPELL_EXTERN_C const ErrorInfo * const aerror_version_control;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_bad_version_string;
AL_ASPELL_EXTERN_C const ErrorInfo * const aerror_filter;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_cant_dlopen_file;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_empty_filter;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_no_such_filter;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_confusing_version;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_bad_version;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_identical_option;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_options_only;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_invalid_option_modifier;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_cant_describe_filter;
AL_ASPELL_EXTERN_C const ErrorInfo * const aerror_filter_mode_file;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_mode_option_name;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_no_filter_to_option;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_bad_mode_key;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_expect_mode_key;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_mode_version_requirement;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_confusing_mode_version;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_bad_mode_version;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_missing_magic_expression;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_empty_file_ext;
AL_ASPELL_EXTERN_C const ErrorInfo * const aerror_filter_mode_expand;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_unknown_mode;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_mode_extend_expand;
AL_ASPELL_EXTERN_C const ErrorInfo * const aerror_filter_mode_magic;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_file_magic_pos;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_file_magic_range;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_missing_magic;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_bad_magic;
AL_ASPELL_EXTERN_C const ErrorInfo * const aerror_expression;
AL_ASPELL_EXTERN_C const ErrorInfo * const   aerror_invalid_expression;


static const ErrorInfo * const other_error = aerror_other;
static const ErrorInfo * const operation_not_supported_error = aerror_operation_not_supported;
static const ErrorInfo * const   cant_copy = aerror_cant_copy;
static const ErrorInfo * const   unimplemented_method = aerror_unimplemented_method;
static const ErrorInfo * const file_error = aerror_file;
static const ErrorInfo * const   cant_open_file_error = aerror_cant_open_file;
static const ErrorInfo * const     cant_read_file = aerror_cant_read_file;
static const ErrorInfo * const     cant_write_file = aerror_cant_write_file;
static const ErrorInfo * const   invalid_name = aerror_invalid_name;
static const ErrorInfo * const   bad_file_format = aerror_bad_file_format;
static const ErrorInfo * const dir_error = aerror_dir;
static const ErrorInfo * const   cant_read_dir = aerror_cant_read_dir;
static const ErrorInfo * const config_error = aerror_config;
static const ErrorInfo * const   unknown_key = aerror_unknown_key;
static const ErrorInfo * const   cant_change_value = aerror_cant_change_value;
static const ErrorInfo * const   bad_key = aerror_bad_key;
static const ErrorInfo * const   bad_value = aerror_bad_value;
static const ErrorInfo * const   duplicate = aerror_duplicate;
static const ErrorInfo * const   key_not_string = aerror_key_not_string;
static const ErrorInfo * const   key_not_int = aerror_key_not_int;
static const ErrorInfo * const   key_not_bool = aerror_key_not_bool;
static const ErrorInfo * const   key_not_list = aerror_key_not_list;
static const ErrorInfo * const   no_value_reset = aerror_no_value_reset;
static const ErrorInfo * const   no_value_enable = aerror_no_value_enable;
static const ErrorInfo * const   no_value_disable = aerror_no_value_disable;
static const ErrorInfo * const   no_value_clear = aerror_no_value_clear;
static const ErrorInfo * const language_related_error = aerror_language_related;
static const ErrorInfo * const   unknown_language = aerror_unknown_language;
static const ErrorInfo * const   unknown_soundslike = aerror_unknown_soundslike;
static const ErrorInfo * const   language_not_supported = aerror_language_not_supported;
static const ErrorInfo * const   no_wordlist_for_lang = aerror_no_wordlist_for_lang;
static const ErrorInfo * const   mismatched_language = aerror_mismatched_language;
static const ErrorInfo * const affix_error = aerror_affix;
static const ErrorInfo * const   corrupt_affix = aerror_corrupt_affix;
static const ErrorInfo * const   invalid_cond = aerror_invalid_cond;
static const ErrorInfo * const   invalid_cond_strip = aerror_invalid_cond_strip;
static const ErrorInfo * const   incorrect_encoding = aerror_incorrect_encoding;
static const ErrorInfo * const encoding_error = aerror_encoding;
static const ErrorInfo * const   unknown_encoding = aerror_unknown_encoding;
static const ErrorInfo * const   encoding_not_supported = aerror_encoding_not_supported;
static const ErrorInfo * const   conversion_not_supported = aerror_conversion_not_supported;
static const ErrorInfo * const pipe_error = aerror_pipe;
static const ErrorInfo * const   cant_create_pipe = aerror_cant_create_pipe;
static const ErrorInfo * const   process_died = aerror_process_died;
static const ErrorInfo * const bad_input_error = aerror_bad_input;
static const ErrorInfo * const   invalid_string = aerror_invalid_string;
static const ErrorInfo * const   invalid_word = aerror_invalid_word;
static const ErrorInfo * const   invalid_affix = aerror_invalid_affix;
static const ErrorInfo * const   inapplicable_affix = aerror_inapplicable_affix;
static const ErrorInfo * const   unknown_unichar = aerror_unknown_unichar;
static const ErrorInfo * const   word_list_flags_error = aerror_word_list_flags;
static const ErrorInfo * const     invalid_flag = aerror_invalid_flag;
static const ErrorInfo * const     conflicting_flags = aerror_conflicting_flags;
static const ErrorInfo * const version_control_error = aerror_version_control;
static const ErrorInfo * const   bad_version_string = aerror_bad_version_string;
static const ErrorInfo * const filter_error = aerror_filter;
static const ErrorInfo * const   cant_dlopen_file = aerror_cant_dlopen_file;
static const ErrorInfo * const   empty_filter = aerror_empty_filter;
static const ErrorInfo * const   no_such_filter = aerror_no_such_filter;
static const ErrorInfo * const   confusing_version = aerror_confusing_version;
static const ErrorInfo * const   bad_version = aerror_bad_version;
static const ErrorInfo * const   identical_option = aerror_identical_option;
static const ErrorInfo * const   options_only = aerror_options_only;
static const ErrorInfo * const   invalid_option_modifier = aerror_invalid_option_modifier;
static const ErrorInfo * const   cant_describe_filter = aerror_cant_describe_filter;
static const ErrorInfo * const filter_mode_file_error = aerror_filter_mode_file;
static const ErrorInfo * const   mode_option_name = aerror_mode_option_name;
static const ErrorInfo * const   no_filter_to_option = aerror_no_filter_to_option;
static const ErrorInfo * const   bad_mode_key = aerror_bad_mode_key;
static const ErrorInfo * const   expect_mode_key = aerror_expect_mode_key;
static const ErrorInfo * const   mode_version_requirement = aerror_mode_version_requirement;
static const ErrorInfo * const   confusing_mode_version = aerror_confusing_mode_version;
static const ErrorInfo * const   bad_mode_version = aerror_bad_mode_version;
static const ErrorInfo * const   missing_magic_expression = aerror_missing_magic_expression;
static const ErrorInfo * const   empty_file_ext = aerror_empty_file_ext;
static const ErrorInfo * const filter_mode_expand_error = aerror_filter_mode_expand;
static const ErrorInfo * const   unknown_mode = aerror_unknown_mode;
static const ErrorInfo * const   mode_extend_expand = aerror_mode_extend_expand;
static const ErrorInfo * const filter_mode_magic_error = aerror_filter_mode_magic;
static const ErrorInfo * const   file_magic_pos = aerror_file_magic_pos;
static const ErrorInfo * const   file_magic_range = aerror_file_magic_range;
static const ErrorInfo * const   missing_magic = aerror_missing_magic;
static const ErrorInfo * const   bad_magic = aerror_bad_magic;
static const ErrorInfo * const expression_error = aerror_expression;
static const ErrorInfo * const   invalid_expression = aerror_invalid_expression;


}

#endif /* ASPELL_ERRORS__HPP */
