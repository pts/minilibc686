#! /bin/sh --
set -ex

CFLAGS="${*:-}"
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o strstr_faster.o strstr_faster.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f bin -o strstr_faster.bin strstr_faster.nasm
nasm-0.98.39 $CFLAGS -O0 -w+orphan-labels -f bin -o strstr_faster.o0.bin strstr_faster.nasm
ndisasm -b 32 strstr_faster.bin | tail  # For the size.
if ! cmp strstr_faster.bin strstr_faster.o0.bin; then
  ndisasm-0.98.39 -b 32 strstr_faster.bin >strstr_faster.ndisasm
  ndisasm-0.98.39 -b 32 strstr_faster.o0.bin >strstr_faster.o0.ndisasm
  diff -U3 strstr_faster.ndisasm strstr_faster.o0.ndisasm
fi
qq xstatic gcc -m32 -Os -W -Wall -s -o test_strstr_faster.prog -Dmini_strstr=mini_strstr_faster test_strstr.c strstr_faster.o
./test_strstr_faster.prog

: "$0" OK.
