unit uListaCorreos;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, fpjson, jsonparser, uListaUsuarios;

type
  PCorreo = ^TCorreo;
  TCorreo = record
    id          : LongInt;
    remitente   : string;
    destinatario: string;
    estado      : string;  // 'NL' o 'L'
    programado  : string;  // fecha/hora si aplica
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
    function  Add(const AId: LongInt; const ARem, ADest, AEstado, AProg,
                  AAsunto, AFecha, AMsg: string): PCorreo;
    function  Count: SizeInt;

    // Helpers
    function  First: PCorreo;
    procedure Remove(ACorreo: PCorreo);  // quita y LIBERA memoria
    procedure Detach(ACorreo: PCorreo);  // quita SIN liberar (p.ej. mover a papelera)
    function  NextId: LongInt;

    // Carga masiva
    procedure LoadFromJSON(const ARuta: string; const Usuarios: TListaUsuarios);

    // Reportes
    procedure ExportRelacionesDOT(const ARuta: string);
    procedure ExportRelacionesMatrizDOT(const ARuta: string);
  end;

implementation

{=== Utilidad local para desenlazar un nodo doblemente enlazado ===}
procedure UnlinkNode(var Head, Tail: PCorreo; ACorreo: PCorreo);
begin
  if ACorreo = nil then Exit;

  if ACorreo^.prev <> nil then
    ACorreo^.prev^.next := ACorreo^.next
  else
    Head := ACorreo^.next;

  if ACorreo^.next <> nil then
    ACorreo^.next^.prev := ACorreo^.prev
  else
    Tail := ACorreo^.prev;
end;

{ TListaCorreos }

constructor TListaCorreos.Create;
begin
  inherited Create;
  FHead := nil;
  FTail := nil;
  FCount := 0;
end;

destructor TListaCorreos.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TListaCorreos.Clear;
var
  cur, nx: PCorreo;
begin
  cur := FHead;
  while cur <> nil do
  begin
    nx := cur^.next;
    Dispose(cur);
    cur := nx;
  end;
  FHead := nil;
  FTail := nil;
  FCount := 0;
end;

function TListaCorreos.Add(const AId: LongInt; const ARem, ADest, AEstado, AProg,
                           AAsunto, AFecha, AMsg: string): PCorreo;
var
  n: PCorreo;
begin
  New(n);
  n^.id           := AId;
  n^.remitente    := ARem;
  n^.destinatario := ADest;
  n^.estado       := AEstado;
  n^.programado   := AProg;
  n^.asunto       := AAsunto;
  n^.fecha        := AFecha;
  n^.mensaje      := AMsg;
  n^.next := nil;
  n^.prev := FTail;

  if FTail <> nil then
    FTail^.next := n
  else
    FHead := n;

  FTail := n;
  Inc(FCount);
  Result := n;
end;

function TListaCorreos.Count: SizeInt;
begin
  Result := FCount;
end;

function TListaCorreos.First: PCorreo;
begin
  Result := FHead;
end;

procedure TListaCorreos.Remove(ACorreo: PCorreo);
begin
  if ACorreo = nil then Exit;
  UnlinkNode(FHead, FTail, ACorreo);
  if FCount > 0 then Dec(FCount);
  Dispose(ACorreo);                // borrado definitivo
end;

procedure TListaCorreos.Detach(ACorreo: PCorreo);
begin
  if ACorreo = nil then Exit;
  UnlinkNode(FHead, FTail, ACorreo);
  if FCount > 0 then Dec(FCount);
  // NO liberar aquí (lo hará quien corresponda)
end;

function TListaCorreos.NextId: LongInt;
var
  cur: PCorreo;
  m  : LongInt;
begin
  m := 0;
  cur := FHead;
  while cur <> nil do
  begin
    if cur^.id > m then m := cur^.id;
    cur := cur^.next;
  end;
  Result := m + 1;
end;

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
      // Forma A: { "correos": [ {remitente, destinatario, ...}, ... ] }
      if (j.JSONType = jtObject) then
      begin
        root := TJSONObject(j);

        if root.Find('correos', arr) then
        begin
          // Si el primer elemento ya tiene 'remitente', asumimos forma A
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

          // Forma B: { "correos": [ {usuario_id, bandeja_entrada:[ {...}, ... ]}, ... ] }
          for i := 0 to arr.Count - 1 do
          begin
            o := arr.Objects[i];
            uid := o.Get('usuario_id', 0);
            destEmail := Usuarios.EmailById(uid);
            if destEmail = '' then Continue;
            if not o.Find('bandeja_entrada', mail) then Continue;

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

          Exit; // terminó forma B
        end;
      end;

      // Si llega aquí, el JSON no matcheó las formas soportadas.
      // No se lanza excepción: simplemente deja la lista vacía.
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
  keys : TStringList;
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

procedure TListaCorreos.ExportRelacionesMatrizDOT(const ARuta: string);
var
  senders, dests : TStringList;
  counts         : array of array of Integer;
  i, j           : Integer;
  cur            : PCorreo;
  f              : TextFile;

  procedure W(const S: string); inline;
  begin
    WriteLn(f, S);
  end;

  procedure WriteHeaderRow;   // fila superior (destinatarios)
  var j: Integer;
  begin
    W('  { rank=same;');
    W('    Corner [label="", shape=box, style=filled, fillcolor="gray70", width=1, height=0.5, fixedsize=true];');
    for j := 0 to dests.Count-1 do
      W(Format(
        '    C%d [label="%s", shape=box, style=filled, fillcolor="lightblue", fontsize=10, width=2.6, height=0.6, fixedsize=true];',
        [j, StringReplace(dests[j], '"', '\"', [rfReplaceAll])]));
    // alineación horizontal
    for j := -1 to dests.Count-2 do
      if j = -1 then W('    Corner -> C0 [style=invis, weight=50];')
      else            W(Format('    C%d -> C%d [style=invis, weight=50];', [j, j+1]));
    W('  }');

    // flechas entre cabeceras (como la maqueta)
    for j := 0 to dests.Count-2 do
      W(Format('  C%d -> C%d [dir=both, arrowsize=0.5];', [j, j+1]));
  end;

  procedure WriteRow(i: Integer); // columna izquierda + celdas
  var
    j: Integer;
    rowId: string;

    // Devuelve el ID del nodo de la celda (visible X_ o invisible P_)
    function CellId(ii, jj: Integer): string;
    begin
      if counts[ii][jj] > 0 then
        Result := Format('X_%d_%d', [ii, jj])
      else
        Result := Format('P_%d_%d', [ii, jj]);
    end;

  begin
    rowId := Format('R%d', [i]);

    // remitente a la izquierda
    W('  { rank=same;');
    W(Format(
      '    %s [label="%s", shape=box, style=filled, fillcolor="lightgreen", fontsize=10, width=2.8, height=0.6, fixedsize=true];',
      [rowId, StringReplace(senders[i], '"', '\"', [rfReplaceAll])]));

    // nodos de celdas (visibles en naranja si hay conteo; invisibles si no)
    for j := 0 to dests.Count-1 do
    begin
      if counts[i][j] > 0 then
        W(Format(
          '    X_%d_%d [label="%d", shape=box, style=filled, fillcolor="orange", fontsize=11, width=1.0, height=0.6, fixedsize=true];',
          [i, j, counts[i][j]]))
      else
        W(Format(
          '    P_%d_%d [label="", shape=box, style=invis, width=1.0, height=0.6, fixedsize=true];',
          [i, j]));
    end;

    // alineación horizontal de la fila (de izquierda a derecha) — sin IfThen
    if dests.Count > 0 then
      W(Format('    %s -> %s [style=invis, weight=50];', [rowId, CellId(i,0)]));
    for j := 0 to dests.Count-2 do
      W(Format('    %s -> %s [style=invis, weight=50];', [CellId(i,j), CellId(i,j+1)]));

    W('  }');

    // conexiones visibles: remitente ↔ celda y celda ↔ cabecera
    for j := 0 to dests.Count-1 do
      if counts[i][j] > 0 then
      begin
        W(Format('  %s -> X_%d_%d [dir=both, arrowsize=0.5];', [rowId, i, j]));
        W(Format('  X_%d_%d -> C%d [dir=both, arrowsize=0.5];', [i, j, j]));
      end;
  end;



end.

