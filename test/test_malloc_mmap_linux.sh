#! /bin/sh --
set -ex

CFLAGS="${*:-}"
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o malloc_mmap_linux.o malloc_mmap_linux.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f bin -o malloc_mmap_linux.bin malloc_mmap_linux.nasm
nasm-0.98.39 $CFLAGS -O0 -w+orphan-labels -f bin -o malloc_mmap_linux.o0.bin malloc_mmap_linux.nasm
ndisasm -b 32 malloc_mmap_linux.bin | tail  # For the size.
if ! cmp malloc_mmap_linux.bin malloc_mmap_linux.o0.bin; then
  ndisasm-0.98.39 -b 32 malloc_mmap_linux.bin >malloc_mmap_linux.ndisasm
  ndisasm-0.98.39 -b 32 malloc_mmap_linux.o0.bin >malloc_mmap_linux.o0.ndisasm
  diff -U3 malloc_mmap_linux.ndisasm malloc_mmap_linux.o0.ndisasm
fi
qq xstatic gcc -m32 -Os -W -Wall -s -o test_malloc_mmap_linux.prog test_malloc.c malloc_mmap_linux.o
if ./test_malloc_mmap_linux.prog; then :; else echo "$?"; exit 1; fi

: "$0" OK.
