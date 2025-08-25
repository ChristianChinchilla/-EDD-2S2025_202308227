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
    lblTitle: TLabel;
    OpenDialog1: TOpenDialog;
    procedure btnCargaMasivaClick(Sender: TObject);
    procedure btnRepUsuariosClick(Sender: TObject);
    procedure btnRepRelacionesClick(Sender: TObject);
    procedure btnLogoutClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    procedure RunDot(const dotFile, pngFile: string);
  public
  end;

var
  frmRootMenu: TfrmRootMenu;

implementation

{$R *.lfm}

// Modelo en IMPLEMENTATION
uses
  uData,            // GUsuarios (y luego GCorreos)
  uListaUsuarios,   // ExportToDOT, etc.
  Process, FileUtil; // FindDefaultExecutablePath

{ TfrmRootMenu }

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
    // Si ya tienes Count puedes poner: Format('Usuarios cargados: %d', [GUsuarios.Count])
    ShowMessage('Usuarios cargados correctamente desde: ' + OpenDialog1.FileName);
  except
    on E: Exception do
      ShowMessage('Error al cargar JSON: ' + E.Message);
  end;
end;

procedure TfrmRootMenu.RunDot(const dotFile, pngFile: string);
var
  p  : TProcess;
  exe: string;
begin
  // Intentar localizar 'dot' con FileUtil; si no aparece, usar 'dot' directo (requiere que esté en PATH)
  exe := FindDefaultExecutablePath('dot');
  if exe = '' then exe := 'dot';

  p := TProcess.Create(nil);
  try
    p.Executable := exe;
    p.Parameters.Add('-Tpng');
    p.Parameters.Add(dotFile);
    p.Parameters.Add('-o');
    p.Parameters.Add(pngFile);
    p.Options := [poNoConsole, poWaitOnExit];
    try
      p.Execute;
    except
      on E: Exception do
      begin
        // Si falla dot, al menos queda el .dot
        ShowMessage('No se pudo ejecutar Graphviz (dot). Se generó solo el .dot.' + LineEnding +
                    'Error: ' + E.Message);
      end;
    end;
  finally
    p.Free;
  end;
end;

procedure TfrmRootMenu.btnRepUsuariosClick(Sender: TObject);
var
  dot, png: string;
begin
  ForceDirectories('Root-Reportes');
  dot := 'Root-Reportes/usuarios.dot';
  png := 'Root-Reportes/usuarios.png';

  // Exporta la lista de usuarios a DOT (método dentro de TListaUsuarios)
  GUsuarios.ExportToDOT('Root-Reportes/usuarios.dot');

  // Intenta generar PNG con Graphviz
  RunDot(dot, png);

  if FileExists(png) then
    ShowMessage('Reporte generado:' + LineEnding + dot + LineEnding + png)
  else
    ShowMessage('Reporte .dot generado: ' + dot + LineEnding +
                '(Instala graphviz para crear también el .png)');
end;

procedure TfrmRootMenu.btnRepRelacionesClick(Sender: TObject);
var
  f        : TextFile;
  dot, png : string;
begin
  // Placeholder hasta que tengas uListaCorreos listo
  ForceDirectories('Root-Reportes');
  dot := 'Root-Reportes/relaciones.dot';
  png := 'Root-Reportes/relaciones.png';

  AssignFile(f, dot);
  Rewrite(f);
  try
    Writeln(f, 'digraph G {');
    Writeln(f, '  label="Relaciones (pendiente)\nIntegra uListaCorreos para graficar remitente -> destinatario";');
    Writeln(f, '  labelloc="t"; fontsize=16;');
    Writeln(f, '  "remitente" -> "destinatario";');
    Writeln(f, '}');
  finally
    CloseFile(f);
  end;

  RunDot(dot, png);

  if FileExists(png) then
    ShowMessage('Reporte de Relaciones generado (placeholder): ' + png)
  else
    ShowMessage('Se generó relaciones.dot (placeholder): ' + dot + LineEnding +
                '(Cuando tengas correos, reemplazamos por el real y generamos .png)');
end;

procedure TfrmRootMenu.btnLogoutClick(Sender: TObject);
begin
  Application.MainForm.Show; // volver al login
  Self.Hide;
end;

end.

