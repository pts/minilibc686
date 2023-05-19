#! /bin/sh --
set -ex

CFLAGS="${*:-}"
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o printf_callvf.o printf_callvf.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o vfprintf_noplus.o vfprintf_noplus.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o write_linux.o write_linux.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o start_stdio_nomini_linux.o start_stdio_nomini_linux.nasm
qq xstatic gcc -m32 -Os -W -Wall -Werror=implicit-function-declaration -nostdlib -nostdinc -s -o test_c_stdio_stdout_simple2.prog demo_c_hello.c printf_callvf.o vfprintf_noplus.o c_stdio_stdout_simple2.c write_linux.o start_stdio_nomini_linux.o
./test_c_stdio_stdout_simple2.prog  # Prints: Hello, World!
./test_c_stdio_stdout_simple2.prog there  # Prints: Hello, there!

: "$0" OK.
