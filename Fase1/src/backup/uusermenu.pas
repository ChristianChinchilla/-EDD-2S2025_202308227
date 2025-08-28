unit uUserMenu;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls;

type
<<<<<<< HEAD
  TfrmUserMenu = class(TForm)
    btnBandeja: TButton;
    btnEnviar: TButton;
=======

  { TfrmUserMenu }

  TfrmUserMenu = class(TForm)
    btnBandeja: TButton;
    btnEnviar: TButton;
    btnPapelera: TButton;   // <-- NUEVO
    btnProgramar: TButton;
>>>>>>> e486c4b (actualizacion en el codigo de bandeja de entrada, interfaz y codigo de enviar correo, interfaz de programar correo, correcciones en papelera y codigo de progrgamar correo)
    lblHola: TLabel;
    btnCerrarSesion: TButton;
    procedure btnBandejaClick(Sender: TObject);
    procedure btnCerrarSesionClick(Sender: TObject);
    procedure btnEnviarClick(Sender: TObject);
<<<<<<< HEAD
=======
    procedure btnPapeleraClick(Sender: TObject);  // <-- NUEVO
    procedure btnProgramarClick(Sender: TObject);
>>>>>>> e486c4b (actualizacion en el codigo de bandeja de entrada, interfaz y codigo de enviar correo, interfaz de programar correo, correcciones en papelera y codigo de progrgamar correo)
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
<<<<<<< HEAD
  uMain, uData, uInboxForm, uComposeForm;
=======
  uMain, uData, uInboxForm, uComposeForm, uTrashForm, uScheduleForm;;  // <-- añade uTrashForm
>>>>>>> e486c4b (actualizacion en el codigo de bandeja de entrada, interfaz y codigo de enviar correo, interfaz de programar correo, correcciones en papelera y codigo de progrgamar correo)

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
<<<<<<< HEAD
  if not Assigned(ComposeForm) then
    Application.CreateForm(TfrmCompose, ComposeForm);
  ComposeForm.OpenForUser(FEmailActual);
  Hide; // opcional
=======
  if not Assigned(frmCompose) then
    Application.CreateForm(TfrmCompose, frmCompose);
  frmCompose.OpenForUser(FEmailActual);
  Hide;
>>>>>>> e486c4b (actualizacion en el codigo de bandeja de entrada, interfaz y codigo de enviar correo, interfaz de programar correo, correcciones en papelera y codigo de progrgamar correo)
end;

procedure TfrmUserMenu.btnBandejaClick(Sender: TObject);
begin
  if not Assigned(frmInbox) then
    Application.CreateForm(TfrmInbox, frmInbox);
  frmInbox.OpenForUser(FEmailActual);
<<<<<<< HEAD
  Hide; // opcional
=======
  Hide;
end;

procedure TfrmUserMenu.btnPapeleraClick(Sender: TObject);  // <-- NUEVO
begin
  if not Assigned(frmTrash) then
    Application.CreateForm(TfrmTrash, frmTrash);
  frmTrash.OpenForUser(FEmailActual);
  Hide;
end;

procedure TfrmUserMenu.btnProgramarClick(Sender: TObject);
begin

>>>>>>> e486c4b (actualizacion en el codigo de bandeja de entrada, interfaz y codigo de enviar correo, interfaz de programar correo, correcciones en papelera y codigo de progrgamar correo)
end;

end.

