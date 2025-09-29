unit uNewContactForm;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls, Dialogs;

type
  { TfrmNewContact }
  TfrmNewContact = class(TForm)
    pnlCard: TPanel;
    lblTitle: TLabel;
    lblCorreo: TLabel;
    edtCorreo: TEdit;
    btnAgregar: TButton;
    btnVolver: TButton;
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

uses uData, uContacts, uUserMenu;

procedure TfrmNewContact.FormCreate(Sender: TObject);
begin
  Caption := 'Agregar Contacto';
  lblTitle.Caption  := 'Agregar Contacto';
  lblCorreo.Caption := 'Correo';
  btnAgregar.Caption := 'Agregar';
  btnVolver.Caption  := 'Volver';
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

