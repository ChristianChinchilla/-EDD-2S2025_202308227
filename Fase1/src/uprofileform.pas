unit uProfileForm;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, Dialogs;

type
  { TfrmProfile }
  TfrmProfile = class(TForm)
    lblTitle: TLabel;
    lblNombre: TLabel;
    lblUsuario: TLabel;
    lblCorreo: TLabel;
    lblTelefono: TLabel;
    edtNombre: TEdit;
    edtUsuario: TEdit;
    edtCorreo: TEdit;
    edtTelefono: TEdit;
    btnActualizar: TButton;
    btnVolver: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btnActualizarClick(Sender: TObject);
    procedure btnVolverClick(Sender: TObject);
  private
    FEmailActual: string;
  public
    procedure OpenForUser(const AOwnerEmail: string);
  end;

var
  frmProfile: TfrmProfile;

implementation

{$R *.lfm}

uses
  uData, uListaUsuarios, uUserMenu, uContacts;  // <-- AÑADIDO uListaUsuarios

{ TfrmProfile }

procedure TfrmProfile.FormCreate(Sender: TObject);
begin
  Caption := 'Actualizar Perfil';
  lblTitle.Caption    := 'Actualizar Perfil';
  lblNombre.Caption   := 'Nombre';
  lblUsuario.Caption  := 'Usuario';
  lblCorreo.Caption   := 'Correo';
  lblTelefono.Caption := 'Telefono';

  // Por si no lo hiciste en el diseñador:
  edtUsuario.ReadOnly := True;
  edtCorreo.ReadOnly  := True;
end;

procedure TfrmProfile.OpenForUser(const AOwnerEmail: string);
var
  U: PUsuario;  // viene de uListaUsuarios
begin
  FEmailActual := AOwnerEmail;

  // Cargar datos del usuario actual
  U := GUsuarios.FindByEmail(FEmailActual);
  if U = nil then
  begin
    ShowMessage('No se encontró el usuario actual.');
    Close;
    Exit;
  end;

  edtNombre.Text   := U^.nombre;
  edtUsuario.Text  := U^.usuario;
  edtCorreo.Text   := U^.email;     // usa el campo que tengas en tu record
  edtTelefono.Text := U^.telefono;

  Show;
end;

procedure TfrmProfile.btnActualizarClick(Sender: TObject);
var
  U: PUsuario;
  nuevoNombre, nuevoTel: string;
begin
  U := GUsuarios.FindByEmail(FEmailActual);
  if U = nil then
  begin
    ShowMessage('No se encontró el usuario actual.');
    Exit;
  end;

  nuevoNombre := Trim(edtNombre.Text);
  nuevoTel    := Trim(edtTelefono.Text);

  if (nuevoNombre = '') and (nuevoTel = '') then
  begin
    ShowMessage('No hay cambios para guardar.');
    Exit;
  end;

  if nuevoNombre <> '' then
    U^.nombre := nuevoNombre;

  if nuevoTel <> '' then
    U^.telefono := nuevoTel;

  // Si tienes persistencia, llama aquí tu método de guardado.
  // p.ej.: GUsuarios.SaveToFile('usuarios_guardados.json');

  if Assigned(frmContacts) and frmContacts.Visible then
    frmContacts.RefreshList;

  ShowMessage('Perfil actualizado.');
end;

procedure TfrmProfile.btnVolverClick(Sender: TObject);
begin
  Hide;
  if not Assigned(frmUserMenu) then
    Application.CreateForm(TfrmUserMenu, frmUserMenu);
  frmUserMenu.Show;
end;

end.

