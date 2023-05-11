#! /bin/sh --
set -ex

CFLAGS="${*:-}"
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o vfprintf_plus.o vfprintf_plus.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f bin -o vfprintf_plus.bin vfprintf_plus.nasm
ndisasm -b 32 vfprintf_plus.bin | tail  # For the size.
qq xstatic gcc -m32 -Os -W -Wall -s -o test_vfprintf_plus.prog test_vfprintf_plus.c vfprintf_plus.o
./test_vfprintf_plus.prog a b c d
./test_vfprintf_plus.prog a

: "$0" OK.
