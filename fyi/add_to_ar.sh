#! /bin/sh --
# by pts@fazekas.hu at Sat Jun 10 23:07:09 CEST 2023

set -ex
AFILE="$1"; shift
test "${AFILE%.a}" != "$AFILE"
test $# != 0

for F in "$@"; do  # Strip the .o file.
  ALL_SECTIONS="$(objdump -hw "$F" | busybox awk '$3~/^[0-9a-fA-F]+$/{print$2}')"
  if test -z "$ALL_SECTIONS"; then
    if test "$(objdump -t "$F" | grep '[*]COM[*]')"; then  # Found a common symbol.
      strip -S -x "$F" ||:  # harmless: strip: error: the input file 'h_errno.o' has no sections
    else
      rm -f "$F"
    fi
    continue
  fi
  HAS_GLOBALBEG="$(objdump -t "$F" | grep '^00000000  *g  *[.]text[     ]' ||:)"
  test "$HAS_GLOBALBEG" && HAS_GLOBALBEG=.text
  EMPTY_SECTIONS="$(objdump -hw "$F" | busybox awk '$3~/^0+$/&&$2!='"\"$HAS_GLOBALBEG\""'{print"-R "$2}')"
  strip -S -x -R .note.GNU-stack -R .comment -R .eh_frame $EMPTY_SECTIONS "$F"
  ALL_SECTIONS="$(objdump -hw "$F" | busybox awk '$3~/^[0-9a-fA-F]+$/{print$2}')"
  if test -z "$ALL_SECTIONS" && test -z "$(objdump -t "$F" | grep '[*]COM[*]')" && test -z "$HAS_GLOBALBEG"; then
    rm -f "$F"
  fi
done

rm -rf "$AFILE.tmp"
mkdir "$AFILE.tmp"
(cd "$AFILE.tmp" && ar x ../"${AFILE##*/}" && ls) || exit "$?"
cp -t "$AFILE.tmp" -- "$@"
(cd "$AFILE.tmp" && ar crs -- ../"${AFILE##*/}.crtmp" *) || exit "$?"
mv "$AFILE.crtmp" "$AFILE"
rm -rf "$AFILE.tmp"

: "$0" OK.
