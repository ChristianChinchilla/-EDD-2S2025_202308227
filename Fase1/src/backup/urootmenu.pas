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
    btnLogout: TButton;
    Button1: TButton;
    Button1btnCargaMasiva: TButton;
    lblTitle: TLabel;
    OpenDialog1: TOpenDialog;
    procedure btnCargaMasivaClick(Sender: TObject);
    procedure btnRepUsuariosClick(Sender: TObject);
    procedure btnRepRelacionesClick(Sender: TObject);
    procedure btnLogoutClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    function  GetReportsDir: string;           // <-- ahora devuelve Reportes/Root-Reportes/
    procedure RunDot(const dotFile, pngFile: string);
  public
  end;

var
  frmRootMenu: TfrmRootMenu;

implementation

{$R *.lfm}

uses uData, uListaUsuarios, Process, FileUtil;

procedure TfrmRootMenu.FormCreate(Sender: TObject);
begin
  Caption := 'Root';
  lblTitle.Caption := 'Root';
  OpenDialog1.Filter := 'JSON|*.json|Todos|*.*';
end;

procedure TfrmRootMenu.btnCargaMasivaClick(Sender: TObject);
begin
  if OpenDialog1.Execute then
  try
    GUsuarios.LoadFromJSON(OpenDialog1.FileName);
    ShowMessage(Format('Usuarios cargados: %d', [GUsuarios.Count]));
  except
    on E: Exception do ShowMessage('Error al cargar JSON: ' + E.Message);
  end;
end;

function TfrmRootMenu.GetReportsDir: string;
var
  base: string;
begin
  // …/Reportes/Root-Reportes/ junto al ejecutable
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
  dir := GetReportsDir;               // …/Reportes/Root-Reportes/
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
  dir := GetReportsDir;               // …/Reportes/Root-Reportes/
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

procedure TfrmRootMenu.btnLogoutClick(Sender: TObject);
begin
  Application.MainForm.Show;
  Hide;
end;

end.

