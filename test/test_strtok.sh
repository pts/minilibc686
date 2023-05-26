#! /bin/sh --
set -ex

CFLAGS="${*:-}"
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o strtok.o strtok.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f bin -o strtok.bin strtok.nasm
nasm-0.98.39 $CFLAGS -O0 -w+orphan-labels -f bin -o strtok.o0.bin strtok.nasm
ndisasm -b 32 strtok.bin | tail  # For the size.
if ! cmp strtok.bin strtok.o0.bin; then
  ndisasm-0.98.39 -b 32 strtok.bin >strtok.ndisasm
  ndisasm-0.98.39 -b 32 strtok.o0.bin >strtok.o0.ndisasm
  diff -U3 strtok.ndisasm strtok.o0.ndisasm
fi
qq xstatic gcc -m32 -Os -W -Wall -s -o test_strtok.prog test_strtok.c strtok.o
./test_strtok.prog

: "$0" OK.
