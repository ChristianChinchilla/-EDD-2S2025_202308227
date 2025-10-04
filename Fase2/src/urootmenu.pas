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
    btnRepComunidades: TButton;      // Reporte de comunidades (BST)
    btnLogout: TButton;
    btnComunidades: TButton;
    btnMensaje: TButton;             // Ver mensajes de comunidad
    Button1btnCargaMasiva: TButton;
    lblTitle: TLabel;
    OpenDialog1: TOpenDialog;
    procedure btnCargaMasivaClick(Sender: TObject);
    procedure btnComunidadesClick(Sender: TObject);
    procedure btnMensajeClick(Sender: TObject);         // abre visor de mensajes
    procedure btnRepUsuariosClick(Sender: TObject);
    procedure btnRepRelacionesClick(Sender: TObject);
    procedure btnRepComunidadesClick(Sender: TObject);  // usa CommunityReport
    procedure btnLogoutClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    function  GetReportsDir: string;
    procedure RunDot(const dotFile, pngFile: string);
    function  LoadCorreosFromJSON(const AFile: string): Integer;
  public
  end;

var
  frmRootMenu: TfrmRootMenu;

implementation

{$R *.lfm}

uses
  // JSON
  fpjson, jsonparser,
  // App
  uData, uListaUsuarios, uListaCorreos,
  Process, FileUtil,
  comunidadesMenu,               // formulario para crear comunidades (grupo)
  uCommunityMessagesForm;        // <-- usa TfrmCommunityMessages y frmCommunityMessages

procedure TfrmRootMenu.FormCreate(Sender: TObject);
begin
  Caption := 'Root';
  lblTitle.Caption := 'Root';
  OpenDialog1.Filter := 'JSON|*.json|Todos|*.*';
end;

procedure TfrmRootMenu.btnCargaMasivaClick(Sender: TObject);
var
  j     : TJSONData;
  root  : TJSONObject;
  nUsers, nMails: Integer;
begin
  if not OpenDialog1.Execute then Exit;

  try
    j := GetJSON(TFileStream.Create(OpenDialog1.FileName, fmOpenRead or fmShareDenyWrite), True);
    if (j = nil) or (j.JSONType <> jtObject) then
      raise Exception.Create('El JSON debe tener un objeto raíz.');

    root := TJSONObject(j);
    nUsers := 0; nMails := 0;

    if root.Find('usuarios') <> nil then
    begin
      GUsuarios.LoadFromJSON(OpenDialog1.FileName);
      nUsers := GUsuarios.Count;
      ShowMessage(Format('Usuarios cargados: %d', [nUsers]));
      Exit;
    end;

    if root.Find('correos') <> nil then
    begin
      nMails := LoadCorreosFromJSON(OpenDialog1.FileName);
      ShowMessage(Format('Correos cargados: %d', [nMails]));
      Exit;
    end;

    raise Exception.Create('JSON no reconocido. Se esperaba "usuarios" o "correos".');

  except
    on E: Exception do
      ShowMessage('Error al cargar JSON: ' + E.Message);
  end;
end;

procedure TfrmRootMenu.btnComunidadesClick(Sender: TObject);
begin
  if comunidadesForm = nil then
    Application.CreateForm(TcomunidadesForm, comunidadesForm);
  comunidadesForm.Show;
  comunidadesForm.BringToFront;
end;

procedure TfrmRootMenu.btnMensajeClick(Sender: TObject);
begin
  // Abrir el formulario para ver mensajes por comunidad
  if frmCommunityMessages = nil then
    Application.CreateForm(TfrmCommunityMessages, frmCommunityMessages);
  frmCommunityMessages.Open;      // carga comunidades y muestra los mensajes de la seleccionada
  frmCommunityMessages.BringToFront;
end;

function TfrmRootMenu.GetReportsDir: string;
var
  base: string;
begin
  base   := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
  Result := IncludeTrailingPathDelimiter(base + 'Reportes' + DirectorySeparator + 'Root-Reportes');
  ForceDirectories(Result);
end;

procedure TfrmRootMenu.RunDot(const dotFile, pngFile: string);
var
  p: TProcess; exe: string;
begin
  exe := FindDefaultExecutablePath('dot'); if exe = '' then exe := 'dot';
  p := TProcess.Create(nil);
  try
    p.Executable := exe;
    p.Parameters.Add('-Tpng');
    p.Parameters.Add(dotFile);
    p.Parameters.Add('-o');
    p.Parameters.Add(pngFile);
    p.Options := [poNoConsole, poWaitOnExit];
    try p.Execute; except
      on E: Exception do
        ShowMessage('No se pudo ejecutar Graphviz (dot). Se generó solo el .dot.'+LineEnding+'Error: '+E.Message);
    end;
  finally
    p.Free;
  end;
end;

procedure TfrmRootMenu.btnRepUsuariosClick(Sender: TObject);
var
  dir, dot, png: string;
begin
  dir := GetReportsDir;
  dot := dir + 'usuarios.dot';
  png := dir + 'usuarios.png';

  GUsuarios.ExportToDOT(dot);
  RunDot(dot, png);

  if FileExists(png) then
    ShowMessage('Reporte generado:' + LineEnding + dot + LineEnding + png)
  else
    ShowMessage('Reporte .dot generado: ' + dot + LineEnding +
                '(Instala graphviz para crear también el .png)');
end;

procedure TfrmRootMenu.btnRepRelacionesClick(Sender: TObject);
var
  dir, dot, png: string;
begin
  dir := GetReportsDir;
  dot := dir + 'relaciones.dot';
  png := dir + 'relaciones.png';

  GCorreos.ExportRelacionesMatrizDOT(dot);
  RunDot(dot, png);

  if FileExists(png) then
    ShowMessage('Reporte de Relaciones (matriz) generado: ' + png)
  else
    ShowMessage('Se generó relaciones.dot: ' + dot + LineEnding +
                '(Instala graphviz para crear el .png)');
end;

procedure TfrmRootMenu.btnRepComunidadesClick(Sender: TObject);
var
  dir, dot: string;
begin
  dir := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) +
         'Reportes' + DirectorySeparator + 'Reporte-Comunidades' + DirectorySeparator;
  ForceDirectories(dir);

  dot := dir + 'reporte_comunidades.dot';
  CommunityReport(dot);

  ShowMessage('Reporte de Comunidades generado en: ' + LineEnding + dot);
end;

procedure TfrmRootMenu.btnLogoutClick(Sender: TObject);
begin
  Application.MainForm.Show;
  Hide;
end;

function TfrmRootMenu.LoadCorreosFromJSON(const AFile: string): Integer;
var
  j      : TJSONData;
  root   : TJSONObject;
  arr    : TJSONArray;
  i, id  : Integer;
  o      : TJSONObject;
  remitente, destinatario, estado, asunto, mensaje: string;
  programado, fecha: string;
begin
  Result := 0;

  j := GetJSON(TFileStream.Create(AFile, fmOpenRead or fmShareDenyWrite), True);
  try
    if (j = nil) or (j.JSONType <> jtObject) then
      raise Exception.Create('El JSON de correos debe tener objeto raíz.');

    root := TJSONObject(j);
    if root.Find('correos') = nil then
      raise Exception.Create('No se encontró la clave "correos".');

    arr := root.Arrays['correos'];
    for i := 0 to arr.Count - 1 do
    begin
      o := arr.Objects[i];

      id           := o.Get('id', 0);
      remitente    := o.Get('remitente', '');
      destinatario := o.Get('destinatario', '');
      estado       := o.Get('estado', 'NL');
      asunto       := o.Get('asunto', '');
      mensaje      := o.Get('mensaje', '');
      programado   := o.Get('programado', '');
      fecha        := o.Get('fecha', '');

      if id <= 0 then
        id := GCorreos.NextId;

      GCorreos.Add(id, remitente, destinatario, estado, programado, asunto, fecha, mensaje);
      Inc(Result);
    end;
  finally
    j.Free;
  end;
end;

end.

