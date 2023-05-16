#! /bin/sh --
set -ex

CFLAGS="${*:-}"
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o strncasecmp_both.o strncasecmp_both.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f bin -o strncasecmp_both.bin strncasecmp_both.nasm
nasm-0.98.39 $CFLAGS -O0 -w+orphan-labels -f bin -o strncasecmp_both.o0.bin strncasecmp_both.nasm
ndisasm -b 32 strncasecmp_both.bin | tail  # For the size.
if ! cmp strncasecmp_both.bin strncasecmp_both.o0.bin; then
  ndisasm-0.98.39 -b 32 strncasecmp_both.bin >strncasecmp_both.ndisasm
  ndisasm-0.98.39 -b 32 strncasecmp_both.o0.bin >strncasecmp_both.o0.ndisasm
  diff -U3 strncasecmp_both.ndisasm strncasecmp_both.o0.ndisasm
fi
qq xstatic gcc -m32 -Os -W -Wall -s -o test_strncasecmp_both.prog test_strncasecmp_both.c strncasecmp_both.o
./test_strncasecmp_both.prog

: "$0" OK.
