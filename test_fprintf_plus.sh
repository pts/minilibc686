#! /bin/sh --
set -ex

CFLAGS="${*:-}"
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o vfprintf_plus.o vfprintf_plus.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o fprintf_callvf.o fprintf_callvf.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f bin -o fprintf_callvf.bin fprintf_callvf.nasm
nasm-0.98.39 $CFLAGS -O0 -w+orphan-labels -f bin -o fprintf_callvf.o0.bin fprintf_callvf.nasm
ndisasm -b 32 fprintf_callvf.bin | tail  # For the size.
if ! cmp fprintf_callvf.bin fprintf_callvf.o0.bin; then
  ndisasm-0.98.39 -b 32 fprintf_callvf.bin >fprintf_callvf.ndisasm
  ndisasm-0.98.39 -b 32 fprintf_callvf.o0.bin >fprintf_callvf.o0.ndisasm
  diff -U3 fprintf_callvf.ndisasm fprintf_callvf.o0.ndisasm
fi
qq xstatic gcc -m32 -Os -W -Wall -s -o test_fprintf_plus.prog test_fprintf_plus.c vfprintf_plus.o fprintf_callvf.o
./test_fprintf_plus.prog a b c d
./test_fprintf_plus.prog a

: "$0" OK.
