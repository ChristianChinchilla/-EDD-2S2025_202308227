unit uListaUsuarios;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson, jsonparser;

type
  PUsuario = ^TUsuario;
  TUsuario = record
    id       : LongInt;
    nombre   : string;
    usuario  : string;
    password : string;
    email    : string;
    telefono : string;
    next     : PUsuario;
  end;

  TListaUsuarios = class
  private
    FHead : PUsuario;
    FCount: Integer;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear;
    function  Add(AId: LongInt; const ANombre, AUsuario, APassword, AEmail, ATelefono: string): PUsuario;

    // login
    function  FindLogin(const AEmail, APass: string): PUsuario;

    // búsquedas / helpers
    function  FindById(AId: LongInt): PUsuario;
    function  FindByEmail(const AEmail: string): PUsuario;
    function  EmailById(AId: LongInt): string;
    function  IdByEmail(const AEmail: string): LongInt;
    function  ExistsEmail(const AEmail: string): Boolean; // <- NUEVO

    // cargas y reportes
    procedure LoadFromJSON(const ARuta: string);
    procedure ExportToDOT(const ARuta: string);

    property Count: Integer read FCount;
  end;

implementation

{ TListaUsuarios }

constructor TListaUsuarios.Create;
begin
  inherited Create;
  FHead  := nil;
  FCount := 0;
end;

destructor TListaUsuarios.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TListaUsuarios.Clear;
var
  cur, nxt: PUsuario;
begin
  cur := FHead;
  while cur <> nil do
  begin
    nxt := cur^.next;
    Dispose(cur);
    cur := nxt;
  end;
  FHead  := nil;
  FCount := 0;
end;

function TListaUsuarios.Add(AId: LongInt; const ANombre, AUsuario, APassword, AEmail, ATelefono: string): PUsuario;
var
  n: PUsuario;
begin
  New(n);
  n^.id       := AId;
  n^.nombre   := ANombre;
  n^.usuario  := AUsuario;
  n^.password := APassword;
  n^.email    := AEmail;
  n^.telefono := ATelefono;
  n^.next     := FHead;
  FHead       := n;
  Inc(FCount);
  Result      := n;
end;

function TListaUsuarios.FindLogin(const AEmail, APass: string): PUsuario;
var
  cur: PUsuario;
begin
  Result := nil;
  cur := FHead;
  while cur <> nil do
  begin
    if (CompareText(cur^.email, AEmail) = 0) and (cur^.password = APass) then
      Exit(cur);
    cur := cur^.next;
  end;
end;

function TListaUsuarios.FindById(AId: LongInt): PUsuario;
var
  cur: PUsuario;
begin
  Result := nil;
  cur := FHead;
  while cur <> nil do
  begin
    if cur^.id = AId then Exit(cur);
    cur := cur^.next;
  end;
end;

function TListaUsuarios.FindByEmail(const AEmail: string): PUsuario;
var
  cur: PUsuario;
begin
  Result := nil;
  cur := FHead;
  while cur <> nil do
  begin
    if CompareText(cur^.email, AEmail) = 0 then Exit(cur);
    cur := cur^.next;
  end;
end;

function TListaUsuarios.EmailById(AId: LongInt): string;
var
  p: PUsuario;
begin
  p := FindById(AId);
  if p <> nil then Result := p^.email else Result := '';
end;

function TListaUsuarios.IdByEmail(const AEmail: string): LongInt;
var
  p: PUsuario;
begin
  p := FindByEmail(AEmail);
  if p <> nil then Result := p^.id else Result := -1;
end;

function TListaUsuarios.ExistsEmail(const AEmail: string): Boolean;
begin
  Result := FindByEmail(AEmail) <> nil;
end;

procedure TListaUsuarios.LoadFromJSON(const ARuta: string);
var
  s : TStringStream;
  j : TJSONData;
  root: TJSONObject;
  arr: TJSONArray;
  i  : Integer;
  o  : TJSONObject;
begin
  Clear;

  s := TStringStream.Create('');
  try
    s.LoadFromFile(ARuta);
    j := GetJSON(s.DataString);
    try
      root := j as TJSONObject;
      arr  := root.Arrays['usuarios'];
      for i := 0 to arr.Count - 1 do
      begin
        o := arr.Objects[i];
        Add(
          o.Integers['id'],
          o.Strings['nombre'],
          o.Strings['usuario'],
          o.Strings['password'],
          o.Strings['email'],
          o.Strings['telefono']
        );
      end;
    finally
      j.Free;
    end;
  finally
    s.Free;
  end;
end;

procedure TListaUsuarios.ExportToDOT(const ARuta: string);
var
  f  : TextFile;
  cur: PUsuario;
  idx: Integer;
begin
  AssignFile(f, ARuta);
  Rewrite(f);
  try
    Writeln(f, 'digraph G { rankdir=LR;');
    Writeln(f, '  node [shape=record, style=filled, fillcolor=lightblue];');

    cur := FHead;
    idx := 0;
    while cur <> nil do
    begin
      Inc(idx);
      Writeln(f, Format('  n%d [label="ID: %d | Nombre: %s | Usuario: %s | Email: %s | Telefono: %s"];',
        [idx, cur^.id, cur^.nombre, cur^.usuario, cur^.email, cur^.telefono]));
      if cur^.next <> nil then
        Writeln(f, Format('  n%d -> n%d;', [idx, idx + 1]));
      cur := cur^.next;
    end;

    Writeln(f, '}');
  finally
    CloseFile(f);
  end;
end;

end.

