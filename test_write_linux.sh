#! /bin/sh --
set -ex

CFLAGS="${*:-}"
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o write_linux.o write_linux.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f bin -o write_linux.bin write_linux.nasm
nasm-0.98.39 $CFLAGS -O0 -w+orphan-labels -f bin -o write_linux.o0.bin write_linux.nasm
ndisasm -b 32 write_linux.bin | tail  # For the size.
if ! cmp write_linux.bin write_linux.o0.bin; then
  ndisasm-0.98.39 -b 32 write_linux.bin >write_linux.ndisasm
  ndisasm-0.98.39 -b 32 write_linux.o0.bin >write_linux.o0.ndisasm
  diff -U3 write_linux.ndisasm write_linux.o0.ndisasm
fi
qq xstatic gcc -m32 -Os -W -Wall -s -o test_write_linux.prog test_write.c write_linux.o
./test_write_linux.prog

: "$0" OK.
