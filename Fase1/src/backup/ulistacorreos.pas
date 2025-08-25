unit uListaCorreos;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson, jsonparser, uListaUsuarios;

type
  PCorreo = ^TCorreo;
  TCorreo = record
    id          : LongInt;
    remitente   : string;   // email remitente
    destinatario: string;   // email destinatario (derivado del usuario_id si hace falta)
    estado      : string;
    programado  : string;
    asunto      : string;
    fecha       : string;
    mensaje     : string;
    next, prev  : PCorreo;
  end;

  TListaCorreos = class
  private
    FHead, FTail: PCorreo;
    FCount      : SizeInt;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function  Add(const AId: LongInt; const ARem, ADest, AEstado, AProg, AAsunto, AFecha, AMsg: string): PCorreo;
    function  Count: SizeInt;

    // Carga masiva (soporta dos “formas” comunes de JSON)
    procedure LoadFromJSON(const ARuta: string; const Usuarios: TListaUsuarios);

    // Reporte de relaciones (remitente -> destinatario, colapsando múltiples correos)
    procedure ExportRelacionesDOT(const ARuta: string);
  end;

implementation

{ TListaCorreos }

constructor TListaCorreos.Create;
begin
  inherited Create;
  FHead := nil; FTail := nil; FCount := 0;
end;

destructor TListaCorreos.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TListaCorreos.Clear;
var
  cur, nxt: PCorreo;
begin
  cur := FHead;
  while cur <> nil do
  begin
    nxt := cur^.next;
    Dispose(cur);
    cur := nxt;
  end;
  FHead := nil; FTail := nil; FCount := 0;
end;

function TListaCorreos.Add(const AId: LongInt; const ARem, ADest, AEstado, AProg, AAsunto, AFecha, AMsg: string): PCorreo;
var
  n: PCorreo;
begin
  New(n);
  n^.id          := AId;
  n^.remitente   := ARem;
  n^.destinatario:= ADest;
  n^.estado      := AEstado;
  n^.programado  := AProg;
  n^.asunto      := AAsunto;
  n^.fecha       := AFecha;
  n^.mensaje     := AMsg;
  n^.next := nil; n^.prev := FTail;

  if FTail <> nil then FTail^.next := n else FHead := n;
  FTail := n;
  Inc(FCount);
  Result := n;
end;

function TListaCorreos.Count: SizeInt; begin Result := FCount; end;

procedure TListaCorreos.LoadFromJSON(const ARuta: string; const Usuarios: TListaUsuarios);
var
  s : TStringStream;
  j : TJSONData;
  root: TJSONObject;
  arr : TJSONArray;
  i,k: Integer;
  o, mail: TJSONObject;
  uid: LongInt;
  destEmail, remit: string;
begin
  Clear;

  s := TStringStream.Create('');
  try
    s.LoadFromFile(ARuta);
    j := GetJSON(s.DataString);
    try
      if j.JSONType <> jtObject then Exit;
      root := TJSONObject(j);

      // Forma A: cada elemento ya trae remitente y destinatario como emails
      if root.Find('correos') <> nil then
      begin
        arr := root.Arrays['correos'];
        // si el primer elemento tiene 'remitente' ya sabemos que es forma A
        if (arr.Count > 0) and (arr.Objects[0].Find('remitente') <> nil) then
        begin
          for i := 0 to arr.Count - 1 do
          begin
            o := arr.Objects[i];
            Add(
              o.Get('id', i+1),
              o.Get('remitente',''),
              o.Get('destinatario',''),
              o.Get('estado',''),
              o.Get('programado',''),
              o.Get('asunto',''),
              o.Get('fecha',''),
              o.Get('mensaje','')
            );
          end;
          Exit;
        end;
      end;

      // Forma B (del enunciado):
      // { "correos": [ { "usuario_id": N, "bandeja_entrada": [ { remitente, ... }, ... ] }, ... ] }
      if root.Find('correos') = nil then Exit;
      arr := root.Arrays['correos'];

      for i := 0 to arr.Count - 1 do
      begin
        o   := arr.Objects[i];
        uid := o.Get('usuario_id', 0);
        destEmail := Usuarios.EmailById(uid);
        if destEmail = '' then Continue;                      // usuario no existe
        if not o.Find('bandeja_entrada', mail) then Continue; // sin bandeja_entrada

        for k := 0 to o.Arrays['bandeja_entrada'].Count - 1 do
        begin
          mail  := o.Arrays['bandeja_entrada'].Objects[k];
          remit := mail.Get('remitente','');
          Add(
            mail.Get('id', (i+1)*1000 + k + 1),
            remit,
            destEmail,
            mail.Get('estado',''),
            mail.Get('programado',''),
            mail.Get('asunto',''),
            mail.Get('fecha',''),
            mail.Get('mensaje','')
          );
        end;
      end;
    finally
      j.Free;
    end;
  finally
    s.Free;
  end;
end;

procedure TListaCorreos.ExportRelacionesDOT(const ARuta: string);
var
  f: TextFile;
  keys : TStringList;   // “a|b” → contador
  cur  : PCorreo;

  function K(const a,b:string):string; inline;
  begin
    Result := a + '|' + b;
  end;

  procedure IncEdge(const a,b:string);
  var idx: Integer;
  begin
    idx := keys.IndexOf(K(a,b));
    if idx < 0 then
      keys.AddObject(K(a,b), TObject(PtrInt(1)))
    else
      keys.Objects[idx] := TObject(PtrInt(PtrInt(keys.Objects[idx]) + 1));
  end;

  procedure EmitEdges;
  var
    i, cnt: Integer;
    a, b: string;
  begin
    for i := 0 to keys.Count - 1 do
    begin
      a := Copy(keys[i], 1, Pos('|', keys[i]) - 1);
      b := Copy(keys[i], Pos('|', keys[i]) + 1, MaxInt);
      cnt := PtrInt(keys.Objects[i]);
      Writeln(f, '  "', a, '" -> "', b, '" [label="', cnt, '"];');
    end;
  end;

begin
  keys := TStringList.Create;
  try
    keys.Sorted := False;
    keys.Duplicates := dupIgnore;

    cur := FHead;
    while cur <> nil do
    begin
      if (cur^.remitente <> '') and (cur^.destinatario <> '') then
        IncEdge(cur^.remitente, cur^.destinatario);
      cur := cur^.next;
    end;

    AssignFile(f, ARuta); Rewrite(f);
    try
      Writeln(f, 'digraph G {');
      Writeln(f, '  rankdir=LR; splines=true; overlap=false;');
      Writeln(f, '  node [shape=box, style=filled, fillcolor=lightyellow];');
      Writeln(f, '  labelloc="t"; fontsize=16;');
      Writeln(f, '  label="Relaciones: Remitente → Destinatario";');
      EmitEdges;
      Writeln(f, '}');
    finally
      CloseFile(f);
    end;
  finally
    keys.Free;
  end;
end;

end.

