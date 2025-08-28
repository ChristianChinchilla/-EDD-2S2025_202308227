unit uComposeForm;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, Dialogs;

type
  { TfrmCompose }
  TfrmCompose = class(TForm)
    lblPara: TLabel;
    lblAsunto: TLabel;
    lblMensaje: TLabel;
    edtPara: TEdit;
    edtAsunto: TEdit;
    memMensaje: TMemo;
    btnEnviar: TButton;
    btnVolver: TButton;
    procedure btnEnviarClick(Sender: TObject);
    procedure btnVolverClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    FRemitente: string;
    function ValidarCampos(out ADest, AAsunto, AMsg: string): Boolean;
  public
    procedure OpenForUser(const AEmail: string);
  end;

var
<<<<<<< HEAD
  ComposeForm: TfrmCompose;
=======
  frmCompose: TfrmCompose;
>>>>>>> e486c4b (actualizacion en el codigo de bandeja de entrada, interfaz y codigo de enviar correo, interfaz de programar correo, correcciones en papelera y codigo de progrgamar correo)

implementation

{$R *.lfm}

uses
  uUserMenu, uData, uListaCorreos, DateUtils;

{ TfrmCompose }

procedure TfrmCompose.FormCreate(Sender: TObject);
begin
  Caption := 'Enviar Correo';
end;

procedure TfrmCompose.OpenForUser(const AEmail: string);
begin
  FRemitente := AEmail;
  // Limpia campos cada vez que abras
  edtPara.Text   := '';
  edtAsunto.Text := '';
  memMensaje.Lines.Clear;
  Show;
end;

function TfrmCompose.ValidarCampos(out ADest, AAsunto, AMsg: string): Boolean;
begin
  ADest   := Trim(edtPara.Text);
  AAsunto := Trim(edtAsunto.Text);
  AMsg    := Trim(memMensaje.Text);

  if ADest = '' then begin
    ShowMessage('Ingresa el destinatario.');
    Exit(False);
  end;

  if not EsContacto(FRemitente, ADest) then begin
    ShowMessage('No puedes enviar a "'+ADest+'". No está en tus contactos.');
    Exit(False);
  end;

  if AAsunto = '' then begin
    ShowMessage('Ingresa un asunto.');
    Exit(False);
  end;

  if AMsg = '' then begin
    ShowMessage('Escribe un mensaje.');
    Exit(False);
  end;

  Result := True;
end;

procedure TfrmCompose.btnEnviarClick(Sender: TObject);
var
  dest, asunto, cuerpo: string;
  nuevoId: LongInt;
begin
  if not ValidarCampos(dest, asunto, cuerpo) then Exit;

  // Generar ID y registrar el correo como "No leído" en la bandeja del destinatario
  nuevoId := GCorreos.NextId; // <- ver Paso 3 para añadir NextId si aún no existe
  GCorreos.Add(
    nuevoId,
    FRemitente,         // remitente
    dest,               // destinatario
    'NL',               // estado (No leído)
    '',                 // programado
    asunto,
    FormatDateTime('dd/mm/yyyy hh:nn', Now),
    cuerpo
  );

  ShowMessage('Correo enviado a ' + dest + '.');
  // Limpia para el siguiente
  edtPara.Text   := '';
  edtAsunto.Text := '';
  memMensaje.Lines.Clear;
end;

procedure TfrmCompose.btnVolverClick(Sender: TObject);
begin
  Hide;
  if Assigned(frmUserMenu) then frmUserMenu.Show;
end;

end.

