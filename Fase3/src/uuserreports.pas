unit uUserReports;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

function GenerateAllUserReports(const AEmail: string; out ABaseDir: string): string;

implementation

uses
  FileUtil, Process, Math, md5,
  uData,           // GPapelera, GScheduled, GContacts, GCorreos, GDrafts, GFavorites, GetMailById
  uListaUsuarios,  // PUsuario, GUsuarios
  uListaCorreos;   // PCorreo, TListaCorreos (First/next)

// ===================================================================
// Utilidades
// ===================================================================

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

// Pequeñas utilidades extra para Merkle
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

// ===================================================================
// CONTACTOS (lista circular, horizontal)
// ===================================================================

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

// ===================================================================
// INBOX (lista doblemente enlazada)
// ===================================================================

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

// ===================================================================
// PAPELERA (pila)
// ===================================================================

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

// ===================================================================
// PROGRAMADOS (cola, vertical)
// ===================================================================

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

// ===================================================================
// FASE 2: BORRADORES (AVL) — GLOBAL (todos los remitentes)
// ===================================================================

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

// ===================================================================
// FASE 2: BORRADORES (AVL) — POR USUARIO (remitente = OwnerEmail)
// ===================================================================

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

// ===================================================================
// FASE 2: FAVORITOS (Árbol B orden 5) — visual
// ===================================================================

procedure ExportFavoritesBTree(const OwnerEmail, TargetDot, TargetPng: string);
const
  ORDER = 5;
  KEYS_PER_NODE = ORDER - 1;
var
  ids   : TStringList;
  mails : array of PCorreo;
  n,i   : Integer;
  L     : TStringList;

  procedure SortIdsNumeric(Lst: TStringList);
  var i, j: Integer;
  begin
    for i := 0 to Lst.Count - 2 do
      for j := 0 to Lst.Count - i - 2 do
        if StrToIntDef(Lst[j], 0) > StrToIntDef(Lst[j + 1], 0) then
          Lst.Exchange(j, j + 1);
  end;

  function Esc(const S: string): string; inline;
  begin
    Result := StringReplace(S, '"','\"',[rfReplaceAll]);
  end;

  function LabelForMail(const M: PCorreo): string; inline;
  var fechaStr: string;
  begin
    if (M=nil) or (Trim(M^.fecha)='') then fechaStr := '(sin fecha)' else fechaStr := M^.fecha;
    Result :=
      'ID: '        + IntToStr(M^.id)       + '\l' +
      'Remitente: ' + Esc(M^.remitente)     + '\l' +
      'Asunto: '    + Esc(M^.asunto)        + '\l' +
      'Fecha: '     + Esc(fechaStr)         + '\l' +
      'Mensaje: '   + Esc(M^.mensaje)       + '\l';
  end;

  procedure BuildVisualBTree;
  var take, idx, childNo, j, k: Integer; rootLbl, childLbl: string;
  begin
    L.Add('digraph G {');
    L.Add('  graph [fontname="Helvetica"];');
    L.Add('  node  [shape=record, style="rounded,filled", fillcolor="lightgreen", fontname="Helvetica"];');
    L.Add(Format('  label="Árbol B (Orden %d) - Correos Favoritos (%s)"; labelloc=t; fontsize=20;', [ORDER, OwnerEmail]));

    if n = 0 then begin L.Add('  Empty [label="(sin favoritos)"];'); L.Add('}'); Exit; end;

    // Nodo raíz con hasta 4 claves
    rootLbl := '|';
    take := n; if take > KEYS_PER_NODE then take := KEYS_PER_NODE;
    for k := 0 to take-1 do rootLbl += '{' + LabelForMail(mails[k]) + '}|';
    L.Add(Format('  root [label="%s"];', [rootLbl]));

    // Hijos (bloques de 4)
    idx := take; childNo := 0;
    while idx < n do
    begin
      childLbl := '|';
      for j := 0 to KEYS_PER_NODE-1 do
      begin
        if (idx+j) >= n then Break;
        childLbl += '{' + LabelForMail(mails[idx+j]) + '}|';
      end;
      L.Add(Format('  c%d [label="%s"];', [childNo, childLbl]));
      L.Add(Format('  root -> c%d;', [childNo]));
      Inc(childNo);
      Inc(idx, KEYS_PER_NODE);
    end;

    L.Add('}');
  end;

begin
  L := TStringList.Create;
  ids := GFavorites.GetIdListCopy(OwnerEmail);
  try
    SortIdsNumeric(ids);

    // Inicializa y llena compacto
    SetLength(mails, ids.Count);
    n := 0;
    for i := 0 to ids.Count-1 do
    begin
      mails[n] := GetMailById(StrToIntDef(ids[i], 0));
      if mails[n] <> nil then Inc(n);
    end;
    SetLength(mails, n); // recorta a tamaño real

    BuildVisualBTree;
    SaveAndMaybePng(TargetDot, TargetPng, L);
  finally
    ids.Free;
    L.Free;
  end;
end;

// ===================================================================
// PRIVADOS -> Árbol de Merkle (hojas = correos favoritos del usuario)
// ===================================================================

procedure ExportMerklePrivados(const OwnerEmail, TargetDot, TargetPng: string);
type
  THashArray = array of string;

  function Esc(const S: string): string; inline;
  begin
    Result := StringReplace(S, '"','\"',[rfReplaceAll]);
  end;

  function Short(const S: string; N: Integer): string; inline;
  begin
    if Length(S) <= N then Exit(S);
    Result := Copy(S, 1, N) + '...';
  end;

  // Hash simple (no criptográfico) suficiente para ilustrar Merkle
  function SimpleHash(const S: string): string;
  var
    i: Integer; h: LongWord;
  begin
    h := 2166136261;
    for i := 1 to Length(S) do
    begin
      h := h xor Ord(S[i]);
      h := h * 16777619;
    end;
    Result := LowerCase(IntToHex(h, 8));
  end;

  function MailLabel(const M: PCorreo): string;
  var
    remit, asu, fec: string;
  begin
    if M = nil then
    begin
      Result :=
        'De: (no encontrado)\l' +
        'Asunto: (no encontrado)\l' +
        'Fecha: (no encontrado)\l';
      Exit;
    end;

    remit := Trim(M^.remitente);
    asu   := Trim(M^.asunto);
    fec   := Trim(M^.fecha);

    if remit = '' then remit := '(sin remitente)';
    if asu   = '' then asu   := '(sin asunto)';
    if fec   = '' then fec   := '(sin fecha)';

    Result :=
      'De: '     + Esc(Short(remit, 32)) + '\l' +
      'Asunto: ' + Esc(Short(asu,   38)) + '\l' +
      'Fecha: '  + Esc(Short(fec,   32)) + '\l';
  end;

var
  ids : TStringList;
  mails : array of PCorreo;
  leafH : THashArray;
  n,i   : Integer;
  L     : TStringList;

  // Construye niveles hasta llegar a la raíz
  function BuildLevel(const Prev: THashArray): THashArray;
  var
    i, j, outN: Integer;
    a, b: string;
  begin
    if Length(Prev) = 0 then Exit(nil);
    outN := (Length(Prev) + 1) div 2;
    SetLength(Result, outN);
    j := 0;
    for i := 0 to outN-1 do
    begin
      a := Prev[j]; Inc(j);
      if j < Length(Prev) then
      begin
        b := Prev[j]; Inc(j);
        Result[i] := SimpleHash(a + b);
      end
      else
        Result[i] := SimpleHash(a + a); // duplicar último si es impar
    end;
  end;

  procedure AddLeafNode(const idx: Integer; const M: PCorreo; const H: string);
  begin
    L.Add(Format(
      '  leaf%d [shape=box, style="rounded", fontname="Helvetica", '+
      'label="%sHash: %s"];',
      [idx, MailLabel(M), Esc(Short(H, 10))]));
  end;

  procedure AddInnerNode(const level, idx: Integer; const H: string);
  begin
    L.Add(Format(
      '  n_%d_%d [shape=box, style="rounded", fontname="Helvetica", '+
      'label="Hash: %s"];',
      [level, idx, Esc(Short(H, 10))]));
  end;

var
  curLevel, nextLevel : THashArray;
  level, idx, j       : Integer;
begin
  L := TStringList.Create;
  ids := GFavorites.GetIdListCopy(OwnerEmail);
  try
    // Recolectar correos favoritos (pueden no existir ya)
    SetLength(mails, ids.Count);
    SetLength(leafH, ids.Count);
    n := 0;
    for i := 0 to ids.Count-1 do
    begin
      mails[n] := GetMailById(StrToIntDef(ids[i], 0));
      if mails[n] <> nil then
        leafH[n] := SimpleHash(
          mails[n]^.remitente + '|' + mails[n]^.asunto + '|' + mails[n]^.fecha + '|' + mails[n]^.mensaje)
      else
        leafH[n] := SimpleHash('nil|' + ids[i]);
      Inc(n);
    end;
    SetLength(mails, n);
    SetLength(leafH, n);

    // DOT header
    L.Add('digraph G {');
    L.Add('  graph [fontname="Helvetica"];');
    L.Add('  labelloc="t"; label="Reporte de Árbol de Merkle";');
    L.Add('  subgraph cluster0 { label="Privados"; style="rounded"; color="gray70";');

    if n = 0 then
    begin
      L.Add('  Empty [label="(sin privados / favoritos)"];');
      L.Add('  }');
      L.Add('}');
      SaveAndMaybePng(TargetDot, TargetPng, L);
      Exit;
    end;

    // Hojas
    for i := 0 to n-1 do
      AddLeafNode(i, mails[i], leafH[i]);

    // Construcción de niveles
    curLevel := leafH;
    level := 0;
    while Length(curLevel) > 1 do
    begin
      nextLevel := BuildLevel(curLevel);

      // dibujar nodos de este nivel
      for idx := 0 to Length(nextLevel)-1 do
        AddInnerNode(level, idx, nextLevel[idx]);

      // conectar pares del nivel anterior con su nodo del nivel nuevo
      j := 0;
      for idx := 0 to Length(nextLevel)-1 do
      begin
        if level = 0 then
        begin
          L.Add(Format('  leaf%d -> n_%d_%d;', [j,     level, idx])); Inc(j);
          if j < Length(curLevel) then
            L.Add(Format('  leaf%d -> n_%d_%d;', [j,   level, idx]))
          else
            L.Add(Format('  leaf%d -> n_%d_%d;', [j-1, level, idx]));
          Inc(j);
        end
        else
        begin
          L.Add(Format('  n_%d_%d -> n_%d_%d;', [level-1, j,   level, idx])); Inc(j);
          if j < Length(curLevel) then
            L.Add(Format('  n_%d_%d -> n_%d_%d;', [level-1, j, level, idx]))
          else
            L.Add(Format('  n_%d_%d -> n_%d_%d;', [level-1, j-1, level, idx]));
          Inc(j);
        end;
      end;

      curLevel := nextLevel;
      Inc(level);
    end;

    // Raíz
    L.Add(Format('  root [shape=box, style="rounded", fontname="Helvetica", '+
                 'label="Hash: %s"];', [Esc(Short(curLevel[0], 10))]));
    if level = 0 then
      L.Add('  root -> leaf0;')
    else
      L.Add(Format('  root -> n_%d_%d;', [level-1, 0]));

    L.Add('  }'); // cluster
    L.Add('}');
    SaveAndMaybePng(TargetDot, TargetPng, L);
  finally
    ids.Free;
    L.Free;
  end;
end;

// ===================================================================
// ORQUESTADOR: genera TODOS los reportes del usuario
// ===================================================================

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
  ExportMerklePrivados (AEmail, ABaseDir+DirectorySeparator+'privados_merkle.dot',
                               ABaseDir+DirectorySeparator+'privados_merkle.png');

  // ── Fase 2 (GLOBAL: todos los remitentes con borradores)
  globalDir := 'Reportes' + DirectorySeparator + 'Global';
  ForceDirectories(globalDir);
  ExportAllDraftsAVL(globalDir + DirectorySeparator + 'borradores_avl_global.dot',
                     globalDir + DirectorySeparator + 'borradores_avl_global.png');

  Result := ABaseDir;
end;

end.

