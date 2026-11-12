{ Ported from PMPA's pas/pmpainfopmpa.pas (itself from PJA's pas/pjainfopja.pas).

  The info provider (pdainfo) of the .pda: its header (pdaformat), read as
  the unit lays it out, without decoding the stream: the format, the flags,
  the original's size and BLAKE3-128, whether it is stored as is, and the
  size of the coded stream. Whether it extracts is DescribeAction's (it
  decodes). A .pda keeps no name nor extension: x names the output after
  the .pda (NAME.pda -> NAME). }
unit pdainfopda;

{$I pda.inc}
{$ifopt R-}{$fatal pdainfopda: range checks ($R+) are mandatory}{$endif}
{$ifopt Q-}{$fatal pdainfopda: overflow checks ($Q+) are mandatory}{$endif}

interface

uses SysUtils, pdainfo;

function ProbePda(const d: TBytes): Boolean;
procedure DescribePda(const d: TBytes; n: TInfoNode);

implementation

uses pdaformat, pdapack;

function ProbePda(const d: TBytes): Boolean;
begin
  Result := PdaIsPda(d);
end;

procedure DescribePda(const d: TBytes; n: TInfoNode);
var h: TPdaHeader; why, flags: string; c, st: TInfoNode; ok: Boolean;
begin
  n.Str('format', '.pda');
  n.Num('size', Length(d));
  c := n.Obj('container');
  ok := PdaOpen(d, h, why);
  c.Num('format', h.format);
  flags := '';
  if h.flags and PDA_FLAG_STORED <> 0 then flags := 'stored';
  if h.flags and not PDA_FLAG_STORED <> 0 then begin
    if flags <> '' then flags := flags + ', ';
    flags := flags + 'unknown ' + IntToStr(h.flags and not PDA_FLAG_STORED);
  end;
  if flags = '' then flags := 'none';
  c.Str('flags', flags);
  c.Bool('valid', ok);
  if not ok then begin
    c.Str('error', why);
    Exit;
  end;
  c.Num('original_size', h.origSize);
  c.Str('blake3_128', HexBytes(h.hash));
  c.Bool('stored', h.stored);
  c.Num('payload_size', h.payloadSize);
  st := n.Obj('stream');
  if h.stored then st.Str('kind', 'none: the original stored as is')
  else begin
    st.Str('kind', 'coded: the document''s streams, each through its codec');
    st.Num('coded_bytes', h.payloadSize);
    if h.origSize > 0 then st.Fixed('ratio_percent', 100 * Length(d) / h.origSize);
  end;
end;

initialization
  RegisterInfoProvider('pda', @ProbePda, @DescribePda);
end.
