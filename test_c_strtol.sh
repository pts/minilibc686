#! /bin/sh --
set -ex

qq xstatic gcc -m32 -Os -W -Wall -s -o test_strtol.prog test_strtol.c c_strtol.c
./test_strtol.prog

: "$0" OK.
