#!/bin/sh
# What CI runs on every platform: build (FPC from $FPC), the unit tests,
# the command line's checks, the selftest, the round trip of every sample,
# and hash.txt: the SHA-256 of every sample's .pda, which must be the same
# everywhere. (Adapted from POA's .github/test.sh; libpda comes later.)
set -eu
HERE=$(cd "$(dirname "$0")/.." && pwd)
cd "$HERE"
./build.sh build/ci
OUT=$HERE/build/ci
T=$OUT/tests
"$T/test_blake3" pas/tests/kat.txt | tail -1
"$T/test_format" | tail -1
PDA=$OUT/pda pas/tests/cli.sh | tail -1
"$OUT/pda" selftest | tail -1
# the round trip of every sample, and the .pda of each, hashed
D=$OUT/pdas
rm -rf "$D"; mkdir -p "$D/x"
for f in tests/doc/*; do
  n=$(basename "$f")
  "$OUT/pda" a -q --no-sync "$f" -o "$D/$n.pda"
  "$OUT/pda" x -q --no-sync "$D/$n.pda" -o "$D/x/$n"
  cmp -s "$f" "$D/x/$n" || { echo "FAIL: $n does not come back"; exit 1; }
done
echo "every sample back"
python3 -c '
import hashlib, os, sys
d = sys.argv[1]
for n in sorted(os.listdir(d)):
    p = os.path.join(d, n)
    if os.path.isfile(p):
        print(hashlib.sha256(open(p, "rb").read()).hexdigest(), n)
' "$D" > hash.txt
echo "hash.txt: $(wc -l < hash.txt) streams"
