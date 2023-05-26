#! /bin/sh --
set -ex

CFLAGS="${*:-}"
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o strtod.o strtod.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f bin -o strtod.bin strtod.nasm
nasm-0.98.39 $CFLAGS -O0 -w+orphan-labels -f bin -o strtod.o0.bin strtod.nasm
ndisasm -b 32 strtod.bin | tail  # For the size.
if ! cmp strtod.bin strtod.o0.bin; then
  ndisasm-0.98.39 -b 32 strtod.bin >strtod.ndisasm
  ndisasm-0.98.39 -b 32 strtod.o0.bin >strtod.o0.ndisasm
  diff -U3 strtod.ndisasm strtod.o0.ndisasm
fi
qq xstatic gcc -m32 -Os -W -Wall -s -o test_strtod.prog test_strtod.c strtod.o
./test_strtod.prog

: "$0" OK.
