#! /bin/sh --
set -ex

CFLAGS="${*:-}"
qq xstatic gcc -m32 -Os -W -Wall $CFLAGS -s -o test_c_strtod.prog test_strtod.c c_strtod.c
./test_c_strtod.prog

: "$0" OK.
