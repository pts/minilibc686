#! /bin/sh --
#
# build.sh: builds the libc as static Linux i386 library from sources
# by pts@fazekas.hu at Sun May 21 00:33:10 CEST 2023
#

cd "${0%/*}" || exit 1

if test "$NASM"; then :
elif nasm-0.98.39 -h 2>/dev/null >&2; then NASM=nasm-0.98.39
elif nasm -h 2>/dev/null >&2; then NASM=nasm
else NASM=nasm  # Will fail.
fi

if test "$NDISASM"; then :
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
if ! test -f start_stdio_file_linux.nasm; then
  echo "fatal: missing: start_stdio_file_linux.nasm" >&2
  exit 2
fi
for F in *.nasm; do
  test "${F#c_}" = "$F" || continue  # Skip c_*.nasm.
  grep -q CONFIG_PIC <"$F" || continue  # Not a libc source file.
  echo "info: compiling: $F" >&2
  BF="${F%.*}"
  for ARCH in i386 i686; do
    CFLAGS_ARCH=
    BFA="$BF"
    test "$ARCH" = i386 && CFLAGS_ARCH=-DCONFIG_I386 && BFA="$BF.i386"
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
    LA=
    case "$F" in
     exit_linux.nasm) ;;
     # fputc_unbuffered.nasm) ;;
     # malloc_mmap_linux.nasm) ;;
     # start_stdio_file_linux.nasm) ;;
     strcasecmp.nasm) ;;  # TODO(pts): How to link strcasecmp.nasm if only strcasecmp(3) is needed, and strncasecmp_both.nasm if both strcasecmp(3) and strncasecmp(3) are needed?
     strtok_sep1.nasm) ;;  # TODO(pts): Link it with the symbol name strtok_sep.
     vfprintf_noplus.nasm) ;;  # vfprintf_plus provides more functionality.
     write_linux.nasm) ;;  # start_stdio_file_linux.nasm provides it.
     m_flushall_dummy.nasm) ;;
     start_stdio_file_linux.nasm) LA=1 ;;
     start_*.nasm) ;;
     *.nasm) LA=1 ;;
    esac
    if test -z "$LA"; then :
    elif test "$ARCH" = i386; then LIBI386_OBJS="$LIBI386_OBJS $BFA.o"
    else LIBI686_OBJS="$LIBI686_OBJS $BFA.o"
    fi
  done
done

for F in start_uclibc_linux.nasm need_start.nasm need_uclibc_main.nasm; do
  echo "info: compiling: $F" >&2
  BF="${F%.*}"
  set -ex
  $NASM -O0 -w+orphan-labels -f elf -o "$BF".o "$F"
  set +ex
done

for ARCH in i386 i686; do
  rm -f libmini686_hello.a  # Some versions of ar(1) such as GNU ar(1) do something different if the .a file already exists.
  if test "$ARCH" = i386; then LIB_OBJS="$LIBI386_OBJS"
  else LIB_OBJS="$LIBI686_OBJS"
  fi
  set -ex
  # !! TODO(pts): Remove local symbols first, to make the .o files smaller.
  $AR crs libmin"$ARCH".a $LIB_OBJS
  set +ex
done
cp -a start_stdio_file_linux.o mini686_start.o
cp -a start_stdio_file_linux.i386.o mini386_start.o

ls -l libmini386.a libmini686.a mini386_start.o need_start.o
echo : "$0" OK.
