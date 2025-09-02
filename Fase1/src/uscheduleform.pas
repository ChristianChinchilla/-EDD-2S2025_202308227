unit uScheduleForm;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, Dialogs;

type
  { TfrmSchedule }
  TfrmSchedule = class(TForm)
    lblDest: TLabel;
    lblAsu: TLabel;
    lblMsg: TLabel;
    lblFecha: TLabel;
    edtDest: TEdit;
    edtAsu: TEdit;
    memMsg: TMemo;
    edtFecha: TEdit;   // formato libre, ej. 31/12/2025 18:00
    btnProgramar: TButton;
    btnVolver: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btnProgramarClick(Sender: TObject);
    procedure btnVolverClick(Sender: TObject);
  private
    FRemitente: string;
    function Validar(out ADest,AAsunto,AMsg,AProg: string): Boolean;
  public
    procedure OpenForUser(const AEmail: string);
  end;

var
  frmSchedule: TfrmSchedule;

implementation

{$R *.lfm}

uses uUserMenu, uData, uListaCorreos, DateUtils;

procedure TfrmSchedule.FormCreate(Sender: TObject);
begin
  Caption := 'Programar Correo'
end;

procedure TfrmSchedule.OpenForUser(const AEmail: string);
begin
  FRemitente := AEmail;
  edtDest.Text:=''; edtAsu.Text:=''; memMsg.Lines.Clear; edtFecha.Text:='';
  Show;
end;

function TfrmSchedule.Validar(out ADest,AAsunto,AMsg,AProg: string): Boolean;
begin
  ADest   := Trim(edtDest.Text);
  AAsunto := Trim(edtAsu.Text);
  AMsg    := Trim(memMsg.Text);
  AProg   := Trim(edtFecha.Text);

  if ADest='' then begin ShowMessage('Ingresa el destinatario.'); Exit(False) end;
  if not EsContacto(FRemitente, ADest) then begin
    ShowMessage('No puedes enviar a "'+ADest+'". No está en tus contactos.');
    Exit(False);
  end;
  if AAsunto='' then begin ShowMessage('Ingresa un asunto.'); Exit(False) end;
  if AMsg='' then begin ShowMessage('Escribe un mensaje.'); Exit(False) end;
  if AProg='' then begin ShowMessage('Ingresa la fecha/hora de envío.'); Exit(False) end;
  Result := True;
end;

procedure TfrmSchedule.btnProgramarClick(Sender: TObject);
var
  dest,asu,msg,prog: string;
  id: LongInt;
  p: PCorreo;
begin
  if not Validar(dest,asu,msg,prog) then Exit;

  id := GCorreos.NextId;
  // Creamos el correo en la lista principal y encolamos el mismo puntero
  p := GCorreos.Add(id, FRemitente, dest, 'NL', prog, asu,
                    FormatDateTime('dd/mm/yyyy hh:nn', Now), msg);
  GScheduled.Enqueue(p);

  ShowMessage('Correo programado para: ' + prog);
  edtDest.Text:=''; edtAsu.Text:=''; memMsg.Lines.Clear; edtFecha.Text:='';
end;

procedure TfrmSchedule.btnVolverClick(Sender: TObject);
begin
  Hide;
  if Assigned(frmUserMenu) then
    frmUserMenu.Show
end;

end.

