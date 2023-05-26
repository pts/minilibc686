#! /bin/sh --
set -ex

qq xstatic gcc -m32 -Os -W -Wall -s -o test_c_vfprintf_plus.prog test_vfprintf_plus.c c_vfprintf_plus.c
./test_c_vfprintf_plus.prog a b c d; echo $?
./test_c_vfprintf_plus.prog a; echo $?

: "$0" OK.
