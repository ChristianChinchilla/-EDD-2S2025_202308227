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

var frmCompose: TfrmCompose;

implementation

{$R *.lfm}

uses uUserMenu, uData, uListaCorreos, DateUtils;

procedure TfrmCompose.FormCreate(Sender: TObject);
begin Caption := 'Enviar Correo' end;

procedure TfrmCompose.OpenForUser(const AEmail: string);
begin
  FRemitente := AEmail;
  edtPara.Text := ''; edtAsunto.Text := ''; memMensaje.Lines.Clear;
  Show;
end;

function TfrmCompose.ValidarCampos(out ADest, AAsunto, AMsg: string): Boolean;
begin
  ADest := Trim(edtPara.Text);
  AAsunto := Trim(edtAsunto.Text);
  AMsg := Trim(memMensaje.Text);

  if ADest='' then begin ShowMessage('Ingresa el destinatario.'); Exit(False) end;
  if not EsContacto(FRemitente, ADest) then begin
    ShowMessage('No puedes enviar a "'+ADest+'". No está en tus contactos.');
    Exit(False);
  end;
  if AAsunto='' then begin ShowMessage('Ingresa un asunto.'); Exit(False) end;
  if AMsg='' then begin ShowMessage('Escribe un mensaje.'); Exit(False) end;

  Result := True;
end;

procedure TfrmCompose.btnEnviarClick(Sender: TObject);
var dest, asunto, cuerpo: string; nuevoId: LongInt;
begin
  if not ValidarCampos(dest, asunto, cuerpo) then Exit;

  nuevoId := GCorreos.NextId;
  GCorreos.Add(nuevoId, FRemitente, dest, 'NL', '', asunto,
               FormatDateTime('dd/mm/yyyy hh:nn', Now), cuerpo);
  ShowMessage('Correo enviado a ' + dest + '.');
  edtPara.Text:=''; edtAsunto.Text:=''; memMensaje.Lines.Clear;
end;

procedure TfrmCompose.btnVolverClick(Sender: TObject);
begin Hide; if Assigned(frmUserMenu) then frmUserMenu.Show end;

end.

