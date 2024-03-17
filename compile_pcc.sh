#! /bin/sh --
# by pts@fazekas.hu at Sun Mar 17 18:30:49 CET 2024

set -ex

test "${0%/*}" = "$0" || cd "${0%/*}"

../pts-pcc/compile.sh "$PWD"/pathbin/minicc --gcc=4.8 -Wadd=shadow -march=i686 -ansi -pedantic -Wno-long-long -Wno-format -DCONFIG_NO_FERROR -DCONFIG_SIGNAL_BSD -DCONFIG_STAT64 -DCONFIG_MALLOC_FROM_STDLIB_H
upx.pts --brute --no-lzma -f -o tools/pts-pcc ../pts-pcc/pccbin/pcc

: "$0" OK.
