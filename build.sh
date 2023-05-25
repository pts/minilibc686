#! /bin/sh --
#
# build.sh: builds the libc as static Linux i386 library from sources
# by pts@fazekas.hu at Sun May 21 00:33:10 CEST 2023
#

cd "${0%/*}" || exit 1

if test "$NASM"; then :
elif test -f tools/nasm-0.98.39 && tools/nasm-0.98.39 -h 2>/dev/null >&2; then NASM=tools/nasm-0.98.39
elif nasm-0.98.39 -h 2>/dev/null >&2; then NASM=nasm-0.98.39
elif nasm -h 2>/dev/null >&2; then NASM=nasm
else NASM=nasm  # Will fail.
fi

if test "$NDISASM"; then :
elif test -f tools/ndisasm-0.98.39 && tools/ndisasm-0.98.39 -h 2>/dev/null >&2; then NDISASM=tools/ndisasm-0.98.39
elif ndisasm-0.98.39 -h 2>/dev/null >&2; then NDISASM=ndisasm-0.98.39
elif ndisasm -h 2>/dev/null >&2; then NDISASM=ndisasm
else NDISASM=  # Disabled.
fi

if test "$AR"; then :
elif test -f tools/tiny_libmaker && tools/tiny_libmaker -h 2>/dev/null >&2; then AR=tools/tiny_libmaker
elif ar -h 2>/dev/null >&2; then AR=ar
else AR=ar  # Will fail.
fi

export LC_ALL=C  # For consistency.

LIBI386_OBJS=
LIBI686_OBJS=
if ! test -f start_stdio_medium_linux.nasm; then
  echo "fatal: missing: start_stdio_medium_linux.nasm" >&2
  exit 2
fi
for F in *.nasm; do
  test "${F#c_}" = "$F" || continue  # Skip c_*.nasm.
  grep -q CONFIG_PIC <"$F" || continue  # Not a libc source file.
  echo "info: compiling: $F" >&2
  ARCH_I686=
  grep -q CONFIG_I386 <"$F" && ARCH_I686=i686
  for ARCH in i386 $ARCH_I686; do
    LA=
    case "$F" in
     exit_linux.nasm) ;;
     fputc_unbuffered.nasm) ;;  # The libc uses stdio_medium instead.
     stdio_file_simple_buffered.nasm) ;;  # The libc uses stdio_medium instead.
     isatty_linux_syscall.nasm) ;;  # The libc uses isatty_linux.nasm instead.
     vfprintf_*.nasm) ;;  # The libc uses stdio_medium_vfprintf.nasm instead.
     strcasecmp.nasm) ;;  # TODO(pts): How to link strcasecmp.nasm if only strcasecmp(3) is needed, and strncasecmp_both.nasm if both strcasecmp(3) and strncasecmp(3) are needed?
     strtok_sep1.nasm) ;;  # TODO(pts): Link it with the symbol name strtok_sep.
     write_linux.nasm) ;;  # start_stdio_medium_linux.nasm provides it.
     m_flushall_dummy.nasm) ;;
     start_uclibc_linux.nasm) ;;
     need_start.nasm) ;;
     need_uclibc_main.nasm) ;;
     tcc_alloca.nasm) ;;
     stdio_medium_flush_opened.nasm) ;;  # We want special order in the .a file, for pts-tcc.
     start_stdio_medium_linux.nasm) ;;  # We want special order in the .a file, for pts-tcc.
     start_*.nasm) ;;
     *.nasm) LA=1 ;;
    esac
    BF="${F%.*}"
    BFA="$BF"
    CFLAGS_ARCH=
    if test "$ARCH_I686"; then  # .nasm source file contains CONFIG_I386.
      BFA="$BF.$ARCH"
      test "$ARCH" = i386 && CFLAGS_ARCH=-DCONFIG_I386
    fi
    test "${F#start_}" != "$F" && CFLAGS_ARCH="$CFLAGS_ARCH -Dmini__start=_start"  # Makes both _start and mini__start defined.
    set -ex
    $NASM $CFLAGS_ARCH $CFLAGS -O999999999 -w+orphan-labels -f elf -o "$BFA".o "$F"
    $NASM $CFLAGS_ARCH $CFLAGS -O999999999 -w+orphan-labels -f bin -o "$BFA".bin "$F"
    $NASM $CFLAGS_ARCH $CFLAGS -O0 -w+orphan-labels -f bin -o "$BFA".o0.bin "$F"
    # $NDISASM -b 32 "$BFA".bin | tail  # For the size.
    if ! cmp "$BFA".bin "$BFA".o0.bin; then
      $NDISASM -b 32 "$BFA".bin >"$BFA".ndisasm
      $NDISASM -b 32 "$BFA".o0.bin >"$BFA".o0.ndisasm
      diff -U3 "$BFA".ndisasm "$BFA".o0.ndisasm
    fi
    set +ex
    if test -z "$LA"; then :
    elif test -z "$ARCH_I686"; then LIBI386_OBJS="$LIBI386_OBJS $BFA.o"; LIBI686_OBJS="$LIBI686_OBJS $BFA.o"
    elif test "$ARCH" = i386; then LIBI386_OBJS="$LIBI386_OBJS $BFA.o"
    else LIBI686_OBJS="$LIBI686_OBJS $BFA.o"
    fi
  done
done

# !! Replace this with something simpler in tools.
# !! Bad relocations for the weak symbol.
#objcopy -W mini___M_start_isatty_stdin -W mini___M_start_isatty_stdout -W mini___M_start_flush_stdout -W mini___M_start_flush_opened start_stdio_medium_linux.o start_stdio_medium_linux_weak.o
#yasm-1.3.0 $CFLAGS -O999999999 -w+orphan-labels -f elf -Dmini__start=_start -o start_stdio_medium_linux_weak.o start_stdio_medium_linux.nasm  # Works, but with suboptimal relocations.
as --32 -march=i386 -o start_stdio_medium_linux_weak.o start_stdio_medium_linux.s

LIB_OBJS_SPECIAL_ORDER="stdio_medium_flush_opened.o start_stdio_medium_linux_weak.o"

rm -f libminitcc1.a  # Some versions of ar(1) such as GNU ar(1) do something different if the .a file already exists.
set -ex
$AR crs libminitcc1.a tcc_alloca.o
set +ex

for ARCH in i386 i686; do
  rm -f libmini686_hello.a  # Some versions of ar(1) such as GNU ar(1) do something different if the .a file already exists.
  if test "$ARCH" = i386; then LIB_OBJS="$LIBI386_OBJS"
  else LIB_OBJS="$LIBI686_OBJS"
  fi
  set -ex
  # !! TODO(pts): Remove local symbols first, to make the .o files smaller, e.g. objcopy -x in.o out.o
  # Work around pts-tcc common symbol linking bug (tcc_common_lib_bug.sh).
  $AR crs libmin"$ARCH".a $LIB_OBJS $LIB_OBJS_SPECIAL_ORDER
  set +ex
done

ls -l libmini386.a libmini686.a need_start.o
echo : "$0" OK.
