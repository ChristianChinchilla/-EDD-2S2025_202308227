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
  public
  end;

var
  comunidadesForm: TcomunidadesForm;

implementation

{$R *.lfm}

uses
  uData; // <- aquí están CommunityEnsure, CommunityPost, CommunityExists, CommunityReport

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
var base: string;
begin
  base := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
  Result := base + 'Reportes' + DirectorySeparator + 'Reporte-Comunidades' + DirectorySeparator;
  ForceDirectories(Result);
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
  comu, correo, msg: string;
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

  // Pedimos el texto del mensaje en un cuadro de entrada simple
  if not InputQuery('Publicar mensaje', 'Mensaje:', msg) then
    Exit; // canceló

  msg := Trim(msg);
  if msg = '' then
  begin
    MessageDlg('Error', 'El mensaje no puede estar vacío.', mtError, [mbOK], 0);
    Exit;
  end;

  // Publica en el BST
  CommunityPost(comu, correo, msg);

  MessageDlg('Éxito', 'Mensaje publicado en "'+comu+'".', mtInformation, [mbOK], 0);
  comunidadTextBox.Clear;
  correoTextBox.Clear;
end;

procedure TcomunidadesForm.reporteButtonClick(Sender: TObject);
var
  dotPath: string;
begin
  dotPath := ReportsDir + 'reporte_comunidades.dot';
  CommunityReport(dotPath);
  MessageDlg('Reporte generado',
             'Archivo DOT: '+dotPath+LineEnding+
             'Si tienes Graphviz configurado, también se habrá generado el SVG en la misma carpeta.',
             mtInformation, [mbOK], 0);
end;

end.

