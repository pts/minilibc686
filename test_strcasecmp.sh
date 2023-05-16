#! /bin/sh --
set -ex

CFLAGS="${*:-}"
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o strcasecmp.o strcasecmp.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f bin -o strcasecmp.bin strcasecmp.nasm
nasm-0.98.39 $CFLAGS -O0 -w+orphan-labels -f bin -o strcasecmp.o0.bin strcasecmp.nasm
ndisasm -b 32 strcasecmp.bin | tail  # For the size.
if ! cmp strcasecmp.bin strcasecmp.o0.bin; then
  ndisasm-0.98.39 -b 32 strcasecmp.bin >strcasecmp.ndisasm
  ndisasm-0.98.39 -b 32 strcasecmp.o0.bin >strcasecmp.o0.ndisasm
  diff -U3 strcasecmp.ndisasm strcasecmp.o0.ndisasm
fi
qq xstatic gcc -m32 -Os -W -Wall -s -o test_strcasecmp.prog test_strcasecmp.c strcasecmp.o
./test_strcasecmp.prog

: "$0" OK.
