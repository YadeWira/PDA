{ The .pda file: header and payload.

  Format 1 (not frozen: it may change until a 0.9.x freezes it, see the
  family's doc/STABILITY.md model in PJA):

    offset  size  field
         0     4  magic 'P' 'D' 'A' $1A
         4     1  format (PDA_FORMAT)
         5     1  flags: bit 0 = stored (the payload is the original as it is)
         6     8  original size, little endian
        14    16  BLAKE3-128 of the original
        30     -  payload

  Today every file is stored: this is the base layer (stage 1 of the plan),
  the container, the command and the checks around them, before any
  container parser or codec. A coded payload (flag 0) is reserved for the
  stream tree that comes next and is refused by this version. }
unit pdaformat;

{$I pda.inc}
{$ifopt R-}{$fatal pdaformat: range checks ($R+) are mandatory}{$endif}
{$ifopt Q-}{$fatal pdaformat: overflow checks ($Q+) are mandatory}{$endif}

interface

uses SysUtils, pdablake3;

const
  PDA_FORMAT = 1;
  PDA_HEADER = 4 + 1 + 1 + 8 + 16;
  PDA_MAGIC: array[0..3] of Byte = (Ord('P'), Ord('D'), Ord('A'), $1A);
  { header flags: bit 0, the original stored as it is }
  PDA_FLAG_STORED = 1;

type
  { a damaged or foreign .pda }
  EPdaFormat = class(Exception);

  { What the coder saw. Streams: the streams the document was split into
    (0 while every file is stored whole). }
  TPdaStats = record
    Streams: SizeInt;
    StoredBytes: QWord;
  end;

{ The .pda bytes for a file. Does not verify: the caller decodes and
  compares before writing anything. }
function PdaEncode(const a: TBytes; out st: TPdaStats): TBytes;

{ The original file. Raises EPdaFormat on a damaged or foreign input;
  checks the size and the BLAKE3 stored in the header. }
function PdaDecode(const c: TBytes): TBytes;

function PdaIsPda(const c: TBytes): Boolean;

{ What the payload decodes to, without checking the size or the BLAKE3 the
  header declares (the caller does: x --keep-corrupt keeps what does not
  match). Raises EPdaFormat on a header it does not know, a damaged
  payload, or an output that would pass cap bytes. Stored: the payload as
  it is. }
function PdaDecodeData(const c: TBytes; cap: QWord): TBytes;

implementation

procedure Wr64(var b: TBytes; p: SizeInt; v: QWord);
var i: Integer;
begin
  for i := 0 to 7 do begin b[p + i] := Byte(v and $FF); v := v shr 8; end;
end;

function Rd64(const b: TBytes; p: SizeInt): QWord;
var i: Integer;
begin
  Result := 0;
  for i := 7 downto 0 do Result := (Result shl 8) or b[p + i];
end;

function PdaIsPda(const c: TBytes): Boolean;
begin
  Result := (Length(c) >= PDA_HEADER) and (c[0] = PDA_MAGIC[0]) and (c[1] = PDA_MAGIC[1]) and
            (c[2] = PDA_MAGIC[2]) and (c[3] = PDA_MAGIC[3]);
end;

function PdaEncode(const a: TBytes; out st: TPdaStats): TBytes;
var h: THash16; i: Integer;
begin
  st := Default(TPdaStats);
  h := Blake3_128(a);
  SetLength(Result, PDA_HEADER + Length(a));
  FillChar(Result[0], PDA_HEADER, 0);
  for i := 0 to 3 do Result[i] := PDA_MAGIC[i];
  Result[4] := PDA_FORMAT;
  Result[5] := PDA_FLAG_STORED;
  Wr64(Result, 6, QWord(Length(a)));
  for i := 0 to 15 do Result[14 + i] := h[i];
  if Length(a) > 0 then Move(a[0], Result[PDA_HEADER], Length(a));
  st.StoredBytes := QWord(Length(a));
end;

function PdaDecodeData(const c: TBytes; cap: QWord): TBytes;
begin
  if not PdaIsPda(c) then raise EPdaFormat.Create('not a .pda file');
  if c[4] <> PDA_FORMAT then
    raise EPdaFormat.Create('a .pda of format ' + IntToStr(c[4]) + ', which this version does not read (it reads ' +
                            IntToStr(PDA_FORMAT) + ')');
  if (c[5] and PDA_FLAG_STORED) = 0 then
    raise EPdaFormat.Create('a coded .pda, which this version does not read (it only stores)');
  if (c[5] and not PDA_FLAG_STORED) <> 0 then raise EPdaFormat.Create('damaged header (flags)');
  if QWord(Length(c) - PDA_HEADER) > cap then raise EPdaFormat.Create('damaged: longer than its declared size');
  Result := Copy(c, PDA_HEADER, Length(c) - PDA_HEADER);
end;

function PdaDecode(const c: TBytes): TBytes;
var size: QWord; h, actual: THash16; i: Integer;
begin
  if not PdaIsPda(c) then raise EPdaFormat.Create('not a .pda file');
  size := Rd64(c, 6);
  for i := 0 to 15 do h[i] := c[14 + i];
  Result := PdaDecodeData(c, size);
  if QWord(Length(Result)) <> size then raise EPdaFormat.Create('damaged: the size differs from the declared one');
  actual := Blake3_128(Result);
  if not CompareMem(@actual[0], @h[0], SizeOf(THash16)) then
    raise EPdaFormat.Create('damaged: the BLAKE3-128 differs from the declared one');
end;

end.
