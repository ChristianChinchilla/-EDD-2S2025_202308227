unit uUserReports;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

function GenerateAllUserReports(const AEmail: string; out ABaseDir: string): string;

implementation

uses
  FileUtil, Process,
<<<<<<< HEAD
  uData,
  uListaUsuarios,
  uListaCorreos;

=======
  uData,            // GPapelera, GScheduled, GContacts, GCorreos
  uListaUsuarios,   // PUsuario, GUsuarios
  uListaCorreos;    // PCorreo, TListaCorreos (First/next)

{------------------- utilidades -------------------}
>>>>>>> 93f5b82 (Fase1)
function Sanitize(const S: string): string;
var i: Integer;
begin
  Result := '';
  for i := 1 to Length(S) do
<<<<<<< HEAD
    if S[i] in ['a'..'z','A'..'Z','0'..'9','-','_','@','.'] then Result += S[i]
    else Result += '_';
=======
    if S[i] in ['a'..'z','A'..'Z','0'..'9','-','_','@','.'] then
      Result += S[i]
    else
      Result += '_';
>>>>>>> 93f5b82 (Fase1)
end;

function HTMLEscape(const S: string): string;
var i: Integer; c: Char;
begin
  Result := '';
  for i := 1 to Length(S) do
  begin
    c := S[i];
    case c of
<<<<<<< HEAD
      '&': Result += '&amp;';
      '<': Result += '&lt;';
      '>': Result += '&gt;';
      '"': Result += '&quot;';
=======
      '&' : Result += '&amp;';
      '<' : Result += '&lt;';
      '>' : Result += '&gt;';
      '"' : Result += '&quot;';
>>>>>>> 93f5b82 (Fase1)
      '''': Result += '&#39;';
    else
      Result += c;
    end;
  end;
end;

procedure RunDot(const dotFile, pngFile: string);
<<<<<<< HEAD
var P: TProcess; Exe: string;
=======
var P  : TProcess; Exe: string;
>>>>>>> 93f5b82 (Fase1)
begin
  Exe := FindDefaultExecutablePath('dot'); if Exe = '' then Exe := 'dot';
  P := TProcess.Create(nil);
  try
    P.Executable := Exe;
    P.Parameters.Add('-Tpng');
    P.Parameters.Add(dotFile);
<<<<<<< HEAD
    P.Parameters.Add('-o');
    P.Parameters.Add(pngFile);
=======
    P.Parameters.Add('-o'); P.Parameters.Add(pngFile);
>>>>>>> 93f5b82 (Fase1)
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

<<<<<<< HEAD
{-------------------- Contactos (lista circular, horizontal) ------------------}
procedure ExportContactsDOT(const OwnerEmail, TargetDot, TargetPng: string);
var
  L, List: TStringList;
  i: Integer;
  mail: string;
  U: PUsuario;
=======
{------------------- CONTACTOS (lista circular, HORIZONTAL) -------------------}
procedure ExportContactsDOT(const OwnerEmail, TargetDot, TargetPng: string);
var
  L, List : TStringList;
  i       : Integer;
  mail    : string;
  U       : PUsuario;
>>>>>>> 93f5b82 (Fase1)
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
<<<<<<< HEAD
      if (List = nil) or (List.Count = 0) then
        L.Add('  Empty [label="(sin contactos)"];')
      else
      begin
        for i := 0 to List.Count - 1 do
        begin
          mail := List[i];
          U := GUsuarios.FindByEmail(mail);
          if U <> nil then
=======
      if (List=nil) or (List.Count=0) then
        L.Add('  Empty [label="(sin contactos)"];')
      else
      begin
        for i := 0 to List.Count-1 do
        begin
          mail := List[i];
          U := GUsuarios.FindByEmail(mail);
          if U<>nil then
>>>>>>> 93f5b82 (Fase1)
            L.Add(Format(
              '  n%d [label=<<table border="0" cellborder="1" cellspacing="0" bgcolor="#cfe8ff">'+
              '<tr><td><b>ID:</b> %d</td></tr>'+
              '<tr><td><b>Nombre:</b> %s</td></tr>'+
              '<tr><td><b>Usuario:</b> %s</td></tr>'+
              '<tr><td><b>Email:</b> %s</td></tr>'+
              '<tr><td><b>Teléfono:</b> %s</td></tr>'+
              '</table>>];',
              [i+1, i+1, HTMLEscape(U^.nombre), HTMLEscape(U^.usuario),
<<<<<<< HEAD
                     HTMLEscape(U^.email), HTMLEscape(U^.telefono)]))
=======
                     HTMLEscape(U^.email),  HTMLEscape(U^.telefono)]))
>>>>>>> 93f5b82 (Fase1)
          else
            L.Add(Format(
              '  n%d [label=<<table border="0" cellborder="1" cellspacing="0" bgcolor="#cfe8ff">'+
              '<tr><td><b>ID:</b> %d</td></tr>'+
              '<tr><td><b>Email:</b> %s</td></tr>'+
              '<tr><td>(no encontrado)</td></tr></table>>];',
              [i+1, i+1, HTMLEscape(mail)]));
        end;

<<<<<<< HEAD
        for i := 0 to List.Count - 1 do
          L.Add(Format('  n%d -> n%d;', [i+1, ((i+1) mod List.Count) + 1]));
=======
        for i := 0 to List.Count-1 do
          L.Add(Format('  n%d -> n%d;', [i+1, ((i+1) mod List.Count)+1]));
>>>>>>> 93f5b82 (Fase1)
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

<<<<<<< HEAD
{-------------------- Inbox (lista doblemente enlazada) -----------------------}
procedure ExportInboxDOT(const OwnerEmail, TargetDot, TargetPng: string);
var
  L: TStringList;
  logicalIdx: Integer;

  procedure AddCorreoNode(const NId, Id: Integer;
    const Remitente, Estado, Programado, Asunto, Fecha, Mensaje: string);
=======
{------------------- INBOX (lista doblemente enlazada) -------------------}
procedure ExportInboxDOT(const OwnerEmail, TargetDot, TargetPng: string);
var
  L          : TStringList;
  logicalIdx : Integer;

  procedure AddCorreoNode(const NId, Id: Integer;
                          const Remitente, Estado, ProgSN, Asunto, Fecha, Mensaje: string);
>>>>>>> 93f5b82 (Fase1)
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
<<<<<<< HEAD
      [NId, Id, HTMLEscape(Remitente), HTMLEscape(Estado), HTMLEscape(Programado),
=======
      [NId, Id, HTMLEscape(Remitente), HTMLEscape(Estado), HTMLEscape(ProgSN),
>>>>>>> 93f5b82 (Fase1)
       HTMLEscape(Asunto), HTMLEscape(Fecha), HTMLEscape(Mensaje)]));
  end;

var
<<<<<<< HEAD
  p: PCorreo;
  i: Integer;
=======
  p : PCorreo;
  progSN : string;
  i : Integer;
>>>>>>> 93f5b82 (Fase1)
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

<<<<<<< HEAD
=======
    // Recorrer la lista enlazada: First -> next
>>>>>>> 93f5b82 (Fase1)
    p := GCorreos.First;
    while p <> nil do
    begin
      if (p^.destinatario = OwnerEmail) and (UpperCase(p^.estado) <> 'EL') then
      begin
        Inc(logicalIdx);
<<<<<<< HEAD
        AddCorreoNode(logicalIdx, p^.id, p^.remitente, p^.estado, p^.programado,
=======
        if Trim(p^.programado) <> '' then progSN := 'Sí' else progSN := 'No';
        AddCorreoNode(logicalIdx, p^.id, p^.remitente, p^.estado, progSN,
>>>>>>> 93f5b82 (Fase1)
                      p^.asunto, p^.fecha, p^.mensaje);
      end;
      p := p^.next;
    end;

    if logicalIdx = 0 then
      L.Add('  Empty [label="(sin correos)"];')
    else
<<<<<<< HEAD
      for i := 1 to logicalIdx - 1 do
=======
      for i := 1 to logicalIdx-1 do
>>>>>>> 93f5b82 (Fase1)
        L.Add(Format('  n%d -> n%d;', [i, i+1]));

    L.Add('  }'); L.Add('}');
    SaveAndMaybePng(TargetDot, TargetPng, L);
  finally
    L.Free;
  end;
end;

<<<<<<< HEAD
{-------------------- Papelera (pila) -----------------------------------------}
procedure ExportTrashDOT(const OwnerEmail, TargetDot, TargetPng: string);
var
  L: TStringList;
  logicalIdx: Integer;

  procedure AddCorreoNode(const NId, Id: Integer;
    const Remitente, Estado, Programado, Asunto, Fecha, Mensaje: string);
=======
{------------------- PAPELERA (pila) -------------------}
procedure ExportTrashDOT(const OwnerEmail, TargetDot, TargetPng: string);
var
  L          : TStringList;
  logicalIdx : Integer;
  A          : TPCorreoArray;
  i          : Integer;

  procedure AddCorreoNode(const NId, Id: Integer;
                          const Remitente, EstadoLegible, ProgSN, Asunto, Fecha, Mensaje: string);
>>>>>>> 93f5b82 (Fase1)
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
<<<<<<< HEAD
      [NId, Id, HTMLEscape(Remitente), HTMLEscape(Estado), HTMLEscape(Programado),
=======
      [NId, Id, HTMLEscape(Remitente), HTMLEscape(EstadoLegible), HTMLEscape(ProgSN),
>>>>>>> 93f5b82 (Fase1)
       HTMLEscape(Asunto), HTMLEscape(Fecha), HTMLEscape(Mensaje)]));
  end;

var
<<<<<<< HEAD
  p: PCorreo;
=======
  progSN: string;
>>>>>>> 93f5b82 (Fase1)
begin
  L := TStringList.Create;
  try
    L.Add('digraph G {');
<<<<<<< HEAD
=======
    L.Add('  rankdir=TB;');
>>>>>>> 93f5b82 (Fase1)
    L.Add('  graph [fontname="Helvetica"]; node [shape=plaintext, fontname="Helvetica"];');
    L.Add('  labelloc="t"; label="Reporte de Papelera";');
    L.Add('  subgraph cluster0 { label="Pila"; style="rounded"; color="lightcoral";');

    logicalIdx := 0;
<<<<<<< HEAD

    p := GCorreos.First;
    while p <> nil do
    begin
      if (p^.destinatario = OwnerEmail) and (UpperCase(p^.estado) = 'EL') then
      begin
        Inc(logicalIdx);
        AddCorreoNode(logicalIdx, p^.id, p^.remitente, p^.estado, p^.programado,
                      p^.asunto, p^.fecha, p^.mensaje);
      end;
      p := p^.next;
    end;

    if logicalIdx = 0 then
      L.Add('  Empty [label="(papelera vacía)"];');
=======
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
>>>>>>> 93f5b82 (Fase1)

    L.Add('  }'); L.Add('}');
    SaveAndMaybePng(TargetDot, TargetPng, L);
  finally
    L.Free;
  end;
end;

<<<<<<< HEAD
{-------------------- Programados (cola) --------------------------------------}
procedure ExportScheduledDOT(const OwnerEmail, TargetDot, TargetPng: string);
var
  L: TStringList;
  logicalIdx: Integer;
  i: Integer;

  procedure AddCorreoNode(const NId, Id: Integer;
    const Remitente, Estado, Programado, Asunto, Fecha, Mensaje: string);
=======
{------------------- PROGRAMADOS (cola, VERTICAL) -------------------}
procedure ExportScheduledDOT(const OwnerEmail, TargetDot, TargetPng: string);
var
  L          : TStringList;
  logicalIdx : Integer;
  i          : Integer;

  procedure AddCorreoNode(const NId, Id: Integer;
                          const Remitente, ProgSN, Asunto, Fecha, Mensaje: string);
>>>>>>> 93f5b82 (Fase1)
  begin
    L.Add(Format(
      '  n%d [label=<<table border="0" cellborder="1" cellspacing="0" bgcolor="#d6f0ff">'+
      '<tr><td><b>ID:</b> %d</td></tr>'+
      '<tr><td><b>Remitente:</b> %s</td></tr>'+
<<<<<<< HEAD
      '<tr><td><b>Estado:</b> %s</td></tr>'+
=======
      '<tr><td><b>Estado:</b> Programado</td></tr>'+
>>>>>>> 93f5b82 (Fase1)
      '<tr><td><b>Programado:</b> %s</td></tr>'+
      '<tr><td><b>Asunto:</b> %s</td></tr>'+
      '<tr><td><b>Fecha:</b> %s</td></tr>'+
      '<tr><td><b>Mensaje:</b> %s</td></tr></table>>];',
<<<<<<< HEAD
      [NId, Id, HTMLEscape(Remitente), HTMLEscape(Estado), HTMLEscape(Programado),
=======
      [NId, Id, HTMLEscape(Remitente), HTMLEscape(ProgSN),
>>>>>>> 93f5b82 (Fase1)
       HTMLEscape(Asunto), HTMLEscape(Fecha), HTMLEscape(Mensaje)]));
  end;

var
<<<<<<< HEAD
  p: PCorreo;
  n: Integer;
=======
  p : PCorreo;
  n : Integer;
>>>>>>> 93f5b82 (Fase1)
begin
  L := TStringList.Create;
  try
    L.Add('digraph G {');
<<<<<<< HEAD
    L.Add('  rankdir=LR;');
=======
    L.Add('  rankdir=TB;'); // vertical
>>>>>>> 93f5b82 (Fase1)
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
<<<<<<< HEAD
          AddCorreoNode(logicalIdx, p^.id, p^.remitente, p^.estado, p^.programado,
=======
          // Programado siempre “Sí”
          AddCorreoNode(logicalIdx, p^.id, p^.remitente, 'Sí',
>>>>>>> 93f5b82 (Fase1)
                        p^.asunto, p^.fecha, p^.mensaje);
        end;
        GScheduled.Enqueue(p);
      end;
      Dec(n);
    end;

    if logicalIdx = 0 then
      L.Add('  Empty [label="(sin programados)"];')
    else
<<<<<<< HEAD
      for i := 1 to logicalIdx - 1 do
        L.Add(Format('  n%d -> n%d;', [i, i+1]));
=======
      for i := 1 to logicalIdx-1 do
        L.Add(Format('  n%d -> n%d [arrowhead=vee];', [i, i+1]));
>>>>>>> 93f5b82 (Fase1)

    L.Add('  }'); L.Add('}');
    SaveAndMaybePng(TargetDot, TargetPng, L);
  finally
    L.Free;
  end;
end;

<<<<<<< HEAD
{-------------------- Orquestador --------------------------------------------}
=======
{------------------- ORQUESTADOR -------------------}
>>>>>>> 93f5b82 (Fase1)
function GenerateAllUserReports(const AEmail: string; out ABaseDir: string): string;
var base, userSafe: string;
begin
  base     := 'Reportes' + DirectorySeparator + 'Usuario-Reportes';
  userSafe := Sanitize(AEmail);
  ABaseDir := base + DirectorySeparator + userSafe;
  ForceDirectories(ABaseDir);

  ExportInboxDOT     (AEmail, ABaseDir+DirectorySeparator+'inbox.dot',
                             ABaseDir+DirectorySeparator+'inbox.png');
  ExportTrashDOT     (AEmail, ABaseDir+DirectorySeparator+'papelera.dot',
                             ABaseDir+DirectorySeparator+'papelera.png');
  ExportScheduledDOT (AEmail, ABaseDir+DirectorySeparator+'programados.dot',
                             ABaseDir+DirectorySeparator+'programados.png');
  ExportContactsDOT  (AEmail, ABaseDir+DirectorySeparator+'contactos.dot',
                             ABaseDir+DirectorySeparator+'contactos.png');

  Result := ABaseDir;
end;

end.

