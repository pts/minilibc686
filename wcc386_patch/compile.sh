#! /bin/sh --
# by pts@fazekas.hu at Thu Jun 22 00:00:20 CEST 2023

unset MYDIR
MYDIR="$(readlink "$0" 2>/dev/null)"
if test "$MYDIR"; then test "${MYDIR#/}" = "$MYDIR" && MYDIR="${0%/*}/$MYDIR"
else MYDIR="$0"
fi
MYDIR="${MYDIR%/*}"
# Use BusyBox (if available) for consistent shell and coreutils.
# Use empty environment (env -i) for reproducible tests.
test -z "$BUSYBOX_SH_SCRIPT" && test -f "$MYDIR/../shbin/env" &&
    exec "$MYDIR/../shbin/env" -i BUSYBOX_SH_SCRIPT=1 PATH="$MYDIR/../shbin" sh -- "$0" "$@"
unset BUSYBOX_SH_SCRIPT

set -ex

cd "$MYDIR"
export PATH=../shbin

../tools/nasm-0.98.39 -O0 -w+orphan-labels -f bin -o wcc386.unc wcc386p.nasm
chmod +x wcc386.unc
cmp -l wcc386.unc.golden wcc386.unc

../tools/nasm-0.98.39 -DCONFIG_PATCH -O0 -w+orphan-labels -f bin -o wcc386p.unc wcc386p.nasm
chmod +x wcc386p.unc
cmp -l wcc386.unc.golden wcc386p.unc ||:

# With `-ec', it would put string literals to segment YIB, otherwise (by
# default) CONST. It would ignore `-zc' (string literals to CODE).
: './wcc386p.unc -ec -s -j -of+ -bt=linux -fr -zl -zld -zp=4 -6r -os -wx -wce=308 -fo=t.obj t.c && wdis t.obj'

: "$0" OK.
