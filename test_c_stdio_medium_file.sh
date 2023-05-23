#! /bin/sh --
set -ex

# Similar to test_c_stdio_file_simple_unbuffered.sh .

CFLAGS="${*:-}"
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o stdio_medium_flush_opened.o stdio_medium_flush_opened.nasm  # We need this because of mini_fopen(...).
# !! Bad relocations for the weak symbol.
#nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -Dmini__start=_start -o start_stdio_medium_linux.o start_stdio_medium_linux.nasm
#objcopy -W mini___M_start_isatty_stdin -W mini___M_start_isatty_stdout -W mini___M_start_flush_stdout -W mini___M_start_flush_opened start_stdio_medium_linux.o start_stdio_medium_linux_weak.o  # !! Better tool.
yasm-1.3.0 $CFLAGS -O999999999 -w+orphan-labels -f elf -Dmini__start=_start -o start_stdio_medium_linux_weak.o start_stdio_medium_linux.nasm
ARGS="-D__MINILIBC686__ -m32 -Os -W -Wall -s -Werror=implicit-function-declaration -ffreestanding -Iinclude -nostdlib -nostdinc -pedantic c_stdio_medium_rest.c c_stdio_medium_for_printf.c c_stdio_medium_fopen.c demo_file_medium_copy.c stdio_medium_flush_opened.o start_stdio_medium_linux_weak.o"
#clang -static -o test_c_stdio_medium_file.prog -ansi $ARGS
qq xstatic gcc -o test_c_stdio_medium_file.prog -ansi $ARGS
qq xstatic gcc -o test_c_stdio_medium_file.macro.prog -ansi -DCONFIG_MACRO_GETC_PUTC -DCONFIG_MACRO_FILENO $ARGS
qq xstatic gcc -o test_c_stdio_medium_file.inline.prog -ansi -DCONFIG_INLINE_GETC_PUTC -DCONFIG_INLINE_FILENO $ARGS
tools/pts-tcc -o test_c_stdio_medium_file.tcc.prog -DCONFIG_MACRO_GETC_PUTC -DCONFIG_MACRO_FILENO $ARGS
echo foobar >f1.tmp.dat
: t1
rm -f f2.tmp.dat
if ./test_c_stdio_medium_file.prog f1.tmp.dat f2.tmp.dat; then :; else echo "$?"; exit 1; fi  # Copies f1.tmp.dat to f2.tmp.dat.
cmp f1.tmp.dat f2.tmp.dat
: t1b autoflush
rm -f f2.tmp.dat
if ./test_c_stdio_medium_file.prog f1.tmp.dat f2.tmp.dat a; then :; else echo "$?"; exit 1; fi  # Copies f1.tmp.dat to f2.tmp.dat.
cmp f1.tmp.dat f2.tmp.dat
: t2 overwritten
echo overwritten >f2.tmp.dat
if ./test_c_stdio_medium_file.prog f1.tmp.dat f2.tmp.dat; then :; else echo "$?"; exit 1; fi  # Copies f1.tmp.dat to f2.tmp.dat.
cmp f1.tmp.dat f2.tmp.dat
: t3
rm -f f1.tmp.dat
if ./test_c_stdio_medium_file.prog f1.tmp.dat f2.tmp.dat; then echo unexpected-success; exit 1; fi  # f1.tmp.dat doesn't exist, copy must fail.
: t4
awk 'BEGIN{for(i=0;i<=1000;++i){print "L",i}}' >f1.tmp.dat
rm -f f2.tmp.dat
if ./test_c_stdio_medium_file.prog f1.tmp.dat f2.tmp.dat; then :; else echo "$?"; exit 1; fi  # Copies long file f1.tmp.dat to f2.tmp.dat.
cmp f1.tmp.dat f2.tmp.dat
: t5 fgetc
rm -f f2.tmp.dat
if ./test_c_stdio_medium_file.prog f1.tmp.dat f2.tmp.dat c; then :; else echo "$?"; exit 1; fi  # Copies long file f1.tmp.dat to f2.tmp.dat.
cmp f1.tmp.dat f2.tmp.dat
: t6 fputc
rm -f f2.tmp.dat
if ./test_c_stdio_medium_file.prog f1.tmp.dat f2.tmp.dat p; then :; else echo "$?"; exit 1; fi  # Copies long file f1.tmp.dat to f2.tmp.dat.
cmp f1.tmp.dat f2.tmp.dat
: t7 putc
rm -f f2.tmp.dat
if ./test_c_stdio_medium_file.prog f1.tmp.dat f2.tmp.dat q; then :; else echo "$?"; exit 1; fi  # Copies long file f1.tmp.dat to f2.tmp.dat.
cmp f1.tmp.dat f2.tmp.dat
: t8 putc macro
rm -f f2.tmp.dat
if ./test_c_stdio_medium_file.macro.prog f1.tmp.dat f2.tmp.dat q; then :; else echo "$?"; exit 1; fi  # Copies long file f1.tmp.dat to f2.tmp.dat.
cmp f1.tmp.dat f2.tmp.dat
: t9 putc inline
rm -f f2.tmp.dat
if ./test_c_stdio_medium_file.inline.prog f1.tmp.dat f2.tmp.dat q; then :; else echo "$?"; exit 1; fi  # Copies long file f1.tmp.dat to f2.tmp.dat.
cmp f1.tmp.dat f2.tmp.dat
: t10 putc tcc
rm -f f2.tmp.dat
if ./test_c_stdio_medium_file.tcc.prog f1.tmp.dat f2.tmp.dat q; then :; else echo "$?"; exit 1; fi  # Copies long file f1.tmp.dat to f2.tmp.dat.
cmp f1.tmp.dat f2.tmp.dat
: t11 getc
rm -f f2.tmp.dat
if ./test_c_stdio_medium_file.prog f1.tmp.dat f2.tmp.dat d; then :; else echo "$?"; exit 1; fi  # Copies long file f1.tmp.dat to f2.tmp.dat.
cmp f1.tmp.dat f2.tmp.dat
: t12 getc macro
rm -f f2.tmp.dat
if ./test_c_stdio_medium_file.macro.prog f1.tmp.dat f2.tmp.dat d; then :; else echo "$?"; exit 1; fi  # Copies long file f1.tmp.dat to f2.tmp.dat.
cmp f1.tmp.dat f2.tmp.dat
: t13 getc inline
rm -f f2.tmp.dat
if ./test_c_stdio_medium_file.inline.prog f1.tmp.dat f2.tmp.dat d; then :; else echo "$?"; exit 1; fi  # Copies long file f1.tmp.dat to f2.tmp.dat.
cmp f1.tmp.dat f2.tmp.dat
: t14 getc tcc
rm -f f2.tmp.dat
if ./test_c_stdio_medium_file.tcc.prog f1.tmp.dat f2.tmp.dat d; then :; else echo "$?"; exit 1; fi  # Copies long file f1.tmp.dat to f2.tmp.dat.
cmp f1.tmp.dat f2.tmp.dat
: t15 fseek
rm -f f2.tmp.dat
if ./test_c_stdio_medium_file.prog f1.tmp.dat f2.tmp.dat s; then :; else echo "$?"; exit 1; fi  # Copies long file f1.tmp.dat to f2.tmp.dat.
cmp f1.tmp.dat f2.tmp.dat

rm -f f1.tmp.dat f2.tmp.dat

: "$0" OK.
