#! /bin/sh --
# by pts@fazekas.hu at Wed May 17 02:43:02 CEST 2023

if test "$NASM"; then :
elif nasm-0.98.39 -h 2>/dev/null >&2; then NASM=nasm-0.98.39
elif nasm -h 2>/dev/null >&2; then NASM=nasm
else NASM=nasm  # Will fail.
fi

if test "$GCC" = :; then GCC=  # Explicitly disabled.
elif qq gcc -print-libgcc-file-name 2>/dev/null >&2; then GCC="qq gcc"
elif gcc -print-libgcc-file-name 2>/dev/null >&2; then GCC=gcc
elif clang -print-libgcc-file-name 2>/dev/null >&2; then GCC=clang  # Also accepts the $GCC_FLAGS.
else GCC=  # Disabled.
fi

if test "$TCC" = :; then TCC=  # Explicitly disabled.
elif test "$TCC"; then :
elif pts-tcc -v 2>/dev/null >&2; then TCC=pts-tcc
elif i386-tcc -v 2>/dev/null >&2; then TCC=i386-tcc
elif tcc -v 2>/dev/null; then TCC=tcc
else TCC=  # Disabled.
fi

set -ex

CFLAGS="${*:-}"
OFS="vfprintf_noplus.o printf_callvf.o fputc_unbuffered.o write_linux.o start_nomini_linux.o"
for OF in $OFS; do
  $NASM $CFLAGS -O999999999 -w+orphan-labels -f elf -o "$OF" "${OF%.*}.nasm"
done
# !! TODO(pts): Buiild an .a archive.

# -Wl,-e,mini__start is not supported by tcc.
# tcc either supports or silently ignores these $GCC_FLAGS.
GCC_TCC_FLAGS="-m32 -march=i386 -static -s -fno-pic -Os -W -Wall -Werror -U_FORTIFY_SOURCE -fno-stack-protector -fno-unwind-tables -fno-asynchronous-unwind-tables -fno-builtin -fno-ident -fsigned-char -ffreestanding -fno-lto -nostdlib -nostdinc"
GCC_FLAGS="-Wl,--build-id=none"
case "$GCC" in
*clang*) GCC_FLAGS="$GCC_FLAGS -mstack-alignment=2" ;;
*) GCC_FLAGS="$GCC_FLAGS -falign-functions=1 -falign-jumps=1 -falign-loops=1 -mpreferred-stack-boundary=2" ;;
esac

if test "$GCC"; then
  $GCC $GCC_TCC_FLAGS $GCC_FLAGS -Os -W -Wall -o demo_c_hello_linux.prog demo_c_hello.c $OFS
  ./demo_c_hello_linux.prog  # Prints: Hello, World!
  ./demo_c_hello_linux.prog there  # Prints: Hello, there!
fi

if test "$TCC"; then
  $TCC $GCC_TCC_FLAGS -Os -W -Wall -o demo_c_hello_linux.tcc.prog demo_c_hello.c $OFS
  ./demo_c_hello_linux.tcc.prog  # Prints: Hello, World!
  ./demo_c_hello_linux.tcc.prog there  # Prints: Hello, there!
fi

: "$0" OK.
