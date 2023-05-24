#! /bin/sh --
set -ex

CFLAGS="${*:-}"
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o strstr.o strstr.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f bin -o strstr.bin strstr.nasm
nasm-0.98.39 $CFLAGS -O0 -w+orphan-labels -f bin -o strstr.o0.bin strstr.nasm
ndisasm -b 32 strstr.bin | tail  # For the size.
if ! cmp strstr.bin strstr.o0.bin; then
  ndisasm-0.98.39 -b 32 strstr.bin >strstr.ndisasm
  ndisasm-0.98.39 -b 32 strstr.o0.bin >strstr.o0.ndisasm
  diff -U3 strstr.ndisasm strstr.o0.ndisasm
fi
qq xstatic gcc -m32 -Os -W -Wall -s -o test_strstr.prog test_strstr.c strstr.o
./test_strstr.prog

: "$0" OK.
