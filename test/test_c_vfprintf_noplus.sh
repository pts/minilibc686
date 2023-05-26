#! /bin/sh --
set -ex

qq xstatic gcc -m32 -Os -W -Wall -s -o test_c_vfprintf_noplus.prog test_vfprintf_noplus.c c_vfprintf_noplus.c
./test_c_vfprintf_noplus.prog a b c d
./test_c_vfprintf_noplus.prog a

: "$0" OK.
