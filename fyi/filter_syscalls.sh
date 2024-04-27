#! /bin/sh --
#
# filter_syscalls.sh: removes all .o files from an .a library which do syscalls
# by pts@fazekas.hu at Sun Apr 28 00:46:32 CEST 2024
#
#

set -ex

afile="$1"
test "$afile" || afile="${0%/*}"/../libc/minilibc/libc.i386.a
tmp=filter_syscalls.tmp
rm -rf -- "$tmp"
mkdir -- "$tmp"
test "${afile#/}" != "$afile" || afile="$PWD/$afile"
(cd "$tmp" && ar x "$afile") || exit "$?"
for ofile in "$tmp"/*.o; do
  obase="${ofile##*/}"
  if test "${obase#strerror}" != "$obase" ||
     test "${obase#sig*_linux}" != "$obase" ||
     ! objdump -d -- "$ofile" | awk '/:[ \t]+cd 80[ \t]+/{exit 4}' ||
     ! objdump -t -- "$ofile" | awk '/ [*]UND[*][ \t]+0+[ \t]+(mini_)?(syscall|__M_jmp_syscall|__M_jmp_mov_syscall|malloc_mmap|execve|ioctl)/||/[.]text[ \t]+0+[ \t]+(mini_)?(_start|_exit)$/{exit 4}'; then
    rm -f -- "$ofile"
  else
    "${0%/*}"/strip_elf_o.sh "$ofile"
  fi
done
ar="${0%/*}"/../tools/tiny_libmaker
test "${ar#/}" != "$ar" || ar="$PWD/$ar"
(cd "$tmp" && "$ar" crs ../filtered.a *.o)
rm -rf -- "$tmp"

: "$0" OK.
