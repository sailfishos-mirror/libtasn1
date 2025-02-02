#!/bin/sh

# Copyright (C) 2017-2025 Free Software Foundation, Inc.
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

srcdir="${srcdir:-.}"
top_srcdir="${top_srcdir:-../}"

ASAN_OPTIONS="detect_leaks=0:exitcode=6"
export ASAN_OPTIONS

if ! test -z "${VALGRIND}";then
VALGRIND="${LIBTOOL:-libtool} --mode=execute ${VALGRIND} --error-exitcode=7"
fi

ASN1CODING="${ASN1CODING:-../src/asn1Coding$EXEEXT}"
ASN1PKIX="${ASN1PKIX:-pkix.asn}"
TMPFILE="asn1.$$.tmp"
TMPASSIGNFILE="assignments.$$.tmp"
TMPFILEOUTPUT=coding.out.$$.tmp
FGREP=${FGREP:-fgrep}

cat <<EOF >$TMPFILE
PKIX1 { }

DEFINITIONS IMPLICIT TAGS ::=

BEGIN

Dss-Sig-Value ::= SEQUENCE {
     r       INTEGER,
     s       INTEGER
}

END
EOF

cat <<EOF >$TMPASSIGNFILE
dp PKIX1.Dss-Sig-Value

r 65
s 66
EOF

$VALGRIND "$ASN1CODING" -c $TMPFILE "${srcdir}"/invalid-assignments1.txt
if test $? != 1;then
	echo "Encoding failed (1)"
	exit 1
fi

$VALGRIND "$ASN1CODING" -c $TMPFILE "${srcdir}"/invalid-assignments2.txt
if test $? != 1;then
	echo "Encoding failed (2)"
	exit 1
fi

# Test invalid command line option
$VALGRIND "$ASN1CODING" --asdf > "$TMPFILEOUTPUT" 2>&1
if test $? != 1; then
	echo "Invalid command line arg - incorrect return code!"
	exit 1
fi

# Look for "--help" in the output, make grep quiet.
# "--" to avoid grep trying to interpret "--help" as an option.
if ! $FGREP -q -- "--help" "$TMPFILEOUTPUT"; then
	echo "Invalid command line arg - incorrect command output!"
    exit 1
fi

# Test help command line option
$VALGRIND "$ASN1CODING" --help > $TMPFILEOUTPUT 2>&1
if test $? != 0; then
	echo "Help command line arg - incorrect return code!"
	exit 1
fi

# Look for "--help" in the output, make grep quiet.
# "--" to avoid grep trying to interpret "--help" as an option.
if ! $FGREP -q -- "--help" $TMPFILEOUTPUT; then
	echo "Help command line arg - incorrect command output!"
    exit 1
fi

# Test no command line option
$VALGRIND "$ASN1CODING" > $TMPFILEOUTPUT 2>&1
if test $? != 1; then
	echo "Help command line arg - incorrect return code!"
	exit 1
fi

# Look for "--help" in the output, make grep quiet.
# "--" to avoid grep trying to interpret "--help" as an option.
if ! $FGREP -q -- "--help" $TMPFILEOUTPUT; then
	echo "Help command line arg - incorrect command output!"
    exit 1
fi

# Test missing asn file
$VALGRIND "$ASN1CODING" -c missingfile.asn "${srcdir}"/invalid-assignments1.txt
if test $? != 1;then
	echo "Encoding failed (1)"
	exit 1
fi

# Test version option
$VALGRIND "$ASN1CODING" --version > $TMPFILEOUTPUT 2>&1
EXPECTEDVER=$(cat "${top_srcdir}"/.version)
if test $? != 0; then
	echo "Version command line arg - incorrect return code!"
	exit 1
fi

# Look for actual version in the output
if ! $FGREP -q "$EXPECTEDVER" $TMPFILEOUTPUT; then
	echo "Version command line arg - incorrect command output!"
    exit 1
fi

# Test valid case
$VALGRIND "$ASN1CODING" $TMPFILE $TMPASSIGNFILE -o $TMPFILEOUTPUT
if test $? != 0;then
	echo "Encoding failed (2)"
	exit 1
fi

# Expected output for the above
# Viewed with xxd:
# 00000000: 3006 0201 4102 0142                      0...A..B
# md5sum of this should be b1cea8feb4e3d83c1bc2314151e9a0fe
md5sum $TMPFILEOUTPUT > md5sum.$TMPFILEOUTPUT
if  ! $FGREP -q "b1cea8feb4e3d83c1bc2314151e9a0fe" md5sum.$TMPFILEOUTPUT;then
	echo "Encoded output differs from expected (2)!"
	exit 1
fi

# Test valid case without specifying output file
$VALGRIND "$ASN1CODING" $TMPFILE $TMPASSIGNFILE
if test $? != 0;then
	echo "Encoding failed (3)"
	exit 1
fi

# Expected output for the above
# Viewed with xxd:
# 00000000: 3006 0201 4102 0142                      0...A..B
# md5sum of this should be b1cea8feb4e3d83c1bc2314151e9a0fe
AUTOOUTPUTFILE=$(echo $TMPASSIGNFILE | sed -e s/tmp/out/)

md5sum "$AUTOOUTPUTFILE" > md5sum.$TMPFILEOUTPUT
if  ! $FGREP -q "b1cea8feb4e3d83c1bc2314151e9a0fe" md5sum.$TMPFILEOUTPUT;then
	echo "Encoded output differs from expected (3)!"
	exit 1
fi

# Test valid case without specifying output file and assign file has slash
$VALGRIND "$ASN1CODING" $TMPFILE ./$TMPASSIGNFILE
if test $? != 0;then
	echo "Encoding failed (4)"
	exit 1
fi

# Expected output for the above
# Viewed with xxd:
# 00000000: 3006 0201 4102 0142                      0...A..B
# md5sum of this should be b1cea8feb4e3d83c1bc2314151e9a0fe
AUTOOUTPUTFILE=$(echo $TMPASSIGNFILE | sed -e s/tmp/out/)

md5sum "$AUTOOUTPUTFILE" > md5sum.$TMPFILEOUTPUT
if  ! $FGREP -q "b1cea8feb4e3d83c1bc2314151e9a0fe" md5sum.$TMPFILEOUTPUT;then
	echo "Encoded output differs from expected (4)!"
	exit 1
fi

# Test invalid OID value case (first digit of OID max is 2, we give 3)
$VALGRIND "$ASN1CODING" "${srcdir}"/"Test_oid_invalid.asn" "${srcdir}"/"invalid-oid-assignments.txt" -o $TMPFILEOUTPUT
if test $? != 1;then
	echo "Encoding failed (6)"
	exit 1
fi

# Test invalid case - try to set a (NULL)
sed -i -e 's/s 66/s \(NULL\)/' $TMPASSIGNFILE
$VALGRIND "$ASN1CODING" $TMPFILE $TMPASSIGNFILE
if test $? != 1;then
	echo "Encoding passed when not expected"
	exit 1
fi

# Test providing a missing assignment file
$VALGRIND "$ASN1CODING" $TMPFILE missing_assignment_file.txt
if test $? != 1;then
	echo "Encoding passed when not expected (2)"
	exit 1
fi

# Test an empty variable case identified by double single quotes
sed -i -e "s/s (NULL)/\'\' 66/" $TMPASSIGNFILE
$VALGRIND "$ASN1CODING" $TMPFILE $TMPASSIGNFILE
if test $? != 1;then
	echo "Encoding passed when not expected (3)"
	exit 1
fi

rm -f "$AUTOOUTPUTFILE"
rm -f md5sum.$TMPFILEOUTPUT
rm -f $TMPASSIGNFILE
rm -f $TMPFILEOUTPUT
rm -f $TMPFILE

exit 0
