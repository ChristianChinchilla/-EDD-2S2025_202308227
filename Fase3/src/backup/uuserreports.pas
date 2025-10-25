unit uUserReports;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

function GenerateAllUserReports(const AEmail: string; out ABaseDir: string): string;
procedure ExportBlockchainDOT(const TargetDot, TargetPng: string);

implementation

uses
  FileUtil, Process, Math, md5,
  uData,           // GPapelera, GScheduled, GContacts, GCorreos, GDrafts, GetMailById, GBlockchain
  uListaUsuarios,  // PUsuario, GUsuarios
  uListaCorreos,   // PCorreo, TListaCorreos (First/Next)
  uBlockchain;

{ ===================================================================
  Utilidades
  =================================================================== }

function Sanitize(const S: string): string;
var
  i: Integer;
begin
  Result := '';
  for i := 1 to Length(S) do
    if S[i] in ['a'..'z','A'..'Z','0'..'9','-','_','@','.'] then
      Result += S[i]
    else
      Result += '_';
end;

function HTMLEscape(const S: string): string;
var
  i: Integer;
  c: Char;
begin
  Result := '';
  for i := 1 to Length(S) do
  begin
    c := S[i];
    case c of
      '&' : Result += '&amp;';
      '<' : Result += '&lt;';
      '>' : Result += '&gt;';
      '"' : Result += '&quot;';
      '''': Result += '&#39;';
    else
      Result += c;
    end;
  end;
end;

procedure RunDot(const dotFile, pngFile: string);
var
  P  : TProcess;
  Exe: string;
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

procedure SaveAndMaybePng(const Dot, Png: string; Lines: TStrings);
begin
  ForceDirectories(ExtractFileDir(Dot));
  Lines.SaveToFile(Dot);
  RunDot(Dot, Png);
end;

function MD5Hex(const S: string): string; inline;
var D: TMD5Digest;
begin
  D := MD5String(S);
  Result := LowerCase(MD5Print(D));
end;

function Trunc8(const H: string): string; inline;
begin
  if Length(H) <= 8 then Result := H else Result := Copy(H, 1, 8) + '...';
end;

{ ===================================================================
  CONTACTOS (lista circular, horizontal)
  =================================================================== }

procedure ExportContactsDOT(const OwnerEmail, TargetDot, TargetPng: string);
var
  L, List : TStringList;
  i       : Integer;
  mail    : string;
  U       : PUsuario;
begin
  L := TStringList.Create;
  try
    L.Add('digraph G {');
    L.Add('  rankdir=LR;');
    L.Add('  graph [fontname="Helvetica"]; node [shape=plaintext, fontname="Helvetica"];');
    L.Add('  labelloc="t"; label="Reporte de Contactos";');
    L.Add('  subgraph cluster0 { label="Lista Circular"; style="rounded"; color="lightsteelblue";');
    L.Add('  edge [dir="both"];');

    List := GContacts.GetListCopy(OwnerEmail);
    try
      if (List=nil) or (List.Count=0) then
        L.Add('  Empty [label="(sin contactos)"];')
      else
      begin
        for i := 0 to List.Count-1 do
        begin
          mail := List[i];
          U := GUsuarios.FindByEmail(mail);
          if U<>nil then
            L.Add(Format(
              '  n%d [label=<<table border="0" cellborder="1" cellspacing="0" bgcolor="#cfe8ff">'+
              '<tr><td><b>ID:</b> %d</td></tr>'+
              '<tr><td><b>Nombre:</b> %s</td></tr>'+
              '<tr><td><b>Usuario:</b> %s</td></tr>'+
              '<tr><td><b>Email:</b> %s</td></tr>'+
              '<tr><td><b>Teléfono:</b> %s</td></tr>'+
              '</table>>];',
              [i+1, i+1, HTMLEscape(U^.nombre), HTMLEscape(U^.usuario),
                     HTMLEscape(U^.email),  HTMLEscape(U^.telefono)]))
          else
            L.Add(Format(
              '  n%d [label=<<table border="0" cellborder="1" cellspacing="0" bgcolor="#cfe8ff">'+
              '<tr><td><b>ID:</b> %d</td></tr>'+
              '<tr><td><b>Email:</b> %s</td></tr>'+
              '<tr><td>(no encontrado)</td></tr></table>>];',
              [i+1, i+1, HTMLEscape(mail)]));
        end;

        for i := 0 to List.Count-1 do
          L.Add(Format('  n%d -> n%d;', [i+1, ((i+1) mod List.Count)+1]));
      end;
    finally
      List.Free;
    end;

    L.Add('  }'); L.Add('}');
    SaveAndMaybePng(TargetDot, TargetPng, L);
  finally
    L.Free;
  end;
end;

{ ===================================================================
  INBOX (lista doblemente enlazada)
  =================================================================== }

procedure ExportInboxDOT(const OwnerEmail, TargetDot, TargetPng: string);
var
  L          : TStringList;
  logicalIdx : Integer;

  procedure AddCorreoNode(const NId, Id: Integer;
                          const Remitente, Estado, ProgSN, Asunto, Fecha, Mensaje: string);
  begin
    L.Add(Format(
      '  n%d [label=<<table border="0" cellborder="1" cellspacing="0" bgcolor="#fff7cc">'+
      '<tr><td><b>ID:</b> %d</td></tr>'+
      '<tr><td><b>Remitente:</b> %s</td></tr>'+
      '<tr><td><b>Estado:</b> %s</td></tr>'+
      '<tr><td><b>Programado:</b> %s</td></tr>'+
      '<tr><td><b>Asunto:</b> %s</td></tr>'+
      '<tr><td><b>Fecha:</b> %s</td></tr>'+
      '<tr><td><b>Mensaje:</b> %s</td></tr></table>>];',
      [NId, Id, HTMLEscape(Remitente), HTMLEscape(Estado), HTMLEscape(ProgSN),
       HTMLEscape(Asunto), HTMLEscape(Fecha), HTMLEscape(Mensaje)]));
  end;

var
  p      : PCorreo;
  progSN : string;
  i      : Integer;
begin
  L := TStringList.Create;
  try
    L.Add('digraph G {');
    L.Add('  rankdir=LR;');
    L.Add('  graph [fontname="Helvetica"]; node [shape=plaintext, fontname="Helvetica"];');
    L.Add('  labelloc="t"; label="Reporte de Correos Recibidos";');
    L.Add('  subgraph cluster0 { label="Lista Doblemente Enlazada"; style="rounded"; color="gray70";');
    L.Add('  edge [dir="both"];');

    logicalIdx := 0;

    p := GCorreos.First;
    while p <> nil do
    begin
      if (p^.destinatario = OwnerEmail) and (UpperCase(p^.estado) <> 'EL') then
      begin
        Inc(logicalIdx);
        if Trim(p^.programado) <> '' then progSN := 'Sí' else progSN := 'No';
        AddCorreoNode(logicalIdx, p^.id, p^.remitente, p^.estado, progSN,
                      p^.asunto, p^.fecha, p^.mensaje);
      end;
      p := p^.next;
    end;

    if logicalIdx = 0 then
      L.Add('  Empty [label="(sin correos)"];')
    else
      for i := 1 to logicalIdx-1 do
        L.Add(Format('  n%d -> n%d;', [i, i+1]));

    L.Add('  }'); L.Add('}');
    SaveAndMaybePng(TargetDot, TargetPng, L);
  finally
    L.Free;
  end;
end;

{ ===================================================================
  PAPELERA (pila)
  =================================================================== }

procedure ExportTrashDOT(const OwnerEmail, TargetDot, TargetPng: string);
var
  L          : TStringList;
  logicalIdx : Integer;
  A          : TPCorreoArray;
  i          : Integer;

  procedure AddCorreoNode(const NId, Id: Integer;
                          const Remitente, EstadoLegible, ProgSN, Asunto, Fecha, Mensaje: string);
  begin
    L.Add(Format(
      '  n%d [label=<<table border="0" cellborder="1" cellspacing="0" bgcolor="#ffd6d6">'+
      '<tr><td><b>ID:</b> %d</td></tr>'+
      '<tr><td><b>Remitente:</b> %s</td></tr>'+
      '<tr><td><b>Estado:</b> %s</td></tr>'+
      '<tr><td><b>Programado:</b> %s</td></tr>'+
      '<tr><td><b>Asunto:</b> %s</td></tr>'+
      '<tr><td><b>Fecha:</b> %s</td></tr>'+
      '<tr><td><b>Mensaje:</b> %s</td></tr></table>>];',
      [NId, Id, HTMLEscape(Remitente), HTMLEscape(EstadoLegible), HTMLEscape(ProgSN),
       HTMLEscape(Asunto), HTMLEscape(Fecha), HTMLEscape(Mensaje)]));
  end;

var
  progSN: string;
begin
  L := TStringList.Create;
  try
    L.Add('digraph G {');
    L.Add('  rankdir=TB;');
    L.Add('  graph [fontname="Helvetica"]; node [shape=plaintext, fontname="Helvetica"];');
    L.Add('  labelloc="t"; label="Reporte de Papelera";');
    L.Add('  subgraph cluster0 { label="Pila"; style="rounded"; color="lightcoral";');

    logicalIdx := 0;

    A := GPapelera.Snapshot;

    for i := 0 to High(A) do
      if (A[i] <> nil) and (A[i]^.destinatario = OwnerEmail) then
      begin
        Inc(logicalIdx);
        if Trim(A[i]^.programado) <> '' then progSN := 'Sí' else progSN := 'No';
        AddCorreoNode(logicalIdx, A[i]^.id, A[i]^.remitente, 'Eliminado', progSN,
                      A[i]^.asunto, A[i]^.fecha, A[i]^.mensaje);
      end;

    if logicalIdx = 0 then
      L.Add('  Empty [label="(papelera vacía)"];')
    else
      for i := 1 to logicalIdx-1 do
        L.Add(Format('  n%d -> n%d;', [i, i+1]));

    L.Add('  }'); L.Add('}');
    SaveAndMaybePng(TargetDot, TargetPng, L);
  finally
    L.Free;
  end;
end;

{ ===================================================================
  PROGRAMADOS (cola, vertical)
  =================================================================== }

procedure ExportScheduledDOT(const OwnerEmail, TargetDot, TargetPng: string);
var
  L          : TStringList;
  logicalIdx : Integer;
  i          : Integer;

  procedure AddCorreoNode(const NId, Id: Integer;
                          const Remitente, ProgSN, Asunto, Fecha, Mensaje: string);
  begin
    L.Add(Format(
      '  n%d [label=<<table border="0" cellborder="1" cellspacing="0" bgcolor="#d6f0ff">'+
      '<tr><td><b>ID:</b> %d</td></tr>'+
      '<tr><td><b>Remitente:</b> %s</td></tr>'+
      '<tr><td><b>Estado:</b> Programado</td></tr>'+
      '<tr><td><b>Programado:</b> %s</td></tr>'+
      '<tr><td><b>Asunto:</b> %s</td></tr>'+
      '<tr><td><b>Fecha:</b> %s</td></tr>'+
      '<tr><td><b>Mensaje:</b> %s</td></tr></table>>];',
      [NId, Id, HTMLEscape(Remitente), HTMLEscape(ProgSN),
       HTMLEscape(Asunto), HTMLEscape(Fecha), HTMLEscape(Mensaje)]));
  end;

var
  p : PCorreo;
  n : Integer;
begin
  L := TStringList.Create;
  try
    L.Add('digraph G {');
    L.Add('  rankdir=TB;');
    L.Add('  graph [fontname="Helvetica"]; node [shape=plaintext, fontname="Helvetica"];');
    L.Add('  labelloc="t"; label="Reporte de Correos Programados";');
    L.Add('  subgraph cluster0 { label="Cola"; style="rounded"; color="lightskyblue";');

    logicalIdx := 0;

    n := GScheduled.Count;
    while n > 0 do
    begin
      p := GScheduled.Dequeue;
      if p <> nil then
      begin
        if (p^.remitente = OwnerEmail) and (Trim(p^.programado) <> '') then
        begin
          Inc(logicalIdx);
          AddCorreoNode(logicalIdx, p^.id, p^.remitente, 'Sí',
                        p^.asunto, p^.fecha, p^.mensaje);
        end;
        GScheduled.Enqueue(p);
      end;
      Dec(n);
    end;

    if logicalIdx = 0 then
      L.Add('  Empty [label="(sin programados)"];')
    else
      for i := 1 to logicalIdx-1 do
        L.Add(Format('  n%d -> n%d [arrowhead=vee];', [i, i+1]));

    L.Add('  }'); L.Add('}');
    SaveAndMaybePng(TargetDot, TargetPng, L);
  finally
    L.Free;
  end;
end;

{ ===================================================================
  FASE 2: BORRADORES (AVL) — GLOBAL
  =================================================================== }

procedure ExportAllDraftsAVL(const TargetDot, TargetPng: string);
var
  L  : TStringList;
  T  : TList;
  i  : Integer;
  D  : PDraft;

  function NodeId(const N: PDraft): string; inline;
  begin
    Result := 'n' + IntToStr(N^.id);
  end;

  function Esc(const S: string): string; inline;
  begin
    Result := StringReplace(S, '"','\"',[rfReplaceAll]);
  end;

  function HasAnyDraft: Boolean;
  var j: Integer;
  begin
    Result := False;
    for j := 0 to T.Count-1 do
      if PDraft(T[j]) <> nil then Exit(True);
  end;

begin
  L := TStringList.Create;
  T := TList.Create;
  try
    L.Add('digraph G {');
    L.Add('  rankdir=TB;');
    L.Add('  graph [fontname="Helvetica", nodesep="0.35", ranksep="0.5"];');
    L.Add('  node [shape=box, style="rounded,filled", fillcolor="lightyellow", fontname="Helvetica"];');
    L.Add('  labelloc="t";');
    L.Add('  label="Árbol AVL - Borradores (todos los remitentes)";');

    GDrafts.ListIn(T);

    if not HasAnyDraft then
    begin
      L.Add('  Empty [label="(sin borradores)"];');
      L.Add('}');
      SaveAndMaybePng(TargetDot, TargetPng, L);
      Exit;
    end;

    // NODOS
    for i := 0 to T.Count-1 do
    begin
      D := PDraft(T[i]);
      if D = nil then Continue;
      L.Add(Format(
        '  %s [label="ID: %d\lRemitente: %s\lAsunto: %s\lFecha: %s\lMensaje: %s\l"];',
        [ NodeId(D),
          D^.id,
          Esc(D^.remitente),
          Esc(D^.asunto),
          Esc(D^.fecha),
          Esc(D^.mensaje)
        ]));
    end;

    // ARISTAS
    for i := 0 to T.Count-1 do
    begin
      D := PDraft(T[i]);
      if D = nil then Continue;
      if D^.left  <> nil then
        L.Add(Format('  %s -> %s;', [NodeId(D), NodeId(D^.left)]));
      if D^.right <> nil then
        L.Add(Format('  %s -> %s;', [NodeId(D), NodeId(D^.right)]));
    end;

    L.Add('}');
    SaveAndMaybePng(TargetDot, TargetPng, L);
  finally
    T.Free;
    L.Free;
  end;
end;

{ ===================================================================
  FASE 2: BORRADORES (AVL) — POR USUARIO
  =================================================================== }

procedure ExportDraftsAVL(const OwnerEmail, TargetDot, TargetPng: string);
var
  L  : TStringList;
  T  : TList;
  i  : Integer;
  D  : PDraft;

  function NodeId(const N: PDraft): string; inline;
  begin
    Result := 'u' + IntToStr(N^.id);
  end;

  function Esc(const S: string): string; inline;
  begin
    Result := StringReplace(S, '"','\"',[rfReplaceAll]);
  end;

  function HasAnyForUser: Boolean;
  var j: Integer; P: PDraft;
  begin
    Result := False;
    for j := 0 to T.Count-1 do
    begin
      P := PDraft(T[j]);
      if (P <> nil) and (CompareText(Trim(P^.remitente), Trim(OwnerEmail)) = 0) then
        Exit(True);
    end;
  end;

begin
  L := TStringList.Create;
  T := TList.Create;
  try
    L.Add('digraph G {');
    L.Add('  rankdir=TB;');
    L.Add('  graph [fontname="Helvetica", nodesep="0.35", ranksep="0.5"];');
    L.Add('  node [shape=box, style="rounded,filled", fillcolor="lightgoldenrod1", fontname="Helvetica"];');
    L.Add(Format('  labelloc="t"; label="Árbol AVL - Borradores (%s)";', [OwnerEmail]));

    GDrafts.ListIn(T);

    if not HasAnyForUser then
    begin
      L.Add('  Empty [label="(sin borradores del usuario)"];');
      L.Add('}');
      SaveAndMaybePng(TargetDot, TargetPng, L);
      Exit;
    end;

    // NODOS (solo del usuario)
    for i := 0 to T.Count-1 do
    begin
      D := PDraft(T[i]);
      if (D=nil) or (CompareText(Trim(D^.remitente), Trim(OwnerEmail))<>0) then Continue;
      L.Add(Format(
        '  %s [label="ID: %d\lAsunto: %s\lFecha: %s\lMensaje: %s\l"];',
        [ NodeId(D), D^.id, Esc(D^.asunto), Esc(D^.fecha), Esc(D^.mensaje) ]));
    end;

    // ARISTAS (si ambos extremos pertenecen al usuario)
    for i := 0 to T.Count-1 do
    begin
      D := PDraft(T[i]);
      if (D=nil) or (CompareText(Trim(D^.remitente), Trim(OwnerEmail))<>0) then Continue;
      if (D^.left  <> nil) and (CompareText(Trim(D^.left^.remitente),  Trim(OwnerEmail))=0) then
        L.Add(Format('  %s -> %s;', [NodeId(D), NodeId(D^.left)]));
      if (D^.right <> nil) and (CompareText(Trim(D^.right^.remitente), Trim(OwnerEmail))=0) then
        L.Add(Format('  %s -> %s;', [NodeId(D), NodeId(D^.right)]));
    end;

    L.Add('}');
    SaveAndMaybePng(TargetDot, TargetPng, L);
  finally
    T.Free;
    L.Free;
  end;
end;

{ ===================================================================
  FAVORITOS (BTree) — Placeholder temporal
  =================================================================== }

procedure ExportFavoritesBTree(const OwnerEmail, TargetDot, TargetPng: string);
var
  L: TStringList;
begin
  L := TStringList.Create;
  try
    L.Add('digraph G {');
    L.Add('  rankdir=TB;');
    L.Add('  graph [fontname="Helvetica"];');
    L.Add(Format('  label="Árbol B de Favoritos (%s)"; labelloc=t;', [OwnerEmail]));
    L.Add('  node [shape=box, style="rounded,filled", fillcolor="lightblue"];');
    L.Add('  Empty [label="(sin favoritos o función no implementada)"];');
    L.Add('}');
    SaveAndMaybePng(TargetDot, TargetPng, L);
  finally
    L.Free;
  end;
end;

{ ===================================================================
  ÁRBOL DE MERKLE DE PRIVADOS — Implementación
  =================================================================== }

procedure ExportMerklePrivados(const OwnerEmail, TargetDot, TargetPng: string);
type
  TLeaf = record
    Id   : string;
    Hash : string;
  end;
var
  L           : TStringList;
  Leaves      : array of TLeaf;
  p           : PCorreo;
  leafCount   : Integer;
  payload     : string;  // <- movidos al var de la procedure (sin var inline)
  h           : string;

  function HtmlEsc(const S: string): string; inline;
  begin
    Result := HTMLEscape(S);
  end;

  function MakeParentId(levelIdx, pairIdx: Integer): string; inline;
  begin
    Result := Format('n_%d_%d', [levelIdx, pairIdx]);
  end;

  procedure AddLeafNode(const Id, Remi, Asun, Fec, H: string);
  begin
    L.Add(Format(
      '  %s [shape=box, style="rounded", label=<<table border="0" cellborder="1" cellspacing="0">'+
      '<tr><td align="left"><b>De:</b> %s</td></tr>'+
      '<tr><td align="left"><b>Asunto:</b> %s</td></tr>'+
      '<tr><td align="left"><b>Fecha:</b> %s</td></tr>'+
      '<tr><td align="left"><b>Hash:</b> %s</td></tr>'+
      '</table>>];',
      [ Id, HtmlEsc(Remi), HtmlEsc(Asun), HtmlEsc(Fec), HtmlEsc(Trunc8(H)) ]));
  end;

  procedure BuildUpperLevels;
  var
    curLevel, nextLevel : Integer;
    curCount, k         : Integer;
    ids                 : array of string;
    hs                  : array of string;
    leftH, rightH, parH : string;
    parId, leftId, rightId: string;
    needPad             : Boolean;
    idx                 : Integer; // evita "Illegal counter variable"

    LevelIds    : array of array of string;
    LevelHashes : array of array of string;
  begin
    // Nivel 0: copio Leaves -> LevelIds/LevelHashes
    SetLength(LevelIds,    1);
    SetLength(LevelHashes, 1);
    SetLength(LevelIds[0],    Length(Leaves));
    SetLength(LevelHashes[0], Length(Leaves));

    for idx := 0 to High(Leaves) do
    begin
      LevelIds[0][idx]    := Leaves[idx].Id;
      LevelHashes[0][idx] := Leaves[idx].Hash;
    end;

    curLevel := 0;

    if Length(LevelHashes[0]) <= 1 then Exit;

    while Length(LevelHashes[curLevel]) > 1 do
    begin
      ids := LevelIds[curLevel];
      hs  := LevelHashes[curLevel];

      curCount := Length(hs);
      needPad := (curCount mod 2 = 1);
      if needPad then
      begin
        SetLength(ids, curCount+1);
        SetLength(hs,  curCount+1);
        ids[curCount] := ids[curCount-1];
        hs[curCount]  := hs[curCount-1];
        Inc(curCount);
      end;

      nextLevel := curLevel + 1;
      SetLength(LevelIds,    nextLevel+1);
      SetLength(LevelHashes, nextLevel+1);
      SetLength(LevelIds[nextLevel],    curCount div 2);
      SetLength(LevelHashes[nextLevel], curCount div 2);

      k := 0;
      while k < curCount do
      begin
        leftH   := hs[k];
        rightH  := hs[k+1];
        parH    := MD5Hex(leftH + rightH);

        leftId  := ids[k];
        rightId := ids[k+1];
        parId   := MakeParentId(nextLevel, k div 2);

        LevelIds[nextLevel][k div 2]    := parId;
        LevelHashes[nextLevel][k div 2] := parH;

        L.Add(Format('  %s [shape=box, style="rounded", label="Hash: %s"];',
                     [parId, HtmlEsc(Trunc8(parH))]));
        L.Add(Format('  %s -> %s;', [parId, leftId]));
        L.Add(Format('  %s -> %s;', [parId, rightId]));

        Inc(k, 2);
      end;

      curLevel := nextLevel;
    end;

    if (Length(LevelHashes[curLevel]) = 1) then
    begin
      L.Add(Format('  root [shape=box, style="rounded,bold", label="Hash: %s"];',
                   [HtmlEsc(Trunc8(LevelHashes[curLevel][0]))]));
      L.Add(Format('  root -> %s;', [LevelIds[curLevel][0]]));
    end;
  end;

begin
  L := TStringList.Create;
  try
    L.Add('digraph G {');
    L.Add('  rankdir=TB;');
    L.Add('  graph [fontname="Helvetica"];');
    L.Add('  node  [fontname="Helvetica"];');
    L.Add(Format('  labelloc="t"; label="Árbol de Merkle de Privados (%s)";', [OwnerEmail]));

    SetLength(Leaves, 0);
    p := GCorreos.First;
    leafCount := 0;
    while p <> nil do
    begin
      if (CompareText(Trim(p^.destinatario), Trim(OwnerEmail)) = 0) and
         (UpperCase(Trim(p^.estado)) = 'PR') then
      begin
        // Hash de la hoja
        payload := IntToStr(p^.id) + '|' + p^.remitente + '|' +
                   p^.asunto + '|' + p^.fecha + '|' + p^.mensaje;
        h := MD5Hex(payload);

        SetLength(Leaves, leafCount+1);
        Leaves[leafCount].Id   := 'leaf_' + IntToStr(p^.id);
        Leaves[leafCount].Hash := h;

        AddLeafNode(Leaves[leafCount].Id, p^.remitente, p^.asunto, p^.fecha, h);
        Inc(leafCount);
      end;
      p := p^.next;
    end;

    if leafCount = 0 then
    begin
      L.Add('  Empty [label="(sin privados)"];');
      L.Add('}');
      SaveAndMaybePng(TargetDot, TargetPng, L);
      Exit;
    end;

    BuildUpperLevels;

    L.Add('}');
    SaveAndMaybePng(TargetDot, TargetPng, L);
  finally
    L.Free;
  end;
end;

{ ===================================================================
  BLOCKCHAIN -> Reporte (expuesto para Root)
  =================================================================== }

procedure ExportBlockchainDOT(const TargetDot, TargetPng: string);
begin
  if Assigned(GBlockchain) then
    GBlockchain.ToDOT(TargetDot, TargetPng);
end;

{ ===================================================================
  ORQUESTADOR
  =================================================================== }

function GenerateAllUserReports(const AEmail: string; out ABaseDir: string): string;
var
  base, userSafe, globalDir: string;
begin
  // Carpeta por usuario
  base     := 'Reportes' + DirectorySeparator + 'Usuario-Reportes';
  userSafe := Sanitize(AEmail);
  ABaseDir := base + DirectorySeparator + userSafe;
  ForceDirectories(ABaseDir);

  // ── Fase 1 (por usuario)
  ExportInboxDOT     (AEmail, ABaseDir+DirectorySeparator+'inbox.dot',
                             ABaseDir+DirectorySeparator+'inbox.png');
  ExportTrashDOT     (AEmail, ABaseDir+DirectorySeparator+'papelera.dot',
                             ABaseDir+DirectorySeparator+'papelera.png');
  ExportScheduledDOT (AEmail, ABaseDir+DirectorySeparator+'programados.dot',
                             ABaseDir+DirectorySeparator+'programados.png');
  ExportContactsDOT  (AEmail, ABaseDir+DirectorySeparator+'contactos.dot',
                             ABaseDir+DirectorySeparator+'contactos.png');

  // ── Fase 2 (por usuario)
  ExportDraftsAVL      (AEmail, ABaseDir+DirectorySeparator+'borradores_avl.dot',
                               ABaseDir+DirectorySeparator+'borradores_avl.png');
  ExportFavoritesBTree (AEmail, ABaseDir+DirectorySeparator+'favoritos_btree.dot',
                               ABaseDir+DirectorySeparator+'favoritos_btree.png');

  // ── Fase 2 (GLOBAL)
  globalDir := 'Reportes' + DirectorySeparator + 'Global';
  ForceDirectories(globalDir);
  ExportAllDraftsAVL(globalDir + DirectorySeparator + 'borradores_avl_global.dot',
                     globalDir + DirectorySeparator + 'borradores_avl_global.png');

  // ── Extra: Árbol de Merkle de privados
  ExportMerklePrivados(AEmail, ABaseDir+DirectorySeparator+'privados_merkle.dot',
                               ABaseDir+DirectorySeparator+'privados_merkle.png');

  // *** Ya NO se genera blockchain aquí ***
  Result := ABaseDir;
end;

end.

