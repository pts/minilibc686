#! /bin/sh --
#
# test.sh: test runner framework
# by pts@fazekas.hu at Fri May 26 13:06:56 CEST 2023
#
# Input source files: src/*.nasm
# Test scripts (shell scripts): test/*.test
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

MYDIRP="$MYDIR/"
while test "${MYDIRP#./}" != "$MYDIRP"; do MYDIRP="${MYDIRP#./}"; done

CFLAGS=  # TODO(pts): Make this configurable from the command line.
export LC_ALL=C  # For consistency. With Busybox we don't need it, because the environment is empty.

# --- Shell functions callable from the *.test scripts.

# Some gcc flags: -Werror=implicit-function-declaration -freestanding -ansi -pedantic
# Out of this TinyCC rejects -ansi.
_utcc() { "$TESTTCC" -s -Os -W -Wall -Werror=implicit-function-declaration -nostdinc -I"$INCLUDE" -D"__asm__(x)=" -D__UCLIBC__ "$@"; }
_mtcc() { "$TESTTCC" -s -Os -W -Wall -Werror=implicit-function-declaration -nostdlib -nostdinc -I"$INCLUDE" -D__MINILIBC686__ "$@"; }
_nasm() {
  local FNASM FBASE DEFINES=
  while test "${1%-[DU]?*}" != "$1"; do DEFINES="$DEFINES $1"; shift; done
  for FNASM in "$@"; do
    FBASE="${FNASM%.*}"
    test "${FNASM%.o}" = "$FNASM" || FNASM="$FBASE".nasm
    "$NASM" -I"$MYDIRP" $DEFINES $CFLAGS -O999999999 -w+orphan-labels -f elf -o "$FBASE".o "$SRC"/"$FBASE".nasm
  done
}
_nasm_start() {
  local FNASM FBASE DEFINES=
  while test "${1%-[DU]?*}" != "$1"; do DEFINES="$DEFINES $1"; shift; done
  for FNASM in "$@"; do
    FBASE="${FNASM%.*}"
    test "${FNASM%.o}" = "$FNASM" || FNASM="$FBASE".nasm
    "$NASM" -I"$MYDIRP" $DEFINES $CFLAGS -Dmini__start=_start -O999999999 -w+orphan-labels -f elf -o "$FBASE".o "$SRC"/"$FBASE".nasm
    "$TOOLS"/elfofix -w -- "$FBASE".o  # `-w' fixes weak symbols. .nasm files containing WEAK.. are affected.
  done
}
_nasm2() {
  local FNASM FBASE DEFINES=
  while test "${1%-[DU]?*}" != "$1"; do DEFINES="$DEFINES $1"; shift; done
  for FNASM in "$@"; do
    FBASE="${FNASM%.*}"
    test "${FNASM%.o}" = "$FNASM" || FNASM="$FBASE".nasm
    "$NASM" -I"$MYDIRP" $DEFINES $CFLAGS -O999999999 -w+orphan-labels -f elf -o "$FBASE".o "$SRC"/"$FBASE".nasm
    "$NASM" -I"$MYDIRP" $DEFINES $CFLAGS -O999999999 -w+orphan-labels -f bin -o "$FBASE".bin "$SRC"/"$FBASE".nasm
    "$NASM" -I"$MYDIRP" $DEFINES $CFLAGS -O0 -w+orphan-labels -f bin -o "$FBASE".o0.bin "$SRC"/"$FBASE".nasm
    "$NDISASM" -b 32 "$FBASE".bin | tail  # For the size.
    if ! cmp "$FBASE".bin "$FBASE".o0.bin; then
      "$NDISASM" -b 32 "$FBASE".bin >"$FBASE".ndisasm
      "$NDISASM" -b 32 "$FBASE".o0.bin >"$FBASE".o0.ndisasm
      diff -U3 "$FBASE".ndisasm "$FBASE".o0.ndisasm
    fi
  done
}
_utcc_nasm2() {
  local FNASM="$1"
  _nasm2 "$FNASM"
  shift
  _utcc "${FNASM%.*}.o" "$@"
}

# ---

DO_STOP=
if test "$1" == --stop; then shift; DO_STOP=1; fi

test $# = 0 && set x "$MYDIRP"test/*.test && shift
OKC=0; FAILC=0
for TF in "$@"; do
  case "$TF" in
   *.test) ;; *)
    echo "info: skipping non-test file: $TF"; continue
  esac
  if ! test -f "$TF"; then echo "fatal: missing test script: $TF"; exit 2; fi
  while test "${TF#./}" != "$TF"; do  # Remove leading ./, as long as possible.
    TF="${TF#./}"
    while test "${TF#/}" != "$TF"; do TF="${TF/}"; done
  done
  DD=
  case "$TF" in  # Just make it simpler for convenience.
   /* | */../* | */../* | */../* | *//* | */) ;;  # Too complicated, give up.
   ../*/*) test "$MYDIRP" = ../ && DD=../../ ;;
   ./*/*) if test "$MYDIRP" = ./ || test -z "$MYDIRP"; then DD=../../; fi ;;
  esac
  echo "$MYDIRP---$TF--$DD"
  if test -z "$DD"; then
    case "$TF" in
     /* | ./* | */../* | */./* | ../* | */../* | *//* | */) DD="$(cd "$MYDIR" && pwd)/"; if test "$DD" = /; then echo "fatal: error getting current directory: $MYDIR"; exit 4; fi ;;
     */*/*/*/*/*) echo "fatal: too many components in test pathname: $TF" >&2; exit 4 ;;  # TODO(pts): Support more.
     */*/*/*/*) DD=../../../../../"$MYDIRP" ;;
     */*/*/*) DD=../../../../"$MYDIRP" ;;
     */*/*) DD=../../../"$MYDIRP" ;;
     */*) DD=../../"$MYDIRP" ;;
     *) DD=../"$MYDIRP" ;;
    esac
  fi
  echo "info: running test: $TF" >&2
  RUNDIR="${TF%.*}.rundir"  # TODO(pts): When parallel execution is active, add $$ etc. here.
  if test -e "$RUNDIR"; then
    if ! rm -rf -- "$RUNDIR"; then echo "fatal: error deleting recursively: $RUNDIR" >&2; exit 5; fi
  fi
  if ! mkdir -- "$RUNDIR"; then echo "fatal: error creating test rundir: $RUNDIR" >&2; exit 6; fi
  # !! TODO(pts): Create empty tmp directory for test for each run, for better isolation.
  if (cd "$RUNDIR" && export PATH="$DD"shbin && unset OKC FAILC DO_STOP &&
      export PATH="$DD"shbin && : unset SRC INCLUDE TOOLS NASM NDISASM AR TESTTCC &&
      MYDIRP="$DD" &&
      SRC="$DD"src && INCLUDE="$DD"libc/minilibc/include && TOOLS="$DD"tools &&
      NASM="$TOOLS"/nasm-0.98.39 && NDISASM="$TOOLS"/ndisasm-0.98.39 &&
      AR="$TOOLS"/tiny_libmaker && TESTTCC="$TOOLS"/miniutcc && TESTDIR=.. &&
      unset DD RUNDIR && set -- && set -ex && . ../"${TF##*/}"); then
    let OKC+=1
    echo >&2  # Terminate possible partial line.
    if ! rm -rf -- "$RUNDIR"; then echo "fatal: error deleting recursively: $RUNDIR" >&2; exit 5; fi
    printf "info: \\033[0;32mtest succeeded\\033[0m: %s\n" "$TF" >&2  # TODO(pts): Add option to run the subsequent tests.
  else
    XC="$?"
    let FAILC+=1
    if test "$DO_STOP"; then
      printf "\nfatal: \\033[0;31mtest failed\\033[0m with exit code %d: %s\n" "$XC" "$TF" >&2  # TODO(pts): Add option to run the subsequent tests.
      exit 3
    else
      printf "\nerror: \\033[0;31mtest failed\\033[0m with exit code %d: %s\n" "$XC" "$TF" >&2  # TODO(pts): Add option to run the subsequent tests.
    fi
  fi
done

if test "$FAILC" = 0; then
  printf "info: done running tests, all %d \\033[0;32msucceeded\033[0m\n" "$OKC" >&2
  exit
else
  printf "fatal: done running tests, %d succeeded, %d \\033[0;31mfailed\\033[0m\n" "$OKC" "$FAILC" >&2
  exit 3
fi
