#! /bin/sh --
set -ex

CFLAGS="${*:-}"
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o strchr.o strchr.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f bin -o strchr.bin strchr.nasm
nasm-0.98.39 $CFLAGS -O0 -w+orphan-labels -f bin -o strchr.o0.bin strchr.nasm
ndisasm -b 32 strchr.bin | tail  # For the size.
if ! cmp strchr.bin strchr.o0.bin; then
  ndisasm-0.98.39 -b 32 strchr.bin >strchr.ndisasm
  ndisasm-0.98.39 -b 32 strchr.o0.bin >strchr.o0.ndisasm
  diff -U3 strchr.ndisasm strchr.o0.ndisasm
fi
qq xstatic gcc -m32 -Os -W -Wall -s -o test_strchr.prog test_strchr.c strchr.o
./test_strchr.prog

: "$0" OK.
