#! /bin/sh --
set -ex

CFLAGS="${*:-}"
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o fputc_unbuffered.o fputc_unbuffered.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f bin -o fputc_unbuffered.bin fputc_unbuffered.nasm
nasm-0.98.39 $CFLAGS -O0 -w+orphan-labels -f bin -o fputc_unbuffered.o0.bin fputc_unbuffered.nasm
ndisasm -b 32 fputc_unbuffered.bin | tail  # For the size.
if ! cmp fputc_unbuffered.bin fputc_unbuffered.o0.bin; then
  ndisasm-0.98.39 -b 32 fputc_unbuffered.bin >fputc_unbuffered.ndisasm
  ndisasm-0.98.39 -b 32 fputc_unbuffered.o0.bin >fputc_unbuffered.o0.ndisasm
  diff -U3 fputc_unbuffered.ndisasm fputc_unbuffered.o0.ndisasm
fi
qq xstatic gcc -m32 -Os -W -Wall -s -o test_fputc_unbuffered.prog test_fputc_unbuffered.c fputc_unbuffered.o
./test_fputc_unbuffered.prog

: "$0" OK.
