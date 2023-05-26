#! /bin/sh --
set -ex

CFLAGS="${*:-}"
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o strtok_sep1.o strtok_sep1.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f bin -o strtok_sep1.bin strtok_sep1.nasm
nasm-0.98.39 $CFLAGS -O0 -w+orphan-labels -f bin -o strtok_sep1.o0.bin strtok_sep1.nasm
ndisasm -b 32 strtok_sep1.bin | tail  # For the size.
if ! cmp strtok_sep1.bin strtok_sep1.o0.bin; then
  ndisasm-0.98.39 -b 32 strtok_sep1.bin >strtok_sep1.ndisasm
  ndisasm-0.98.39 -b 32 strtok_sep1.o0.bin >strtok_sep1.o0.ndisasm
  diff -U3 strtok_sep1.ndisasm strtok_sep1.o0.ndisasm
fi
qq xstatic gcc -m32 -Os -W -Wall -s -o test_strtok_sep1.prog test_strtok.c strtok_sep1.o
./test_strtok_sep1.prog

: "$0" OK.
