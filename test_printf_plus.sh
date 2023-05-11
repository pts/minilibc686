#! /bin/sh --
set -ex

CFLAGS="${*:-}"
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o vfprintf_plus.o vfprintf_plus.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o printf_callvf.o printf_callvf.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f bin -o printf_callvf.bin printf_callvf.nasm
nasm-0.98.39 $CFLAGS -O0 -w+orphan-labels -f bin -o printf_callvf.o0.bin printf_callvf.nasm
ndisasm -b 32 printf_callvf.bin | tail  # For the size.
if ! cmp printf_callvf.bin printf_callvf.o0.bin; then
  ndisasm-0.98.39 -b 32 printf_callvf.bin >printf_callvf.ndisasm
  ndisasm-0.98.39 -b 32 printf_callvf.o0.bin >printf_callvf.o0.ndisasm
  diff -U3 printf_callvf.ndisasm printf_callvf.o0.ndisasm
fi
qq xstatic gcc -m32 -Os -W -Wall -s -o test_printf_plus.prog test_printf_plus.c vfprintf_plus.o printf_callvf.o
./test_printf_plus.prog a b c d
./test_printf_plus.prog a

: "$0" OK.
