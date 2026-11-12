{ The .pda container (pdaformat) and the checks around it (pdapack):
  round trips of edge-case inputs, and every kind of damage refused. }
program test_format;

{$I pda.inc}

uses SysUtils, pdablake3, pdaformat, pdapack, pdalimits;

var failures: Integer = 0;

procedure Check(ok: Boolean; const what: string);
begin
  if not ok then begin Inc(failures); Writeln('FAIL: ', what); end;
end;

function Same(const a, b: TBytes): Boolean;
begin
  Result := (Length(a) = Length(b)) and ((Length(a) = 0) or CompareMem(@a[0], @b[0], Length(a)));
end;

{ n pseudo-random bytes (a plain LCG, kept below 2^32 by hand: $Q+ is on) }
function Bytes(n: Integer; seed: QWord): TBytes;
var i: Integer;
begin
  SetLength(Result, n);
  for i := 0 to n - 1 do begin
    seed := (seed * 1103515245 + 12345) and $FFFFFFFF;
    Result[i] := Byte((seed shr 16) and $FF);
  end;
end;

procedure RoundTrip(const a: TBytes; const what: string);
var c, back: TBytes; r: TPackResult; h: THash16;
begin
  r := Pack(a, c, True);
  Check(r.Ok, what + ': pack');
  Check(Length(c) = PDA_HEADER + Length(a), what + ': stored size');
  r := Unpack(c, QWord(Length(a)), back, h);
  Check(r.Ok, what + ': unpack');
  Check(Same(back, a), what + ': same bytes');
  Check(Same(PdaDecode(c), a), what + ': PdaDecode');
end;

procedure Damaged;
var a, c, d, back: TBytes; r: TPackResult; h: THash16;
begin
  a := Bytes(1000, 7);
  Pack(a, c, True);
  { a flipped payload byte: the hash catches it }
  d := Copy(c); d[PDA_HEADER + 500] := d[PDA_HEADER + 500] xor 1;
  r := Unpack(d, 1 shl 20, back, h);
  Check(r.err = ukHashMismatch, 'flipped payload byte: hash mismatch');
  { a truncated file: the size catches it }
  d := Copy(c, 0, Length(c) - 1);
  r := Unpack(d, 1 shl 20, back, h);
  Check(r.err = ukSizeMismatch, 'truncated: size mismatch');
  { a declared size above the cap: refused before decoding }
  r := Unpack(c, 999, back, h);
  Check(r.err = ukTooLarge, 'above --max-output: refused');
  { an unknown format, unknown flags, a coded payload, a foreign file }
  d := Copy(c); d[4] := PDA_FORMAT + 1;
  Check(Unpack(d, 1 shl 20, back, h).err = ukFormat, 'unknown format');
  d := Copy(c); d[5] := d[5] or 2;
  Check(Unpack(d, 1 shl 20, back, h).err = ukFormat, 'unknown flags');
  d := Copy(c); d[5] := 0;
  Check(not Unpack(d, 1 shl 20, back, h).Ok, 'coded payload: not read by this version');
  d := Copy(c); d[0] := Ord('X');
  Check(Unpack(d, 1 shl 20, back, h).err = ukFormat, 'foreign magic');
  Check(Unpack(Copy(c, 0, 10), 1 shl 20, back, h).err = ukFormat, 'shorter than a header');
end;

begin
  RoundTrip(nil, 'empty');
  RoundTrip(Bytes(1, 1), 'one byte');
  RoundTrip(Bytes(65537, 2), '64 KiB + 1');
  Damaged;
  if failures = 0 then Writeln('test_format: ok') else begin
    Writeln('test_format: ', failures, ' failures');
    Halt(1);
  end;
end.
