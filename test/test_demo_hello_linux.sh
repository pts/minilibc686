#! /bin/sh --
# by pts@fazekas.hu at Wed May 17 03:32:07 CEST 2023

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

CFLAGS="${*:-}"
#$NASM $CFLAGS -O999999999 -w+orphan-labels -f elf -o demo_hello_linux.o demo_hello_linux.nasm
$NASM $CFLAGS -O999999999 -w+orphan-labels -f bin -o demo_hello_linux.elf demo_hello_linux.nasm
$NASM $CFLAGS -O0 -w+orphan-labels -f bin -o demo_hello_linux.o0.elf demo_hello_linux.nasm
if test "$NDISASM"; then
  $NDISASM -b 32 demo_hello_linux.elf | tail  # For the size.
fi
if ! cmp demo_hello_linux.elf demo_hello_linux.o0.elf; then
  if test "$NDISASM"; then
    $NDISASM -b 32 -e 0x54 demo_hello_linux.elf >demo_hello_linux.ndisasm
    $NDISASM -b 32 -e 0x54 demo_hello_linux.o0.elf >demo_hello_linux.o0.ndisasm
    diff -U3 demo_hello_linux.ndisasm demo_hello_linux.o0.ndisasm
  fi
  : error: nasm optimization diff found.
  exit 2
fi
chmod +x demo_hello_linux.elf
./demo_hello_linux.elf  # Prints: Hello, World!
./demo_hello_linux.elf a  # Prints: ello, World!
./demo_hello_linux.elf foo b  # Prints: llo, World!
env -i MYVAR=myvalue ./demo_hello_linux.elf foo b ar  # Prints: MYVAR=myvaluelo, World!

: "$0" OK.
