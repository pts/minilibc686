#! /bin/sh --
set -ex

CFLAGS="${*:-}"
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o strlen.o strlen.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f bin -o strlen.bin strlen.nasm
nasm-0.98.39 $CFLAGS -O0 -w+orphan-labels -f bin -o strlen.o0.bin strlen.nasm
ndisasm -b 32 strlen.bin | tail  # For the size.
if ! cmp strlen.bin strlen.o0.bin; then
  ndisasm-0.98.39 -b 32 strlen.bin >strlen.ndisasm
  ndisasm-0.98.39 -b 32 strlen.o0.bin >strlen.o0.ndisasm
  diff -U3 strlen.ndisasm strlen.o0.ndisasm
fi
qq xstatic gcc -m32 -Os -W -Wall -s -o test_strlen.prog test_strlen.c strlen.o
./test_strlen.prog

: "$0" OK.
