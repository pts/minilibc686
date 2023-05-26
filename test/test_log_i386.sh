#! /bin/sh --
set -ex

CFLAGS="-DCONFIG_I386 ${*:-}"
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o log_i586.o log.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f bin -o log_i586.bin log.nasm
nasm-0.98.39 $CFLAGS -O0 -w+orphan-labels -f bin -o log_i586.o0.bin log.nasm
ndisasm -b 32 log_i586.bin | tail  # For the size.
if ! cmp log_i586.bin log_i586.o0.bin; then
  ndisasm-0.98.39 -b 32 log_i586.bin >log_i586.ndisasm
  ndisasm-0.98.39 -b 32 log_i586.o0.bin >log_i586.o0.ndisasm
  diff -U3 log_i586.ndisasm log_i586.o0.ndisasm
fi
qq xstatic gcc -m32 -Os -W -Wall -s -o test_log_i586.prog test_log.c log_i586.o
./test_log_i586.prog

: "$0" OK.
