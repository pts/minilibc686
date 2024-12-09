#! /bin/sh --
#
# build.sh: builds the libc as static Linux i386 library from sources
# by pts@fazekas.hu at Sun May 21 00:33:10 CEST 2023
#
# Input source files: src/*.nasm
# Output files: helper_lib/*.a helper_lib/*.o libc/minilibc/libc.i386.a libc/minilibc/libc.i686.a
# Temporary output files: build_tmp/*.o build_tmp/*.a
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

# !! TODO(pts): Make this work again as command-line flags (no envirnoment variables), e.g. find /usr/bin/nasm.
# !! TODO(pts): Also make CFLAGS work
#if test "$NASM"; then :
#elif test -f tools/nasm-0.98.39 && tools/nasm-0.98.39 -h 2>/dev/null >&2; then NASM=tools/nasm-0.98.39
#elif nasm-0.98.39 -h 2>/dev/null >&2; then NASM=nasm-0.98.39
#elif nasm -h 2>/dev/null >&2; then NASM=nasm
#else NASM=nasm  # Will fail.
#fi
#
#if test "$NDISASM"; then :
#elif test -f tools/ndisasm-0.98.39 && tools/ndisasm-0.98.39 -h 2>/dev/null >&2; then NDISASM=tools/ndisasm-0.98.39
#elif ndisasm-0.98.39 -h 2>/dev/null >&2; then NDISASM=ndisasm-0.98.39
#elif ndisasm -h 2>/dev/null >&2; then NDISASM=ndisasm
#else NDISASM=  # Disabled.
#fi
#
#if test "$AR"; then :
#elif test -f tools/tiny_libmaker && tools/tiny_libmaker -h 2>/dev/null >&2; then AR=tools/tiny_libmaker
#elif ar -h 2>/dev/null >&2; then AR=ar
#else AR=ar  # Will fail.
#fi

export LC_ALL=C  # For consistency. With Busybox we don't need it, because the environment is empty.

OUTFNS='libmini386.a libmini686.a libmina386.a libminitcc1.a need_start.o need_uclibc_main.o start_uclibc_linux.o'
OUTDIR=helper_lib
LIBI386_OBJS=
LIBA386_OBJS=
LIBI686_OBJS=
if ! test -f src/start_stdio_medium_linux.nasm; then
  echo "fatal: missing: src/start_stdio_medium_linux.nasm" >&2
  exit 2
fi
if ! test -d build_tmp; then  # Must have a single component, i.e. no slashes.
  mkdir build_tmp
  if ! test -d build_tmp; then echo "fatal: cannot create temporary directory: build_tmp" >&2; exit 2; fi
fi
if ! test -d "$OUTDIR"; then
  mkdir "$OUTDIR"
  if ! test -d "$OUTDIR"; then echo "fatal: cannot create build output directory: $OUTDIR" >&2; exit 2; fi
fi

rm -f build_tmp/*.o
for F in src/[a-zA-Z0-9_]*.nasm; do
  test "${F#c_}" = "$F" || continue  # Skip c_*.nasm.
  grep -q CONFIG_PIC <"$F" || continue  # Not a libc source file.
  echo "info: compiling: $F" >&2
  ARCH_I686=
  grep -q CONFIG_I386 <"$F" && ARCH_I686=i686
  for ARCH in i386 $ARCH_I686; do
    LA=
    case "${F#src/}" in
     exit_linux.nasm) ;;
     fputc_unbuffered.nasm) ;;  # The libc uses stdio_medium instead.
     stdio_file_simple_buffered.nasm) ;;  # The libc uses stdio_medium instead.
     isatty_linux_syscall.nasm) ;;  # The libc uses isatty_linux.nasm instead.
     vfprintf_*.nasm) ;;  # The libc uses stdio_medium_vfprintf.nasm instead.
     strtok_sep1.nasm) ;;  # TODO(pts): Link it with the symbol name strtok_sep.
     write_linux.nasm) ;;  # start_stdio_medium_linux.nasm provides it.
     syscall3_linux.nasm) ;;  # start_stdio_file_linux.nasm provides it.
     stdio_medium_stdout_in_data.nasm) ;; # src/stdio_medium_stdout.nasm %include()s it.
     m_flushall_dummy.nasm) ;;
     start_uclibc_linux.nasm) ;;
     need_start.nasm) ;;
     need_uclibc_main.nasm) ;;
     tcc_*.nasm) ;;
     stdio_medium_flush_opened.nasm) ;;  # We want special order in the .a file, for miniutcc.
     start_stdio_medium_linux.nasm) ;;  # We want special order in the .a file, for miniutcc.
     start_*.nasm) ;;
     smart.nasm) ;;  # Will be used in source form by smart linking, as libc/minilibc/smart.nasm.
     *.nasm) LA=1 ;;
    esac
    BF="${F#src/}"
    BF=build_tmp/"${BF%.*}"
    BFA="$BF"
    CFLAGS_ARCH=
    if test "$ARCH_I686"; then  # .nasm source file contains CONFIG_I386.
      BFA="$BF.$ARCH"
      test "$ARCH" = i386 && CFLAGS_ARCH=-DCONFIG_I386
    fi
    test "${F#src/start_}" != "$F" && CFLAGS_ARCH="$CFLAGS_ARCH -Dmini__start=_start"  # Makes both _start and mini__start defined.
    test "$F" = src/smart.nasm && CFLAGS_ARCH="$CFLAGS_ARCH -DUNDEFSYMS="
    set -ex
    # We cd into src, otherwise NASM would insert `build_tmp/' to the "$BFA".o as filename.
    "$NASM" $CFLAGS_ARCH $CFLAGS -O999999999 -w+orphan-labels -f elf -o "$BFA".o "$F" || exit 4  # Can %include "src/....nasm".
    # !! TODO(pts): Remove local symbols from the .o file, to make it smaller.
    tools/elfofix -r -v -w -- "$BFA".o  # `-w' fixes weak symbols. .nasm files containing WEAK.. are affected.
    "$NASM" $CFLAGS_ARCH $CFLAGS -O999999999 -w+orphan-labels -f bin -o "$BFA".bin "$F"
    "$NASM" $CFLAGS_ARCH $CFLAGS -O0 -w+orphan-labels -f bin -o "$BFA".o0.bin "$F"
    # $NDISASM -b 32 "$BFA".bin | tail  # For the size.
    if ! cmp "$BFA".bin "$BFA".o0.bin; then
      "$NDISASM" -b 32 "$BFA".bin >"$BFA".ndisasm
      "$NDISASM" -b 32 "$BFA".o0.bin >"$BFA".o0.ndisasm
      diff -U3 "$BFA".ndisasm "$BFA".o0.ndisasm
    fi
    set +ex
    if test "$LA"; then
      if test -z "$ARCH_I686"; then LIBI386_OBJS="$LIBI386_OBJS ${BFA#build_tmp/}.o"; LIBI686_OBJS="$LIBI686_OBJS ${BFA#build_tmp/}.o"
      elif test "$ARCH" = i386; then LIBI386_OBJS="$LIBI386_OBJS ${BFA#build_tmp/}.o"
      else LIBI686_OBJS="$LIBI686_OBJS ${BFA#build_tmp/}.o"
      fi
      case "$F" in *_linux.nasm) ;; *) LIBA386_OBJS="$LIBA386_OBJS ${BFA#build_tmp/}.o" ;; esac
    fi
    # !! TODO(pts): Strip the .o file (strip -S -x -R .comment start.o), and remove empty sections. Unfortunately we don't have strip(1) available here.
  done
done

# !! We don't have .c source ready for this. Needed by TCC 0.9.26.
cp -a src/tcc_float.o src/tcc_bcheck.o build_tmp/

# Order of these .o files in libmini[34]86.a is importan when linking with
# miniutcc, because these .o files contain weak symbols, and if they were
# early, miniutcc would pick them (and then use the weak symbols within,
# rather than the full implementation in another .o file).
#
# TODO(pts): Does GNU ld(1) have the same behavior?
LIBA_OBJS_SPECIAL_ORDER="stdio_medium_flush_opened.o"
LIBC_OBJS_SPECIAL_ORDER="$LIBA_OBJS_SPECIAL_ORDER start_stdio_medium_linux.o"
LIB_OBJS_TCC1="$(for F in build_tmp/tcc_*.o; do echo "${F#build_tmp/}"; done)"
ARB="$AR"
test "${ARB#/}" = "$ARB" && ARB=../"$ARB"
OUTPNS=
for OUTFN in $OUTFNS; do
  OUTPN="$OUTDIR/$OUTFN"
  case "$OUTFN" in
   *.a)
    if test "$OUTFN" = libminitcc1.a; then LIB_OBJS="$LIB_OBJS_TCC1"
    elif test "$OUTFN" = libmini386.a; then LIB_OBJS="$LIBI386_OBJS $LIBC_OBJS_SPECIAL_ORDER"; OUTPN=libc/minilibc/libc.i386.a
    elif test "$OUTFN" = libmina386.a; then LIB_OBJS="$LIBA386_OBJS $LIBA_OBJS_SPECIAL_ORDER"; OUTPN=libc/minilibc/libca.i386.a  # Only those parts which work with any operating system (not only Linux).
    elif test "$OUTFN" = libmini686.a; then LIB_OBJS="$LIBI686_OBJS $LIBC_OBJS_SPECIAL_ORDER"; OUTPN=libc/minilibc/libc.i686.a
    else echo "fatal: unknown output library: $OUTFN" >&2; exit 3
    fi
    rm -f "$OUTDIR/$OUTFN"  # Some versions of ar(1) such as GNU ar(1) do something different if the .a file already exists.
    set -ex
    (cd build_tmp && "$ARB" crs ../"$OUTPN" $LIB_OBJS) || exit 5
    set +ex
    ;;
   *) cp -a -- build_tmp/"$OUTFN" "$OUTPN" ;;
  esac
  OUTPNS="$OUTPNS $OUTPN"
done
set -ex
<src/smart.nasm >build_tmp/smart1.nasm awk '{if(/^ *%include "src\/[^"]+"/){print ";;"$0;sub(/^[^"]*"/,"");sub(/".*/,"");fn=$0;for(;;){if((getline<fn)<1){break};print}close(fn);print";;"}else{print}}'
<build_tmp/smart1.nasm >build_tmp/smart2.nasm awk '{sub(/;.*/,""); sub(/[ \t]+$/, ""); sub(/^[ \t]+/, ""); if (/[^ \t]/) {print}}'
<build_tmp/smart2.nasm >libc/minilibc/smart.nasm cat
set +ex
OUTPNS="$OUTPNS libc/minilibc/smart.nasm"

ls -l $OUTPNS || exit "$?"

echo : "$0" OK.
