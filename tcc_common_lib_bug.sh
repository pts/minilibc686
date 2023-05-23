#! /bin/sh --

set -ex
LIBOBJS="stdio_medium_vfprintf.o printf_callvf.o fprintf_callvf.o stdio_medium_getchar.o stdio_medium_putchar.o start_stdio_medium_linux.o stdio_medium_init_isatty.o isatty_linux.o stdio_medium_flushall.o stdio_medium_stdin.o stdio_medium_stdout.o stdio_medium_stderr.o"
tools/pts-tcc -o t1 -DCONFIG_INLINE_GETC_PUTC -D__MINILIBC686__ -m32 -Os -W -Wall -s -Werror=implicit-function-declaration -ffreestanding -Iinclude -nostdlib -nostdinc -pedantic c_stdio_medium.c test_stdstream.c $LIBOBJS
rm -f t.a
tools/tiny_libmaker t.a $LIBOBJS
tools/pts-tcc -o t2 -DCONFIG_INLINE_GETC_PUTC -D__MINILIBC686__ -m32 -Os -W -Wall -s -Werror=implicit-function-declaration -ffreestanding -Iinclude -nostdlib -nostdinc -pedantic c_stdio_medium.c test_stdstream.c t.a
: "./t1 calls ioctl at startup (because of mini___M_init_isatty in stdio_medium_init_isatty.o), ./t2 doesn not"
