#! /bin/sh --
set -ex

CFLAGS="${*:-}"
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o strtol.o strtol.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f bin -o strtol.bin strtol.nasm
nasm-0.98.39 $CFLAGS -O0 -w+orphan-labels -f bin -o strtol.o0.bin strtol.nasm
ndisasm -b 32 strtol.bin | tail  # For the size.
if ! cmp strtol.bin strtol.o0.bin; then
  ndisasm-0.98.39 -b 32 strtol.bin >strtol.ndisasm
  ndisasm-0.98.39 -b 32 strtol.o0.bin >strtol.o0.ndisasm
  diff -U3 strtol.ndisasm strtol.o0.ndisasm
fi
qq xstatic gcc -m32 -Os -W -Wall -s -o test_strtol.prog test_strtol.c strtol.o
./test_strtol.prog

: "$0" OK.
