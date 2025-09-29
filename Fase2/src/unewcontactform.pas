unit uNewContactForm;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls, Dialogs;

type
  { TfrmNewContact }
  TfrmNewContact = class(TForm)
    btnEliminar: TButton;
    pnlCard: TPanel;
    lblTitle: TLabel;
    lblCorreo: TLabel;
    edtCorreo: TEdit;
    btnAgregar: TButton;
    btnVolver: TButton;
    procedure btnEliminarClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnAgregarClick(Sender: TObject);
    procedure btnVolverClick(Sender: TObject);
  private
    FOwner: string;
  public
    procedure OpenForUser(const AOwnerEmail: string);
  end;

var
  frmNewContact: TfrmNewContact;

implementation

{$R *.lfm}

uses
  uData, uContacts, uUserMenu;

procedure TfrmNewContact.FormCreate(Sender: TObject);
begin
  Caption := 'Agregar Contacto';
  lblTitle.Caption  := 'Agregar Contacto';
  lblCorreo.Caption := 'Correo';
  btnAgregar.Caption := 'Agregar';
  btnEliminar.Caption := 'Eliminar';
  btnVolver.Caption  := 'Volver';
end;

procedure TfrmNewContact.btnEliminarClick(Sender: TObject);
var
  correo: string;
  ok: Boolean;
begin
  correo := Trim(edtCorreo.Text);
  if correo = '' then
  begin
    ShowMessage('Ingresa el correo del contacto a eliminar.');
    Exit;
  end;

  // Validar que exista como contacto del usuario
  if not GContacts.Has(FOwner, correo) then
  begin
    ShowMessage('Ese correo no está en tus contactos.');
    Exit;
  end;

  // Eliminar (devuelve True si se eliminó)
  ok := GContacts.Remove(FOwner, correo);
  if ok then
  begin
    ShowMessage('Contacto eliminado.');
    // Refrescar lista si la ventana de contactos está abierta
    if Assigned(frmContacts) and frmContacts.Visible then
      frmContacts.RefreshList;
    edtCorreo.Clear;
    edtCorreo.SetFocus;
  end
  else
    ShowMessage('No se pudo eliminar el contacto.');
end;

procedure TfrmNewContact.OpenForUser(const AOwnerEmail: string);
begin
  FOwner := AOwnerEmail;
  edtCorreo.Text := '';
  Show;
end;

procedure TfrmNewContact.btnAgregarClick(Sender: TObject);
var
  correo: string;
begin
  correo := Trim(edtCorreo.Text);
  if correo = '' then begin ShowMessage('Ingresa un correo.'); Exit; end;
  if SameText(correo, FOwner) then begin ShowMessage('No puedes agregarte a ti mismo.'); Exit; end;
  if GUsuarios.FindByEmail(correo) = nil then begin ShowMessage('El correo no existe.'); Exit; end;
  if GContacts.Has(FOwner, correo) then begin ShowMessage('Ese contacto ya existe.'); Exit; end;

  GContacts.Add(FOwner, correo);
  ShowMessage('Contacto agregado.');

  if Assigned(frmContacts) and frmContacts.Visible then
    frmContacts.RefreshList;

  edtCorreo.Text := '';
  edtCorreo.SetFocus;
end;

procedure TfrmNewContact.btnVolverClick(Sender: TObject);
begin
  Hide;
  if not Assigned(frmUserMenu) then
    Application.CreateForm(TfrmUserMenu, frmUserMenu);
  frmUserMenu.Show;
end;

end.

