#! /bin/sh --
#
# test.sh: test runner framework
# by pts@fazekas.hu at Fri May 26 13:06:56 CEST 2023
#
# Input source files: src/*.nasm
# Test scripts (shell scripts): test/*.test
#

# Rerun ourselves with shbin/sh (BusyBox sh), without environment variables
# (for reproducible builds).
# !! TODO(pts): Ship with a much smaller busybox executable, which also covers minicc.
if test "$PATH" != shbin && test -f "${0%/*}/shbin/env"; then
  cd "${0%/*}" && exec shbin/env -i PATH=shbin sh -- "${0##*/}" "$@"
  echo "fatal: failed to start busybox sh" >&2; exit 2
fi

NASM=tools/nasm-0.98.39
NDISASM=tools/ndisasm-0.98.39
AR=tools/tiny_libmaker
TESTTCC=tools/pts-tcc
INCLUDE=include
TOOLS=tools
SRC=src
CFLAGS=
export LC_ALL=C  # For consistency. With Busybox we don't need it, because the environment is empty.

DO_STOP=
if test "$1" == --stop; then shift; DO_STOP=1; fi

test $# = 0 && set x test/*.test && shift
OKC=0; FAILC=0
for TF in "$@"; do
  if ! test -f "$TF"; then echo "fatal: missing test script: $TF"; exit 2; fi
  DD=
  case "$TF" in
   /*) ;;
   *//*)  echo "fatal: double slash in test pathname: $TF" >&2; exit 4 ;;
   */*/*/*) echo "fatal: too many components in test pathname: $TF" >&2; exit 4 ;;  # TODO(pts): Support more.
   */*/*) DD=../../ ;;
   */*) DD=../ ;;
  esac
  echo "info: running test: $TF" >&2
  # !! TODO(pts): Create empty tmp directory for test for each run, for better isolation.
  if (cd "${TF%/*}" && export PATH="$DD"shbin && unset OKC FAILC DO_STOP &&
      NASM="$DD$NASM" && NDISASM="$DD$NDISASM" &&
      AR="$DD$AR" && TESTTCC="$DD$TESTTCC" && INCLUDE="$DD$INCLUDE" &&
      TOOLS="$DD$TOOLS" && SRC="$DD$SRC" &&
      set -- && set -ex && . "${TF##*/}"); then
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


