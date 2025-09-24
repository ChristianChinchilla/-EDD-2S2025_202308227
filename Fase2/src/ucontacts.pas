unit uContacts;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls;

type
  { TfrmContacts }
  TfrmContacts = class(TForm)
    btnPrev: TButton;
    btnNext: TButton;
    btnVolver: TButton;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    lblNombreT,   lblNombreV:   TLabel;
    lblUsuarioT,  lblUsuarioV:  TLabel;
    lblCorreoT,   lblCorreoV:   TLabel;
    lblTelefonoT, lblTelefonoV: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure btnPrevClick(Sender: TObject);
    procedure btnNextClick(Sender: TObject);
    procedure btnVolverClick(Sender: TObject);
  private
    FOwner : string;
    FList  : TStringList;
    FIndex : Integer;
    procedure UpdateView;
  public
    procedure OpenForUser(const AOwnerEmail: string);
    procedure RefreshList;
  end;

var
  frmContacts: TfrmContacts;

implementation

{$R *.lfm}

uses
  uData, uListaUsuarios, uUserMenu;

{ TfrmContacts }

procedure TfrmContacts.FormCreate(Sender: TObject);
begin
  Caption := 'Contacts';
  FList := TStringList.Create;
  FIndex := -1;
end;

procedure TfrmContacts.OpenForUser(const AOwnerEmail: string);
begin
  FOwner := AOwnerEmail;
  RefreshList;
  Show;
end;

procedure TfrmContacts.RefreshList;
begin
  FreeAndNil(FList);
  FList := GContacts.GetListCopy(FOwner);
  if FList.Count > 0 then
    FIndex := 0
  else
    FIndex := -1;
  UpdateView;
end;

procedure TfrmContacts.UpdateView;
var
  u: PUsuario;
begin
  if (FIndex < 0) or (FIndex >= FList.Count) then
  begin
    lblNombreV.Caption   := '(sin contactos)';
    lblUsuarioV.Caption  := '';
    lblCorreoV.Caption   := '';
    lblTelefonoV.Caption := '';
    Exit;
  end;

  lblCorreoV.Caption := FList[FIndex];
  u := GUsuarios.FindByEmail(lblCorreoV.Caption);

  if u <> nil then
  begin
    lblNombreV.Caption   := u^.nombre;
    lblUsuarioV.Caption  := u^.usuario;
    lblTelefonoV.Caption := u^.telefono;
  end
  else
  begin
    lblNombreV.Caption   := '(desconocido)';
    lblUsuarioV.Caption  := '';
    lblTelefonoV.Caption := '';
  end;
end;

procedure TfrmContacts.btnPrevClick(Sender: TObject);
begin
  if FList.Count = 0 then Exit;
  if FIndex > 0 then
    Dec(FIndex)
  else
    FIndex := FList.Count - 1;
  UpdateView;
end;

procedure TfrmContacts.btnNextClick(Sender: TObject);
begin
  if FList.Count = 0 then Exit;
  if FIndex < FList.Count - 1 then
    Inc(FIndex)
  else
    FIndex := 0;
  UpdateView;
end;

procedure TfrmContacts.btnVolverClick(Sender: TObject);
begin
  Hide;
  if not Assigned(frmUserMenu) then
    Application.CreateForm(TfrmUserMenu, frmUserMenu);
  frmUserMenu.Show;
end;

end.

