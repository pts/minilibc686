#! /bin/sh --
set -ex

CFLAGS="${*:-}"
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o vfprintf_noplus.o vfprintf_noplus.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f bin -o vfprintf_noplus.bin vfprintf_noplus.nasm
nasm-0.98.39 $CFLAGS -O0 -w+orphan-labels -f bin -o vfprintf_noplus.o0.bin vfprintf_noplus.nasm
ndisasm -b 32 vfprintf_noplus.bin | tail  # For the size.
if ! cmp vfprintf_noplus.bin vfprintf_noplus.o0.bin; then
  ndisasm-0.98.39 -b 32 vfprintf_noplus.bin >vfprintf_noplus.ndisasm
  ndisasm-0.98.39 -b 32 vfprintf_noplus.o0.bin >vfprintf_noplus.o0.ndisasm
  diff -U3 vfprintf_noplus.ndisasm vfprintf_noplus.o0.ndisasm
fi
qq xstatic gcc -m32 -Os -W -Wall -s -o test_vfprintf_noplus.prog test_vfprintf_noplus.c vfprintf_noplus.o
./test_vfprintf_noplus.prog a b c d
./test_vfprintf_noplus.prog a

: "$0" OK.
