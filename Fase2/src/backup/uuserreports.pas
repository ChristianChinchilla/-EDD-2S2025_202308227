unit uUserReports;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

function GenerateAllUserReports(const AEmail: string; out ABaseDir: string): string;

implementation

uses
  FileUtil, Process,
  uData,           // GPapelera, GScheduled, GContacts, GCorreos, GDrafts, GFavorites, GetMailById
  uListaUsuarios,  // PUsuario, GUsuarios
  uListaCorreos;   // PCorreo, TListaCorreos (First/next)

{------------------- utilidades -------------------}
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

{------------------- CONTACTOS (lista circular, HORIZONTAL) -------------------}
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

{------------------- INBOX (lista doblemente enlazada) -------------------}
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

    // Recorrer la lista enlazada: First -> next
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

{------------------- PAPELERA (pila) -------------------}
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
    L.Add('  rankdir=TB;'); // pila vertical
    L.Add('  graph [fontname="Helvetica"]; node [shape=plaintext, fontname="Helvetica"];');
    L.Add('  labelloc="t"; label="Reporte de Papelera";');
    L.Add('  subgraph cluster0 { label="Pila"; style="rounded"; color="lightcoral";');

    logicalIdx := 0;

    // Tomar snapshot de la pila (de arriba hacia abajo)
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

{------------------- PROGRAMADOS (cola, VERTICAL) -------------------}
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
    L.Add('  rankdir=TB;'); // vertical
    L.Add('  graph [fontname="Helvetica"]; node [shape=plaintext, fontname="Helvetica"];');
    L.Add('  labelloc="t"; label="Reporte de Correos Programados";');
    L.Add('  subgraph cluster0 { label="Cola"; style="rounded"; color="lightskyblue";');

    logicalIdx := 0;

    // Recorrer la cola sin consumirla
    n := GScheduled.Count;
    while n > 0 do
    begin
      p := GScheduled.Dequeue;
      if p <> nil then
      begin
        if (p^.remitente = OwnerEmail) and (Trim(p^.programado) <> '') then
        begin
          Inc(logicalIdx);
          // Es cola de programados: “Programado: Sí”
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

{==================== FASE 2: BORRADORES (AVL) ====================}
procedure ExportDraftsAVL(const OwnerEmail, TargetDot, TargetPng: string);
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

  function HasAnyForOwner: Boolean;
  var j: Integer;
  begin
    Result := False;
    for j := 0 to T.Count-1 do
      if (PDraft(T[j])<>nil) and SameText(PDraft(T[j])^.remitente, OwnerEmail) then
        Exit(True);
  end;

begin
  L := TStringList.Create;
  T := TList.Create;
  try
    L.Add('digraph G {');
    L.Add('  graph [fontname="Helvetica"]; node [shape=box, style="rounded,filled", fillcolor="lightyellow", fontname="Helvetica"];');
    L.Add(Format('  label="Árbol AVL - borradores (%s)"; labelloc=t; fontsize=20;', [OwnerEmail]));

    GDrafts.ListIn(T); // listamos en-orden para tener todos los punteros

    if not HasAnyForOwner then
    begin
      L.Add('  Empty [label="(sin borradores)"];');
      L.Add('}');
      SaveAndMaybePng(TargetDot, TargetPng, L);
      Exit;
    end;

    // Nodos
    for i := 0 to T.Count-1 do
    begin
      D := PDraft(T[i]);
      if (D=nil) or (not SameText(D^.remitente, OwnerEmail)) then Continue;
      L.Add(Format('  %s [label="ID: %d\lDestinatario: %s\lAsunto: %s\lFecha: %s\lMensaje: %s\l"];',
        [NodeId(D), D^.id, Esc(D^.destinatario), Esc(D^.asunto), Esc(D^.fecha), Esc(D^.mensaje)]));
    end;

    // Aristas (left/right) solo si ambos pertenecen al mismo owner
    for i := 0 to T.Count-1 do
    begin
      D := PDraft(T[i]);
      if (D=nil) or (not SameText(D^.remitente, OwnerEmail)) then Continue;
      if (D^.left<>nil)  and SameText(D^.left^.remitente , OwnerEmail) then
        L.Add(Format('  %s -> %s;', [NodeId(D), NodeId(D^.left)]));
      if (D^.right<>nil) and SameText(D^.right^.remitente, OwnerEmail) then
        L.Add(Format('  %s -> %s;', [NodeId(D), NodeId(D^.right)]));
    end;

    L.Add('}');
    SaveAndMaybePng(TargetDot, TargetPng, L);
  finally
    T.Free;
    L.Free;
  end;
end;

{==================== FASE 2: FAVORITOS (ÁRBOL B visual) ====================}
procedure ExportFavoritesBTree(const OwnerEmail, TargetDot, TargetPng: string);
const
  ORDER = 5;                     // <<---- cambia aquí el orden del “B-tree”
  KEYS_PER_NODE = ORDER - 1;     // claves máximas por nodo
var
  ids   : TStringList;
  mails : array of PCorreo;
  n,i   : Integer;
  L     : TStringList;

  function Esc(const S: string): string; inline;
  begin
    Result := StringReplace(S, '"','\"',[rfReplaceAll]);
  end;

  procedure BuildVisualBTree;
  var
    take, idx, childNo, j: Integer;
    rootLbl, childLbl: string;
  begin
    L.Add('digraph G {');
    L.Add('  node [shape=record, style="rounded,filled", fillcolor="lightgreen", fontname="Helvetica"];');
    L.Add('  graph [fontname="Helvetica"];');
    L.Add(Format('  label="Árbol B (orden %d) - favoritos (%s)"; labelloc=t; fontsize=20;', [ORDER, OwnerEmail]));

    if n = 0 then
    begin
      L.Add('  Empty [label="(sin favoritos)"];');
      L.Add('}');
      Exit;
    end;

    // ----- Raíz: hasta KEYS_PER_NODE claves -----
    rootLbl := '';
    take := n; if take > KEYS_PER_NODE then take := KEYS_PER_NODE;
    for i := 0 to take-1 do
    begin
      if i>0 then rootLbl += '|';
      rootLbl += Format('{<k%d> %d | %s}', [i, mails[i]^.id, Esc(mails[i]^.asunto)]);
    end;
    L.Add(Format('  root [label="%s"];', [rootLbl]));

    // ----- Hijos: grupos de KEYS_PER_NODE (visual de 2 niveles) -----
    idx := take;
    childNo := 0;
    while idx < n do
    begin
      childLbl := '';
      for j := 0 to KEYS_PER_NODE-1 do
      begin
        if (idx+j) >= n then Break;
        if j>0 then childLbl += '|';
        childLbl += Format('{<k%d> %d | %s | %s}', [j, mails[idx+j]^.id,
                         Esc(mails[idx+j]^.remitente), Esc(mails[idx+j]^.asunto)]);
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
    ids.Sort;
    SetLength(mails, ids.Count);
    n := 0;
    for i := 0 to ids.Count-1 do
    begin
      mails[n] := GetMailById(StrToIntDef(ids[i], 0));
      if mails[n] <> nil then Inc(n);
    end;
    SetLength(mails, n);

    BuildVisualBTree;
    SaveAndMaybePng(TargetDot, TargetPng, L);
  finally
    ids.Free;
    L.Free;
  end;
end;


{------------------- ORQUESTADOR -------------------}
function GenerateAllUserReports(const AEmail: string; out ABaseDir: string): string;
var
  base, userSafe: string;
begin
  base     := 'Reportes' + DirectorySeparator + 'Usuario-Reportes';
  userSafe := Sanitize(AEmail);
  ABaseDir := base + DirectorySeparator + userSafe;
  ForceDirectories(ABaseDir);

  // Fase 1
  ExportInboxDOT     (AEmail, ABaseDir+DirectorySeparator+'inbox.dot',
                             ABaseDir+DirectorySeparator+'inbox.png');
  ExportTrashDOT     (AEmail, ABaseDir+DirectorySeparator+'papelera.dot',
                             ABaseDir+DirectorySeparator+'papelera.png');
  ExportScheduledDOT (AEmail, ABaseDir+DirectorySeparator+'programados.dot',
                             ABaseDir+DirectorySeparator+'programados.png');
  ExportContactsDOT  (AEmail, ABaseDir+DirectorySeparator+'contactos.dot',
                             ABaseDir+DirectorySeparator+'contactos.png');

  // Fase 2
  ExportDraftsAVL    (AEmail, ABaseDir+DirectorySeparator+'borradores_avl.dot',
                             ABaseDir+DirectorySeparator+'borradores_avl.png');
  ExportFavoritesBTree(AEmail, ABaseDir+DirectorySeparator+'favoritos_btree.dot',
                             ABaseDir+DirectorySeparator+'favoritos_btree.png');

  Result := ABaseDir;
end;

end.

