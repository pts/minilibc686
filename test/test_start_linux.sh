#! /bin/sh --
set -ex

CFLAGS="${*:-}"
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o start_linux.o start_linux.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f bin -o start_linux.bin start_linux.nasm
nasm-0.98.39 $CFLAGS -O0 -w+orphan-labels -f bin -o start_linux.o0.bin start_linux.nasm
ndisasm -b 32 start_linux.bin | tail  # For the size.
if ! cmp start_linux.bin start_linux.o0.bin; then
  ndisasm-0.98.39 -b 32 start_linux.bin >start_linux.ndisasm
  ndisasm-0.98.39 -b 32 start_linux.o0.bin >start_linux.o0.ndisasm
  diff -U3 start_linux.ndisasm start_linux.o0.ndisasm
fi
qq xstatic gcc -m32 -Os -W -Wall -s -o test_start_linux.prog test_start.c start_linux.o
./test_start_linux.prog

: "$0" OK.
