#! /bin/sh --
set -ex

CFLAGS="${*:-}"
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o memmove.o memmove.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f bin -o memmove.bin memmove.nasm
nasm-0.98.39 $CFLAGS -O0 -w+orphan-labels -f bin -o memmove.o0.bin memmove.nasm
ndisasm -b 32 memmove.bin | tail  # For the size.
if ! cmp memmove.bin memmove.o0.bin; then
  ndisasm-0.98.39 -b 32 memmove.bin >memmove.ndisasm
  ndisasm-0.98.39 -b 32 memmove.o0.bin >memmove.o0.ndisasm
  diff -U3 memmove.ndisasm memmove.o0.ndisasm
fi
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o memcmp.o memcmp.nasm
qq xstatic gcc -m32 -Os -W -Wall -s -o test_memmove.prog test_memmove.c memmove.o memcmp.o
if ./test_memmove.prog; then :; else echo "$?"; exit 1; fi

: "$0" OK.
