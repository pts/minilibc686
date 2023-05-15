#! /bin/sh --
set -ex

qq xstatic gcc -m32 -Os -W -Wall -s -o test_c_strtol.prog test_strtol.c c_strtol.c
./test_c_strtol.prog

: "$0" OK.
