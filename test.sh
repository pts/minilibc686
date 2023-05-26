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
  case "$TF" in
   /*) DD="$(cd "$MYDIR" && pwd)/"; if test "$DD" = /; then echo "fatal: error getting current directory: $MYDIR"; exit 4; fi ;;
   *//*)  echo "fatal: double slash in test pathname: $TF" >&2; exit 4 ;;
   */*/*/*/*/*) echo "fatal: too many components in test pathname: $TF" >&2; exit 4 ;;  # TODO(pts): Support more.
   */*/*/*/*) DD=../../../../"$MYDIRP" ;;
   */*/*/*) DD=../../../"$MYDIRP" ;;
   */*/*) DD=../../"$MYDIRP" ;;
   */*) DD=../"$MYDIRP" ;;
   *) DD="$MYDIRP" ;;
  esac
  echo "info: running test: $TF" >&2
  # !! TODO(pts): Create empty tmp directory for test for each run, for better isolation.
  if (cd "${TF%/*}" && export PATH="$DD"shbin && unset OKC FAILC DO_STOP &&
      export PATH="$DD"shbin && : unset SRC INCLUDE TOOLS NASM NDISASM AR TESTTCC &&
      SRC="$DD"src && INCLUDE="$DD"include && TOOLS="$DD"tools &&
      NASM="$TOOLS"/nasm-0.98.39 && NDISASM="$TOOLS"/ndisasm-0.98.39 &&
      AR="$TOOLS"/tiny_libmaker && TESTTCC="$TOOLS"/pts-tcc &&
      unset DD && set -- && set -ex && . "${TF##*/}"); then
    let OKC+=1
  else
    let FAILC+=1
    if test "$DO_STOP"; then
      printf "fatal: \\033[0;31mtest failed\\033[0m: %s\n" "$TF" >&2  # TODO(pts): Add option to run the subsequent tests.
      exit 3
    else
      printf "error: \\033[0;31mtest failed\\033[0m: %s\n" "$TF" >&2  # TODO(pts): Add option to run the subsequent tests.
    fi
  fi
done

if test "$FAILC" = 0; then
  printf "info: done running tests, all %d \\033[0;32msucceeded\033[0m\n" "$OKC" >&2
else
  printf "fatal: done running tests, %d succeeded, %d \\033[0;31mfailed\\033[0m\n" "$OKC" "$FAILC" >&2
  exit 3
fi
