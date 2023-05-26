#! /bin/sh --
set -ex

CFLAGS="${*:-}"

nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o lseek64_linux.o lseek64_linux.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f bin -o lseek64_linux.bin lseek64_linux.nasm
nasm-0.98.39 $CFLAGS -O0 -w+orphan-labels -f bin -o lseek64_linux.o0.bin lseek64_linux.nasm
ndisasm -b 32 lseek64_linux.bin | tail  # For the size.
if ! cmp lseek64_linux.bin lseek64_linux.o0.bin; then
  ndisasm-0.98.39 -b 32 lseek64_linux.bin >lseek64_linux.ndisasm
  ndisasm-0.98.39 -b 32 lseek64_linux.o0.bin >lseek64_linux.o0.ndisasm
  diff -U3 lseek64_linux.ndisasm lseek64_linux.o0.ndisasm
fi

nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o lseek64_set_linux.o lseek64_set_linux.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f bin -o lseek64_set_linux.bin lseek64_set_linux.nasm
nasm-0.98.39 $CFLAGS -O0 -w+orphan-labels -f bin -o lseek64_set_linux.o0.bin lseek64_set_linux.nasm
ndisasm -b 32 lseek64_set_linux.bin | tail  # For the size.
if ! cmp lseek64_set_linux.bin lseek64_set_linux.o0.bin; then
  ndisasm-0.98.39 -b 32 lseek64_set_linux.bin >lseek64_set_linux.ndisasm
  ndisasm-0.98.39 -b 32 lseek64_set_linux.o0.bin >lseek64_set_linux.o0.ndisasm
  diff -U3 lseek64_set_linux.ndisasm lseek64_set_linux.o0.ndisasm
fi
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -Dmini__start=_start -o start_stdio_file_linux.o start_stdio_file_linux.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o m_flushall_dummy.o m_flushall_dummy.nasm
qq gcc -nostdlib -nostdinc -Iinclude -m32 -Os -W -Wall -s -o test_lseek64_linux.prog test_lseek64.c lseek64_linux.o lseek64_set_linux.o m_flushall_dummy.o start_stdio_file_linux.o
if ./test_lseek64_linux.prog; then :; else echo "$?"; exit 1; fi

: "$0" OK.
