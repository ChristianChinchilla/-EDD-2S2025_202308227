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

    // Helpers para admitir “nombre” (local-part)
    function LocalPart(const S: string): string;
    function ResolveInputToEmailForOwner(const Input: string): string; // para eliminar
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
  lblTitle.Caption  := 'Agregar/Eliminar Contacto';
  lblCorreo.Caption := 'Correo o nombre';
  btnAgregar.Caption := 'Agregar';
  btnEliminar.Caption := 'Eliminar';
  btnVolver.Caption  := 'Volver';
end;

function TfrmNewContact.LocalPart(const S: string): string;
var p: SizeInt;
begin
  Result := Trim(S);
  p := Pos('@', Result);
  if p > 0 then
    Result := Copy(Result, 1, p-1);
end;

function TfrmNewContact.ResolveInputToEmailForOwner(const Input: string): string;
var
  L: TStringList;
  i: Integer;
  needle: string;
begin
  Result := '';
  if Pos('@', Input) > 0 then
  begin
    Result := Trim(Input);
    Exit;
  end;

  L := GContacts.GetListCopy(FOwner);
  try
    needle := Trim(Input);
    for i := 0 to L.Count-1 do
      if SameText(LocalPart(L[i]), needle) then
        Exit(L[i]);

    L.Free;
  end;
end;

procedure TfrmNewContact.btnEliminarClick(Sender: TObject);
var
  input, email: string;
  ok: Boolean;
begin
  input := Trim(edtCorreo.Text);
  if input = '' then
  begin
    ShowMessage('Ingresa el correo o el nombre del contacto a eliminar.');
    Exit;
  end;

  email := ResolveInputToEmailForOwner(input);
  if email = '' then
  begin
    ShowMessage('No se encontró ese contacto en tu lista. '+
                'Escribe el correo completo o el nombre tal como aparece antes del @.');
    Exit;
  end;

  if not GContacts.Has(FOwner, email) then
  begin
    ShowMessage('Ese contacto no está en tu lista.');
    Exit;
  end;

  ok := GContacts.Remove(FOwner, email);
  if ok then
  begin
    ShowMessage('Contacto eliminado.');
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
  input, email: string;
begin
  input := Trim(edtCorreo.Text);
  if input = '' then begin ShowMessage('Ingresa un correo o nombre.'); Exit; end;

  // *** NUEVO: permitir “nombre” (local-part) al agregar ***
  if Pos('@', input) = 0 then
    email := input + '@edd.com'     // regla del proyecto
  else
    email := input;

  if SameText(email, FOwner) then begin ShowMessage('No puedes agregarte a ti mismo.'); Exit; end;

  if GUsuarios.FindByEmail(email) = nil then
  begin
    ShowMessage('El correo no existe.');
    Exit;
  end;

  if GContacts.Has(FOwner, email) then begin ShowMessage('Ese contacto ya existe.'); Exit; end;

  GContacts.Add(FOwner, email);
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

