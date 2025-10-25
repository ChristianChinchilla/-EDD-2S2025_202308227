unit uBlockchain;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

type
  PBlock = ^TBlock;
  TBlock = record
    Index     : LongInt;
    Timestamp : string;  // 'dd-mm-yy::hh:nn:ss'
    Data      : string;  // Información del correo o texto
    Nonce     : LongInt;
    PrevHash  : string;
    Hash      : string;
    Next      : PBlock;  // siguiente bloque (el más nuevo en FHead)
  end;

  TMined = record
    Nonce: LongInt;
    Hash : string;
  end;

  { TBlockchain }
  TBlockchain = class
  private
    FHead  : PBlock;
    FCount : LongInt;
    function  PoW(const Index: LongInt; const TS, Data, Prev: string): TMined;
    function  NowStamp: string;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function  Count: LongInt;
    function  AddRaw(const Data: string): PBlock;
    function  AddWithTimestamp(const Data, CustomTS: string): PBlock;
    function  AddMail(const CorreoId: LongInt; const Asunto, Fecha: string): PBlock;
    procedure ToDOT(const TargetDot, TargetPng: string);
  end;

// SHA-256 puro
function SHA256Hex(const S: string): string;

implementation

uses
  Process, FileUtil;

{============================ SHA-256 puro ============================}

function SHA256Hex(const S: string): string;
type
  TDWords = array[0..7] of DWord;
const
  H0: TDWords = (
    $6A09E667, $BB67AE85, $3C6EF372, $A54FF53A,
    $510E527F, $9B05688C, $1F83D9AB, $5BE0CD19
  );
  K: array[0..63] of DWord = (
    $428A2F98,$71374491,$B5C0FBCF,$E9B5DBA5,$3956C25B,$59F111F1,$923F82A4,$AB1C5ED5,
    $D807AA98,$12835B01,$243185BE,$550C7DC3,$72BE5D74,$80DEB1FE,$9BDC06A7,$C19BF174,
    $E49B69C1,$EFBE4786,$0FC19DC6,$240CA1CC,$2DE92C6F,$4A7484AA,$5CB0A9DC,$76F988DA,
    $983E5152,$A831C66D,$B00327C8,$BF597FC7,$C6E00BF3,$D5A79147,$06CA6351,$14292967,
    $27B70A85,$2E1B2138,$4D2C6DFC,$53380D13,$650A7354,$766A0ABB,$81C2C92E,$92722C85,
    $A2BFE8A1,$A81A664B,$C24B8B70,$C76C51A3,$D192E819,$D6990624,$F40E3585,$106AA070,
    $19A4C116,$1E376C08,$2748774C,$34B0BCB5,$391C0CB3,$4ED8AA4A,$5B9CCA4F,$682E6FF3,
    $748F82EE,$78A5636F,$84C87814,$8CC70208,$90BEFFFA,$A4506CEB,$BEF9A3F7,$C67178F2
  );
var
  a,b,c,d,e,f,g,h,t1,t2: DWord;
  W: array[0..63] of DWord;
  state: TDWords;
  msg: array of Byte;
  lenBits: QWord;
  off, newLen, origLen, i: Integer;

  function ROR(x: DWord; n: Byte): DWord; inline;
  begin
    Result := (x shr n) or (x shl (32 - n));
  end;
  function Ch(x,y,z: DWord): DWord; inline;  begin Result := (x and y) xor ((not x) and z); end;
  function Maj(x,y,z: DWord): DWord; inline; begin Result := (x and y) xor (x and z) xor (y and z); end;
  function BSIG0(x: DWord): DWord; inline;   begin Result := ROR(x,2) xor ROR(x,13) xor ROR(x,22); end;
  function BSIG1(x: DWord): DWord; inline;   begin Result := ROR(x,6) xor ROR(x,11) xor ROR(x,25); end;
  function SSIG0(x: DWord): DWord; inline;   begin Result := ROR(x,7) xor ROR(x,18) xor (x shr 3); end;
  function SSIG1(x: DWord): DWord; inline;   begin Result := ROR(x,17) xor ROR(x,19) xor (x shr 10); end;

  procedure ProcessBlock(const p: PByte);
  var idx: Integer;
  begin
    for idx := 0 to 15 do
      W[idx] :=
        (DWord(p[idx*4+0]) shl 24) or
        (DWord(p[idx*4+1]) shl 16) or
        (DWord(p[idx*4+2]) shl 8)  or
        (DWord(p[idx*4+3]));
    for idx := 16 to 63 do
      W[idx] := SSIG1(W[idx-2]) + W[idx-7] + SSIG0(W[idx-15]) + W[idx-16];

    a:=state[0]; b:=state[1]; c:=state[2]; d:=state[3];
    e:=state[4]; f:=state[5]; g:=state[6]; h:=state[7];

    for idx := 0 to 63 do
    begin
      t1 := h + BSIG1(e) + Ch(e,f,g) + K[idx] + W[idx];
      t2 := BSIG0(a) + Maj(a,b,c);
      h := g;  g := f;  f := e;  e := d + t1;
      d := c;  c := b;  b := a;  a := t1 + t2;
    end;

    Inc(state[0], a); Inc(state[1], b); Inc(state[2], c); Inc(state[3], d);
    Inc(state[4], e); Inc(state[5], f); Inc(state[6], g); Inc(state[7], h);
  end;

  function ToHex(x: DWord): string; inline;
  begin
    Result := LowerCase(IntToHex(x,8));
  end;

var
  pb: PByte;
begin
  state := H0;
  origLen := Length(S);
  lenBits := QWord(origLen) * 8;

  newLen := origLen + 1;
  while (newLen mod 64) <> 56 do Inc(newLen);
  Inc(newLen, 8);

  SetLength(msg, newLen);
  if origLen > 0 then Move(S[1], msg[0], origLen);
  msg[origLen] := $80;

  msg[newLen-8] := (lenBits shr 56) and $FF;
  msg[newLen-7] := (lenBits shr 48) and $FF;
  msg[newLen-6] := (lenBits shr 40) and $FF;
  msg[newLen-5] := (lenBits shr 32) and $FF;
  msg[newLen-4] := (lenBits shr 24) and $FF;
  msg[newLen-3] := (lenBits shr 16) and $FF;
  msg[newLen-2] := (lenBits shr 8 ) and $FF;
  msg[newLen-1] := (lenBits       ) and $FF;

  off := 0;
  while off < newLen do
  begin
    pb := @msg[off];
    ProcessBlock(pb);
    Inc(off, 64);
  end;

  Result :=
    ToHex(state[0]) + ToHex(state[1]) + ToHex(state[2]) + ToHex(state[3]) +
    ToHex(state[4]) + ToHex(state[5]) + ToHex(state[6]) + ToHex(state[7]);
end;

{========================== TBlockchain ==========================}

constructor TBlockchain.Create;
var
  g: PBlock;
begin
  inherited Create;
  FHead := nil;
  FCount := 0;

  // Bloque génesis
  New(g);
  g^.Index     := 0;
  g^.Timestamp := '00-00-00::00:00:00';
  g^.Data      := 'Genesis Block';
  g^.Nonce     := 0;
  g^.PrevHash  := '0000';
  g^.Hash      := SHA256Hex(IntToStr(g^.Index)+g^.Timestamp+g^.Data+IntToStr(g^.Nonce)+g^.PrevHash);
  g^.Next      := nil;

  FHead := g;
  Inc(FCount);
end;

destructor TBlockchain.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TBlockchain.Clear;
var
  p, nx: PBlock;
begin
  p := FHead;
  while p <> nil do
  begin
    nx := p^.Next;
    Dispose(p);
    p := nx;
  end;
  FHead := nil;
  FCount := 0;
end;

function TBlockchain.Count: LongInt;
begin
  Result := FCount;
end;

function TBlockchain.NowStamp: string;
begin
  Result := FormatDateTime('dd"-"mm"-"yy"::"hh":"nn":"ss', Now);
end;

function TBlockchain.PoW(const Index: LongInt; const TS, Data, Prev: string): TMined;
var
  nonce: LongInt;
  h: string;
begin
  nonce := 0;
  repeat
    h := SHA256Hex(IntToStr(Index)+TS+Data+IntToStr(nonce)+Prev);
    Inc(nonce);
  until (Length(h) >= 4) and (Copy(h,1,4) = '0000'); // dificultad 4 ceros

  Result.Nonce := nonce - 1;
  Result.Hash  := h;
end;

function TBlockchain.AddRaw(const Data: string): PBlock;
begin
  Result := AddWithTimestamp(Data, '');
end;

function TBlockchain.AddWithTimestamp(const Data, CustomTS: string): PBlock;
var
  b: PBlock;
  prevHash: string;
  idx: LongInt;
  ts: string;
  mined: TMined;
begin
  if FHead = nil then Exit(nil);
  prevHash := FHead^.Hash;
  idx := FHead^.Index + 1;
  if Trim(CustomTS) <> '' then ts := CustomTS else ts := NowStamp;

  mined := PoW(idx, ts, Data, prevHash);

  New(b);
  b^.Index     := idx;
  b^.Timestamp := ts;
  b^.Data      := Data;
  b^.Nonce     := mined.Nonce;
  b^.PrevHash  := prevHash;
  b^.Hash      := mined.Hash;
  b^.Next      := FHead;
  FHead        := b;
  Inc(FCount);
  Result := b;
end;

function TBlockchain.AddMail(const CorreoId: LongInt; const Asunto, Fecha: string): PBlock;
var
  data: string;
begin
  data := Format('Id Correo: %d | Asunto: %s', [CorreoId, Asunto]);
  Result := AddWithTimestamp(data, Fecha);
end;

procedure TBlockchain.ToDOT(const TargetDot, TargetPng: string);
var
  L: TStringList;
  p: PBlock;
  arr: array of PBlock;
  i, n: Integer;

  procedure RunDot(const dotFile, pngFile: string);
  var P: TProcess; Exe: string;
  begin
    Exe := FindDefaultExecutablePath('dot'); if Exe = '' then Exe := 'dot';
    P := TProcess.Create(nil);
    try
      P.Executable := Exe;
      P.Parameters.Add('-Tpng');
      P.Parameters.Add(dotFile);
      P.Parameters.Add('-o'); P.Parameters.Add(pngFile);
      P.Options := [poNoConsole, poWaitOnExit];
      try P.Execute; except end;
    finally
      P.Free;
    end;
  end;

  procedure AddNode(const name, title: string; const b: PBlock);
  begin
    L.Add(Format(
      '  %s [shape=plaintext, label=<<table border="1" cellborder="1" cellspacing="0" bgcolor="#cfe8ff">' +
      '<tr><td><b>%s</b></td></tr>' +
      '<tr><td>Index: %d</td></tr>' +
      '<tr><td>Timestamp: %s</td></tr>' +
      '<tr><td>%s</td></tr>' +
      '<tr><td>Nonce: %d</td></tr>' +
      '<tr><td>Hash: %s</td></tr>' +
      '<tr><td>PrevHash: %s</td></tr>' +
      '</table>>];',
      [name, title, b^.Index, b^.Timestamp,
       StringReplace(b^.Data,'"','\"',[rfReplaceAll]),
       b^.Nonce, Copy(b^.Hash,1,16)+'...', Copy(b^.PrevHash,1,16)+'...']));
  end;

begin
  L := TStringList.Create;
  try
    n := 0; p := FHead;
    while p <> nil do begin Inc(n); p := p^.Next; end;
    if n = 0 then Exit;
    SetLength(arr, n);
    p := FHead; i := n-1;
    while p <> nil do begin arr[i] := p; Dec(i); p := p^.Next; end;

    L.Add('digraph G {');
    L.Add('  rankdir=TB;');
    L.Add('  graph [fontname="Helvetica"];');
    L.Add('  labelloc="t"; label="Blockchain (Emails)";');

    for i := 0 to High(arr) do
      if i = 0 then
        AddNode(Format('b%d',[i]), 'Block 0 (Genesis)', arr[i])
      else
        AddNode(Format('b%d',[i]), Format('Block %d',[arr[i]^.Index]), arr[i]);

    for i := 0 to High(arr)-1 do
      L.Add(Format('  b%d -> b%d;', [i, i+1]));

    L.Add('}');
    ForceDirectories(ExtractFileDir(TargetDot));
    L.SaveToFile(TargetDot);
    RunDot(TargetDot, TargetPng);
  finally
    L.Free;
  end;
end;

end.

