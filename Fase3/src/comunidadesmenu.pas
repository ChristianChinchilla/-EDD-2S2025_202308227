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
  uData,      // <- aquí están CommunityEnsure, CommunityPost, CommunityExists, CommunityReport
  Process,    // para ejecutar Graphviz (dot)
  FileUtil;   // ForceDirectories

{ TcomunidadesForm }

procedure TcomunidadesForm.FormCreate(Sender: TObject);
begin
  // UI
  Caption := 'Comunidades';
  Position := poScreenCenter;
  BorderStyle := bsSingle;

  // Etiquetas (por si el .lfm no las tiene ya)
  if Assigned(nombreLabel) then nombreLabel.Caption := 'Nombre:';
  if Assigned(comunidadLabel) then comunidadLabel.Caption := 'Comunidad:';
  if Assigned(correoLabel) then correoLabel.Caption := 'Correo:';

  if Assigned(crearButton) then crearButton.Caption := 'Crear';
  if Assigned(addButton) then addButton.Caption := 'Añadir';
  if Assigned(reporteButton) then reporteButton.Caption := 'Reporte de comunidades';
end;

procedure TcomunidadesForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  // Solo ocultar la ventana (como en el resto de formularios del proyecto)
  CloseAction := caHide;
end;

function TcomunidadesForm.ReportsDir: string;
var
  base: string;
begin
  base := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
  // Carpeta exacta solicitada:
  Result := base + 'Reportes' + DirectorySeparator + 'Reporte Comunidad BST' + DirectorySeparator;
  ForceDirectories(Result);
end;

procedure TcomunidadesForm.RunDot(const DotFile, PngFile: string);
var
  P  : TProcess;
  Exe: string;
begin
  Exe := FindDefaultExecutablePath('dot');
  if Exe = '' then Exe := 'dot'; // por si ya está en PATH

  P := TProcess.Create(nil);
  try
    P.Executable := Exe;
    P.Parameters.Add('-Tpng');
    P.Parameters.Add(DotFile);
    P.Parameters.Add('-o');
    P.Parameters.Add(PngFile);
    P.Options := [poNoConsole, poWaitOnExit];
    try
      P.Execute;
    except
      on E: Exception do
        MessageDlg('Graphviz', 'No se pudo ejecutar dot. Se generó solo el .dot.' + LineEnding +
                   'Error: ' + E.Message, mtWarning, [mbOK], 0);
    end;
  finally
    P.Free;
  end;
end;

procedure TcomunidadesForm.crearButtonClick(Sender: TObject);
var
  nombre: string;
begin
  nombre := Trim(nombreTextBox.Text);
  if nombre = '' then
  begin
    MessageDlg('Error', 'El nombre de la comunidad no puede estar vacío.', mtError, [mbOK], 0);
    Exit;
  end;

  if CommunityExists(nombre) then
  begin
    MessageDlg('Info', 'La comunidad "'+nombre+'" ya existe.', mtInformation, [mbOK], 0);
    Exit;
  end;

  // Crea/asegura en el BST
  CommunityEnsure(nombre);
  MessageDlg('Éxito', 'Comunidad creada exitosamente.', mtInformation, [mbOK], 0);
  nombreTextBox.Clear;
end;

procedure TcomunidadesForm.addButtonClick(Sender: TObject);
var
  comu, correo: string;
begin
  comu   := Trim(comunidadTextBox.Text);
  correo := Trim(correoTextBox.Text);

  if (comu = '') or (correo = '') then
  begin
    MessageDlg('Error', 'Comunidad y correo no pueden estar vacíos.', mtError, [mbOK], 0);
    Exit;
  end;

  if not CommunityExists(comu) then
  begin
    MessageDlg('Error', 'La comunidad "'+comu+'" no existe. Primero créala.', mtError, [mbOK], 0);
    Exit;
  end;

  // Aquí solo confirmamos que el usuario se asoció a la comunidad
  MessageDlg('Éxito',
             'El usuario "'+correo+'" fue agregado a la comunidad "'+comu+'".',
             mtInformation, [mbOK], 0);

  comunidadTextBox.Clear;
  correoTextBox.Clear;
end;

procedure TcomunidadesForm.reporteButtonClick(Sender: TObject);
var
  dir, dotPath, pngPath: string;
begin
  dir     := ReportsDir;
  dotPath := dir + 'reporte_comunidades.dot';
  pngPath := dir + 'reporte_comunidades.png';

  // Genera el DOT (tu uData debe hacerlo con: nombre arriba, fecha creación, mensajes publicados)
  CommunityReport(dotPath);

  // Intenta generar PNG también
  RunDot(dotPath, pngPath);

  if FileExists(pngPath) then
    MessageDlg('Reporte generado',
               'Se generó el reporte de Comunidades (BST):' + LineEnding +
               pngPath, mtInformation, [mbOK], 0)
  else
    MessageDlg('Reporte generado',
               'Se generó el archivo DOT: ' + dotPath + LineEnding +
               '(Instala Graphviz para crear también el PNG).',
               mtInformation, [mbOK], 0);
end;

end.

