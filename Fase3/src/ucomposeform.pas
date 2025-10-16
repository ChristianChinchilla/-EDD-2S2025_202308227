unit uComposeForm;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, Dialogs;

type

  { TfrmCompose }

  TfrmCompose = class(TForm)
    btnEnviar: TButton;
    btnGuardarBorrador: TButton;
    edtPara: TEdit;
    edtAsunto: TEdit;
    memMensaje: TMemo;
    lblPara: TLabel;
    lblAsunto: TLabel;
    lblMensaje: TLabel;
    btnVolver: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btnEnviarClick(Sender: TObject);
    procedure btnGuardarBorradorClick(Sender: TObject);
    procedure btnVolverClick(Sender: TObject);
  private
    FRemitente: string;
  public
    procedure OpenForUser(const AEmail: string);
    procedure LoadFromDraft(const Dest, Asunto, Mensaje: string);
  end;

var
  frmCompose: TfrmCompose;

implementation

{$R *.lfm}

uses
  uData, uListaCorreos, DateUtils, uUserMenu,
  uDraftsForm;  // RefreshDraftsView

procedure TfrmCompose.FormCreate(Sender: TObject);
begin
  Caption := 'Enviar correo';
  btnGuardarBorrador.Caption := 'Guardar borrador';
end;

procedure TfrmCompose.OpenForUser(const AEmail: string);
begin
  FRemitente := AEmail;
  edtPara.Text := '';
  edtAsunto.Text := '';
  memMensaje.Clear;
  Show;
end;

procedure TfrmCompose.LoadFromDraft(const Dest, Asunto, Mensaje: string);
begin
  edtPara.Text := Dest;
  edtAsunto.Text := Asunto;
  memMensaje.Lines.Text := Mensaje;
end;

procedure TfrmCompose.btnEnviarClick(Sender: TObject);
var
  para, asu, msg, fecha: string;
begin
  para := Trim(edtPara.Text);
  asu  := Trim(edtAsunto.Text);
  msg  := Trim(memMensaje.Text);

  if (para='') or (asu='') or (msg='') then
  begin
    ShowMessage('Completa destinatario, asunto y mensaje.');
    Exit;
  end;

  // validar contacto
  if not EsContacto(FRemitente, para) then
  begin
    ShowMessage('El destinatario no está en tus contactos.');
    Exit;
  end;

  fecha := FormatDateTime('dd/mm/yyyy hh:nn', Now);
  GCorreos.Add(GCorreos.NextId, FRemitente, para, 'NL', '', asu, fecha, msg);

  ShowMessage('Correo enviado.');
  Hide;
  if Assigned(frmUserMenu) then frmUserMenu.Show;
end;

procedure TfrmCompose.btnGuardarBorradorClick(Sender: TObject);
var
  para, asu, msg, fecha: string;
begin
  para := Trim(edtPara.Text);
  asu  := Trim(edtAsunto.Text);
  msg  := memMensaje.Text;

  if (para='') and (asu='') and (Trim(msg)='') then
  begin
    ShowMessage('No hay contenido para guardar.');
    Exit;
  end;

  fecha := FormatDateTime('dd/mm/yyyy hh:nn', Now);
  GDrafts.Add(FRemitente, para, asu, fecha, msg);
  ShowMessage('Borrador guardado.');

  // refrescar borradores (si está abierto o al abrirse)
  RefreshDraftsView(FRemitente);
end;

procedure TfrmCompose.btnVolverClick(Sender: TObject);
begin
  Hide;
  if Assigned(frmUserMenu) then frmUserMenu.Show;
end;

end.

