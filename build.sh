#!/bin/bash
# Builds pda (release: -O3) and the tests (-O1 with every check on) into
# build/ (or $1).
#   ./build.sh            -> build/pda, build/tests/*
#   FPC="fpc -Pi386" ./build.sh build32
# pda --version shows the commit from PDA_COMMIT, taken from git when it is
# not set (a build outside git says "commit:" and nothing).
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
export PDA_COMMIT=${PDA_COMMIT:-$(git -C "$HERE" describe --always --dirty --abbrev=7 2> /dev/null || true)}
OUT=${1:-build}
FPC=${FPC:-fpc}
# FPC gets paths relative to the repository: on Windows (Git Bash) an
# absolute /d/a/... path would reach it mangled. OUT is relative to it too.
cd "$HERE"
HERE=.
case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) EXE=.exe ;; *) EXE= ;; esac
mkdir -p "$OUT/rel" "$OUT/tests/u"
# -B: the program is rebuilt every time, so that it takes the commit and the date
$FPC -B -O3 -dPDA_FAST -Fu"$HERE/pas" -FU"$OUT/rel" -o"$OUT/pda$EXE" "$HERE/pas/pda.pas" > "$OUT/fpc.log" 2>&1 \
  || { cat "$OUT/fpc.log"; exit 1; }
cp "$OUT/fpc.log" "$OUT/fpc-pda.log"
for t in test_blake3 test_format; do
  $FPC -O1 -Fu"$HERE/pas" -Fi"$HERE/pas" -FU"$OUT/tests/u" -o"$OUT/tests/$t$EXE" "$HERE/pas/tests/$t.pas" > "$OUT/fpc.log" 2>&1 \
    || { cat "$OUT/fpc.log"; exit 1; }
done
echo "built $OUT/pda and $OUT/tests"
