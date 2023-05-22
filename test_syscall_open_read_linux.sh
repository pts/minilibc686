#! /bin/sh --
set -ex

CFLAGS="${*:-}"
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -Dmini__start=_start -o start_stdio_file_linux.o start_stdio_file_linux.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o syscall_linux.o syscall_linux.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f bin -o syscall_linux.bin syscall_linux.nasm
nasm-0.98.39 $CFLAGS -O0 -w+orphan-labels -f bin -o syscall_linux.o0.bin syscall_linux.nasm
ndisasm -b 32 syscall_linux.bin | tail  # For the size.
if ! cmp syscall_linux.bin syscall_linux.o0.bin; then
  ndisasm-0.98.39 -b 32 syscall_linux.bin >syscall_linux.ndisasm
  ndisasm-0.98.39 -b 32 syscall_linux.o0.bin >syscall_linux.o0.ndisasm
  diff -U3 syscall_linux.ndisasm syscall_linux.o0.ndisasm
fi

nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o m_flushall_dummy.o m_flushall_dummy.nasm

qq gcc -nostdlib -nostdinc -Iinclude -m32 -Os -W -Wall -s -o test_syscall_open_read_linux.prog test_syscall_open_read.c syscall_linux.o m_flushall_dummy.o start_stdio_file_linux.o
if ./test_syscall_open_read_linux.prog; then :; else echo "$?"; exit 1; fi

: "$0" OK.
