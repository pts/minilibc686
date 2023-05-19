#! /bin/sh --
set -ex

CFLAGS="${*:-}"
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o start_stdio_file_nomini_linux.o start_stdio_file_nomini_linux.nasm
qq xstatic gcc -m32 -Os -W -Wall -s -Werror=implicit-function-declaration -nostdlib -nostdinc -o test_c_stdio_file_simple_unbuffered.prog c_stdio_file_simple_unbuffered.c demo_file_simple_copy.c start_stdio_file_nomini_linux.o
echo foobar >f1.tmp.dat
: t1
rm -f f2.tmp.dat
if ./test_c_stdio_file_simple_unbuffered.prog f1.tmp.dat f2.tmp.dat; then :; else echo "$?"; exit 1; fi  # Copies f1.tmp.dat to f2.tmp.dat.
cmp f1.tmp.dat f2.tmp.dat
: t2
echo bad >f2.tmp.dat
if ./test_c_stdio_file_simple_unbuffered.prog f1.tmp.dat f2.tmp.dat; then :; else echo "$?"; exit 1; fi  # Copies f1.tmp.dat to f2.tmp.dat.
cmp f1.tmp.dat f2.tmp.dat
: t3
rm -f f1.tmp.dat
if ./test_c_stdio_file_simple_unbuffered.prog f1.tmp.dat f2.tmp.dat; then echo unexpected-success; exit 1; fi  # f1.tmp.dat doesn't exist, copy must fail.
: t4
awk 'BEGIN{for(i=0;i<=10000;++i){print "L",i}}' >f1.tmp.dat
rm -f f2.tmp.dat
if ./test_c_stdio_file_simple_unbuffered.prog f1.tmp.dat f2.tmp.dat; then :; else echo "$?"; exit 1; fi  # Copies long file f1.tmp.dat to f2.tmp.dat.
rm -f f1.tmp.dat f2.tmp.dat

: "$0" OK.
