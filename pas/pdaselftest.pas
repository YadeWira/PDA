{ Ported from POA's pas/poaselftest.pas (itself from PJA by way of PMPA).

  pda selftest (doc/CLI.md): the samples inside the binary
  (pdaselftest.inc, written by tools/gen_selftest.py from tests/doc: a
  small PDF, DOCX and RTF) compressed and extracted. Each .pda has to be the very
  bytes the include names (its size and BLAKE3-128), and each has to come
  back as its sample. The format is frozen within a version: those bytes
  do not change with the platform, the compiler's optimisation or the
  threads. PDA has one path (plain), so --cpu=plain changes nothing. }
unit pdaselftest;

{$I pda.inc}
{$ifopt R-}{$fatal pdaselftest: range checks ($R+) are mandatory}{$endif}
{$ifopt Q-}{$fatal pdaselftest: overflow checks ($Q+) are mandatory}{$endif}

interface

uses pdasysinfo;

{ Prints a line per sample and a summary (only failures and the summary
  with quiet). 0 when every check passed, 1 if not. }
function RunSelftest(quiet: Boolean; onePath: Boolean = False; only: TCpuPath = cpPlain): Integer;

implementation

uses SysUtils, pdablake3, pdapack, pdainfo;

{$I pdaselftest.inc}

function SameBytes(const a, b: TBytes): Boolean;
begin
  Result := (Length(a) = Length(b)) and ((Length(a) = 0) or CompareMem(@a[0], @b[0], Length(a)));
end;

function RunSelftest(quiet: Boolean; onePath: Boolean; only: TCpuPath): Integer;
var k, checks, failed: Integer; data, got, back: TBytes; r: TPackResult; h: THash16; why, hex: string;
begin
  checks := 0; failed := 0;
  if not quiet then
    Writeln('pda selftest: ', SELFTEST_COUNT, ' samples inside the binary, on the path ',
            CPU_PATH_NAMES[only], ' (the only one PDA has)');
  for k := 0 to SELFTEST_COUNT - 1 do begin
    SelftestSample(k, data, h);
    hex := HexBytes(h);
    Inc(checks);
    why := '';
    try
      r := Pack(data, got, True);
      if not r.Ok then why := 'compress failed: ' + r.Text
      else if (Length(got) <> SELFTEST_PDA_SIZE[k]) or (HexBytes(Blake3_128(got)) <> hex) then
        why := 'a different .pda: ' + IntToStr(Length(got)) + ' B, blake3-128 ' + HexBytes(Blake3_128(got)) +
               ' (expected ' + IntToStr(SELFTEST_PDA_SIZE[k]) + ' B, ' + hex + ')';
      if why = '' then begin
        r := Unpack(got, QWord(Length(data)), back, h);
        if not r.Ok then why := 'extract failed: ' + r.Text
        else if not SameBytes(back, data) then why := 'extracted to other bytes';
      end;
    except
      on e: Exception do why := 'internal error: ' + e.ClassName + ': ' + e.Message;
    end;
    if why <> '' then begin
      Inc(failed);
      Writeln(StdErr, 'pda: selftest: ', SELFTEST_NAMES[k], ': ', why);
    end else if not quiet then
      Writeln('  ', SELFTEST_NAMES[k], ': ', Length(data), ' B -> ', Length(got), ' B, .pda blake3-128 ', hex,
              ': ok');
  end;
  if failed = 0 then begin
    Writeln('selftest: ', checks, ' of ', checks, ' checks passed on 1 path(s) (', CPU_PATH_NAMES[only],
            '): every .pda the expected bytes, every sample back');
    Result := 0;
  end else begin
    Writeln(StdErr, 'pda: selftest: ', failed, ' of ', checks, ' checks FAILED. This is a bug in PDA: please run',
            ' pda report and open an issue at ', ISSUES_URL);
    Result := 1;
  end;
end;

end.
