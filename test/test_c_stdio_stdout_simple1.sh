#! /bin/sh --
set -ex

CFLAGS="${*:-}"
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o printf_callvf.o printf_callvf.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o vfprintf_noplus.o vfprintf_noplus.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o write_linux.o write_linux.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -Dmini__start=_start -o start_stdio_linux.o start_stdio_linux.nasm
qq xstatic gcc -m32 -Os -W -Wall -s -Werror=implicit-function-declaration -nostdlib -nostdinc -o test_c_stdio_stdout_simple1.prog test_printf.c printf_callvf.o vfprintf_noplus.o c_stdio_stdout_simple1.c write_linux.o start_stdio_linux.o
./test_c_stdio_stdout_simple1.prog  # Prints: Hello, World!
./test_c_stdio_stdout_simple1.prog there  # Prints: Hello, there!

: "$0" OK.