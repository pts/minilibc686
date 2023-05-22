#! /bin/sh --
set -ex

# Similar to test_c_stdio_file_simple_unbuffered.sh .

CFLAGS="${*:-}"
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o stdio_medium_vfprintf.o stdio_medium_vfprintf.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o printf_callvf.o printf_callvf.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o fprintf_callvf.o fprintf_callvf.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o stdio_medium_stdout.o stdio_medium_stdout.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -Dmini__start=_start -o start_stdio_file_linux.o start_stdio_file_linux.nasm
ARGS="-m32 -Os -W -Wall -s -Werror=implicit-function-declaration -Iinclude -nostdlib -nostdinc -pedantic c_stdio_medium.c test_stdstream.c stdio_medium_vfprintf.o printf_callvf.o fprintf_callvf.o stdio_medium_stdout.o start_stdio_file_linux.o"
#clang -static -o test_c_stdio_medium_stdstream.prog -ansi $ARGS
qq xstatic gcc -o test_c_stdio_medium_stdstream.prog -ansi $ARGS
# tools/pts-tcc -o test_c_stdio_medium.tcc.prog $ARGS

: t1
if ./test_c_stdio_medium_stdstream.prog; then :; else echo "$?"; exit 1; fi  # Copies f1.tmp.dat to f2.tmp.dat.
RESULT="$(./test_c_stdio_medium_stdstream.prog 2>&1 ||:)"
test "$RESULT" = "Hello, World!"

: "$0" OK.