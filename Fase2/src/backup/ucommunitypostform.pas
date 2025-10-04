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
  uData, uUserMenu; // GCommunity vive en uData

procedure TfrmCommunityPost.FormCreate(Sender: TObject);
begin
  Caption := 'Publicar mensaje';
  if Assigned(lblTitle) then lblTitle.Caption := 'Publicar mensaje';
  if Assigned(lblComunidad) then lblComunidad.Caption := 'Comunidad';
  if Assigned(lblMensaje) then lblMensaje.Caption := 'Mensaje';
  if Assigned(btnPublicar) then btnPublicar.Caption := 'Publicar';
  if Assigned(btnVolver) then btnVolver.Caption := 'Volver';
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
  comu, msg, fecha: string;
begin
  comu := Trim(edtComunidad.Text);
  msg  := Trim(memMensaje.Text);

  if (comu = '') or (msg = '') then
  begin
    ShowMessage('Ingresa comunidad y mensaje.'); Exit;
  end;

  // Debe EXISTIR la comunidad (según tu requerimiento)
  if (not GCommunity.Exists(comu)) then
  begin
    ShowMessage('La comunidad "'+comu+'" no existe.'); Exit;
  end;

  // Guardar el mensaje en el store de comunidades
  fecha := FormatDateTime('dd/mm/yyyy hh:nn', Now);
  GCommunity.Post(comu, FOwnerEmail, msg, fecha);

  ShowMessage('Mensaje publicado en "'+comu+'".');

  // Limpiar para otro post
  memMensaje.Clear;
  memMensaje.SetFocus;
end;

procedure TfrmCommunityPost.btnVolverClick(Sender: TObject);
begin
  Hide;
  if Assigned(frmUserMenu) then frmUserMenu.Show;
end;

end.

