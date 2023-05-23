#! /bin/sh --
set -ex

CFLAGS="${*:-}"
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o stdio_medium_vfprintf.o stdio_medium_vfprintf.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o printf_callvf.o printf_callvf.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o vprintf_callvf.o vprintf_callvf.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o fprintf_callvf.o fprintf_callvf.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o stdio_medium_stdin.o stdio_medium_stdin.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o stdio_medium_stdout.o stdio_medium_stdout.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o stdio_medium_stderr.o stdio_medium_stderr.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o stdio_medium_getchar.o stdio_medium_getchar.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o stdio_medium_putchar.o stdio_medium_putchar.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o stdio_medium_init_isatty.o stdio_medium_init_isatty.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o stdio_medium_flushall.o stdio_medium_flushall.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o stdio_medium_sprintf.o stdio_medium_sprintf.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o stdio_medium_vsprintf.o stdio_medium_vsprintf.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o stdio_medium_snprintf.o stdio_medium_snprintf.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o stdio_medium_vsnprintf.o stdio_medium_vsnprintf.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o isatty_linux.o isatty_linux.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o strcmp.o strcmp.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -Dmini__start=_start -o start_stdio_medium_linux.o start_stdio_medium_linux.nasm
# Moving start_stdio_medium_linux.o earlier to avoid (harmless, exit(0)) pts-tcc linker error: start_stdio_medium_linux.o: error: 'mini___M_stdout_for_flushall' defined twice.
ARGS="-D__MINILIBC686__ -m32 -Os -W -Wall -s -Werror=implicit-function-declaration -ffreestanding -Iinclude -nostdlib -nostdinc -pedantic c_stdio_medium_rest.c c_stdio_medium_for_printf.c test_stdstream.c stdio_medium_sprintf.o stdio_medium_vsprintf.o stdio_medium_snprintf.o stdio_medium_vsnprintf.o stdio_medium_vfprintf.o printf_callvf.o vprintf_callvf.o fprintf_callvf.o stdio_medium_getchar.o stdio_medium_putchar.o start_stdio_medium_linux.o stdio_medium_init_isatty.o isatty_linux.o stdio_medium_flushall.o stdio_medium_stdin.o stdio_medium_stdout.o stdio_medium_stderr.o strcmp.o"
#clang -static -o test_c_stdio_medium_stdstream.prog -ansi $ARGS
qq xstatic gcc -o test_c_stdio_medium_stdstream.prog -ansi $ARGS
qq xstatic gcc -o test_c_stdio_medium_stdstream.macro.prog -ansi -DCONFIG_MACRO_GETC_PUTC $ARGS
qq xstatic gcc -o test_c_stdio_medium_stdstream.inline.prog -ansi -DCONFIG_INLINE_GETC_PUTC $ARGS
tools/pts-tcc -o test_c_stdio_medium_stdstream.tcc.prog -DCONFIG_INLINE_GETC_PUTC $ARGS

if ./test_c_stdio_medium_stdstream.prog; then :; else echo "$?"; exit 1; fi  # Copies f1.tmp.dat to f2.tmp.dat.
RESULT="$(./test_c_stdio_medium_stdstream.prog 2>&1 ||:)"
test "$RESULT" = "Hello, World!"
RESULT="$(echo foobar | ./test_c_stdio_medium_stdstream.prog c ||:)"
test "$RESULT" = "foobar"

: copy using getc+putc
awk 'BEGIN{for(i=0;i<=1000;++i){print "L",i}}' >f1.tmp.dat
./test_c_stdio_medium_stdstream.prog c <f1.tmp.dat >f2.tmp.dat
cmp f1.tmp.dat f2.tmp.dat

./test_c_stdio_medium_stdstream.macro.prog c <f1.tmp.dat >f2.tmp.dat
cmp f1.tmp.dat f2.tmp.dat

./test_c_stdio_medium_stdstream.inline.prog c <f1.tmp.dat >f2.tmp.dat
cmp f1.tmp.dat f2.tmp.dat

./test_c_stdio_medium_stdstream.tcc.prog c <f1.tmp.dat >f2.tmp.dat
cmp f1.tmp.dat f2.tmp.dat

: copy using getchar+putchar
./test_c_stdio_medium_stdstream.prog h <f1.tmp.dat >f2.tmp.dat
cmp f1.tmp.dat f2.tmp.dat

./test_c_stdio_medium_stdstream.macro.prog h <f1.tmp.dat >f2.tmp.dat
cmp f1.tmp.dat f2.tmp.dat

./test_c_stdio_medium_stdstream.inline.prog h <f1.tmp.dat >f2.tmp.dat
cmp f1.tmp.dat f2.tmp.dat

./test_c_stdio_medium_stdstream.tcc.prog h <f1.tmp.dat >f2.tmp.dat
cmp f1.tmp.dat f2.tmp.dat

: 'To test line buffering of stdin and stdout on a TTY manually, run ./test_c_stdio_medium_stdstream.prog, type something and press <Enter>. It should be repeated.'

rm -f f1.tmp.dat f2.tmp.dat

: "$0" OK.
