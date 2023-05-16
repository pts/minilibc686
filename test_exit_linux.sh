#! /bin/sh --
set -ex

CFLAGS="${*:-}"
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o exit_linux.o exit_linux.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f bin -o exit_linux.bin exit_linux.nasm
nasm-0.98.39 $CFLAGS -O0 -w+orphan-labels -f bin -o exit_linux.o0.bin exit_linux.nasm
ndisasm -b 32 exit_linux.bin | tail  # For the size.
if ! cmp exit_linux.bin exit_linux.o0.bin; then
  ndisasm-0.98.39 -b 32 exit_linux.bin >exit_linux.ndisasm
  ndisasm-0.98.39 -b 32 exit_linux.o0.bin >exit_linux.o0.ndisasm
  diff -U3 exit_linux.ndisasm exit_linux.o0.ndisasm
fi
qq xstatic gcc -m32 -Os -W -Wall -s -o test_exit_linux.prog test_exit.c exit_linux.o
./test_exit_linux.prog

: "$0" OK.
