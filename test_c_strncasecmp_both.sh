#! /bin/sh --
set -ex

CFLAGS="${*:-}"
qq xstatic gcc -m32 -Os -W -Wall $CFLAGS -s -o test_c_strncasecmp_both.prog test_strncasecmp_both.c c_strncasecmp_both.c
./test_c_strncasecmp_both.prog

: "$0" OK.
