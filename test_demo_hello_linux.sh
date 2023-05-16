#! /bin/sh --
set -ex

CFLAGS="${*:-}"
#nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f elf -o demo_hello_linux.o demo_hello_linux.nasm
nasm-0.98.39 $CFLAGS -O999999999 -w+orphan-labels -f bin -o demo_hello_linux.elf demo_hello_linux.nasm
nasm-0.98.39 $CFLAGS -O0 -w+orphan-labels -f bin -o demo_hello_linux.o0.elf demo_hello_linux.nasm
ndisasm -b 32 demo_hello_linux.elf | tail  # For the size.
if ! cmp demo_hello_linux.elf demo_hello_linux.o0.elf; then
  ndisasm-0.98.39 -b 32 demo_hello_linux.elf >demo_hello_linux.ndisasm
  ndisasm-0.98.39 -b 32 demo_hello_linux.o0.elf >demo_hello_linux.o0.ndisasm
  diff -U3 demo_hello_linux.ndisasm demo_hello_linux.o0.ndisasm
fi
chmod +x demo_hello_linux.elf
./demo_hello_linux.elf  # Prints: Hello, World!
./demo_hello_linux.elf a  # Prints: ello, World!
./demo_hello_linux.elf foo b  # Prints: llo, World!
env -i MYVAR=myvalue ./demo_hello_linux.elf foo b ar  # Prints: MYVAR=myvaluelo, World!

: "$0" OK.
