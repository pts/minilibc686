#! /bin/sh --
set -ex

CFLAGS="${*:-}"
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o start_stdio_linux.o start_stdio_linux.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f bin -o start_stdio_linux.bin start_stdio_linux.nasm
nasm-0.98.39 $CFLAGS -O0 -w+orphan-labels -f bin -o start_stdio_linux.o0.bin start_stdio_linux.nasm
ndisasm -b 32 start_stdio_linux.bin | tail  # For the size.
if ! cmp start_stdio_linux.bin start_stdio_linux.o0.bin; then
  ndisasm-0.98.39 -b 32 start_stdio_linux.bin >start_stdio_linux.ndisasm
  ndisasm-0.98.39 -b 32 start_stdio_linux.o0.bin >start_stdio_linux.o0.ndisasm
  diff -U3 start_stdio_linux.ndisasm start_stdio_linux.o0.ndisasm
fi
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o m_flushall_dummy.o m_flushall_dummy.nasm
qq xstatic gcc -m32 -Os -W -Wall -s -o test_start_stdio_linux.prog test_start.c start_stdio_linux.o m_flushall_dummy.o
./test_start_stdio_linux.prog

: "$0" OK.
