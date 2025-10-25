unit uRootMenu;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, Dialogs;

type
  { TfrmRootMenu }
  TfrmRootMenu = class(TForm)
    btnCargaMasiva: TButton;
    btnRepUsuarios: TButton;
    btnRepRelaciones: TButton;
    btnRepComunidades: TButton;
    btnRepBlockchain: TButton;   // puede no existir en el .lfm sin problema
    btnLogout: TButton;
    btnComunidades: TButton;
    btnMensaje: TButton;
    btnLogueo: TButton;
    lblTitle: TLabel;
    OpenDialog1: TOpenDialog;
    procedure btnCargaMasivaClick(Sender: TObject);
    procedure btnComunidadesClick(Sender: TObject);
    procedure btnMensajeClick(Sender: TObject);
    procedure btnRepUsuariosClick(Sender: TObject);
    procedure btnRepRelacionesClick(Sender: TObject);
    procedure btnRepComunidadesClick(Sender: TObject);
    procedure btnRepBlockchainClick(Sender: TObject);
    procedure btnLogoutClick(Sender: TObject);
    procedure btnLogueoClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    function  GetReportsDir: string;
    procedure RunDot(const dotFile, pngFile: string);

    // Blockchain helpers
    function  HtmlEsc(const S: string): string;
    function  MD5Hex(const S: string): string;
    function  ShortHash(const S: string): string;
    procedure BuildBlockchainDOT(const TargetDot, TargetPng: string);

    // Cargas masivas
    function  LoadCorreosFromJSON(const AFile: string): Integer;
    function  LoadContactosFromJSON(const AFile: string): Integer; // NUEVO
    function  LooksLikeContactJSON(const Root: TJSONObject): Boolean; // << TJSONObject (no IJSONObject)
  public
  end;

var
  frmRootMenu: TfrmRootMenu;

implementation

{$R *.lfm}

uses
  fpjson, jsonparser,
  uData, uListaUsuarios, uListaCorreos,  // GUsuarios, GCorreos, GContacts
  Process, FileUtil, md5,
  comunidadesMenu, uCommunityMessagesForm,
  uLogControlForm;

{=========================== Form ===========================}

procedure TfrmRootMenu.FormCreate(Sender: TObject);
begin
  Caption := 'Root';
  lblTitle.Caption := 'Root';
  OpenDialog1.Filter := 'JSON|*.json|Todos|*.*';
end;

procedure TfrmRootMenu.btnComunidadesClick(Sender: TObject);
begin
  if comunidadesForm=nil then Application.CreateForm(TcomunidadesForm, comunidadesForm);
  comunidadesForm.Show; comunidadesForm.BringToFront;
end;

procedure TfrmRootMenu.btnMensajeClick(Sender: TObject);
begin
  if frmCommunityMessages=nil then Application.CreateForm(TfrmCommunityMessages, frmCommunityMessages);
  frmCommunityMessages.Open; frmCommunityMessages.BringToFront;
end;

{=========================== Utils comunes ===========================}

function TfrmRootMenu.GetReportsDir: string;
var
  base: string;
begin
  base := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
  Result := IncludeTrailingPathDelimiter(base + 'Reportes' + DirectorySeparator + 'Root-Reportes');
  ForceDirectories(Result);
end;

procedure TfrmRootMenu.RunDot(const dotFile, pngFile: string);
var
  p: TProcess; exe: string;
begin
  exe := FindDefaultExecutablePath('dot'); if exe='' then exe := 'dot';
  p := TProcess.Create(nil);
  try
    p.Executable := exe;
    p.Parameters.Add('-Tpng'); p.Parameters.Add(dotFile);
    p.Parameters.Add('-o');    p.Parameters.Add(pngFile);
    p.Options := [poNoConsole, poWaitOnExit];
    try
      p.Execute;
    except
      on E: Exception do
        ShowMessage('No se pudo ejecutar Graphviz (dot). Se generó solo el .dot.'+LineEnding+'Error: '+E.Message);
    end;
  finally
    p.Free;
  end;
end;

{=========================== Reportes existentes ===========================}

procedure TfrmRootMenu.btnRepUsuariosClick(Sender: TObject);
var
  dir, dot, png: string;
begin
  dir := GetReportsDir; dot := dir+'usuarios.dot'; png := dir+'usuarios.png';
  GUsuarios.ExportToDOT(dot); RunDot(dot, png);
  if FileExists(png) then
    ShowMessage('Reporte generado:'+LineEnding+dot+LineEnding+png)
  else
    ShowMessage('Reporte .dot generado: '+dot+LineEnding+'(Instala graphviz para crear también el .png)');
end;

procedure TfrmRootMenu.btnRepRelacionesClick(Sender: TObject);
var
  dir, dot, png: string;
begin
  dir := GetReportsDir;

  // 1) Relaciones (lo que ya funcionaba)
  dot := dir+'relaciones.dot';
  png := dir+'relaciones.png';
  GCorreos.ExportRelacionesMatrizDOT(dot);
  RunDot(dot, png);

  // 2) Blockchain (se genera junto con relaciones)
  dot := dir+'blockchain.dot';
  png := dir+'blockchain.png';
  BuildBlockchainDOT(dot, png);

  if FileExists(png) then
    ShowMessage('Relaciones y Blockchain generados en:' + LineEnding + dir)
  else
    ShowMessage('Se generaron DOTs en: ' + dir + LineEnding +
                '(instala Graphviz para crear también los PNG)');
end;

procedure TfrmRootMenu.btnRepComunidadesClick(Sender: TObject);
var
  dir, dot, png: string;
begin
  dir := GetReportsDir;
  dot := dir + 'comunidades_bst.dot';
  png := dir + 'comunidades_bst.png';
  CommunityReport(dot);
  RunDot(dot, png);
  if FileExists(png) then
    ShowMessage('Reporte de Comunidades (BST) generado en:' + LineEnding + png)
  else
    ShowMessage('Se generó el archivo DOT en:' + LineEnding + dot + LineEnding +
                '(instala Graphviz para crear también el PNG)');
end;

{=========================== Blockchain ===========================}

function TfrmRootMenu.HtmlEsc(const S: string): string;
var
  i: Integer; c: Char;
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

function TfrmRootMenu.MD5Hex(const S: string): string;
var D: TMD5Digest;
begin
  D := MD5String(S);
  Result := LowerCase(MD5Print(D));
end;

function TfrmRootMenu.ShortHash(const S: string): string;
begin
  if Length(S) <= 8 then Result := S else Result := Copy(S,1,8) + '...';
end;

procedure TfrmRootMenu.BuildBlockchainDOT(const TargetDot, TargetPng: string);
var
  L        : TStringList;
  p        : PCorreo;
  prevHash : string;
  curHash  : string;
  payload  : string;
  idx      : Integer;
  nonceVal : Integer;

  procedure AddBlockNode(const NIdx: Integer; const Title, IndexTxt, TimeTxt,
                         DataTxt, NonceTxt, PrevTxt, HashTxt: string);
  begin
    L.Add(Format(
      '  b%d [label=<<table border="1" cellborder="1" cellspacing="0">'+
      '<tr><td><b>%s</b></td></tr>'+
      '<tr><td>%s</td></tr>'+
      '<tr><td>%s</td></tr>'+
      '<tr><td>%s</td></tr>'+
      '<tr><td>%s</td></tr>'+
      '<tr><td>%s</td></tr>'+
      '<tr><td>%s</td></tr>'+
      '</table>>];',
      [ NIdx, HtmlEsc(Title),
        HtmlEsc(IndexTxt), HtmlEsc(TimeTxt), HtmlEsc(DataTxt),
        HtmlEsc(NonceTxt), HtmlEsc(PrevTxt), HtmlEsc(HashTxt) ]));
  end;

begin
  L := TStringList.Create;
  try
    L.Add('digraph G {');
    L.Add('  rankdir=TB;');
    L.Add('  graph [fontname="Helvetica"];');
    L.Add('  node  [shape=plaintext, fontname="Helvetica"];');
    L.Add('  edge  [arrowhead=vee];');
    L.Add('  labelloc="t"; label="Reporte de Blockchain";');

    idx := 0;

    // Bloque génesis (decorativo)
    prevHash := '0';
    AddBlockNode(
      idx,
      'Block 0 (Genesis)',
      'Index: 0',
      'Timestamp: 0',
      'Data: Genesis Block',
      'Nonce: 0',
      'Prev Hash: 0',
      'Hash: 0'
    );

    p := GCorreos.First;
    while p <> nil do
    begin
      if UpperCase(Trim(p^.estado)) <> 'EL' then
      begin
        Inc(idx);

        payload :=
          IntToStr(p^.id) + '|' + p^.remitente + '|' + p^.destinatario + '|' +
          p^.estado + '|' + p^.programado + '|' + p^.asunto + '|' +
          p^.fecha + '|' + p^.mensaje + '|' + prevHash;

        curHash := MD5Hex(payload);
        nonceVal := (Abs(p^.id * 67891) + Length(p^.mensaje)) mod 100000;

        AddBlockNode(
          idx,
          Format('Block %d', [idx]),
          Format('Index: %d', [idx]),
          'Timestamp: ' + HtmlEsc(p^.fecha),
          Format('Data: ID: %d, Remitente: %s, Asunto: %s, Mensaje: %s',
                 [p^.id, HtmlEsc(p^.remitente), HtmlEsc(p^.asunto), HtmlEsc(p^.mensaje)]),
          Format('Nonce: %d', [nonceVal]),
          'Prev Hash: ' + ShortHash(prevHash),
          'Hash: ' + ShortHash(curHash)
        );

        L.Add(Format('  b%d -> b%d;', [idx-1, idx]));
        prevHash := curHash;
      end;
      p := p^.next;
    end;

    if idx = 0 then
      L.Add('  Empty [label="(sin correos para encadenar)"];');

    L.Add('}');
    ForceDirectories(ExtractFileDir(TargetDot));
    L.SaveToFile(TargetDot);
    RunDot(TargetDot, TargetPng);
  finally
    L.Free;
  end;
end;

procedure TfrmRootMenu.btnRepBlockchainClick(Sender: TObject);
var
  dir, dot, png: string;
begin
  dir := GetReportsDir;
  dot := dir + 'blockchain.dot';
  png := dir + 'blockchain.png';
  BuildBlockchainDOT(dot, png);

  if FileExists(png) then
    ShowMessage('Reporte de Blockchain generado en:' + LineEnding + png)
  else
    ShowMessage('Se generó el archivo DOT en:' + LineEnding + dot + LineEnding +
                '(instala Graphviz para crear también el PNG)');
end;

{====================== Carga masiva ======================}

function TfrmRootMenu.LooksLikeContactJSON(const Root: TJSONObject): Boolean;
var
  arr : TJSONData;
begin
  // Esperamos {"Usuarios":[{ "Usuario":"...", "Contactos":[...] }, ...]}
  Result := False;
  if Root = nil then Exit;
  arr := Root.Find('Usuarios');
  if (arr <> nil) and (arr.JSONType = jtArray) then
    Result := True;
end;

function TfrmRootMenu.LoadContactosFromJSON(const AFile: string): Integer;
var
  jRoot   : TJSONObject;
  usuarios: TJSONArray;
  i, k    : Integer;
  item    : TJSONObject;
  ownerK  : string;
  arrC    : TJSONArray;
  contactK: string;

  function ResolveToEmail(const Key: string): string;
  begin
    // Si ya es correo, usar tal cual; si no, formar alias@edd.com (ajústalo si tu regla es otra)
    if Pos('@', Key) > 0 then
      Result := LowerCase(Trim(Key))
    else
      Result := LowerCase(Trim(Key)) + '@edd.com';
  end;

begin
  Result := 0;
  jRoot := nil;
  try
    jRoot := TJSONObject(GetJSON(TFileStream.Create(AFile, fmOpenRead or fmShareDenyWrite), True));
    if (jRoot=nil) or not LooksLikeContactJSON(jRoot) then
      raise Exception.Create('El JSON no coincide con el esquema de contactos.');

    usuarios := jRoot.Arrays['Usuarios'];
    for i := 0 to usuarios.Count-1 do
    begin
      if usuarios.Items[i].JSONType <> jtObject then Continue;
      item := usuarios.Objects[i];

      ownerK := Trim(item.Get('Usuario',''));
      if ownerK = '' then Continue;

      // Lista de contactos para este usuario
      if item.Find('Contactos') = nil then Continue;
      if item.Arrays['Contactos'].Count = 0 then Continue;

      // Si tu API permite limpiar antes: (opcional)
      try
        GContacts.ClearAllFor(ResolveToEmail(ownerK)); // comenta si tu API no la tiene
      except
      end;

      arrC := item.Arrays['Contactos'];
      for k := 0 to arrC.Count-1 do
      begin
        contactK := Trim(arrC.Strings[k]);
        if contactK = '' then Continue;

        // Agregar relación owner -> contact
        // Asumimos GContacts.Add(OwnerEmail, ContactEmail)
        GContacts.Add( ResolveToEmail(ownerK), ResolveToEmail(contactK) );
        Inc(Result);
      end;
    end;
  finally
    if jRoot<>nil then jRoot.Free;
  end;
end;

procedure TfrmRootMenu.btnCargaMasivaClick(Sender: TObject);
var
  j: TJSONData;
  root: TJSONObject;
  nUsers, nMails, nContacts: Integer;
begin
  if not OpenDialog1.Execute then Exit;
  j := nil;
  try
    j := GetJSON(TFileStream.Create(OpenDialog1.FileName, fmOpenRead or fmShareDenyWrite), True);
    if (j=nil) or (j.JSONType<>jtObject) then
      raise Exception.Create('El JSON debe tener un objeto raíz.');
    root := TJSONObject(j);

    // 1) usuarios
    if root.Find('usuarios')<>nil then
    begin
      GUsuarios.LoadFromJSON(OpenDialog1.FileName);
      nUsers := GUsuarios.Count;
      ShowMessage(Format('Usuarios cargados: %d', [nUsers]));
      Exit;
    end;

    // 2) correos
    if root.Find('correos')<>nil then
    begin
      nMails := LoadCorreosFromJSON(OpenDialog1.FileName);
      ShowMessage(Format('Correos cargados: %d', [nMails]));
      Exit;
    end;

    // 3) contactos (nuevo formato)
    if LooksLikeContactJSON(root) then
    begin
      nContacts := LoadContactosFromJSON(OpenDialog1.FileName);
      ShowMessage(Format('Contactos cargados: %d', [nContacts]));
      Exit;
    end;

    raise Exception.Create('JSON no reconocido. Se esperaba "usuarios", "correos" o "Usuarios/Contactos".');
  except
    on E: Exception do ShowMessage('Error al cargar JSON: ' + E.Message);
  end;
  if j<>nil then j.Free;
end;

{=========================== Logout / Log ===========================}

procedure TfrmRootMenu.btnLogoutClick(Sender: TObject);
begin
  LogRegistrarSalida('root@edd.com', Now);
  Application.MainForm.Show;
  Hide;
end;

procedure TfrmRootMenu.btnLogueoClick(Sender: TObject);
begin
  if not Assigned(frmLoginLog) then
    frmLoginLog := TfrmLoginLog.Create(Application);
  frmLoginLog.Open;
end;

{=========================== Loader de correos ===========================}

function TfrmRootMenu.LoadCorreosFromJSON(const AFile: string): Integer;
var
  j: TJSONData;
  root: TJSONObject;
  arr: TJSONArray;
  i, id: Integer;
  o: TJSONObject;
  remitente, destinatario, estado, asunto, mensaje, programado, fecha: string;
begin
  Result := 0;
  j := GetJSON(TFileStream.Create(AFile, fmOpenRead or fmShareDenyWrite), True);
  try
    if (j=nil) or (j.JSONType<>jtObject) then
      raise Exception.Create('El JSON de correos debe tener objeto raíz.');
    root := TJSONObject(j);
    if root.Find('correos')=nil then
      raise Exception.Create('No se encontró la clave "correos".');

    arr := root.Arrays['correos'];
    for i := 0 to arr.Count-1 do
    begin
      o := arr.Objects[i];
      id := o.Get('id',0);
      remitente    := o.Get('remitente','');
      destinatario := o.Get('destinatario','');
      estado       := o.Get('estado','NL');
      asunto       := o.Get('asunto','');
      mensaje      := o.Get('mensaje','');
      programado   := o.Get('programado','');
      fecha        := o.Get('fecha','');

      if id<=0 then id := GCorreos.NextId;
      GCorreos.Add(id, remitente, destinatario, estado, programado, asunto, fecha, mensaje);
      Inc(Result);
    end;
  finally
    j.Free;
  end;
end;

end.

