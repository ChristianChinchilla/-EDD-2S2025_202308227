unit uCommunityPostForm;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls, Dialogs;

type
  { TfrmCommunityPost }
  TfrmCommunityPost = class(TForm)
    btnPublicar: TButton;
    btnVolver: TButton;
    edtComunidad: TEdit;
    lblComunidad: TLabel;
    lblMensaje: TLabel;
    lblTitle: TLabel;
    memMensaje: TMemo;
    pnlTop: TPanel;
    procedure btnPublicarClick(Sender: TObject);
    procedure btnVolverClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    FOwnerEmail: string;
  public
    procedure OpenForUser(const AEmail: string);
  end;

var
  frmCommunityPost: TfrmCommunityPost;

implementation

{$R *.lfm}

uses
  uData, uUserMenu;

procedure TfrmCommunityPost.FormCreate(Sender: TObject);
begin
  Caption := 'Publicar mensaje';
  if Assigned(lblTitle)     then lblTitle.Caption     := 'Publicar mensaje';
  if Assigned(lblComunidad) then lblComunidad.Caption := 'Comunidad';
  if Assigned(lblMensaje)   then lblMensaje.Caption   := 'Mensaje';
  if Assigned(btnPublicar)  then btnPublicar.Caption  := 'Publicar';
  if Assigned(btnVolver)    then btnVolver.Caption    := 'Volver';
end;

procedure TfrmCommunityPost.OpenForUser(const AEmail: string);
begin
  FOwnerEmail := AEmail;
  edtComunidad.Text := '';
  memMensaje.Clear;
  Show;
end;

procedure TfrmCommunityPost.btnPublicarClick(Sender: TObject);
var
  comu, msg: string;
begin
  comu := Trim(edtComunidad.Text);
  msg  := Trim(memMensaje.Text);

  if (comu = '') or (msg = '') then
  begin
    ShowMessage('Ingresa comunidad y mensaje.'); Exit;
  end;

  // Requisito: la comunidad debe existir previamente
  if not CommunityExists(comu) then
  begin
    ShowMessage('La comunidad "'+comu+'" no existe.'); Exit;
  end;

  // Publicar en el BST
  CommunityPost(comu, FOwnerEmail, msg);

  ShowMessage('Mensaje publicado en "'+comu+'".');

  memMensaje.Clear;
  memMensaje.SetFocus;
end;

procedure TfrmCommunityPost.btnVolverClick(Sender: TObject);
begin
  Hide;
  if Assigned(frmUserMenu) then frmUserMenu.Show;
end;

end.

