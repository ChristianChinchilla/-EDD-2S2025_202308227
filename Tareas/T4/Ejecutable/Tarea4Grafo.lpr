program Tarea4Grafo;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, Process, StrUtils;

type
  TAdjList = class
  private
    function FindCityIndex(const Name: string): Integer;
    function HasNeighbor(FromIdx: Integer; const NeighborName: string): Boolean;
    procedure AddNeighbor(FromIdx: Integer; const NeighborName: string; Weight: Integer);
    function EdgeLine(const A, B: string; Weight: Integer; WithWeights: Boolean): string;
    function ExtractNeighborName(const S: string): string;
    function ExtractNeighborWeight(const S: string): Integer;
  public
    Cities: TStringList;
    Adj: array of TStringList;
    constructor Create;
    destructor Destroy; override;
    function AddCity(const Name: string): Integer;
    procedure AddEdge(const A, B: string; const Weight: Integer = -1);
    procedure PrintAdjacency;
    procedure ExportDOT(const FileName: string; const WithWeights: Boolean);
  end;

constructor TAdjList.Create;
begin
  inherited Create;
  Cities := TStringList.Create;
  Cities.CaseSensitive := False;
  Cities.Duplicates := dupIgnore;
  SetLength(Adj, 0);
end;

destructor TAdjList.Destroy;
var
  i: Integer;
begin
  for i := 0 to High(Adj) do
    Adj[i].Free;
  Cities.Free;
  inherited Destroy;
end;

function TAdjList.FindCityIndex(const Name: string): Integer;
begin
  Result := Cities.IndexOf(Name);
end;

function TAdjList.AddCity(const Name: string): Integer;
var
  idx: Integer;
begin
  idx := FindCityIndex(Name);
  if idx = -1 then
  begin
    idx := Cities.Add(Name);
    SetLength(Adj, Length(Adj) + 1);
    Adj[idx] := TStringList.Create;
    Adj[idx].CaseSensitive := False;
  end;
  Result := idx;
end;

function TAdjList.ExtractNeighborName(const S: string): string;
var
  p: SizeInt;
begin
  p := Pos('=', S);
  if p > 0 then Result := Copy(S, 1, p - 1)
  else Result := S;
end;

function TAdjList.ExtractNeighborWeight(const S: string): Integer;
var
  p: SizeInt; w: string;
begin
  p := Pos('=', S);
  if p > 0 then
  begin
    w := Copy(S, p + 1, MaxInt);
    if TryStrToInt(Trim(w), Result) then Exit;
  end;
  Result := -1;
end;

function TAdjList.HasNeighbor(FromIdx: Integer; const NeighborName: string): Boolean;
var
  j: Integer;
begin
  Result := False;
  for j := 0 to Adj[FromIdx].Count - 1 do
    if SameText(ExtractNeighborName(Adj[FromIdx][j]), NeighborName) then Exit(True);
end;

procedure TAdjList.AddNeighbor(FromIdx: Integer; const NeighborName: string; Weight: Integer);
var
  entry: string;
begin
  if HasNeighbor(FromIdx, NeighborName) then Exit;
  if Weight >= 0 then entry := NeighborName + '=' + IntToStr(Weight)
  else entry := NeighborName;
  Adj[FromIdx].Add(entry);
end;

procedure TAdjList.AddEdge(const A, B: string; const Weight: Integer);
var
  ia, ib: Integer;
begin
  ia := AddCity(Trim(A));
  ib := AddCity(Trim(B));
  if ia = ib then Exit;
  AddNeighbor(ia, Cities[ib], Weight);
  AddNeighbor(ib, Cities[ia], Weight);
end;

procedure TAdjList.PrintAdjacency;
var
  i, j: Integer; neigh, nm: string; w: Integer;
begin
  Writeln('=== Lista de Adyacencia ===');
  for i := 0 to Cities.Count - 1 do
  begin
    Write(Cities[i], ' -> ');
    for j := 0 to Adj[i].Count - 1 do
    begin
      neigh := Adj[i][j]; nm := ExtractNeighborName(neigh); w := ExtractNeighborWeight(neigh);
      if w >= 0 then Write(Format('%s(%d)', [nm, w])) else Write(nm);
      if j < Adj[i].Count - 1 then Write(', ');
    end;
    Writeln;
  end;
end;

function TAdjList.EdgeLine(const A, B: string; Weight: Integer; WithWeights: Boolean): string;
begin
  if WithWeights and (Weight >= 0) then
    Result := Format('  "%s" -- "%s" [label="%d"];', [A, B, Weight])
  else
    Result := Format('  "%s" -- "%s";', [A, B]);
end;

procedure TAdjList.ExportDOT(const FileName: string; const WithWeights: Boolean);
var
  i, j, w, bIdx: Integer;
  neighName: string;
  f: TextFile;
  outName: string;
begin
  AssignFile(f, FileName); Rewrite(f);
  Writeln(f, 'graph G {');
  Writeln(f, '  // Layout vertical tipo árbol');
  Writeln(f, '  rankdir=TB;');
  Writeln(f, '  layout=dot; newrank=true; nodesep=0.6; ranksep=0.9; splines=false;');
  Writeln(f, '  node [shape=circle, style=filled, fillcolor=white, fixedsize=true, width=1.2, height=1.2];');
  for i := 0 to Cities.Count - 1 do
  begin
    Writeln(f, Format('  "%s";', [Cities[i]]));
    for j := 0 to Adj[i].Count - 1 do
    begin
      neighName := ExtractNeighborName(Adj[i][j]);
      bIdx := FindCityIndex(neighName);
      if (bIdx >= 0) and (i < bIdx) then
      begin
        w := ExtractNeighborWeight(Adj[i][j]);
        Writeln(f, EdgeLine(Cities[i], Cities[bIdx], w, WithWeights));
      end;
    end;
  end;
  Writeln(f, '}'); CloseFile(f);

  outName := ChangeFileExt(FileName, '.png');
  with TProcess.Create(nil) do
  try
    Executable := 'dot';
    Parameters.Add('-Kdot');
    Parameters.Add('-Tpng');
    Parameters.Add(FileName);
    Parameters.Add('-o');
    Parameters.Add(outName);
    Options := Options + [poWaitOnExit, poUsePipes];
    Execute;
    if ExitStatus = 0 then
      Writeln('Imagen generada: ', outName)
    else
      Writeln('No se pudo generar PNG (instala graphviz)');
  finally
    Free;
  end;
end;

procedure Pausa; begin Writeln; Write('Presiona ENTER para continuar...'); Readln; end;

procedure Menu;
begin
  Writeln('====================================');
  Writeln('   GRAFO NO DIRIGIDO (Lista Ady)');
  Writeln('====================================');
  Writeln('1) Agregar 1 ciudad');
  Writeln('2) Agregar 2 ciudades');
  Writeln('3) Agregar 3 ciudades');
  Writeln('4) Agregar 4 ciudades');
  Writeln('5) Agregar 1 conexion (arista)');
  Writeln('6) Agregar 2 conexiones');
  Writeln('7) Agregar 3 conexiones');
  Writeln('8) Agregar 4 conexiones');
  Writeln('9) Ver lista de adyacencia');
  Writeln('10) Exportar a DOT y PNG (Graphviz)');
  Writeln('0) Salir');
  Writeln('------------------------------------');
  Write('Elige una opcion: ');
end;

procedure AddNCities(G: TAdjList; N: Integer);
var
  i: Integer; name: string;
begin
  for i := 1 to N do
  begin
    Write(Format('Nombre de la ciudad %d: ', [i])); Readln(name);
    if Trim(name) <> '' then
    begin
      G.AddCity(name);
      Writeln('Ciudad agregada: ', name);
    end
    else Writeln('Nombre invalido. Omitido.');
  end;
end;

procedure AddNEdges(G: TAdjList; N: Integer);
var
  i, peso: Integer; a, b, s: string;
begin
  for i := 1 to N do
  begin
    Writeln(Format('--- Conexion %d ---', [i]));
    Write('Ciudad A: '); Readln(a);
    Write('Ciudad B: '); Readln(b);
    Write('Peso (ENTER si no aplica): '); Readln(s);
    if (Trim(s) <> '') and TryStrToInt(s, peso) then
      G.AddEdge(a, b, peso)
    else
      G.AddEdge(a, b);
    Writeln('Conexion agregada.');
  end;
end;

var
  G: TAdjList;
  op: string; fname: string;
begin
  G := TAdjList.Create;
  try
    repeat
      Menu;
      Readln(op);
      if      op = '1'  then begin AddNCities(G, 1); Pausa; end
      else if op = '2'  then begin AddNCities(G, 2); Pausa; end
      else if op = '3'  then begin AddNCities(G, 3); Pausa; end
      else if op = '4'  then begin AddNCities(G, 4); Pausa; end
      else if op = '5'  then begin AddNEdges(G, 1); Pausa; end
      else if op = '6'  then begin AddNEdges(G, 2); Pausa; end
      else if op = '7'  then begin AddNEdges(G, 3); Pausa; end
      else if op = '8'  then begin AddNEdges(G, 4); Pausa; end
      else if op = '9'  then begin G.PrintAdjacency; Pausa; end
      else if op = '10' then begin
        Write('Archivo DOT: '); Readln(fname);
        if Trim(fname) = '' then fname := 'grafo.dot';
        G.ExportDOT(fname, True); Pausa;
      end
      else if op = '0'  then Writeln('Saliendo...')
      else begin Writeln('Opcion no valida.'); Pausa; end;
    until op = '0';
  finally
    G.Free;
  end;
end.

