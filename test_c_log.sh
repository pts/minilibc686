#! /bin/sh --
set -ex

CFLAGS="${*:-}"
qq xstatic gcc -m32 -Os -W -Wall $CFLAGS -s -o test_c_log.prog test_log.c c_log.c
./test_c_log.prog

: "$0" OK.
