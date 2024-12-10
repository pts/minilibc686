#! /bin/sh --
#
# minicc: compiler frontend for building with minilib686
# by pts@fazekas.hu at Sun May 21 02:21:27 CEST 2023
#
# Don't run this script manually, but run it as pathbin/minicc (from any
# directory).
#

export LC_ALL=C  # To avoid surprises with localized error messages etc.

unset MYDIR
if test "$1" = --sh-script; then  # This is the fast path.
  shift  # Remove --sh-script.
  MYPROG="$0"
  MYDIR="${0%/*}"  # The caller ensures that there is a `/'.
  # TODO(pts): Remove code duplication with the `else' branch below.
  while test "${MYDIR#./}" != "$MYDIR"; do MYDIR="${MYDIR#./}"; done
  if test "$MYDIR" = shbin/..; then MYDIR=.  # Simplification.
  elif test "${MYDIR%/shbin/..}"; then MYDIR="${MYDIR%/shbin/..}"  # Simplification.
  fi
  if test "$MYDIR" = pathbin/..; then MYDIR=.  # Simplification.
  elif test "${MYDIR%/pathbin/..}"; then MYDIR="${MYDIR%/pathbin/..}"  # Simplification.
  fi
  test "${MYDIR#-}" = "$MYDIR" || MYDIR="./$MYDIR"  # Make it not a command-line flag (-...).
  #
  # The symlinks in $0 have already been resolved by the caller.
  # --noenv is for reproducible builds and testing: unset all environment
  # variables, and use a short hardcoded $PATH (`$MYDIR/ccshbin'). Toolchain
  # tools (e.g. miniutcc and ld) are always run from `$MYDIR/tools', no matter
  # the $PATH. System tools (such as with `--gcc=...') will be excplicitly
  # looked up on the old $PATH.
  test "$1" = --noenv && shift && exec env -i PATH="$MYDIR/ccshbin" TMPDIR="$TMPDIR" sh -- "$MYPROG" --sh-script --boxed-path "$PATH" "$@"
  # Use BusyBox (if available) for consistent shell and coreutils.
  if test -f "$MYDIR/ccshbin/sh" && test -x "$MYDIR/ccshbin/sh"; then
    case "$PATH": in "$MYDIR/ccshbin":) ;; *) export PATH="$MYDIR/ccshbin:$PATH" ;; esac
  fi
else
  # Rerun ourselves ($0) with the bundled `busybox sh'. This a hack and a
  # fallback. Most users should use the `shbin/minicc' ELF program to run
  # minicc.sh, which will run it with the bundled `busybox sh', without ever
  # running the system /bin/sh, thus much more efficiently and reliably than
  # this hack.
  if test "${0%/*}" = "$0" && test "${0#-}" = "$0"; then  # We do the `-' check as a fallback to avoid command-lone flag interpretations of $0.
    if test -f "$0"; then  # In case `sh minicc.sh' was run.
      MYPROG=./"$0"
    else  # Try to find $0 on $PATH.
      MYPROG="$(type -p "$0" 2>/dev/null)"
      case "$MYPROG" in
       -p:*)  # dash(1) reports: `-p: not found'.
        MYPROG="$(type "$0" 2>/dev/null)"
        case "$MYPROG" in
         "$0 is "*) MYPROG="${MYPROG#$0 is }" ;;
         *) MYPROG=""  # Make it fail below.
        esac
        ;;
       "$0 is "*) MYPROG="${MYPROG#$0 is }" ;;
      esac
      if ! test -f "$MYPROG"; then echo "fatal: my own command not found: $0" >&2; exit 1; fi
    fi
  else
    MYPROG="$0"
  fi
  while true; do
    MYDIR="$(readlink "$MYPROG" 2>/dev/null)"
    test "$MYDIR" || break
    test "${MYDIR#/}" = "$MYDIR" && MYDIR="${MYPROG%/*}/$MYDIR"
    MYPROG="$MYDIR"  # Resolve another symlink. TODO(pts): Detect more than 0x100 to avoid infinite loops.
  done
  MYDIR="${MYPROG%/*}"
  while test "${MYDIR#./}" != "$MYDIR"; do MYDIR="${MYDIR#./}"; done
  if test "$MYDIR" = shbin/..; then MYDIR=.  # Simplification.
  elif test "${MYDIR%/shbin/..}"; then MYDIR="${MYDIR%/shbin/..}"  # Simplification.
  fi
  if test "$MYDIR" = pathbin/..; then MYDIR=.  # Simplification.
  elif test "${MYDIR%/pathbin/..}"; then MYDIR="${MYDIR%/pathbin/..}"  # Simplification.
  fi
  test "${MYDIR#-}" = "$MYDIR" || MYDIR="./$MYDIR"  # Make it not a command-line flag (-...).
   # Use BusyBox (if available) for consistent shell and coreutils.
  if test -f "$MYDIR/ccshbin/sh" && test -x "$MYDIR/ccshbin/sh"; then
    if test "$1" = --noenv; then
      shift
      exec env -i PATH="$MYDIR/ccshbin" TMPDIR="$TMPDIR" sh -- "$MYPROG" --sh-script --boxed-path "$PATH" "$@"
    fi
    export PATH="$MYDIR/ccshbin:$PATH"
    exec sh -- "$MYPROG" --sh-script "$@"
  elif test "$1" = --noenv; then
    echo "fatal: BusyBox shell not found: $MYDIR/ccshbin/sh" >&2; exit 1
  fi
fi

# --boxed is a weaker version of --noenv for reproducible builds and
# testing: keep most environment variables, but use a short hardcoded
# $PATH (`$MYDIR/ccshbin').
OLD_PATH="$PATH"
IS_BOXED=
while test "$1" = --boxed-path && test "$2"; do OLD_PATH="$2"; shift; shift; export PATH="$MYDIR/ccshbin"; IS_BOXED=1; done
while test "$1" = --boxed; do export PATH="$MYDIR/ccshbin"; IS_BOXED=1; shift; done
# Now $OLD_PATH contains the initial $PATH, with system tools like `gcc'.

test "$TMPDIR" || unset TMPDIR

NL="
"

if test $# = 0 || test "$1" = --help || test "$1" = help || test "$1" = -h || test "$1" = "-?"; then
  # TODO(pts): Add help for e.g <command> sh.
  test $# = 0 && exec >&2
  echo "minicc: C compiler fronted for building small Linux i386 executables$NL""Usage: $0 [<command>] [<gcc-flag>...] <file.c>$NL""There are minicc flags, e.g. --watcom, --gcc, --tcc, --utcc"
  test $# = 0 && exit 1
  exit 0
elif test "$1" = --download; then
  SAVE_PATH="$PATH"
  shift
  WGET_V=-q ; CURL_V=-s
  if test "$1" = -v; then
    shift;
    WGET_V=; CURL_V=
  fi
  for NAME in "$@"; do
    case "$NAME" in
      -* | *[/?%@]*) echo "fatal: bad tool name syntax for download: $NAME" >&2; exit 8 ;;
     eglibc.sfx.7z | eglibc-2.19.sfx.7z) OF="$MYDIR/libc/eglibc-2.19.sfx.7z"; URL="https://github.com/pts/minilibc686/releases/download/eglibc-2.19-v1/eglibc-2.19.sfx.7z" ;;
     *libc*.sfx.7z) echo "fatal: unknown libc for download: $NAME" >&2; exit 8 ;;
     *) OF="$MYDIR/tools/$NAME"; URL="https://github.com/pts/minilibc686/releases/download/cc1-linux-i686/$NAME" ;;
    esac
    if test -f "$OF" && test -s "$OF"; then
      echo "info: tool already downloaded: $OF" >&2
    else
      export PATH="$OLD_PATH"
      if type wget >/dev/null 2>&1; then  # `busybox wget --version' doesn't return 0, so we don't check that.
        echo "info: downloading to $OF using wget: $URL" >&2
        if ! wget $WGET_V -O "$OF".tmp "$URL"; then rm -f "$OF".tmp; exit 8; fi
      elif curl --version >/dev/null 2>&1; then
        echo "info: downloading to $OF using curl: $URL" >&2
        if ! curl $CURL_V -Lo "$OF".tmp "$URL"; then rm -f "$OF".tmp; exit 8; fi
      else
        echo "info: no program to download tool $NAME, install wget or curl" >&2
        exit 8
      fi
      export PATH="$SAVE_PATH"
      mv "$OF".tmp "$OF" || exit 8
    fi
    if ! test -x "$OF"; then
      chmod +x "$OF" || exit 8
    fi
  done
  exit  # All downlodads succeeded.
fi

if ! test -f "$MYDIR/tools/elfxfix"; then
  echo "fatal: missing tool: $MYDIR/tools/elfxfix" >&2
  exit 1
fi
if ! test -x "$MYDIR/tools/elfxfix"; then
  echo "fatal: tool not executable: $MYDIR/tools/elfxfix" >&2
  exit 1
fi

GCC="$MYDIR/tools/wcc386"  # Use the OpenWatcom C compiler by default.
TCC=
USE_UTCC=
CMD=minicc
case "$1" in
 "" | -* | *.[aocisShHCmMfFd] | *.c[cp] | *.[ch]pp | *.cxx | *.asm | *.[nw]asm | *.m[im] | *.mii | *.ii | *.c++ | *.[CH]PP | *.h[hp] | *.hxx | *.hpp | *.h++ | *.tcc | *.for | *.ftn | *.FOR | *.fpp | *.FPP | *.FTN | *.[fF][0-9][0-9] | *.go | *.brig | *.java | *.ad[sb] | *.d[id] | *.sx | *.obj) ;;  # A flag or a source file name is not a program name.
 .) ;;  # An escape to prevent the next source file from being interpreted as a compiler command.
 utcc) GCC=; TCC="$MYDIR"/tools/miniutcc; USE_UTCC=1; shift ;;  # Same as: --utcc: Use the bundled TinyCC compiler (tools/miniutcc) for both compilation, libc (the uClibc bundled within it) and linking.
 diet) LIBC=dietlibc; shift ;;  # Same as: --dietlibc
 xstatic) LIBC=uclibc; shift  ;;  # Same as: --uclibc. Please note that this is not perfect, some .a and .h files are missing from pts-xstatic.
 owcc) GCC="$MYDIR/tools/wcc386"; TCC=; shift ;;
 minicc | cc) shift ;;  # Official way to prevent the next source file from being interpreted as a compiler command.
 sh | shell) CMD=sh; shift ;;
 exec) CMD=exec; shift ;;
 busybox | uname | env) CMD="$MYDIR/shbin/$1"; shift ;;
 nasm | ndisasm) CMD="$MYDIR/tools/$1-0.98.39"; shift ;;
 ar | tiny_libmaker) CMD="$MYDIR/tools/tiny_libmaker"; shift ;;
 pts-tcc | miniutcc) CMD="$MYDIR/tools/miniutcc"; shift ;;  # Just run the bundled TinyCC compiler (tools/miniutcc), with its the original arguments.
 pts-pcc) CMD="$MYDIR/tools/$1"; shift ;;
 as | ld | elfnostack | elfofix | elfxfix | mktmpf | omf2elf | wcc386 | sstrip) CMD="$MYDIR/tools/$1"; shift ;;
 tool)
  if test -z "$2"; then echo "fatal: missing tool name argument" >&2; exit 1; fi
  CMD="$MYDIR/tools/$2"  # E.g. miniutcc.
  shift; shift ;;
 *)  # Interpret $1 as a compiler command (TCC or GCC-like).
  BASENAME="${1##*/}"
  case "$BASENAME" in
   *tcc*) TCC="$1"; GCC= ;;
   *) GCC="$1"; TCC= ;;
  esac
  shift
  ;;
esac
case "$CMD" in
 */*) exec "$CMD" "$@" ;;  # !! TODO(pts): Download "$MYCMD/bin/as" if needed here.
 minicc) ;;  # Continue below.
 sh | exec)
  test "$PATH" = "$MYDIR/ccshbin" && PATH=
  if test "${MYDIR#/}" = "$MYDIR"; then
    MYDIR="$(cd "$MYDIR" && pwd)"
    if test -z "$MYDIR"; then
      echo "fatal: could not find absolute directory" >&2; exit 9
    fi
  fi
  test "$TMPDIR" || unset TMPDIR
  # We also pass environment variable LC_ALL=C above.
  if test -z "$PATH"; then export PATH="$MYDIR/shbin"
  else export PATH="$MYDIR/shbin:$PATH"
  fi
  if test "$CMD" = exec && test "$1" && test "${1#*/}" = "$1" && test -x "$MYDIR/shbin/$1"; then
    exec "$@"  # Example: `minicc sh ls' executes `ls' without `sh'. `sh' would interpret is a shell script.
  fi
  export PS1='minicc-sh$ '  # Our busybox can't substitute directory name here anyway.
  exec sh "$@"  # Executes "$MYDIR/shbin/sh.
  ;;
esac

# --- The rest of this file implements CMD=minicc.

ARCH=i686
DO_ADD_LIB=1
DO_ADD_INCLUDEDIR=1
DO_LINK=1
NEED_GCC_AS=1
SFLAG=
STRIP_MODE=2  # 0: Don't strip, don't chage he ELF OSABI (-g00); 1: change the ELF OSABI (typically to Linux) and fix first section alignment (-g0); 2: change the ELF OSABI and strip; 3: change the ELF OSABI, strip only symbols, keep relocations (-g0r)
WFLAGS="-W$NL-Wall$NL-Werror-implicit-function-declaration"
DO_WKEEP=1
HAD_OFLAG=
HAD_V=
HAD_OFILE=
HAD_SSFILE=
GCC_BARG=-pipe  # Harmless default.
LIBC=
DO_SMART=
ANSIFLAG=
OUTFILE=
MINICC_LD=  # The default will be "$MYDIR"/tools/ld, using --minild.
DO_ARGC=  # Argument 1 of main(...).
DO_ARGV=  # Argument 2 of main(...).
DO_ENVP=  # Argument 3 of main(...).
HAD_TRADITIONAL=
DO_DOWNLOAD=1
HAD_OPTIMIZE=
HAD_NOINLINE=
DO_MODE=
DEF_CMDARG=
PRINTF_PLUS=1
PRINTF_OCTAL=1
PRINTF_LONG=1
PRINTF_LONGLONG=1
FILE_CAPACITY=
IS_AOUT=  # Output file format is Linux i386 a.out QMAGIC executable.
DO_SFIX=  # Do we have to fix the output of GNU as(1)?
DO_GET_CONFIG=
OS=linux

SKIPARG=
ARGS=
for ARG in "$@"; do
  if test "$SKIPARG"; then
    test "$SKIPARG" = -o && OUTFILE="$ARG"
    test "$SKIPARG" = -include && ARGS="$ARGS$NL-include$NL$ARG"
    SKIPARG=
    continue
  fi
  case "$ARG" in
   *"$NL"*) echo "fatal: unexpected newline in minicc argument" >&2; exit 1 ;;
   "") echo "fatal: empty minicc argument" >&2; exit 1 ;;
   --no-download) DO_DOWNLOAD= ;;
   --gcc) TCC=; GCC=gcc ;;  # Doesn't work with --boxed. TODO(pts): Look it up on old $PATH.
   --gcc=*/*) TCC=; GCC="${ARG#*=}"; test "$IS_BOXED" && GCC_BARG="-B${GCC%/*}" ;;
   --gcc=*) TCC=; GCC="${ARG#*=}" ;;
   --wcc | --wcc386 | --watcom) GCC="$MYDIR/tools/wcc386"; TCC= ;;  # Specify --gcc=.../wcc386 to use a specific OpenWatcom compiler.
   --pcc) GCC="$MYDIR"/tools/pts-pcc; TCC= ;;
   --tcc) GCC=; TCC="$MYDIR"/tools/miniutcc ;;  # Use the bundled TinyCC compiler (tools/miniutcc) for compilation and linking. Don't select the libc. To use the bundled TinyCC compiler (tools/miniutcc) for compilation and the bundled GNU ld(1) (tools/ld) for linking, specify `--tcc --minild'.
   --tcc=*) GCC=; TCC="${ARG#*=}" ;;
   --utcc) GCC=; TCC="$MYDIR"/tools/miniutcc; USE_UTCC=1 ;;  # Use the bundled TinyCC compiler (tools/miniutcc) for both compilation, libc (the uClibc bundled within it) and linking.
   --utcc=*) GCC=; TCC="${ARG#*=}"; USE_UTCC=1 ;;
   --tccld) MINICC_LD="$MYDIR"/tools/miniutcc ;;
   --ld=* | --tccld=*) MINICC_LD="${ARG#*=}" ;;
   --minild) MINICC_LD="$MYDIR"/tools/ld ;;  # Use the bundled GNU ld(1) (tools/ld) for linking.
   --gccld) MINICC_LD=///gcc ;;
   --uclibc) LIBC=uclibc ;;
   --dietlibc | --diet | --libc=diet) LIBC=dietlibc ;;
   --eglibc) LIBC=eglibc ;;
   --minilibc) LIBC=minilibc ;;
   --libc=?*) LIBC="${ARG#*=}" ;;
   -traditional*) HAD_TRADITIONAL="$ARG"; ARGS="$ARGS$NL$ARG" ;;  # Includes -traditional-cpp.
   -static | -m32 | -fno-pic | -fno-PIC | -fno-pie | -fno-PIE | -no-pie | -nostartfiles | -Bstatic | -dn | -non_shared | -static-libgcc | -fplt | -fno-plt | -fno-use-linker-plugin | -no-cacnonical-prefixes | --no-sysroot-suffix) ;;
   -fno-lto) ;;  # Passing it to compiling gcc(1) or GCC cc1 doesn't seem to make a difference in the output .s file. So we just omit it for simplicity.
   -flto | -fuse-linker-plugin) echo "fatal: unsupported LTO flag: $ARG" >&2; exit 1 ;;  # LTO is link-time optimization.
   -fno-stack-protector | -fno-stack-check)
    # minicc and minilibc686 default: `gcc -fno-stack-protector', `owcc
    # -fno-stack-check'. Also related to -U_FORTIFY_SOURCE. OpenWatcom has
    # __STK, PCC has __stack_chk_fail and __stack_chk_guard, TinyCC doesn't
    # have anything, GCC and Clang have some version-specific
    # implementation.
    ;;
   -fstack-protector | -fstack-protector-*) echo "fatal: stack protector flag: $ARG" >&2; exit 1 ;;  # Not supported by minicc or minilibc686.
   -fno-rtti | -fno-exceptions | -nostdinc++) ;;  # Ignore some C++ flags. minicc otherwise doesn't support C++.
   -shared | -dynamic | -Bshared | -Bdynamic | -Bshareable | -rpath* | -dy | -call-shared | -shared-libgcc | -rdynamic) echo "fatal: unsupported shared library flag: $ARG" >&2; exit 1 ;;
   --sysroot | --sysroot= | -B | -B* | --gcc-toolchain | --gcc-toolchain | -target | -target=* | -sysld*) echo "fatal: unsupported toolchain flag: $ARG" >&2; exit 1 ;; # These are GCC and/or clang flags.
   -p | -pg | --profile) echo "fatal: unsupported profiling flag: $ARG" >&2; exit 1 ;;
   -m64 | -march=x86[_-]64 | -march=amd64 | -imultiarch) echo "fatal: unsupported 64-bit flag: $ARG" >&2; exit 1 ;;
   -pie | -fpic | -fPIC | -fpie | -fPIE) echo "fatal: unsupported position-independent code flag: $ARG" >&2; exit 1 ;;  # TODO(pts): Add support. It is not useful anyway for static linking, it just adds bloat.
   -idirafter | -imultilib | -iplugindir* | -iquote | -isysroot | -system | -iwithprefix | -iwithprefixbefore) echo "fatal: unsupported include dir flag, use -I instead: $ARG" >&2; exit 1 ;;
   -include=*) ARGS="$ARGS$NL-include$NL${ARG#*=}" ;;  # Not valid gcc(1) syntax, but we support it.
   -include) SKIPARG="$ARG" ;;  # Typical and valid gcc(1) and pcc(1) syntax. TinyCC doesn't support -include, it fails explicitly. For wcc386, we will replace `-include ...' with `-fi=...'.
   -include*) ARGS="$ARGS$NL-include$NL${ARG#-include}" ;;  # Valid but ugly gcc(1) syntax.
   #-imacros | -iprefix) echo "fatal: unsupported include file flag: $ARG" >&2; exit 1 ;;  # TODO(pts): Adding support is relatively easy, we just have to pass these to GCC.
   -mregparm=0) ;;  # Default GCC cdecl calling convention.
   -mregparm=* | -msseregparm | -mrtd | -mno-rtd) echo "fatal: unsupported calling convention flag: $ARG" >&2; exit 1 ;;  # FYI owcc -mregparm=1 ... -mregparm=3 activate __watcall rather than __regparm__(3).
   # TODO(pts): Try to adjust -malign-data=type and -mlarge-data-threshold=threshold to avoid alignment of some arrays to 0x20 bytes.
   -march=i[3456]86) ARCH="${ARG#*=}" ;;
   -march=*) echo "fatal: unsupported minicc arch flag: $ARG" >&2; exit 1 ;;
   -msmart) DO_SMART=1 ;;  # Enable smart linking.
   -mforce-smart) DO_SMART=2 ;;  # Force smart linking even for self-contained programs without undefined symbols. Most users need -msmart instead, that's faster.
   -mno-smart) DO_SMART=0 ;;
   -margc) DO_ARGC=1 ;;
   -mno-argc) DO_ARGC=0 ;;
   -margv) DO_ARGV=1 ;;
   -mno-argv) DO_ARGV=0 ;;
   -menvp) DO_ENVP=1 ;;
   -mno-envp) DO_ENVP=0 ;;
   -mprintf-mini) PRINTF_PLUS=; PRINTF_OCTAL=; PRINTF_LONG=; PRINTF_LONGLONG= ;;  # This is a minilibc686-specific flag. TODO(pts): Fail for this and other such flags with other libcs.
   -mprintf-plus) PRINTF_PLUS=1 ;;
   -mno-printf-plus) PRINTF_PLUS= ;;
   -mprintf-octal) PRINTF_OCTAL=1 ;;
   -mno-printf-octal) PRINTF_OCTAL= ;;
   -mprintf-long | -mprintf-l) PRINTF_LONG=1 ;;
   -mno-printf-long | -mno-printf-l) PRINTF_LONG= ;;
   -mprintf-longlong | -mprintf-long-long | -mprintf-ll) PRINTF_LONGLONG=1 ;;
   -mno-printflonglong | -mno-printf-long-long | -mno-printf-ll) PRINTF_LONGLONG= ;;
   -mfiles=[1-9]* | -mfiles=) FILE_CAPACITY="${ARG#*=}" ;;
   -maout | -Wl,-m,i386linux) IS_AOUT=1 ;;
   -Wno-no) DO_WKEEP= ;;  # Disable warnings. GCC and Clang accept and ignore it. GCC ignores it.
   -Wkeep | -Wno-no-no) DO_WKEEP=1 ;;  # This is not a GCC flag, it's a minicc extension. GCC ignores -Wno-no-no, but Clang warns.
   -Wno-*) ARGS="$ARGS$NL$ARG" ;;
   -Werror[-=]implicit-function-declaration) ARGS="$ARGS$NL-Werror-implicit-function-declaration"; DO_WKEEP= ;;  # GCC 4.1 supports only -Werror-implicit-function-declaration, GCC >=4.2 supports it and also -Werror=implicit-function-declaration.
   -Wadd=*) ARGS="$ARGS$NL-W${ARG#*=}" ;;  # This doesn't set DO_WKEEP="". This is a minicc extension.
   -Wl,*) ARGS="$ARGS$NL$ARG" ;;
   #-Wp,*) ;;  #  Works with the gcc(1) driver, but not with cc1(1).
   -W[a-z],*) echo "fatal: unsupported tool flag: $ARG" >&2; exit 1 ;;
   -W*) ARGS="$ARGS$NL$ARG"; DO_WKEEP= ;;
   -fno-inline) ARGS="$ARGS$NL$ARG"; HAD_NOINLINE=1 ;;
   -finline) ARGS="$ARGS$NL$ARG"; HAD_NOINLINE= ;;
   -[fm]?* | -pedantic) ARGS="$ARGS$NL$ARG" ;;
   -ansi | -std=*) ANSIFLAG="$ARG" ;;
   -[DU]*?) DEF_CMDARG="$DEF_CMDARG$NL$ARG" ;;
   -I*?) ARGS="$ARGS$NL$ARG" ;;
   -O0) ARGS="$ARGS$NL$ARG"; HAD_OFLAG=1; HAD_OPTIMIZE= ;;  # DO_SFIX=1 isn't needed for `gcc -O0'.
   -Os) ARGS="$ARGS$NL$ARG"; HAD_OFLAG=1; HAD_OPTIMIZE=1 ;;  # DO_SFIX=1 isn't needed for `gcc -Os'.
   -O*) ARGS="$ARGS$NL$ARG"; HAD_OFLAG=1; HAD_OPTIMIZE=1; DO_SFIX=1 ;;  # DO_SFIX=1 is needed for `gcc -O1' and `gcc -O2'.
   -g00) STRIP_MODE=0 ;;
   -g0) STRIP_MODE=1 ;;
   -g0r) STRIP_MODE=3 ;;
   -g*) ARGS="$ARGS$NL$ARG"; STRIP_MODE=0 ;;
   -nostdlib | -nodefaultlibs) DO_ADD_LIB= ;;
   -nostdinc) DO_ADD_INCLUDEDIR= ;;
   -blinux) OS=linux ;;  # Compatible with `owcc -blinux'.
   -bany) OS=any ;;  # Choose libc/minilibc/libca.i386.a.
   -[cSE])
     if test "$DO_MODE" && test "$DO_MODE" != "$ARG"; then echo "fatal: conflicting combination of $ARG and $DO_MODE" >&2; exit 1; fi
     test -z "$DO_MODE" && ARGS="$ARGS$NL$ARG"
     DO_ADD_LIB=; DO_LINK=; DO_MODE="$ARG"
     test "$ARG" = -c || NEED_GCC_AS=
     ;;
   -s) SFLAG="$ARG" ;;
   -v) HAD_V=-v; ARGS="$ARGS$NL$ARG" ;;
   -o?*) echo "fatal: unsupported minicc -o flag: $ARG" >&2; exit 1 ;;
   -o) SKIPARG="$ARG" ;;
   --download) SKIPARG="$ARG" ;;
   --get-config) DO_GET_CONFIG=1 ;;
   -L*) echo "fatal: unsupported minicc library path flag: $ARG" >&2; exit 1 ;;
   -l*) echo "fatal: unsupported minicc library flag: $ARG" >&2; exit 1 ;;
   -*) echo "fatal: unsupported minicc flag: $ARG" >&2; exit 1 ;;
   *.[aocisS])
    if ! test -f "$ARG"; then echo "fatal: missing source file: $ARG" >&2; exit 1; fi
    case "$ARG" in
     *.o) HAD_OFILE=1 ;;
     *.[sS]) HAD_SSFILE=1 ;;
    esac
    ARGS="$ARGS$NL$ARG"
    ;;
   *.nasm) ARGS="$ARGS$NL$ARG" ;;
   *.*) echo "fatal: unsupported input file extension for minicc: $ARG" >&2; exit 1 ;;
   *) echo "fatal: missing input file extension for minicc: $ARG" >&2; exit 1 ;;
  esac
done
unset DO_MODE
if test "$SKIPARG"; then
  echo "fatal: missing last flag argument: $SKIPARG" >&2
  exit 1
fi

if test "$HAD_TRADITIONAL" && test "$DO_ADD_INCLUDEDIR"; then  # libcs supported by minicc don't support -traditional.
  echo "fatal: $HAD_TRADITIONAL needs -nostdinc in minicc" >&2
fi

GCCBASE="/${GCC##*/}"
IS_WATCOM=
IS_CC1=  # The value 2 indicates autodownload. The value 3 indicates autodownload + PCC.
if test -z "$GCC"; then :
elif test "$GCC" = 4; then GCC="$MYDIR"/tools/cc1-4.8.5; IS_CC1=2  # minicc default of the GCC 4.x series.
elif test "$GCC" = 4.1 || test "$GCC" = 4.1.2; then GCC="$MYDIR"/tools/cc1-4.1.2; IS_CC1=2
elif test "$GCC" = 4.2 || test "$GCC" = 4.2.1; then GCC="$MYDIR"/tools/cc1-4.2.1; IS_CC1=2
elif test "$GCC" = 4.3 || test "$GCC" = 4.3.6; then GCC="$MYDIR"/tools/cc1-4.3.6; IS_CC1=2
elif test "$GCC" = 4.4 || test "$GCC" = 4.4.7; then GCC="$MYDIR"/tools/cc1-4.4.7; IS_CC1=2
elif test "$GCC" = 4.5 || test "$GCC" = 4.5.4; then GCC="$MYDIR"/tools/cc1-4.5.4; IS_CC1=2
elif test "$GCC" = 4.6 || test "$GCC" = 4.6.4; then GCC="$MYDIR"/tools/cc1-4.6.4; IS_CC1=2
elif test "$GCC" = 4.7 || test "$GCC" = 4.7.4; then GCC="$MYDIR"/tools/cc1-4.7.4; IS_CC1=2
elif test "$GCC" = 4.8 || test "$GCC" = 4.8.5; then GCC="$MYDIR"/tools/cc1-4.8.5; IS_CC1=2
elif test "$GCC" = 4.9 || test "$GCC" = 4.9.3; then GCC="$MYDIR"/tools/cc1-4.9.3; IS_CC1=2
elif test "${GCC#[1-9]}" != "$GCC"; then echo "fatal: GCC version $GCC isn't buundled with minicc; if you want your system GCC, use --gcc or --gcc=gcc-$GCC" >&2; exit 1
elif test "${GCCBASE#*[-/._]wcc386*}" != "$GCCBASE"; then IS_WATCOM=1
elif test "${GCCBASE#*[-/._]cc1}" != "$GCCBASE"; then IS_CC1=1
elif test "${GCCBASE#*[-/._]cc1[-+._]}" != "$GCCBASE"; then IS_CC1=1
elif test "${GCCBASE#*[-/._]pcc}" != "$GCCBASE"; then IS_CC1=3
fi
if test "$MINICC_LD" = ///gcc; then
  if test "$TCC"; then  # TODO(pts): Allow this.
    echo "fatal: conflicting combination of --tcc=... and --gccld" >&2
    exit 1
  elif test "$IS_WATCOM" ; then
    echo "fatal: conflicting combination of --watcom and --gccld" >&2
    exit 1
  elif test "$IS_CC1" ; then
    echo "fatal: conflicting combination of cc1 compiler and --gccld" >&2
    exit 1
  elif test -z "$GCC"; then
    echo "fatal: -gcc=... needed by --gccld" >&2
    exit 1
  fi
fi
LDBASE="/${MINICC_LD##*/}"
case "$LDBASE" in *[-/._]tcc* | *[-/._]miniutcc*) IS_TCCLD=1 ;; *) IS_TCCLD= ;; esac
if test "$TCC" && test "$IS_TCCLD"; then  # $TCCLD should work with $GCC
  if test "$MINICC_LD" != "$TCC"; then
    echo "fatal: conflicting combination of --tcc=... and --tccld=..." >&2
    exit 1
  fi
  MINICC_LD=  # Don't do $PATH lookup below.
fi
if test "$IS_AOUT" && test "$IS_TCCLD"; then
  echo "fatal: conflicting combination of -maout and --tccld=..." >&2
  exit 1
fi
if test "$IS_AOUT" && test "$STRIP_MODE" = 3; then
  echo "fatal: conflicting combination of -maout and -g0r" >&2
  exit 1
fi
if test "$TCC" && test "$GCC"; then
  echo "fatal: conflicting compilers, both --tcc=... and --gcc=..." >&2
  exit 1
fi
if test -z "$TCC" && test -z "$GCC"; then
  echo "fatal: missing compiler, neither --tcc=... nor --gcc=..." >&2
  exit 1
fi
if test "$USE_UTCC" && test "$DO_ADD_LIB"; then
  if test -z "$IS_TCCLD" && test -z "$MINICC_LD"; then
    MINICC_LD="$TCC"
    IS_TCCLD=1
  fi
  if test "${MINICC_LD%/miniutcc}" = "$MINICC_LD"; then
    # That's because ///tmp///LIBTCC1.a is embedded in the tools/miniutcc executable.
    echo "fatal: currently uClibc with --utcc needs --tccld; try --uclibc instead" >&2
    exit 1
  fi
fi
if test "$USE_UTCC" && test "$DO_ADD_LIB" && test "$ARCH" != i686; then
  echo "fatal: the --utcc bundled uClibc doesn't work on i386, it needs -march=i686" >&2
  exit 1
fi

if test "$IS_WATCOM" || test "$IS_CC1" = 3 || test "$TCC"; then DO_SFIX=; fi  # Only GCC (not Watcom, PCC or TinyCC) needs DO_SFIX=1 (`rep ret' so far).

DO_MAIN_AUTO=1
test "$DO_ARGC" && DO_MAIN_AUTO=0
test "$DO_ARGV" && DO_MAIN_AUTO=0
test "$DO_ENVP" && DO_MAIN_AUTO=0
test "$DO_ARGC" = 0 && test -z "$DO_ENVP" && DO_ENVP=0
test "$DO_ARGC" = 0 && test -z "$DO_ARGV" && DO_ARGV=0
test "$DO_ARGV" = 0 && test -z "$DO_ENVP" && DO_ENVP=0
test "$DO_ENVP" || DO_ENVP=1  # Play it safe by default, the program may use it.
test "$DO_ARGV" || DO_ARGV=1  # Play it safe by default, the program may use it.
test "$DO_ARGC" || DO_ARGC=1  # Play it safe by default, the program may use it.
if test "$DO_ENVP" = 1 && test "$DO_ARGV" = 0; then echo "fatal: -menvp needs -margv" >&2; exit 1; fi
if test "$DO_ENVP" = 1 && test "$DO_ARGC" = 0; then echo "fatal: -menvp needs -margc" >&2; exit 1; fi
if test "$DO_ARGV" = 1 && test "$DO_ARGC" = 0; then echo "fatal: -margv needs -margc" >&2; exit 1; fi

case "$GCC" in
 "") ;;
 */*)
  if test "${GCC#*/}" = "$GCC"; then  # No slash.
    :
  elif test -f "$GCC" && test -s "$GCC"; then
    if test -x "$GCC"; then
      :
    elif test "$IS_CC1" = 2; then
      chmod +x "$GCC" || exit 6
    else
      echo "fatal: GCC program file not executable: $GCC" >&2
    fi
  elif test "$IS_CC1" != 2 || test "${GCC#$MYDIR/tools/cc1-*}" = "$GCC"; then
    echo "fatal: GCC command not found: $GCC" >&2; exit 6
  elif test -z "$DO_DOWNLOAD"; then
    echo "fatal: GCC command not found; omit --no-download to get it downloaded: $GCC" >&2; exit 6
  else
    if sh "$0" --boxed-path "$OLD_PATH" --download $HAD_V "${GCC#$MYDIR/tools/}" && test -f "$GCC"; then :; else
      echo "fatal: GCC download failed" >&2; exit 6
    fi
    chmod +x "$GCC" || exit 6
  fi
  if test "$IS_CC1"; then
    if test -f "$GCC" && test -s "$GCC" && test -x "$GCC"; then :; else
      echo "fatal: problem with C compiler program file: $GCC" >&2; exit 6
    fi
  fi
  if test "$IS_CC1" = 2 || test "$IS_CC1" = 3 || test "$IS_WATCOM$HAD_SSFILE" = 11; then
    if test -f "$MYDIR"/tools/as && test -s "$MYDIR"/tools/as; then
      :
    elif test -z "$DO_DOWNLOAD"; then
      echo "fatal: GNU as(1) not found; omit --no-download to get it downloaded: $MYDIR/tools/as-2.22" >&2; exit 6
    else
      if sh "$0" --boxed-path "$OLD_PATH" --download $HAD_V as-2.22 && test -f "$MYDIR/tools/as-2.22"; then :; else
        echo "fatal: GNU as(1) download failed" >&2; exit 6
      fi
      test -x "$MYDIR/tools/as-2.22" || chmod +x "$MYDIR/tools/as-2.22" || exit 6
    fi
    if ! test -x "$MYDIR/tools/as-2.22"; then chmod +x "$MYDIR/tools/as-2.22" || exit 6; fi
    rm -f "$MYDIR/tools/as"
    ln -s as-2.22 "$MYDIR/tools/as" || exit 6
    test -x "$MYDIR/tools/as" || chmod +x "$MYDIR/tools/as" || exit 6
  fi
  if test "$IS_CC1"; then
    if test -f "$MYDIR"/tools/as && test -s "$MYDIR/tools/as" && test -x "$MYDIR"/tools/as; then :; else
      echo "fatal: problem with assembler tool file: $MYDIR/tools/as"; exit 6
    fi
  fi
  ;;
 *)  # Resolve $GCC on $OLD_PATH. Useful for --noenv and --boxed.
  LOOKUP="$(PATH="$OLD_PATH"; type "$GCC" 2>/dev/null)"
  case "$LOOKUP" in
   *\ is\ /*)  LOOKUP="/${LOOKUP#*\ is\ /}"  ;;
   *\ for\ /*) LOOKUP="/${LOOKUP#*\ for\ /}" ;;  # ksh(1).
   *) if test -z "$DO_GET_CONFIG"; then echo "fatal: gcc command not found: $GCC" >&2; exit 6; fi; LOOKUP="$GCC" ;;
  esac
  test "$IS_BOXED" && GCC="$LOOKUP" && GCC_BARG="-B${GCC%/*}"  # Don't mess with $GCC paths unless --noenv or --boxed is specified.
esac
case "$TCC" in "") ;; */*) ;; *)  # Resolve $TCC on $OLD_PATH. Useful for --noenv and --boxed.
  LOOKUP="$(PATH="$OLD_PATH"; type "$TCC" 2>/dev/null)"
  case "$LOOKUP" in
   *\ is\ /*)  LOOKUP="/${LOOKUP#*\ is\ /}"  ;;
   *\ for\ /*) LOOKUP="/${LOOKUP#*\ for\ /}" ;;  # ksh(1).
   *) echo "fatal: tcc command not found: $TCC" >&2; exit 6 ;;
  esac
  TCC="$LOOKUP"
esac
case "$MINICC_LD" in "") ;; */*) ;; *)  # Resolve $MINICC_LD on $OLD_PATH. Useful for --noenv and --boxed.
  LOOKUP="$(PATH="$OLD_PATH"; type "$MINICC_LD" 2>/dev/null)"
  case "$LOOKUP" in
   *\ is\ /*)  LOOKUP="/${LOOKUP#*\ is\ /}"  ;;
   *\ for\ /*) LOOKUP="/${LOOKUP#*\ for\ /}" ;;  # ksh(1).
   *) echo "fatal: --tccld command not found: $MINICC_LD" >&2; exit 6 ;;
  esac
  MINICC_LD="$LOOKUP"
esac

test "$DO_ADD_LIB" || DO_SMART=0

if test -z "$DO_LINK"; then
  MINICC_LD=
  IS_TCCLD=
elif test "$TCC" && test -z "$MINICC_LD"; then  # !! Move earlier.
  MINICC_LD="$TCC"
  IS_TCCLD=1
fi

NEED_LIBC=
test "$DO_ADD_INCLUDEDIR" && NEED_LIBC=1
if test "$USE_UTCC"; then
  if test "$LIBC"; then
    echo "fatal: conflicting combination of --utcc and --libc=$LIBC" >&2
    exit 1
  fi
  LIBC=minilibc  # For -I... ($DO_ADD_INCLUDEDIR).
else
  test "$LIBC" || LIBC=minilibc
  test "$DO_ADD_LIB" && NEED_LIBC=1
fi
if test "$NEED_LIBC"; then
  if test -f "$MYDIR/libc/$LIBC/libc.defs"; then
    :
  elif test -d "$MYDIR/libc/$LIBC"; then
    echo "fatal: missing libc.defs file: $MYDIR/libc/$LIBC/libc.defs" >&2
    exit 4
  else
    if test "${LIBC#*-}" = "$LIBC"; then
      for D in "$MYDIR/libc/$LIBC"-*; do
        if test -f "$D/libc.defs"; then
          LIBC="${D##*/}"; break  # Use the first one found. TODO(pts): Does the list get sorted?
        fi
      done
    fi
    if ! test -f "$MYDIR/libc/$LIBC/libc.defs"; then
      SFX=
      for D in "$MYDIR/libc/$LIBC"-*.sfx.7z; do
        if test -f "$D"; then
          SFX="$D"; LIBC="${D##*/}"; LIBC="${LIBC%.sfx.7z}"; break  # Use the first one found. TODO(pts): Does the list get sorted?
        fi
      done
      if test "$SFX" && test -f "$SFX" && test -s "$SFX"; then
        :
      elif test -z "$DO_DOWNLOAD"; then
        :
      elif test "$LIBC" = eglibc || test "${LIBC#eglibc-}" != "$LIBC"; then
        if ! sh "$0" --boxed-path "$OLD_PATH" --download $HAD_V "$LIBC.sfx.7z"; then
          echo "fatal: libc download failed: $LIBC" >&2; exit 6
        fi
        SFX=
        if test "${LIBC#*-}" = "$LIBC"; then
          for D in "$MYDIR/libc/$LIBC"-*.sfx.7z; do  # Repeats the loop above.
            if test -f "$D"; then
              SFX="$D"; LIBC="${D##*/}"; LIBC="${LIBC%.sfx.7z}"; break  # Use the first one found. TODO(pts): Does the list get sorted?
            fi
          done
        else
          test -f "$MYDIR/libc/$LIBC.sfx.7z" && SFX="$MYDIR/libc/$LIBC.sfx.7z"
        fi
        if test -z "$SFX"; then
          echo "fatal: libc download hasn't created file: $MYDIR/libc/$LIBC*.sfx.7z: $LIBC" >&2; exit 4
        fi
      fi
      if test "$SFX" && test -f "$SFX" && test -s "$SFX"; then
        chmod +x "$SFX" 2>/dev/null
        rm -rf "$MYDIR/libc/$LIBC"
        echo "info: extracting libc sfx archive: $SFX" >&2
        (cd "${SFX%/*}" && ./"${SFX##*/}" -y >/dev/null)
        if ! test -f "$MYDIR/libc/$LIBC/libc.defs"; then
          echo "fatal: libc sfx extraction failed: $SFX" >&2
          exit 4
        fi
      else
        echo "fatal: libc directory not found: $MYDIR/libc/$LIBC" >&2
        exit 4
      fi
    fi
    if test "$DO_ADD_LIB" && test "$IS_TCCLD" && test -f "$MYDIR/libc/$LIBC/libc.notccld"; then  # Example: EGLIBC.
      echo "fatal: $(cat "$MYDIR/libc/$LIBC/libc.notccld")" >&2
      exit 4
    fi
  fi
fi
unset OLD_PATH

if test "$STRIP_MODE" = 0 || test -z "$DO_LINK"; then STRIP_MODE=0
elif test "$STRIP_MODE" = 1; then :
elif test "$STRIP_MODE" = 3; then SFLAG=  # By stripping symbols and keeping relocations at the same time (`ld -s -q'), GNU ld(1) fails for some complicated programs. So we don't strip symbols.
else test "$STRIP_MODE" || STRIP_MODE=2; SFLAG=-s
fi

#if ! "$GCC" "$GCC_BARG" -print-search-dirs >/dev/null 2>&1; then  # Also works with Clang.
#  echo "fatal: gcc not working: $GCC" >&2; exit 2
#fi
if test "$MINICC_LD" = ///gcc; then
  MINICC_LD="$(exec "$GCC" "$GCC_BARG" -print-prog-name=ld 2>/dev/null)"  # Also works with Clang.
  if test -z "$MINICC_LD"; then
    if ! "$GCC" "$GCC_BARG" -print-search-dirs >/dev/null 2>&1; then
      echo "fatal: gcc not working: $GCC" >&2; exit 2
    fi
    echo "fatal: linker not found by gcc: $GCC" >&2; exit 2
  elif test "${MINICC_LD#*$NL}" != "$MINICC_LD"; then  # Multiline report, e.g. from wcc386.
    echo "fatal: gcc failed to report linker: $GCC" >&2; exit 2
  fi
  # Sometimes it's not found, but still returned nonempty.
elif test "$DO_LINK" && test -z "$MINICC_LD"; then
  MINICC_LD="$MYDIR"/tools/ld  # Used by default (like --minild), unless --gccld, --tccld etc. is specified.
fi
if test "$DO_LINK"; then
  if test -z "$MINICC_LD"; then
    echo "fatal: linker not found" >&2; exit 2
  fi
  if test "${MINICC_LD#*/}" != "$MINICC_LD" && test ! -f "$MINICC_LD"; then
    echo "fatal: linker program file not found: $MINICC_LD" >&2; exit 2
  fi
fi

if test -z "$GCC" || test "$GCC_BARG" = -pipe || test "$IS_CC1" || test "$IS_WATCOM" || test -z "$NEED_GCC_AS"; then
  GCC_BARG=
else
  case "$GCCBASE" in
   *[-/._]clang*) GCC_BARG= ;;  # clang(1) and wcc386(1) (unlike gcc) don't need $GCC_BARG to find as(1).
  esac
fi

OFLAG_ARGS=
if test -z "$HAD_OFLAG"; then  # Add some size-optimizing flags.
  HAD_OPTIMIZE=1; HAD_OS=1
  case "$GCCBASE" in
   "") ;;
   *[-/._]clang*) OFLAG_ARGS="-Os$NL-mstack-alignment=2" ;;
   *) OFLAG_ARGS="-Os$NL-falign-functions=1$NL-falign-jumps=1$NL-falign-loops=1$NL-mpreferred-stack-boundary=2" ;;
  esac
  test "$TCC" && OFLAG_ARGS="-Os"
fi
INCLUDEDIR_ARG=
DEF_ARG=
NASM_DEF_ARG=
test "$ARCH" = i686 || NASM_DEF_ARG=-DCONFIG_I386

if test "$DO_ADD_INCLUDEDIR"; then
  INCLUDEDIR_ARG="-I$MYDIR/libc/$LIBC/include"
  if test "$USE_UTCC"; then
    DEF_ARG="-D__UCLIBC__"
  else
    # TODO(pts): Ignore comments in lines starting with `#'.
    # This DEF_ARG must be valid for for nasm (for -msmart), do it should be contain only `-D...' and `-U...'.
    for F in $(cat "$MYDIR/libc/$LIBC/libc.defs"); do  # Split on any whitespace, $IFS hasn't been set yet.
      DEF_ARG="$DEF_ARG$NL$F"
    done
  fi
fi
test "$OS" = any && DEF_ARG="$DEF_ARG$NL-D__ANYOS__"  # Don't mess with -D__linux__ or -D__LINUX__.
test "$DO_MAIN_AUTO" && DEF_ARG="$DEF_ARG$NL-DCONFIG_MAIN_ARGS_AUTO"
if test "$DO_ARGC" = 0; then DEF_ARG="$DEF_ARG$NL-DCONFIG_MAIN_NO_ARGC_ARGV_ENVP"
elif test "$DO_ARGV" = 0; then DEF_ARG="$DEF_ARG$NL-DCONFIG_MAIN_NO_ARGV_ENVP"
elif test "$DO_ENVP" = 0; then DEF_ARG="$DEF_ARG$NL-DCONFIG_MAIN_NO_ENVP"
fi
test "$PRINTF_PLUS"     || DEF_ARG="$DEF_ARG$NL-DCONFIG_VFPRINTF_NO_PLUS"
test "$PRINTF_OCTAL"    || DEF_ARG="$DEF_ARG$NL-DCONFIG_VFPRINTF_NO_OCTAL"
test "$PRINTF_LONG"     || DEF_ARG="$DEF_ARG$NL-DCONFIG_VFPRINTF_NO_LONG"
test "$PRINTF_LONGLONG" || DEF_ARG="$DEF_ARG$NL-DCONFIG_VFPRINTF_NO_LONGLONG"
if test "$FILE_CAPACITY"; then
  if test "$LIBC" = minilibc; then  # Other libcs have unlimited open files.
    if test "$DO_SMART" = 0; then
      echo "fatal: -mfiles=... doesn't work with -mno-smart" >&2
      exit 3
    fi
    #if test "$LIBC" != minilibc; then
    #  echo "fatal: -mfiles=... works only with --libc=minilibc, not --libc=$LIBC" >&2
    #  exit 3
    #fi
  fi
  DEF_ARG="$DEF_ARG$NL-DCONFIG_FILE_CAPACITY=$FILE_CAPACITY"  # Respected by src/stdio_medium_flush_opened.nasm.
fi
if test "$IS_WATCOM" || test "$IS_CC1" = 3 || test "$TCC"; then
  # Add some -D.. flags which GCC (>=1) already defines. These flags affect EGLIBC on other compilers.
  test "$HAD_OPTIMIZE" && DEF_ARG="$DEF_ARG$NL-D__OPTIMIZE__"
  test "$HAD_OS" && DEF_ARG="$DEF_ARG$NL-D__OPTIMIZE_SIZE__"
  test "$HAD_NOINLINE" && DEF_ARG="$DEF_ARG$NL-D__NO_INLINE__"
else
  test "$HAD_OPTIMIZE" && NASM_DEF_ARG="$NASM_DEF_ARG$NL-D__OPTIMIZE__"
  test "$HAD_OS" && NASM_DEF_ARG="$NASM_DEF_ARG$NL-D__OPTIMIZE_SIZE__"
  test "$HAD_NOINLINE" && NASM_DEF_ARG="$NAsM_DEF_ARG$NL-D__NO_INLINE__"
fi
OUTFILE_ARG=
test "$OUTFILE" && OUTFILE_ARG="-o$NL$OUTFILE"
test "$DO_WKEEP" || WFLAGS=  # Maybe clear the default -W... warning flags.
if test "$TCC"; then
  # TODO(pts): Does TCC really generate i386-only code?
  # We don't pass $ANSIFLAG, because TCC 0.9.26 would fail for it.
  case "$ANSIFLAG" in  # TinyCC 0.9.26 doesn't support -ansi or -std=*.
   -std=c* | -ansi) ANSIFLAG=-D__STRICT_ANSI__ ;;
   *) ANSIFLAG= ;;
  esac
  DARCHFLAG=
  test "$ARCH" = i386 || DARCHFLAG="-D__${ARCH}__"  # Just a C #define, it doesn't affect TinyCC code generation.
  ARGS="$TCC$NL-m32$NL-march=$ARCH$NL$DARCHFLAG$NL-static$NL-nostdlib$NL-nostdinc$NL$SFLAG$NL$OFLAG_ARGS$NL$ANSIFLAG$NL$WFLAGS$NL$DEF_ARG$NL$DEF_CMDARG$NL$ARGS$NL$INCLUDEDIR_ARG$NL$OUTFILE_ARG"
  DARCHFLAG=  # Prevent reuse later.
else
  # This also works with TCC, but it's too much cruft.
  # Add $INCLUDEDIR_ARG last, so that -I... specified by the user takes precedence. !! TODO(pts): Does GCC do this or the opposite?
  # Specifying -fcommon since -fno-common is the default since GCC 10 and Clang 11: https://maskray.me/blog/2022-02-06-all-about-common-symbols
  # DYI dietlibc 0.34 adds: gcc -Os -fomit-frame-pointer -falign-functions=1 -falign-jumps=1 -falign-loops=1 -mpreferred-stack-boundary=4
  # !! TODO(pts): Try -fomit-frame-pointer. Sometimes it makes the code larger. OpenWatcom definitely benefits.
  # !! TODO(pts): Try -mno-align-stringops. What happens with old GCC not supporting it, or Clang?
  # !! TODO(pts): Try -fno-unroll-loops -fmerge-all-constants -fno-math-errno. What happens with old GCC not supporting it, or Clang?
  # !! TODO(pts): Document -Wl,-N for merging sections .text and .data.
  ARGS="$TCC$NL$GCC$NL$GCC_BARG$NL-m32$NL-march=$ARCH$NL-static$NL-fno-pic$NL-U_FORTIFY_SOURCE$NL-fcommon$NL-fno-stack-protector$NL-fno-unwind-tables$NL-fno-asynchronous-unwind-tables$NL-fno-builtin$NL-fno-ident$NL-fsigned-char$NL-ffreestanding$NL-nostdlib$NL-nostdinc$NL$SFLAG$NL$OFLAG_ARGS$NL$ANSIFLAG$NL$WFLAGS$NL$DEF_ARG$NL$DEF_CMDARG$NL$ARGS$NL$INCLUDEDIR_ARG$NL$OUTFILE_ARG"
fi
ANSIFLAG= ;  # Prevent reuse later.
NEED_LIBMINITCC1=
if test "$DO_ADD_LIB"; then
  LIBWL=
  if test "$USE_UTCC"; then
    LIBFN=///tmp///LIBTCC1.a  # Embedded in tools/miniutcc.
    if test "$DO_SMART" && test "$DO_SMART" != 0; then
      echo "fatal: --utcc doesn't support -msmart" >&2
      exit 3
    fi
  else
    if test "$OS" = any; then
      LIBFN="$MYDIR/libc/$LIBC/libca.i386.a"
      test "$DO_SMART" || DO_SMART=0
      if test "$DO_SMART" != 0; then
        # TODO(pts): Make smart.nasm recognize -bany, and prevent it from
        # adding any Linux-specific functions then.
        echo "fatal: -bany doesn't work with -msmart" >&2
        exit 3
      fi
    else
      LIBFN="$MYDIR/libc/$LIBC/libc.$ARCH.a"
    fi
    if ! test -f "$LIBFN"; then
      if test "$LIBC" = minilibc; then
        if test "$ARCH" = i586 || test "$ARCH" = i486; then
          LIBFN="$MYDIR/libc/$LIBC/libc.i386.a"
        fi
        if ! test -f "$LIBFN"; then
          if "$MYDIR/build.sh" && test -f "$LIBFN"; then :; else
            echo "fatal: failed to build libc .a: $LIBFN" >&2
            exit 3
          fi
        fi
      else
        if test "$OS" != linux; then
          echo "fatal: the libc wasn't compiled for OS -b$OS, use e.g. -blinux instead" >&2
          exit 3
        elif test -f "$MYDIR/libc/$LIBC/libc.i386.a"; then  # Use libc precompiled for older arch.
          LIBFN="$MYDIR/libc/$LIBC/libc.i386.a"
        elif test -f "$MYDIR/libc/$LIBC/libc.i686.a"; then  # Example: minicc --uclibc -march=i386
          echo "fatal: the libc wasn't compiled for -march=$ARCH, use -march=i686" >&2
          exit 3
        else
          echo "fatal: missing libc .a: $LIBFN" >&2
          exit 3
        fi
      fi
    fi
    if test -z "$DO_SMART"; then
      DO_SMART=0
      test -f "$MYDIR/libc/$LIBC/smart.nasm" && DO_SMART=1  # Use smart linking by default if available for libc.
    elif test "$DO_SMART" != 0; then
      if ! test -f "$MYDIR/libc/$LIBC/smart.nasm"; then
        echo "fatal: missing libc smart.nasm for -msmart: $MYDIR/libc/$LIBC/smart.nasm" >&2
        exit 3
      fi
    fi
  fi
  test "$DO_SMART" || DO_SMART=0  # Fallback.
  if test "$TCC" || test "$IS_TCCLD"; then  # TCC needs an explicit start*.o in the command line -- or does it?
    OBJFN="$MYDIR/helper_lib/need_start.o"
    if ! test -f "$OBJFN"; then
      # !! TODO(pts): Let build.sh take care of this.
      test "$HAD_V" && echo "info: compiling: $MYDIR/helper_lib/need_start.nasm" >&2
      if "$MYDIR/tools/nasm-0.98.39" -O0 -w+orphan-labels -f elf -o "$OBJFN" "$MYDIR/helper_lib/need_start.nasm" && test -f "$OBJFN"; then :; else
        echo "fatal: failed to build need-start .o: $OBJFN" >&2
        exit 3
      fi
    fi
    ARGS="$ARGS$NL$OBJFN"
    if test "$USE_UTCC"; then
      OBJFN="$MYDIR/helper_lib/need_uclibc_main.o"
      if ! test -f "$OBJFN"; then
        # !! TODO(pts): Let build.sh take care of this.
        test "$HAD_V" && echo "info: compiling: $MYDIR/helper_lib/need_uclibc_main.nasm" >&2
        if "$MYDIR/tools/nasm-0.98.39" -O0 -w+orphan-labels -f elf -o "$OBJFN" "$MYDIR/helper_lib/need_uclibc_main.nasm" && test -f "$OBJFN"; then :; else
          echo "fatal: failed to build need-uclibc-main .o: $OBJFN" >&2
          exit 3
        fi
      fi
      ARGS="$ARGS$NL$OBJFN"
    fi
  fi
  test "$DO_SMART" = 0 && ARGS="$ARGS$NL$LIBWL$LIBFN"
  if test "$TCC" && test -z "$USE_UTCC"; then NEED_LIBMINITCC1=1
  elif test "$IS_TCCLD" && test "$IS_WATCOM"; then NEED_LIBMINITCC1=1  # We need it for dummy symbols cstart_ and _argc.
  elif test "$IS_TCCLD" && test "$HAD_OFILE"; then NEED_LIBMINITCC1=1  # We need it for dummy symbols cstart_ and _argc.
  else NEED_LIBMINITCC1=
  fi
  if test "$NEED_LIBMINITCC1"; then
    LIBMTFN="$MYDIR/helper_lib/libminitcc1.a"
    if ! test -f "$LIBMTFN"; then
      if "$MYDIR/build.sh" && test -f "$LIBMTFN"; then :; else
       echo "fatal: failed to build libtcc1 .a: $LIBMTFN" >&2
        exit 3
      fi
    fi
    test "$DO_SMART" = 0 && ARGS="$ARGS$NL$LIBMTFN"
  fi
  if test "$USE_UTCC"; then
    # OBJFN="$MYDIR/helper_lib/start_uclibc_linux.o"  # Not needed.
    OBJFN="///tmp///crt1.o"  # Embedded in the tools/miniutcc executable, same functionality as start_uclibc_linux.o.
    ARGS="$ARGS$NL$LIBWL$OBJFN"
  fi
fi
test "$DO_SMART" || DO_SMART=0  # Fallback.

test "$TMPDIR" || TMPDIR=/tmp
test "${TMPDIR#-}" = "$TMPDIR" || TMPDIR="./$TMPDIR"  # Make it not a command-line flag (-...).
export TMPDIR

if test "$DO_GET_CONFIG"; then
  # The values are not escaped.
  echo "MINICC=v1"
  echo "GCC=$GCC"
  echo "TCC=$TCC"
  echo "IS_TCCLD=$IS_TCCLD"
  echo "USE_UTCC=$USE_UTCC"
  echo "LIBC=$LIBC"
  echo "DO_SMART=$DO_SMART"
  echo "DO_LINK=$DO_LINK"
  echo "LIBFN=$LIBFN"
  echo "OBJFN=$OBJFN"
  exit
fi


IFS="$NL"  # Argument splitting will happen over newlines only.
if test "$DO_LINK"; then
  test "$OUTFILE" || OUTFILE=a.out
fi
test "${OUTFILE#-?}" = "$OUTFILE" || OUTFILE="./$OUTFILE"  # Make it not a command-line flag (-...).

TMPOFILES=
if test "$GCC" || test -z "$IS_TCCLD"; then
  # TCC accepts all these flags (and ignores `-m elf_i386' if passed).
  LDARGS="$MINICC_LD$NL-nostdlib$NL-static"
  if test "$IS_TCCLD"; then
    if test "$STRIP_MODE" = 3; then
      echo "fatal: -g0r doesn't work with --tccld" >&2
      exit 3
    fi
  elif test "$IS_AOUT"; then
    LDARGS="$LDARGS$NL-T$MYDIR/tools/i386linux.x$NL-e${NL}_start$NL--fatal-warnings"
  else
    # `-e _start' is needed, because without it GNU gold(1) wouldn't fail to link if _start is not defined.
    # `--fatal-warnings' is needed, because without it GNU ld(1) would happily create an executable without _start.
    LDARGS="$LDARGS$NL-m${NL}elf_i386$NL-z${NL}norelro$NL-e${NL}_start$NL--fatal-warnings"
    test "$STRIP_MODE" = 3 && LDARGS="$LDARGS$NL-q"  # GNU ld(1) flag -q to keep relocations.
  fi
  CCARGS="$GCC"
  test "$TCC" && CCARGS="$TCC"
  test "$DO_LINK" && CCARGS="$CCARGS$NL-c"
  FILEARGS=
  SKIPARG=
  CCMODE=
  for ARG in --skiparg $ARGS; do
    if test "$SKIPARG"; then
      test "$SKIPARG" = -include && CCARGS="$CCARGS$NL$ARG"
      SKIPARG=; continue
    fi
    case "$ARG" in
     *"$NL"*) echo "fatal: unexpected newline in minicc generated argument" >&2; exit 7 ;;
     "") echo "fatal: empty minicc generated argument" >&2; exit 7 ;;
     --skiparg) SKIPARG=1 ;;
     -o) SKIPARG="$ARG" ;;
     -include) SKIPARG="$ARG"; CCARGS="$CCARGS$NL$ARG" ;;
     -Wl,) ;;
     -Wl,-*)
       ARG="${ARG#-Wl,}"
       IFS=,  # Split on comma.
       for ARG in $ARG; do
         LDARGS="$LDARGS$NL$ARG"
       done
       IFS="$NL"
       ;;
     -Wl,?*) FILEARGS="$FILEARGS$NL--ldfile=$ARG" ;;  # This shouldn't happen.
     -s) LDARGS="$LDARGS$NL$ARG" ;;
     -[cSE])
       if test "$DO_LINK"; then echo "fatal: output mode not supported when linking: $ARG" >&2; exit 7; fi
       CCMODE="$ARG"
       CCARGS="$CCARGS$NL$ARG"
       ;;
     -*) CCARGS="$CCARGS$NL$ARG" ;;
     *.[ao]) FILEARGS="$FILEARGS$NL--ldfile=$ARG" ;;
     *.[ci]) FILEARGS="$FILEARGS$NL--srcfile=$ARG" ;;  # owcc386 treats .i files just like .c, but gcc doesn't allow `#' in .i files, because they are apready preprocesed.
     *.[sS] | *.nasm)
       FILEARGS="$FILEARGS$NL--srcfile=$ARG"
       ;;
     *) echo "fatal: unsupported input file extension: $ARG" >&2; exit 7 ;;
    esac
  done
  if test "$SKIPARG"; then
    echo "fatal: missing last flag argument for minicc wcc386: $SKIPARG" >&2
    exit 7
  fi
  if test -z "$FILEARGS"; then
    echo "fatal: no source files specified" >&2
    exit 7
  fi
  LDARGS="$LDARGS$NL$OUTFILE_ARG"
  # echo "CCARGS: $CCARGS" >&2; echo "LDARGS: $LDARGS" >&2; echo "FILEARGS: $FILEARGS" >&2

  if test "$IS_WATCOM"; then  # If $IS_WATCOM, convert $CCARGS for wcc386.
    if test "$DO_ADD_INCLUDEDIR"; then
      if ! test -f "$MYDIR/libc/$LIBC/include/_preincl.h"; then
        echo "fatal: libc not prepared for wcc386, file missing: $MYDIR/libc/$LIBC/include/_preincl.h" >&2
        exit 5
      fi
    fi
    WAFLAG=
    WFFLAG=-of+  # GCC -fno-omit-frame-pointer default.
    WSFLAG=
    WJFLAG=-j  # `signed char' is GCC default.
    WEIFLAG=-ei  # -fno-short-enums is GCC default.
    WECFLAG=-ec
    WOSSFLAG=  # Flag for tools/omf2emf.
    # Not specifying -zls makes wcc386 insert these extern symbols:
    # * _cstart_: if main is defined.
    # * __argc: if main has at least 1 argument. There is no distinction between argc, argc+argv and argc+argv+envp.
    WAUTOSYMFLAG=
    WARGS=
    WISOMF=
    WHADWEXTRA=
    test "$HAD_V" || WARGS="$WARGS$NL-q"
    WARGS="$WARGS$NL-bt=linux$NL-fr$NL-zl$NL-zld$NL-e=10000$NL-zp=4"
    unset INCLUDE  # Don't let wcc386 find any system #include etc. file.
    unset WATCOM  # Don't let wcc386 find any system #include etc. file.
    SKIPARG=
    for ARG in --skiparg $CCARGS; do
      if test "$SKIPARG"; then
        test "$SKIPARG" = -include && WARGS="$WARGS$NL-fi=$ARG"  # -fi=_preincl.h is automatic, and is included before this.
        SKIPARG=; continue
      fi
      case "$ARG" in
       *"$NL"*) echo "fatal: unexpected newline in minicc wcc386 argument" >&2; exit 5 ;;
       "") echo "fatal: empty minicc wcc386 argument" >&2; exit 5 ;;
       --skiparg) SKIPARG=1 ;;
       -B?*) ;;  # Just to be sure. minicc doesn't add it for wcc386.
       -v) ;;  # Already processed as $HAD_V.
       -ansi | -std=c89 | -std=gnu89) WARGS="$WARGS$NL-za$NL-D__STRICT_ANSI__" ;;
       -std=c99) WARGS="$WARGS$NL-za99$NL-D__STRICT_ANSI__" ;;
       -std=gnu99) WARGS="$WARGS$NL-za99" ;;
       -std=ow) WARGS="$WARGS$NL-ze" ;;
       -pedantic) ;;
       -m32 | -static | -fno-pic | -fcommon | -fno-unwind-tables | -fno-asynchronous-unwind-tables | -fno-builtin | -fno-ident | -ffreestanding | -fno-lto | -nostdinc | -falign-functions=* | -falign-jumps=* | -falign-loops=* | -mpreferred-stack-boundary=*) ;;
       -finline | -fno-inline | -fno-unroll-loops | -fmerge-all-constants | -fno-math-errno | -g0 | -g00 | -Wno-no) ;;
       -fomit-frame-pointer) WFFLAG= ;;
       -fomit-leaf-frame-pointer) WFFLAG=-of ;;
       -fno-omit-frame-pointer) WFFLAG=-of ;;
       -fno-omit-leaf-frame-pointer) WFFLAG=-of+ ;;
       -fstrict-aliasing) WAFLAG= ;;
       -fno-strict-aliasing) WAFLAG=-oa ;;
       -U_FORTIFY_SOURCE) ;;
       -fno-stack-protector | -fno-stack-check) WSFLAG=-s ;;
       #-fstack-protector) WSFLAG= ;;  # TODO(pts): Add libc support (__STK function).
       -mno-autosym) WAUTOSYMFLAG=-zls ;;  # minicc-specific.
       -mautosym) WAUTOSYMFLAG= ;;  # minicc-specific.
       -fsigned-char | -fno-unsigned-char) WJFLAG=-j ;;
       -fno-signed-char | -funsigned-char) WJFLAG=-D__CHAR_UNSIGNED__ ;;  # For GCC compatibility.
       -fshort-enums) WEIFLAG=-em ;;
       -fno-short-enums) WEIFLAG=-ei ;;
       -finline-fp-rounding) WARGS="$WARGS$NL-zri" ;;  # To prevent the call to __CHP.
       -march=i386) WARGS="$WARGS$NL-3r" ;;
       -march=i486) WARGS="$WARGS$NL-4r" ;;
       -march=i586) WARGS="$WARGS$NL-5r" ;;
       -march=i686) WARGS="$WARGS$NL-6r" ;;  # !! TODO(pts): Does it generate larger code? Then change the default with -Os.
       -mconst-seg) WECFLAG=; WOSSFLAG=-oss; WARGS="$WARGS$NL-fpc" ;;  # Put string literals to segment CONST. As a side-effect, -fpc (-msoft-float) must also be enabled. This is not a GCC flag, it's `minicc --wcc' only.
       -mno-80387 | -msoft-float) WARGS="$WARGS$NL-fpc" ;;  # Useful for string merging in .rodata.str1.1.
       -m80387 | -mhard-float | -mhard-emu-float) WARGS="$WARGS$NL-fpi" ;;  # Default.  # -mhard-float would be `-fpi87'.
       -nostdlib) ;;  # minicc $CCARGS always contains -nostdlib.
       -W | -Wextra) WARGS="$WARGS$NL-wx"; WHADWEXTRA=1 ;;
       -Wimplicit-function-declaration) WARGS="$WARGS$NL-wce=308" ;;
       -Werror[-=]implicit-function-declaration) WARGS="$WARGS$NL-wce=308" ;;  # Unfortunately it still remains a warning, there is no per-warning control of errors.
       -Wmissing-prototypes | -Wno-missing-prototypes) ;;  # Silently ignore.
       -Wshadow | -Wno-shadow) ;;  # Silently ignore.
       -Wsign-compare| -Wno-sign-compare) ;;  # Silently ignore.
       -Wformat | -Wno-format) ;;  # Silently ignore.
       -Wunused-parameter) WARGS="$WARGS$NL-wce=303" ;;
       -Wno-unused-parameter) WARGS="$WARGS$NL-wcd=303" ;;
       -Wunused-variable) WARGS="$WARGS$NL-wce=202" ;;
       -Wno-unused-variable) WARGS="$WARGS$NL-wcd=202" ;;
       -Wnewline-eof) WARGS="$WARGS$NL-wce=138" ;;  # Clang (not GCC).
       -Wno-newline-eof) WARGS="$WARGS$NL-wcd=138" ;;
       -Wpointer-sign) WARGS="$WARGS$NL-wce=1180$NL-wce=1181" ;;
       -Wno-pointer-sign) WARGS="$WARGS$NL-wcd=1180$NL-wcd=1181" ;;
       -Wmissing-field-initializers | -Wno-missing-field-initializers | -Wunused-local-typedefs | -Wno-unused-local-typedefs | -Waddress-of-packed-member | -Wno-address-of-packed-member) ;;  # Silently ignore.
       -Wunused-result | -Wno-unused-result) ;;  # Silently ignore.
       -Wshift-negative-value | -Wno-shift-negative-value)  ;;  # Silently ignore.
       -Wall) test "$WHADWEXTRA" || WARGS="$WARGS$NL-w4$NL-wcd=303" ;;
       -Werror) WARGS="$WARGS$NL-we" ;;
       -Werror=*) ;;  # No per-warning control, just ignore for simplicity.
       -w) WARGS="$WARGS$NL-w0" ;;
       -Wlevel[0-9]*) WARGS="$WARGS$NL-w${ARG#-Wlevel}" ;;
       -Wno-n[0-9]*) WARGS="$WARGS$NL-wcd=${ARG#-Wno-n}" ;;
       -Wn[0-9]*) WARGS="$WARGS$NL-wce=${ARG#-Wn}" ;;
       -Wstop-after-errors=[0-9]*) WARGS="$WARGS$NL-e${ARG#*=}" ;;  # owcc(1)-specific.
       -H) WARGS="$WARGS$NL-fti" ;;
       -O0) WARGS="$WARGS$NL-od" ;;  # TODO(pts): Try -oh (expensive optimizations). Does it reduce size?
       -O1) WARGS="$WARGS$NL-oil" ;;
       -O2) WARGS="$WARGS$NL-onatx" ;;
       -O3) WARGS="$WARGS$NL-onatxl+" ;;
       -Os) WARGS="$WARGS$NL-os" ;;
       -Ot) WARGS="$WARGS$NL-ot" ;;
       -O)  WARGS="$WARGS$NL-oil" ;;
       # !! TODO(pts): Copy more flag translations from owcc.c.
       -c) ;;
       -S) echo "fatal: assembly generation not supported by minicc wcc386" >&2; exit 5 ;;
       -E) WARGS="$WARGS$NL-pl" ;;
       -momf) WISOMF=1 ;;  # minicc-specific. Generate the object file in OMF format (OpenWatcom native) rather than ELF-32.
       -[DUI]?*) WARGS="$WARGS$NL$ARG" ;;
       -g*) echo "fatal: debug generation not supported by minicc wcc386" >&2; exit 5 ;;
       -include) SKIPARG="$ARG" ;;
       -*) echo "fatal: unsupported minicc wcc386 flag (try it with --gcc?): $ARG" >&2; exit 5 ;;
       *) echo "fatal: assert: input file not allowed: $ARG" >&2; exit 5 ;;
      esac
    done
    test "$HAD_NOINLINE" && WARGS="$WARGS$NL-oe0"
    CCARGS="$GCC$NL$WSFLAG$NL$WJFLAG$NL$WEIFLAG$NL$WFFLAG$NL$WAFLAG$NL$WAUTOSYMFLAG$NL$WECFLAG$NL$WARGS"; WARGS=
    # TODO(pts): Add -m... flag for string optimizations (like in minilibc32).
  elif test "$IS_CC1"; then  # If $IS_CC1, convert $CCARGS for GCC cc1.
    SKIPARG=
    CC1ARGS=
    if test "$IS_CC1" = 3; then  # PCC (https://en.wikipedia.org/wiki/Portable_C_Compiler)
      CC1ARGS=-S  # PCC.
      test "$HAD_V" && CC1ARGS="$CC1ARGS$NL-v"
    else
      CC1ARGS=-quiet  # Some gcc(1) frontends add -Wformat-security, we don't.
      test "$HAD_V" && CC1ARGS="$CC1ARGS$NL-v$NL-version"
    fi
    for ARG in --skiparg $CCARGS; do  # !! TODO(pts): Check that -S and -E work.
      if test "$SKIPARG"; then
        test "$SKIPARG" = -include && CC1ARGS="$CC1ARGS$NL$ARG"
        SKIPARG=; continue
      fi
      case "$ARG" in
       *"$NL"*) echo "fatal: unexpected newline in minicc wcc386 argument" >&2; exit 5 ;;
       "") echo "fatal: empty minicc wcc386 argument" >&2; exit 5 ;;
       --skiparg) SKIPARG=1 ;;
       -B?*) ;;  # Just to be sure. minicc doesn't add it for wcc386.
       -v) ;;  # Already processed as $HAD_V above.
       -[csS] | -static | -nostdlib) ;;
       -include) SKIPARG="$ARG" && CC1ARGS="$CC1ARGS$NL$ARG" ;;
       -*) CC1ARGS="$CC1ARGS$NL$ARG" ;;
       *) echo "fatal: assert: input file not allowed: $ARG" >&2; exit 5 ;;
      esac
    done
    CCARGS="$GCC$NL$CC1ARGS"; CC1ARGS=
  fi

  if test "$IS_WATCOM" && test "$WISOMF" && test "$CCMODE" != -c; then  # Checking $CCMODE should be enough.
    echo "fatal: -momf needs -c" >&2; exit 5
  fi

  # Now create all the temporary .o files which will be written to $GCC or $TCC.
  TMPOFILES=
  CCFILEARGS=
  if test "$IS_WATCOM"; then TMPCCOUTEXT=obj
  elif test "$IS_CC1"; then TMPCCOUTEXT=s
  else TMPCCOUTEXT=o
  fi
  NEED_OCONV=
  if test "$DO_LINK" || test "$CCMODE" = -c; then
    if test "$IS_WATCOM" && test -z "$WISOMF"; then NEED_OCONV=1
    elif test "$IS_CC1"; then NEED_OCONV=1
    fi
  fi
  for ARG in $FILEARGS; do
    case "$ARG" in
     --srcfile=?*)
      SRCTMPCCOUTEXT="$TMPCCOUTEXT"
      if test "$IS_WATCOM"; then case "$ARG" in *.S) SRCTMPCCOUTEXT=s ;; esac; fi
      if test "$DO_LINK"; then
        TMPOFILE="$("$MYDIR"/tools/mktmpf "$TMPDIR"/minicc.@@@@@@."$SRCTMPCCOUTEXT")"  # Already creates the file.
        if test -z "$TMPOFILE"; then
          echo "fatal: error creating temporary .$SRCTMPCCOUTEXT file: $TMPOFILE" >&2; rm -f $TMPOFILES; exit 7
        fi
        TMPOFILES="$TMPOFILES$NL$TMPOFILE"
        if test "$SRCTMPCCOUTEXT" != o; then  # With $DO_LINK, this test is equivalent to "$NEED_OCONV".
          if ! : >"${TMPOFILE%.*}.o"; then
            echo "fatal: error creating temporary .o file: ${TMPOFILE%.*}.o" >&2; rm -f $TMPOFILES; exit 7
          fi
          TMPOFILES="$TMPOFILES$NL${TMPOFILE%.*}.o"
        fi
        LDARGS="$LDARGS$NL${TMPOFILE%.*}.o"
      else
        TMPOFILE="${ARG#--*=}"
        if test "$CCMODE" = -c; then
          if test "$NEED_OCONV"; then
            TMPOFILE="$("$MYDIR"/tools/mktmpf "$TMPDIR"/minicc.@@@@@@."$SRCTMPCCOUTEXT")"  # Already creates the file.
            if test -z "$TMPOFILE"; then
              echo "fatal: error creating temporary .o file" >&2; rm -f $TMPOFILES; exit 7
            fi
            TMPOFILES="$TMPOFILES$NL$TMPOFILE"
          elif test "$OUTFILE"; then
            TMPOFILE="$OUTFILE"
          else
            TMPOFILE="${TMPOFILE%.*}"."$SRCTMPCCOUTEXT"; TMPOFILE="${TMPOFILE##*/}"  # GCC also strips the dirname.
          fi
        elif test "$CCMODE" = -S; then
          if test "$OUTFILE"; then TMPOFILE="$OUTFILE"
          else TMPOFILE="${TMPOFILE%.*}".s; TMPOFILE="${TMPOFILE##*/}"  # GCC also strips the dirname.
          fi
        else
          if test "$OUTFILE"; then TMPOFILE="$OUTFILE"
          else TMPOFILE=-  # For -E.
          fi
        fi
        test "$TMPOFILE" != - && test "${TMPOFILE#-}" != "$TMPOFILE" && TMPOFILE="./$TMPOFILE"  # Make it not a command-line flag (-...).
      fi
      CCFILEARGS="$CCFILEARGS$NL--tmpofile=$TMPOFILE$NL--srcfile=${ARG#--*=}"
      ;;
     --ldfile=?*) LDARGS="$LDARGS$NL${ARG#--*=}" ;;
     *) echo "fatal: assert: bad filearg: $ARG" >&2; exit 7 ;;
    esac
  done
  # echo "CCARGS: $CCARGS" >&2; echo "LDARGS: $LDARGS" >&2; echo "FILEARGS: $FILEARGS" >&2; echo "CCFILEARGS:$CCFILEARGS" >&2; rm -f $TMPOFILES; exit 7

  # Now run `CC -c -o ... ...' for each file in $CCFILEARGS.
  TMPOFILE=
  for ARG in $CCFILEARGS; do
    case "$ARG" in
     --tmpofile=?*)
      if test "$TMPOFILE"; then
        echo "fatal: assert: duplicate --tmpofile=..." >&2; rm -f $TMPOFILES; exit 7;
      fi
      TMPOFILE="${ARG#--*=}"
      ;;
     --srcfile=?*)
      if test -z "$TMPOFILE"; then
        echo "fatal: assert: missing --tmpofile=..." >&2; rm -f $TMPOFILES; exit 7;
      fi
      OFLAG=
      ARG="${ARG#--*=}"
      if test "$CCMODE" = -E; then
        case "$ARG" in
         *.s) TMPOFILE=; continue ;;  # Skip the source .s file silently, GCC also does it.
         *.[cS]) ;;
         *) echo "fatal: unsupported source file type for -E: $ARG" >&2; exit 7 ;;
        esac
      fi
      if test "$TMPOFILE" = -; then
        case "$ARG" in *.[cS]) ;; *) echo "fatal: unsupported source file type for stdout: $ARG" >&2; exit 7 ;; esac
        test "$HAD_V" && echo "info: running compiler:" $CCARGS "${ARG#--*=}" >&2  # GCC also writes to stderr.
        $CCARGS "${ARG#--*=}"; EC="$?"
      else
        CCFARGS=
        CCTHISARGS="$CCARGS"
        SFILE=
        case "$ARG" in
         *.s | *.nasm) SFILE="$ARG"; CCTHISARGS= ;;  # TODO(pts): Don't create empty $TMPOFILE (with .s extension), we don't use it.
         *.[cS])
          case "$ARG" in
           *.c)
            test "$IS_CC1" && SFILE="$TMPOFILE" ;;
           *.S)
            SFILE="$TMPOFILE"
            if test "$CCMODE" = -E; then SEARG=
            elif test "$IS_WATCOM"; then SEARG=-pl
            elif test "$IS_CC1"; then SEARG=-E
            else SEARG=/
            fi
            if test "$SEARG" != /; then  # Regular GCC and Clang can process .s files directly, no need to change.
              CCTHISARGS="${CCTHISARGS#*$NL}"  # Remove $GCC from the beginning.
              CCTHISARGS="$SEARG$NL-D__ASSEMBLER__$NL$CCTHISARGS"
              CCTHISARGS="$GCC$NL$CCTHISARGS"
            fi
            ;;
          esac
          if test "$IS_WATCOM"; then
            if test "$CCMODE" = -E; then
              EXT="${OUTFILE##*/}"
              case "$EXT" in
               *.*) ;;
               *) echo "fatal: --wcc -E -o <file> needs a <file> with an .<extension>" >&2; exit 7  # Otherwise wcc386 appends `.i'.
               ;;
              esac
            fi
            if test "${TMPOFILE#.}" != "$TMPOFILE"; then
              # Otherwise wcc386 would prepend a basename of the source file.
              echo "fatal: object filename for minicc wcc386 must not start with a dot: $TMPOFILE" >&2; rm -f $TMPOFILES; exit 7;
            fi
            CCFARGS="-fo=$TMPOFILE$NL$ARG"
          elif test "$IS_CC1"; then
            if test "$IS_CC1" = 3; then  # PCC.
              CCFARGS="-o$NL$TMPOFILE$NL$ARG"
            else
              CCFARGS="-dumpbase$NL$ARG$NL-auxbase-strip$NL${ARG%.*}.o$NL-o$NL$TMPOFILE$NL$ARG"
            fi
          else
            CCFARGS="-o$NL$TMPOFILE$NL$ARG"
          fi
          ;;
         *) echo "fatal: assert: unknown source file type: $ARG" >&2; exit 7 ;;
        esac
        if test "$CCTHISARGS"; then
          test "$HAD_V" && echo "info: running compiler:" $CCTHISARGS $CCFARGS >&2  # GCC also writes to stderr.
          $CCTHISARGS $CCFARGS; EC="$?"
        else
          EC=0
        fi
      fi
      if test "$EC" != 0; then  # The compiler has failed.
        if test "$TMPOFILE" = -; then
          rm -f $TMPOFILES
        else
          rm -f $TMPOFILES "$TMPOFILE"  # In case the compiler has created a partial, corrupt output file ($TMPOFILE).
        fi
        exit "$EC"
      fi
      if test "$NEED_OCONV" || test "$SFILE"; then
        if test "$CCMODE" = -c; then
          if test "$OUTFILE"; then TMPOFILE2="$OUTFILE"
          else TMPOFILE2="$ARG"; TMPOFILE2="${TMPOFILE2%.*}.o"; TMPOFILE2="${TMPOFILE2##*/}"
          fi
        else
          TMPOFILE2="${TMPOFILE%.*}.o"
        fi
        if test "$IS_WATCOM" && test "${ARG%.c}" != "$ARG"; then
          EFARGS="$MYDIR/tools/omf2elf$NL-h$NL$WOSSFLAG$NL$HAD_V$NL-o$NL$TMPOFILE2$NL$TMPOFILE"
          test "$HAD_V" && echo "info: running OMF converter:" $EFARGS >&2
        else  # "$IS_CC1" or $SFILE.
          if test "$DO_SFIX"; then  # Replace `rep ret' (https://gcc.gnu.org/legacy-ml/gcc-help/2011-03/msg00286.html) with `.byte 0xf3, 0xc3', for compatibility with GNU as(2) 2.22.
            test "$HAD_V" && echo "info: fixing rep ret in: $SFILE" >&2
            awk '{if(/^[ \t]*rep[ \t]+ret[ \t]*$/){print".byte 0xf3, 0xc3"}else{print}}' <"$SFILE" >"$TMPOFILE2.fix.s"; EC="$?"
            if test "$EC" != 0; then rm -f $TMPOFILES "$TMPOFILE2.fix.s"; exit "$EC"; fi
            SFILE="$TMPOFILE2.fix.s"
          fi
          case "$SFILE" in
           *.nasm)
            # TODO(pts): Specify separate optimization flags for NASM.
            EFARGS="$MYDIR/tools/nasm-0.98.39$NL-O999999999$NL-w+orphan-labels$NL-f${NL}elf$NL$NASM_DEF_ARG$NL$DEF_ARG$NL-D__CPU__=${ARCH#i}$NL-o$NL$TMPOFILE2$NL$SFILE"
            test "$HAD_V" && echo "info: running nasm assembler:" $EFARGS >&2 ;;
           *.s)
            # GNU as(1) also accepts a `-I...' flag, but we don't need it
            # here, because this .s source file was generated by GCC, which
            # doesn't generate includes.
            EFARGS="$MYDIR/tools/as$NL$HAD_V$NL--32$NL-march=$ARCH+387$NL-o$NL$TMPOFILE2$NL$SFILE"
            test "$HAD_V" && echo "info: running GNU assembler:" $EFARGS >&2 ;;
           *) echo "fatal: assert: unknown assembly file type: $SFILE" >&2; exit 7 ;;
          esac
        fi
        $EFARGS; EC="$?"
        if test "$EC" != 0; then rm -f $TMPOFILES "$TMPOFILE2" "$TMPOFILE2.fix.s"; exit "$EC"; fi
        test "$DO_SFIX" && rm -f "$TMPOFILE2.fix.s"
        TMPOFILE="$TMPOFILE2"  # For elfnostack below.
      fi
      if test "$DO_LINK" && test -z "$TCC" && test -z "$IS_WATCOM"; then
        # GCC adds the .note.GNU-stack ELF section header to the .o file, adding
        # 0x20 bytes unnecessary. We remove it, so ld(1) won't generate the
        # PT_GNU_STACK program header in the executable. To get it, specify
        # -Wl,-z,execstack or -Wl,-z,noexecstack.
        #
        # !! TODO(pts): Also remove from .o files explicitly specified, they
        #    may have been created by a previous `minicc -c'.
        test "$HAD_V" && echo "info: removing .note.GNU-stack from: $TMPOFILE" >&2
        "$MYDIR/tools/elfnostack" "$TMPOFILE"; EC="$?"
        if test "$EC" != 0; then rm -f $TMPOFILES; exit "$EC"; fi
      fi
      TMPOFILE=
      ;;
     *) echo "fatal: assert: bad ccfilearg: $ARG" >&2; rm -f $TMPOFILES; exit 7 ;;
    esac
  done
  if test "$TMPOFILE"; then
    echo "fatal: assert: unused --tmpofile=..." >&2; rm -f $TMPOFILES; exit 7;
  fi
  if test -z "$DO_LINK"; then
    rm -f $TMPOFILES; exit
  fi
  ARGS="$LDARGS"
  WHAT=linker
  unset LDARGS CCARGS CCTHISARGS CCFILEARGS FILEARGS TMPOFILE TMPOFILE2 FOFLAG CCMODE TMPCCOUTEXT
  # Don't forget: rm -f $TMPOFILES
else
  TMPOFILES=
  WHAT=compiler
fi

if test "$DO_SMART" != 0; then  # Smart linking.
  LIBMINITCC1=
  test "$NEED_LIBMINITCC1" && LIBMINITCC1="$MYDIR/helper_lib/libminitcc1.a"
  test "$HAD_V" && echo "info: running $WHAT:" $ARGS >&2  # GCC also writes to stderr.
  $ARGS $LIBMINITCC1 2>"$OUTFILE.err"; EC="$?"  # TODO(pts): Write a C program to extract undefined references and display errors in a streaming way. (Some errors like `In ...' need to be buffered.)
  if test "$EC" = 0 && test "$DO_SMART" != 2; then
    cat "$OUTFILE.err" >&2
    if test "$STRIP_MODE" != 0; then rm -f "$OUTFILE.err"
    else rm -f "$OUTFILE.err" $TMPOFILES
    fi
  else
    # The regexps below work for built-in ld of $TCC, ld of $GCC, ld of $GCC (Binutils), gold of $GCC (Binutils). TODO(pts): Make it work with lld (Clang).
    # Examples for GNU ld(1) and GNU gold(1):
    # : warning: cannot find entry symbol '_start'
    # : warning: cannot find entry symbol _start; defaulting to 0000000008048074
    # : warning: entry symbol '_start' exists but is not defined
    UNDEFSYMS="$(awk '{if((((/: undefined reference to [`'\''].+'\''$/&&sub(/^.*?: undefined reference to [`'\'']/, "")||sub(/^tcc: error: undefined symbol '\''/,""))&&sub(/'\''$/,""))||(/: warning: /&&sub(/^.*: warning: (cannot find )?entry symbol '\''?/,"")&&sub(/['\'';].*/,"")&&!/ /))&&!h[$0]){h[$0]=1;printf"%s%s",c,$0;c=","}}' <"$OUTFILE.err")"
    if test -z "$UNDEFSYMS" && test "$EC" != 0; then  # We can read this only if $EC != 0 (i.e. linker failure).
      cat "$OUTFILE.err" >&2
      rm -f "$OUTFILE.err" $TMPOFILES
      exit "$EC"  # No undefined symbols found, this means there is another reason for the $TCC failure.
    fi
    rm -f "$OUTFILE.err" "$OUTFILE.smart.o"  # !! Generate temporary filename.
    if test "$DO_MAIN_AUTO" = 1; then
      case ",$UNDEFSYMS," in ,_start*,)  # Search for cstart_ and _argc manually in the specified .o files.
        SKIPARG=
        for ARG in --skiparg $ARGS; do
          if test "$SKIPARG"; then SKIPARG=; continue; fi
          case "$ARG" in
           --skiparg | -[zmeo]) SKIPARG=1 ;;
           -*) ;;
           *.o)
            if grep -q main 2>/dev/null <"$ARG" && grep -q cstart_ 2>/dev/null <"$ARG" && ! grep -q _argc 2>/dev/null <"$ARG"; then  # !! Write a tool to properly check for undefined symbols.
              DEF_ARG="$DEF_ARG$NL-DCONFIG_MAIN_NO_ARGC_ARGV_ENVP"; break  # smart.nasm recognizes it.
            fi
            ;;
          esac
        done
      esac
    else
      if test "$DO_ARGC" = 0; then DEF_ARG="$DEF_ARG$NL-DCONFIG_MAIN_NO_ARGC_ARGV_ENVP"
      elif test "$DO_ARGV" = 0; then DEF_ARG="$DEF_ARG$NL-DCONFIG_MAIN_NO_ARGV_ENVP"
      elif test "$DO_ENVP" = 0; then DEF_ARG="$DEF_ARG$NL-DCONFIG_MAIN_NO_ENVP"
      fi
    fi
    NASMCMD="$MYDIR/tools/nasm-0.98.39$NL-O0$NL-w+orphan-labels$NL-f${NL}elf$NL-DUNDEFSYMS=$UNDEFSYMS$NL$NASM_DEf_ARG$NL$DEF_ARG$NL$DEF_CMDARG$NL-o$NL$OUTFILE.smart.o$NL$MYDIR/libc/$LIBC/smart.nasm"; EC="$?"
    test "$HAD_V" && echo "info: running smart nasm:" $NASMCMD >&2
    $NASMCMD; EC="$?"
    if test "$EC" = 0 && test -f "$OUTFILE.smart.o"; then :; else
      rm -f "$OUTFILE.smart.o" $TMPOFILES
      test "$EC" = 0 && EC=1
      exit "$EC"
    fi
    # /usr/bin/objdump -d "$OUTFILE.smart.o"
    # /usr/bin/nm "$OUTFILE.smart.o" | grep -v ' [dtbr] '
    ARGS="$ARGS$NL$OUTFILE.smart.o$NL$LIBFN$NL$LIBMINITCC1"
    test "$HAD_V" && echo "info: running $WHAT again:" $ARGS >&2  # GCC also writes to stderr.
    $ARGS >&2; EC="$?"  # Redirect linker stdout to stderr.
    if test "$STRIP_MODE" != 0 && test "$EC" = 0; then :
    else rm -f "$OUTFILE.smart.o" $TMPOFILES
    fi
    test "$EC" = 0 || exit "$EC"
  fi
else
  test "$HAD_V" && echo "info: running $WHAT:" $ARGS >&2  # GCC also writes to stderr.
  $ARGS >&2; EC="$?"  # Redirect linker stdout to stderr.
  if test "$STRIP_MODE" = 0 || test "$EC" != 0; then
    test "$TMPOFILES" && rm -f $TMPOFILES
  fi
  test "$EC" = 0 || exit "$EC"
fi

if test "$OS" = any; then EXFL_FLAG=-ls  # Change ELF OSABI to SYSV.
else EXFL_FLAG=-l  # Change ELF OSABI to Linux.
fi

if test "$STRIP_MODE" = 0; then
  :
elif test "$IS_AOUT"; then
  test "$TMPOFILES" && rm -f $TMPOFILES
elif test "$STRIP_MODE" = 1; then
  EFARGS="$MYDIR/tools/elfxfix$NL$EXFL_FLAG$NL-a$NL$HAD_V$NL--$NL$OUTFILE"
  $EFARGS; EC="$?"
  test "$HAD_V" && echo "info: fixing ELF executable:" $EFARGS >&2
  test "$TMPOFILES" && rm -f $TMPOFILES
  test "$EC" = 0 || exit "$EC"
else  # 2 or 3.
  ELFXFIX_SFLAG="$SFLAG"
  FIX_O_FN=
  if ! test "$IS_TCCLD"; then
    FIX_O_FN="$("$MYDIR"/tools/mktmpf "$TMPDIR"/elfxfix.@@@@@@.o)"  # Already creates the file.
    if test -z "$FIX_O_FN"; then
      echo "fatal: error creating temporary .o file" >&2; exit 7
    fi
  fi
  PARGS=
  test "$FIX_O_FN" && PARGS="-p$NL$FIX_O_FN"
  EFARGS="$MYDIR/tools/elfxfix$NL$EXFL_FLAG$NL-a$NL$ELFXFIX_SFLAG$NL$PARGS$NL$HAD_V$NL--$NL$OUTFILE"
  test "$HAD_V" && echo "info: running extra strip:" $EFARGS >&2
  if test "$FIX_O_FN"; then
    $EFARGS; EC="$?"
    if test "$EC" != 0; then
      rm -f -- "$FIX_O_FN"
      test "$DO_SMART" != 0 && rm -f "$OUTFILE.smart.o"
      exit "$EC"
    fi
    if test -s "$FIX_O_FN"; then  # elfxfix has written to it.
      ARGS="$ARGS$NL$FIX_O_FN"  # Make .bss larger by the size recommended by tools/elfxfix.
      test "$HAD_V" && echo "info: running linker after elfxfix:" $ARGS >&2
      $ARGS; EC="$?"
      if test "$EC" = 0; then
        PARGS="-r$NL$FIX_O_FN"
        EFARGS="$MYDIR/tools/elfxfix$NL$EXFL_FLAG$NL-a$NL$ELFXFIX_SFLAG$NL$PARGS$NL$HAD_V$NL--$NL$OUTFILE"
        test "$HAD_V" && echo "info: running extra strip again:" $EFARGS >&2
        $EFARGS; EC="$?"
      fi
    fi
    rm -f -- "$FIX_O_FN" $TMPOFILES
  else
    $EFARGS; EC="$?"
    test "$TMPOFILES" && rm -f $TMPOFILES
  fi
  test "$DO_SMART" != 0 && rm -f "$OUTFILE.smart.o"
  test "$EC" = 0 || exit "$EC"
fi
