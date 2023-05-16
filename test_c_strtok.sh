#! /bin/sh --
set -ex

CFLAGS="${*:-}"
qq xstatic gcc -m32 -Os -W -Wall $CFLAGS -s -o test_c_strtok_sep1.prog test_strtok.c c_strtok.c
./test_c_strtok_sep1.prog

: "$0" OK.
