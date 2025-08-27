unit uUserMenu;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls;

type
  TfrmUserMenu = class(TForm)
    btnBandeja: TButton;
    btnEnviar: TButton;
    lblHola: TLabel;
    btnCerrarSesion: TButton;
    procedure btnBandejaClick(Sender: TObject);
    procedure btnCerrarSesionClick(Sender: TObject);
    procedure btnEnviarClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    FEmailActual: string;
  public
    procedure SetUser(const ANombre, AEmail: string);
  end;

var
  frmUserMenu: TfrmUserMenu;

implementation

{$R *.lfm}

uses
  uMain, uData, uInboxForm, uComposeForm;

procedure TfrmUserMenu.FormCreate(Sender: TObject);
begin
  Caption := 'Usuario estándar';
  lblHola.Caption := 'Hola';
end;

procedure TfrmUserMenu.SetUser(const ANombre, AEmail: string);
begin
  FEmailActual := AEmail;
  if ANombre <> '' then
    lblHola.Caption := 'Hola: ' + ANombre
  else
    lblHola.Caption := 'Hola: ' + AEmail;
end;

procedure TfrmUserMenu.btnCerrarSesionClick(Sender: TObject);
begin
  Form1.Show;
  Hide;
end;

procedure TfrmUserMenu.btnEnviarClick(Sender: TObject);
begin
  if not Assigned(ComposeForm) then
    Application.CreateForm(TfrmCompose, ComposeForm);
  ComposeForm.OpenForUser(FEmailActual);
  Hide; // opcional
end;

procedure TfrmUserMenu.btnBandejaClick(Sender: TObject);
begin
  if not Assigned(frmInbox) then
    Application.CreateForm(TfrmInbox, frmInbox);
  frmInbox.OpenForUser(FEmailActual);
  Hide; // opcional
end;

end.

