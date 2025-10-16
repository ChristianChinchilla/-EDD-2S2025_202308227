unit comunidadesMenu;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls;

type
  { TcomunidadesForm }

  TcomunidadesForm = class(TForm)
    reporteButton: TButton;
    crearButton: TButton;
    addButton: TButton;
    nombreTextBox: TEdit;
    Label1: TLabel;
    nombreLabel: TLabel;
    comunidadLabel: TLabel;
    correoLabel: TLabel;
    comunidadTextBox: TEdit;
    correoTextBox: TEdit;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure addButtonClick(Sender: TObject);
    procedure crearButtonClick(Sender: TObject);
    procedure reporteButtonClick(Sender: TObject);
  private
    function ReportsDir: string;
    procedure RunDot(const DotFile, PngFile: string);
  public
  end;

var
  comunidadesForm: TcomunidadesForm;

implementation

{$R *.lfm}

uses
  uData, Process, FileUtil;

procedure TcomunidadesForm.FormCreate(Sender: TObject);
begin
  Caption := 'Comunidades';
  Position := poScreenCenter;
  BorderStyle := bsSingle;

  if Assigned(nombreLabel) then nombreLabel.Caption := 'Nombre:';
  if Assigned(comunidadLabel) then comunidadLabel.Caption := 'Comunidad:';
  if Assigned(correoLabel) then correoLabel.Caption := 'Correo:';

  if Assigned(crearButton) then crearButton.Caption := 'Crear';
  if Assigned(addButton) then addButton.Caption := 'Añadir';
  if Assigned(reporteButton) then reporteButton.Caption := 'Reporte de comunidades';
end;

procedure TcomunidadesForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction := caHide;
end;

function TcomunidadesForm.ReportsDir: string;
var base: string;
begin
  base := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
  Result := base + 'Reportes' + DirectorySeparator + 'Root-Reportes' + DirectorySeparator;
  ForceDirectories(Result);
end;

procedure TcomunidadesForm.RunDot(const DotFile, PngFile: string);
var P: TProcess; Exe: string;
begin
  Exe := FindDefaultExecutablePath('dot'); if Exe='' then Exe := 'dot';
  P := TProcess.Create(nil);
  try
    P.Executable := Exe;
    P.Parameters.Add('-Tpng'); P.Parameters.Add(DotFile);
    P.Parameters.Add('-o');    P.Parameters.Add(PngFile);
    P.Options := [poWaitOnExit, poNoConsole];
    try P.Execute; except end;
  finally
    P.Free;
  end;
end;

procedure TcomunidadesForm.crearButtonClick(Sender: TObject);
var nombre: string;
begin
  nombre := Trim(nombreTextBox.Text);
  if nombre='' then begin
    MessageDlg('Error', 'El nombre de la comunidad no puede estar vacío.', mtError, [mbOK], 0); Exit;
  end;

  if CommunityExists(nombre) then begin
    MessageDlg('Info', 'La comunidad "'+nombre+'" ya existe.', mtInformation, [mbOK], 0); Exit;
  end;

  CommunityEnsure(nombre);
  MessageDlg('Éxito', 'Comunidad creada exitosamente.', mtInformation, [mbOK], 0);
  nombreTextBox.Clear;
end;

procedure TcomunidadesForm.addButtonClick(Sender: TObject);
var comu, correo: string;
begin
  comu := Trim(comunidadTextBox.Text);
  correo := Trim(correoTextBox.Text);
  if (comu='') or (correo='') then begin
    MessageDlg('Error', 'Comunidad y correo no pueden estar vacíos.', mtError, [mbOK], 0); Exit;
  end;

  if not CommunityExists(comu) then begin
    MessageDlg('Error', 'La comunidad "'+comu+'" no existe. Primero créala.', mtError, [mbOK], 0); Exit;
  end;

  MessageDlg('Éxito', 'El usuario "'+correo+'" fue agregado a "'+comu+'".', mtInformation, [mbOK], 0);
  comunidadTextBox.Clear; correoTextBox.Clear;
end;

procedure TcomunidadesForm.reporteButtonClick(Sender: TObject);
var dir, dotPath, pngPath: string;
begin
  dir := ReportsDir;
  dotPath := dir + 'comunidades_bst.dot';
  pngPath := dir + 'comunidades_bst.png';

  CommunityReport(dotPath); // uData debe llamar a TBSTree.GenerarReporte internamente
  RunDot(dotPath, pngPath);

  if FileExists(pngPath) then
    MessageDlg('Reporte generado', 'Archivo: ' + pngPath, mtInformation, [mbOK], 0)
  else
    MessageDlg('Reporte generado', 'Archivo DOT: ' + dotPath + LineEnding +
               '(instala Graphviz para crear también el PNG).', mtInformation, [mbOK], 0);
end;

end.

