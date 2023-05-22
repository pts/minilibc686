#! /bin/sh --

if test "$NASM"; then :
elif nasm-0.98.39 -h 2>/dev/null >&2; then NASM=nasm-0.98.39
elif nasm -h 2>/dev/null >&2; then NASM=nasm
else NASM=nasm  # Will fail.
fi

if test "$NDISASM"; then :
elif ndisasm-0.98.39 -h 2>/dev/null >&2; then NDISASM=ndisasm-0.98.39
elif ndisasm -h 2>/dev/null >&2; then NDISASM=ndisasm
else NDISASM=  # Disabled.
fi

set -ex

# Similar to test_c_stdio_file_simple_unbuffered.sh .

CFLAGS="${*:-}"

nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -Dmini__start=_start -o start_stdio_file_linux.o start_stdio_file_linux.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f bin -o start_stdio_file_linux.bin start_stdio_file_linux.nasm
nasm-0.98.39 $CFLAGS -O0 -w+orphan-labels -f bin -o start_stdio_file_linux.o0.bin start_stdio_file_linux.nasm
ndisasm -b 32 start_stdio_file_linux.bin | tail  # For the size.
if ! cmp start_stdio_file_linux.bin start_stdio_file_linux.o0.bin; then
  ndisasm-0.98.39 -b 32 start_stdio_file_linux.bin >start_stdio_file_linux.ndisasm
  ndisasm-0.98.39 -b 32 start_stdio_file_linux.o0.bin >start_stdio_file_linux.o0.ndisasm
  diff -U3 start_stdio_file_linux.ndisasm start_stdio_file_linux.o0.ndisasm
fi

"$NASM" $CFLAGS -O999999999 -w+orphan-labels -f elf -o stdio_file_simple_buffered.o stdio_file_simple_buffered.nasm
"$NASM" $CFLAGS -O999999999 -w+orphan-labels -f bin -o stdio_file_simple_buffered.bin stdio_file_simple_buffered.nasm
"$NASM" $CFLAGS -O0 -w+orphan-labels -f bin -o stdio_file_simple_buffered.o0.bin stdio_file_simple_buffered.nasm
"$NDISASM" -b 32 stdio_file_simple_buffered.bin | tail  # For the size.
if ! cmp stdio_file_simple_buffered.bin stdio_file_simple_buffered.o0.bin; then
  "$NDISASM" -b 32 stdio_file_simple_buffered.bin >stdio_file_simple_buffered.ndisasm
  "$NDISASM" -b 32 stdio_file_simple_buffered.o0.bin >stdio_file_simple_buffered.o0.ndisasm
  diff -U3 stdio_file_simple_buffered.ndisasm stdio_file_simple_buffered.o0.ndisasm
fi

qq xstatic gcc -m32 -Os -W -Wall -s -Werror=implicit-function-declaration -nostdlib -nostdinc -o test_stdio_file_simple_buffered.prog stdio_file_simple_buffered.o demo_file_simple_copy.c start_stdio_file_linux.o
echo foobar >f1.tmp.dat
: t1
rm -f f2.tmp.dat
if ./test_stdio_file_simple_buffered.prog f1.tmp.dat f2.tmp.dat; then :; else echo "$?"; exit 1; fi  # Copies f1.tmp.dat to f2.tmp.dat.
cmp f1.tmp.dat f2.tmp.dat
: t1b autoflush
rm -f f2.tmp.dat
if ./test_stdio_file_simple_buffered.prog f1.tmp.dat f2.tmp.dat a; then :; else echo "$?"; exit 1; fi  # Copies f1.tmp.dat to f2.tmp.dat.
cmp f1.tmp.dat f2.tmp.dat
: t2 overwritten
echo overwritten >f2.tmp.dat
if ./test_stdio_file_simple_buffered.prog f1.tmp.dat f2.tmp.dat; then :; else echo "$?"; exit 1; fi  # Copies f1.tmp.dat to f2.tmp.dat.
cmp f1.tmp.dat f2.tmp.dat
: t3
rm -f f1.tmp.dat
if ./test_stdio_file_simple_buffered.prog f1.tmp.dat f2.tmp.dat; then echo unexpected-success; exit 1; fi  # f1.tmp.dat doesn't exist, copy must fail.
: t4
awk 'BEGIN{for(i=0;i<=1000;++i){print "L",i}}' >f1.tmp.dat
rm -f f2.tmp.dat
if ./test_stdio_file_simple_buffered.prog f1.tmp.dat f2.tmp.dat; then :; else echo "$?"; exit 1; fi  # Copies long file f1.tmp.dat to f2.tmp.dat.
cmp f1.tmp.dat f2.tmp.dat
: t5 fgetc
rm -f f2.tmp.dat
if ./test_stdio_file_simple_buffered.prog f1.tmp.dat f2.tmp.dat c; then :; else echo "$?"; exit 1; fi  # Copies long file f1.tmp.dat to f2.tmp.dat.
cmp f1.tmp.dat f2.tmp.dat
: t6 fseek
rm -f f2.tmp.dat
if ./test_stdio_file_simple_buffered.prog f1.tmp.dat f2.tmp.dat s; then :; else echo "$?"; exit 1; fi  # Copies long file f1.tmp.dat to f2.tmp.dat.
cmp f1.tmp.dat f2.tmp.dat

rm -f f1.tmp.dat f2.tmp.dat

: "$0" OK.
