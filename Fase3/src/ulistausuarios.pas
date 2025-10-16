unit uListaUsuarios;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, fpjson, jsonparser;

type
  PUsuario = ^TUsuario;
  TUsuario = record
    id       : LongInt;
    nombre   : string;
    usuario  : string;  // <— NUEVO
    email    : string;
    telefono : string;  // <— NUEVO
    next     : PUsuario;
  end;

  TListaUsuarios = class
  private
    FHead  : PUsuario;
    FCount : SizeInt;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear;

    // Compatibilidad + versión completa
    function  Add(const AId: LongInt; const ANombre, AEmail: string): PUsuario; overload;
    function  Add(const AId: LongInt; const ANombre, AUsuario, AEmail, ATelefono: string): PUsuario; overload;

    function  FindByEmail(const AEmail: string): PUsuario;
    function  EmailById(const AId: LongInt): string;
    function  Count: SizeInt;
    function  NextId: LongInt;

    // Carga / Reporte
    procedure LoadFromJSON(const AFile: string);
    procedure ExportToDOT(const AFile: string);
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
  c, nx: PUsuario;
begin
  c := FHead;
  while c <> nil do
  begin
    nx := c^.next;
    Dispose(c);
    c := nx;
  end;
  FHead  := nil;
  FCount := 0;
end;

// --- Add (compatibilidad) ---
function TListaUsuarios.Add(const AId: LongInt; const ANombre, AEmail: string): PUsuario;
var
  baseUser: string;
begin
  // Derivar usuario si no se da: parte antes de la @
  baseUser := '';
  if Pos('@', AEmail) > 1 then
    baseUser := Copy(AEmail, 1, Pos('@', AEmail)-1);

  Result := Add(AId, ANombre, baseUser, AEmail, '');
end;

// --- Add (completo) ---
function TListaUsuarios.Add(const AId: LongInt; const ANombre, AUsuario, AEmail, ATelefono: string): PUsuario;
var
  n: PUsuario;
begin
  New(n);
  n^.id       := AId;
  n^.nombre   := ANombre;
  n^.usuario  := AUsuario;
  n^.email    := AEmail;
  n^.telefono := ATelefono;
  n^.next     := FHead;

  FHead := n;
  Inc(FCount);
  Result := n;
end;

function TListaUsuarios.FindByEmail(const AEmail: string): PUsuario;
var
  c: PUsuario;
begin
  c := FHead;
  while c <> nil do
  begin
    if SameText(c^.email, AEmail) then Exit(c);
    c := c^.next;
  end;
  Result := nil;
end;

function TListaUsuarios.EmailById(const AId: LongInt): string;
var
  c: PUsuario;
begin
  c := FHead;
  while c <> nil do
  begin
    if c^.id = AId then Exit(c^.email);
    c := c^.next;
  end;
  Result := '';
end;

function TListaUsuarios.Count: SizeInt;
begin
  Result := FCount;
end;

function TListaUsuarios.NextId: LongInt;
var
  c: PUsuario; m: LongInt;
begin
  m := 0; c := FHead;
  while c <> nil do
  begin
    if c^.id > m then m := c^.id;
    c := c^.next;
  end;
  Result := m + 1;
end;

procedure TListaUsuarios.LoadFromJSON(const AFile: string);

  procedure addFromObj(o: TJSONObject; idxBase: Integer);
  var
    idv, nombrev, usuariov, emailv, telv: string;
  begin
    idv     := IntToStr(o.Get('id', idxBase));
    nombrev := o.Get('nombre', '');
    // aceptar claves alternativas
    if o.Find('usuario') <> nil then
      usuariov := o.Get('usuario','')
    else
      usuariov := o.Get('user','');
    emailv   := o.Get('email','');
    if o.Find('telefono') <> nil then
      telv := o.Get('telefono','')
    else
      telv := o.Get('phone','');

    // si no trae usuario, derivar del email
    if (usuariov = '') and (Pos('@', emailv) > 1) then
      usuariov := Copy(emailv, 1, Pos('@', emailv)-1);

    Add(StrToIntDef(idv, idxBase), nombrev, usuariov, emailv, telv);
  end;

var
  s : TStringStream;
  j : TJSONData;
  arr: TJSONArray;
  obj: TJSONObject;
  o  : TJSONObject;
  i  : Integer;
begin
  Clear;

  s := TStringStream.Create('');
  try
    s.LoadFromFile(AFile);
    j := GetJSON(s.DataString);
    try
      case j.JSONType of
        jtArray:
          begin
            arr := TJSONArray(j);
            for i := 0 to arr.Count-1 do
            begin
              o := arr.Objects[i];
              addFromObj(o, i+1);
            end;
          end;
        jtObject:
          begin
            obj := TJSONObject(j);
            if obj.Find('usuarios', arr) then
            begin
              for i := 0 to arr.Count-1 do
              begin
                o := arr.Objects[i];
                addFromObj(o, i+1);
              end;
            end;
          end;
      end;
    finally
      j.Free;
    end;
  finally
    s.Free;
  end;
end;

procedure TListaUsuarios.ExportToDOT(const AFile: string);
var
  f: TextFile;
  u, nextU: PUsuario;

  function Esc(const s: string): string; inline;
  begin
    Result := StringReplace(s, '"', '\"', [rfReplaceAll]);
  end;

  function CardLabel(p: PUsuario): string;
  begin
  // Orden correcto
  Result := Format(
    'ID: %d\nNombre: %s\nUsuario: %s\nEmail: %s\nTeléfono: %s',
    [p^.id, Esc(p^.nombre), Esc(p^.usuario), Esc(p^.email), Esc(p^.telefono)]
  );
  end;


begin
  AssignFile(f, AFile); Rewrite(f);
  try
    Writeln(f, 'digraph G {');
    Writeln(f, '  rankdir=LR;');
    Writeln(f, '  labelloc="t"; label="Reporte de Usuarios";');
    Writeln(f, '  node  [shape=box, style=filled, fillcolor="#cfe8f3", color="#6a8db5", fontname="Helvetica"];');
    Writeln(f, '  edge  [arrowsize=0.7, color="#444444"];');

    // marco con esquinas redondeadas como en tu ejemplo
    Writeln(f, '  subgraph cluster_lista {');
    Writeln(f, '    label="Lista Enlazada"; style="rounded"; color="#808080";');

    // nodos (tarjetas)
    u := FHead;
    while u <> nil do
    begin
      Writeln(f, Format('    u%d [label="%s"];', [u^.id, CardLabel(u)]));
      u := u^.next;
    end;

    // enlaces u1 -> u2 -> u3 ...
    u := FHead;
    while (u <> nil) and (u^.next <> nil) do
    begin
      nextU := u^.next;
      Writeln(f, Format('    u%d -> u%d;', [u^.id, nextU^.id]));
      u := nextU;
    end;

    Writeln(f, '  }'); // cluster
    Writeln(f, '}');
  finally
    CloseFile(f);
  end;
end;


end.

