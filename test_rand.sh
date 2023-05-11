#! /bin/sh --
set -ex

CFLAGS="${*:-}"
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o rand.o rand.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f bin -o rand.bin rand.nasm
nasm-0.98.39 $CFLAGS -O0 -w+orphan-labels -f bin -o rand.o0.bin rand.nasm
ndisasm -b 32 rand.bin | tail  # For the size.
if ! cmp rand.bin rand.o0.bin; then
  ndisasm-0.98.39 -b 32 rand.bin >rand.ndisasm
  ndisasm-0.98.39 -b 32 rand.o0.bin >rand.o0.ndisasm
  diff -U3 rand.ndisasm rand.o0.ndisasm
fi
qq xstatic gcc -m32 -Os -W -Wall -s -o test_rand.prog test_rand.c rand.o
./test_rand.prog
./test_rand.prog a

: "$0" OK.
