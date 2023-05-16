#! /bin/sh --
set -ex

CFLAGS="${*:-}"
#nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o demo_hello_linux_nolibc.o demo_hello_linux_nolibc.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f bin -o demo_hello_linux_nolibc.elf demo_hello_linux_nolibc.nasm
nasm-0.98.39 $CFLAGS -O0 -w+orphan-labels -f bin -o demo_hello_linux_nolibc.o0.elf demo_hello_linux_nolibc.nasm
ndisasm -b 32 demo_hello_linux_nolibc.elf | tail  # For the size.
if ! cmp demo_hello_linux_nolibc.elf demo_hello_linux_nolibc.o0.elf; then
  ndisasm-0.98.39 -b 32 demo_hello_linux_nolibc.elf >demo_hello_linux_nolibc.ndisasm
  ndisasm-0.98.39 -b 32 demo_hello_linux_nolibc.o0.elf >demo_hello_linux_nolibc.o0.ndisasm
  diff -U3 demo_hello_linux_nolibc.ndisasm demo_hello_linux_nolibc.o0.ndisasm
fi
chmod +x demo_hello_linux_nolibc.elf
./demo_hello_linux_nolibc.elf

: "$0" OK.
