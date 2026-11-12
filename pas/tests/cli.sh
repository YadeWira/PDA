#!/bin/bash
# The command line: exit codes, naming, refusals, --json, t, list, info,
# selftest, report, -n, --clean-temps. Exit 1 at the first failure.
set -u
HERE=$(cd "$(dirname "$0")/../.." && pwd)
PDA=${PDA:-$HERE/build/pda}
W=$(mktemp -d)
trap 'rm -rf "$W"' EXIT
cd "$W"
n=0
ok()   { n=$((n + 1)); echo "ok   $1"; }
fail() { echo "FAIL $1"; exit 1; }
rc()   { "$@" > out.txt 2> err.txt; echo $?; }
expect() { local want=$1 what=$2; shift 2; local got; got=$(rc "$@"); [ "$got" = "$want" ] && ok "$what (exit $want)" || { cat err.txt; fail "$what: exit $got, want $want"; }; }

cp "$HERE/tests/doc/minimal.pdf" a.pdf
cp "$HERE/tests/doc/minimal.docx" b.docx
: > c.bin

expect 0 "a two files"             "$PDA" a a.pdf b.docx
[ -f a.pdf.pda ] && [ -f b.docx.pda ] && ok "outputs named FILE.pda" || fail "outputs"
expect 1 "a refuses an existing output" "$PDA" a a.pdf
expect 0 "a -f replaces it"        "$PDA" a -f a.pdf
expect 0 "a takes an empty file"    "$PDA" a c.bin
expect 2 "unknown command"         "$PDA" zz a.pdf
expect 2 "unknown option"          "$PDA" a --zz a.pdf
expect 2 "--cpu=avx2 refused"      "$PDA" a --cpu=avx2 a.pdf
expect 0 "t"                       "$PDA" t a.pdf.pda b.docx.pda
expect 0 "list"                    "$PDA" list a.pdf.pda
expect 0 "info on a document and .pda"    "$PDA" info a.pdf a.pdf.pda
expect 0 "x -o"                    "$PDA" x a.pdf.pda -o back.pdf
cmp -s a.pdf back.pdf && ok "x gives the original" || fail "x output differs"
expect 1 "x refuses an existing output" "$PDA" x a.pdf.pda -o back.pdf
head -c 300 a.pdf.pda > bad.pda
expect 1 "x of a truncated .pda"   "$PDA" x bad.pda -o bad.pdf
[ ! -e bad.pdf ] && ok "nothing written for it" || fail "bad.pdf written"
expect 1 "t of a truncated .pda"   "$PDA" t bad.pda
"$PDA" t --json a.pdf.pda b.docx.pda > j.txt && python3 -c 'import json,sys; [json.loads(l) for l in open("j.txt")]' \
  && ok "--json lines parse" || fail "--json"
expect 0 "-n writes nothing"       "$PDA" a -n -o dry.pda a.pdf
[ ! -e dry.pda ] && ok "no dry.pda" || fail "dry run wrote"
expect 0 "selftest"                "$PDA" selftest
expect 0 "report without a file"   "$PDA" report
expect 2 "report --with-file without a file" "$PDA" report --with-file
touch .pda-tmp-99999-1
python3 -c 'import os,time; t=time.time()-7200; os.utime(".pda-tmp-99999-1",(t,t))'
expect 0 "--clean-temps"           "$PDA" a -f --clean-temps a.pdf
[ ! -e .pda-tmp-99999-1 ] && ok "old temporary deleted" || fail "temporary left"
expect 0 "--version"               "$PDA" --version
echo "$n checks passed"
