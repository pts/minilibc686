#! /bin/sh --
#
# libc_include_test.sh: test that libc #include files work
# by pts@fazekas.hu at Mon Jun 19 13:26:06 CEST 2023
#
# !! TODO(pts): Check that no external symbols referenced in any libc, especially not __builtin_... -- this follows from empty code; check -c output.
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

for LIBC in minilibc dietlibc-0.34 uclibc-0.9.30.1 eglibc-2.19; do
  for COMPILER in --gcc=/usr/bin/clang --gcc=/usr/bin/gcc --gcc=4.8 --gcc=4.1 --gcc=4.4 --pcc --tcc --wcc; do
    for STD in '' '-pedantic' '-ansi' '-ansi -pedantic' '-std=c99' '-std=c99 -pedantic'; do
      for SRC in test_include.c test_include_rev.c; do
        CMD="pathbin/minicc --libc=$LIBC $COMPILER $STD -c -o test_include.tmp.o libc/$LIBC/$SRC"
        echo "info: running compiler: $CMD" >&2
        rm -f test_include.tmp.o test_include.tmp.err || exit "$?"
        $CMD 2>test_include.tmp.err >&2; EC="$?"
        if test "$EC" != 0; then cat test_include.tmp.err >&2; exit "$?"; fi
        if test -s test_include.tmp.err; then echo "fatal: found errors" >&2; cat test_include.tmp.err >&2; exit "$?"; fi
        /usr/bin/objdump -d test_include.tmp.o 2>test_include.tmp.err >&2; EC="$?"
        if test "$EC" != 0; then cat test_include.tmp.err; exit "$?"; fi
        if ! awk 'length($0)&&!/^test_include[.]tmp[.]o:/{exit 1}' <test_include.tmp.err; then echo "fatal: found errors" >&2; cat test_include.tmp.err >&2; exit "$?"; fi
      done
    done
  done
done
rm -f test_include.tmp.o test_include.tmp.err  # TODO(pts): Clean up unconditionally by defauilt.

printf "info: done running include tests, all \\033[0;32msucceeded\033[0m\n" >&2
