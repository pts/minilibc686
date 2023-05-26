#! /bin/sh --
set -ex

CFLAGS="${*:-}"
OBJS="i64_udivdi3.o i64_umoddi3.o i64_divdi3.o i64_moddi3.o i64_u8d.o i64_i8d.o m_flushall_dummy.o strlen.o"
for OBJ in $OBJS; do
  nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o "$OBJ" "${OBJ%.*}".nasm
done
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -Dmini__start=_start -o start_stdio_file_linux.o start_stdio_file_linux.nasm
qq xstatic gcc -m32 -Os -W -Wall -s -Werror=implicit-function-declaration -Iinclude -nostdlib -nostdinc -o test_long_long.prog test_long_long.c $OBJS start_stdio_file_linux.o
./test_long_long.prog 1234567890123456789 9876543210
RESULT="$(./test_long_long.prog 1234567890123456789 9876543210 ||:)"
test "$RESULT" = 8626543209

: "$0" OK.
