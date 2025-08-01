# Copyright (C) 2006-2025 Free Software Foundation, Inc.
# Author: Simon Josefsson
#
# This file is part of LIBTASN1.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

manual_title = Library for Abstract Syntax Notation One (ASN.1)

old_NEWS_hash = 68919c99ea7b69fa48c9455048a63252

guix = $(shell command -v guix > /dev/null && echo ,guix)
bootstrap-tools = gnulib,autoconf,automake,libtoolize,make,makeinfo,bison,help2man,gtkdocize,tar,gzip$(guix)

local-checks-to-skip = sc_prohibit_strcmp sc_immutable_NEWS	\
	sc_bindtextdomain sc_GPL_version			\
	sc_prohibit_gnu_make_extensions

VC_LIST_ALWAYS_EXCLUDE_REGEX = ^(maint.mk|gtk-doc.make|build-aux/.*|lib/gl/.*|lib/ASN1\.c|m4/pkg.m4|doc/gdoc|windows/.*|doc/fdl-1.3.texi|fuzz/.*_fuzzer.(in|repro)/.*)$$
update-copyright-env = UPDATE_COPYRIGHT_USE_INTERVALS=1

# Explicit syntax-check exceptions.
exclude_file_name_regexp--sc_prohibit_empty_lines_at_EOF = ^tests/TestIndef.p12$$
exclude_file_name_regexp--sc_GPL_version = ^lib/includes/libtasn1.h$$
exclude_file_name_regexp--sc_program_name = ^tests/|examples/
exclude_file_name_regexp--sc_prohibit_atoi_atof = ^src/asn1Coding.c|src/asn1Decoding.c$$
exclude_file_name_regexp--sc_prohibit_empty_lines_at_EOF = ^tests/.*.(cer|der|asn|txt|p12)|tests/TestIndef.p12|msvc/.*$$
exclude_file_name_regexp--sc_error_message_uppercase = ^tests/Test_tree.c$$
exclude_file_name_regexp--sc_unmarked_diagnostics = ^tests/Test_tree.c$$
exclude_file_name_regexp--sc_prohibit_undesirable_word_seq = ^msvc/.*$$
exclude_file_name_regexp--sc_trailing_blank = ^msvc/.*|tests/(TestCertOctetOverflow.der|TestIndef.p12|TestIndef2.p12|TestIndef3.der|invalid-assignments2.txt)|tests/invalid-x509/id-.*|src/gl/lib/(malloc|realloc).c.diff$$
exclude_file_name_regexp--sc_useless_cpp_parens = ^lib/includes/libtasn1.h$$
exclude_file_name_regexp--sc_prohibit_eol_brackets = ^(bootstrap-funclib.sh|tests/.*|fuzz/.*|bootstrap)$$
exclude_file_name_regexp--sc_makefile_DISTCHECK_CONFIGURE_FLAGS = ^Makefile.am$$
exclude_file_name_regexp--sc_unportable_grep_q = ^fuzz/(get_all_corpora|get_ossfuzz_corpora|run-clang.sh)$$
exclude_file_name_regexp--sc_prohibit_have_config_h = ^tests/Test_tree_asn1_tab.c|tests/pkix.asn.out$$
exclude_file_name_regexp--sc_require_config_h = ^examples/CertificateExample.c|examples/CrlExample.c|tests/Test_tree_asn1_tab.c$$
exclude_file_name_regexp--sc_require_config_h_first = $(exclude_file_name_regexp--sc_require_config_h)
exclude_file_name_regexp--sc_prohibit_magic_number_exit = ^tests/.*$$

TAR_OPTIONS += --mode=go+u,go-w --mtime=$(abs_top_srcdir)/NEWS

announce_gen_args = --cksum-checksums
DIST_ARCHIVES += $(shell \
	if test -e $(srcdir)/.git && command -v git > /dev/null; then \
		echo $(PACKAGE)-v$(VERSION)-src.tar.gz; \
	fi)

sc_prohibit_eol_brackets:
	@prohibit='.+\) *{$$' \
	halt='please block bracket { use in a separate line' \
	  $(_sc_search_regexp)

codespell_ignore_words_list = tim,sorce,ans,fo
exclude_file_name_regexp--sc_codespell = _fuzzer.in|_fuzzer.repro|gnulib|tests/.*.der|tests/TestIndef.*.p12|tests/built-in-type.asn|tests/crlf.cer|tests/invalid-assignments..txt|windows/libtasn1.ncb|windows/libtasn1.suo$$

sc_libtool_version_bump:
	@git diff v$(PREV_VERSION).. | grep '^+AC_SUBST(LT' > /dev/null

review-tag ?= $(shell git describe --abbrev=0)
review-diff:
	git diff $(review-tag).. \
	| grep -v -e '^index' -e '^deleted file mode' -e '^new file mode' \
	| filterdiff -p 1 -x 'build-aux/*' -x 'lib/gl*' -x 'po/*' -x 'maint.mk' -x '.gitignore' -x '.gitlab-ci.yml' -x .prev-version -x bootstrap -x bootstrap-funclib.sh \
	| less
