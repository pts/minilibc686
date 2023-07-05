#! /bin/sh --
#
# e2e_test.sh: run some end-to-end tests using minicc
# by pts@fazekas.hu at Wed Jun  7 11:51:11 CEST 2023
#

unset MYDIR
MYDIR="$(readlink "$0" 2>/dev/null)"
if test "$MYDIR"; then test "${MYDIR#/}" = "$MYDIR" && MYDIR="${0%/*}/$MYDIR"
else MYDIR="$0"
fi
MYDIR="${MYDIR%/*}"
# Use BusyBox (if available) for consistent shell and coreutils.
# Use empty environment (env -i) for reproducible tests.
test -z "$BUSYBOX_SH_SCRIPT" && test -f "$MYDIR/shbin/env" &&
    exec "$MYDIR/shbin/env" -i BUSYBOX_SH_SCRIPT=1 PATH="$MYDIR/shbin" sh -- "$0" "$@"
unset BUSYBOX_SH_SCRIPT

set -ex

cd "$MYDIR"
export PATH=shbin
test -d e2e_test_tmp || mkdir e2e_test_tmp
test -d e2e_test_tmp
cd e2e_test_tmp
MYDIR=..
export PATH="$MYDIR/shbin"
SRC="$MYDIR"/src

"$MYDIR"/tools/nasm-0.98.39 -I"$MYDIR"/ -O0 -w+orphan-labels -f bin -o demo_hello_linux_printf.prog "$MYDIR"/demo_hello_linux_printf.nasm
chmod +x demo_hello_linux_printf.prog
./demo_hello_linux_printf.prog
test "$(./demo_hello_linux_printf.prog)" = "Hello, World!"
"$MYDIR"/tools/nasm-0.98.39 -I"$MYDIR"/ -O0 -w+orphan-labels -f elf -o demo_hello_linux_printf.o "$MYDIR"/demo_hello_linux_printf.nasm

"$MYDIR"/tools/nasm-0.98.39 -I"$MYDIR"/ -O0 -w+orphan-labels -f bin -o demo_hello_linux_snprintf.prog "$MYDIR"/test/demo_hello_linux_snprintf.nasm
chmod +x demo_hello_linux_snprintf.prog
./demo_hello_linux_snprintf.prog
test "$(./demo_hello_linux_snprintf.prog)" = "Hello, World!"
"$MYDIR"/tools/nasm-0.98.39 -I"$MYDIR"/ -O0 -w+orphan-labels -f elf -o demo_hello_linux_snprintf.o "$MYDIR"/test/demo_hello_linux_snprintf.nasm

"$MYDIR"/build.sh
"$MYDIR"/pathbin/minicc -mprintf-mini -mno-envp -v -o demo_hello_linux_printf.prog2 demo_hello_linux_printf.o
cmp demo_hello_linux_printf.prog demo_hello_linux_printf.prog2
"$MYDIR"/pathbin/minicc -mprintf-mini -mno-envp -v -o demo_hello_linux_snprintf.prog2 demo_hello_linux_snprintf.o
cmp demo_hello_linux_snprintf.prog demo_hello_linux_snprintf.prog2
#exit 1

"$MYDIR"/test.sh

set +ex
ls -ld demo_hello_linux_printf.prog demo_hello_linux_snprintf.prog
cd ..
export PATH=shbin
rm -rf e2e_test_tmp
printf "info: done running end-to-end tests, all \\033[0;32msucceeded\033[0m\n" >&2
