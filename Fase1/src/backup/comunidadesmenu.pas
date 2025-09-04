unit comunidadesMenu;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ListaDeListas;

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

  public

  end;

var
  comunidadesForm: TcomunidadesForm;
  listaComunidades: PListaDeListas;

implementation

{$R *.lfm}

{ TcomunidadesForm }

procedure TcomunidadesForm.FormCreate(Sender: TObject);
begin
  // center the form on the screen
  Self.Position := poScreenCenter;
  //make the form non-resizable
  Self.BorderStyle := bsSingle;
  Self.OnClose := @FormClose;
  // ------- CAMBIAR POR VARIABLE GLOBAL ----------------
  New(listaComunidades);
  listaComunidades^ := TListaDeListas.Create;
end;

procedure TcomunidadesForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction := caHide;
  // if Assigned(userMenuForm) then
  //   userMenuForm.Show;
end;

procedure TcomunidadesForm.crearButtonClick(Sender: TObject);
var
  nombre: String;
begin
  nombre := nombreTextBox.Text;
  if nombre <> '' then
  begin
    if listaComunidades^.Append(nombre) then
    begin
      MessageDlg('Éxito', 'Comunidad creada exitosamente.', mtInformation, [mbOK], 0);
      nombreTextBox.Text := '';
    end;
  end
  else
  begin
    MessageDlg('Error', 'El nombre no puede estar vacío', mtError, [mbOK], 0);
  end;
end;

procedure TcomunidadesForm.reporteButtonClick(Sender: TObject);
begin
  listaComunidades^.graph();
end;

procedure TcomunidadesForm.addButtonClick(Sender: TObject);
var
  comunidad, correo: String;
  
begin
  comunidad := comunidadTextBox.Text;
  correo := correoTextBox.Text;
  if (comunidad <> '') and (correo <> '') then
  begin
    if listaComunidades^.AgregarUsuarioAComunidad(comunidad, correo) then
    begin
      MessageDlg('Éxito', 'Usuario agregado a la comunidad', mtInformation, [mbOK], 0);
      comunidadTextBox.Text := '';
      correoTextBox.Text := '';
      Exit;
    end;
  end
  else
  begin
    MessageDlg('Error', 'La comunidad y el correo no pueden estar vacíos', mtError, [mbOK], 0);
  end;
end;

end.

