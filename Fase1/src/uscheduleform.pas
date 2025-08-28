unit uScheduleForm;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, Dialogs, DateUtils,
  uListaCorreos; // PCorreo

type
  TfrmSchedule = class(TForm)
    lblTitle, lblDest, lblAsunto, lblMsg, lblFecha: TLabel;
    edDest, edAsunto, edFecha: TEdit;
    memMsg: TMemo;
    btnProgramar, btnVolver: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btnVolverClick(Sender: TObject);
    procedure btnProgramarClick(Sender: TObject);
  private
    FEmailActual: string; // remitente
    function ParseDateTimeSafe(const S: string; out DT: TDateTime): Boolean;
  public
    procedure OpenForUser(const AEmail: string);
  end;

var
  frmSchedule: TfrmSchedule;

implementation

{$R *.lfm}

uses uUserMenu, uData; // EsContacto, GCorreos, GScheduled

procedure TfrmSchedule.FormCreate(Sender: TObject);
begin
  Caption := 'Programar correo';
  lblTitle.Caption := 'Programar Correo';
  lblDest.Caption  := 'Destinatario';
  lblAsunto.Caption:= 'Asunto';
  lblMsg.Caption   := 'Mensaje';
  lblFecha.Caption := 'Fecha y hora (YYYY-MM-DD HH:MM)';
  btnProgramar.Caption := 'Programar';
  btnVolver.Caption    := 'Volver';

  // Por si el diseñador pierde eventos
  btnProgramar.OnClick := @btnProgramarClick;
  btnVolver.OnClick    := @btnVolverClick;
end;

procedure TfrmSchedule.OpenForUser(const AEmail: string);
begin
  FEmailActual := AEmail;
  edDest.Text   := '';
  edAsunto.Text := '';
  memMsg.Lines.Text := '';
  edFecha.Text  := '';
  Show;
end;

procedure TfrmSchedule.btnVolverClick(Sender: TObject);
begin
  Hide;
  if Assigned(frmUserMenu) then frmUserMenu.Show;
end;

function TfrmSchedule.ParseDateTimeSafe(const S: string; out DT: TDateTime): Boolean;
var
  Y, M, D, HH, NN: Integer;
  A, B: String;
begin
  // Espera: "YYYY-MM-DD HH:MM"
  Result := False;
  if Length(S) < 16 then Exit;
  A := Trim(Copy(S, 1, 10));
  B := Trim(Copy(S, 12, 5));
  try
    Y := StrToInt(Copy(A,1,4));
    M := StrToInt(Copy(A,6,2));
    D := StrToInt(Copy(A,9,2));
    HH := StrToInt(Copy(B,1,2));
    NN := StrToInt(Copy(B,4,2));
    DT := EncodeDateTime(Y,M,D,HH,NN,0,0);
    Result := True;
  except
    on E: Exception do Result := False;
  end;
end;

procedure TfrmSchedule.btnProgramarClick(Sender: TObject);
var
  dest, asunto, mensaje: string;
  dt: TDateTime;
  p: PCorreo;
begin
  dest    := Trim(edDest.Text);
  asunto  := Trim(edAsunto.Text);
  mensaje := Trim(memMsg.Lines.Text);

  if (dest = '') or (asunto = '') or (mensaje = '') then
  begin
    MessageDlg('Faltan datos', 'Completa destinatario, asunto y mensaje.', mtWarning, [mbOK], 0);
    Exit;
  end;

  if not EsContacto(FEmailActual, dest) then
  begin
    MessageDlg('Destinatario', 'El destinatario no existe en usuarios.', mtWarning, [mbOK], 0);
    Exit;
  end;

  if not ParseDateTimeSafe(Trim(edFecha.Text), dt) then
  begin
    MessageDlg('Fecha', 'Formato inválido. Usa: YYYY-MM-DD HH:MM', mtWarning, [mbOK], 0);
    Exit;
  end;

  // Creamos el correo como puntero y lo ponemos en la COLA de programados
  New(p);
  p^.id           := GCorreos.NextId;   // toma un id libre
  p^.remitente    := FEmailActual;
  p^.destinatario := dest;
  p^.estado       := 'P';               // Programado
  p^.programado   := 'SI';
  p^.asunto       := asunto;
  p^.fecha        := FormatDateTime('yyyy-mm-dd hh:nn', dt);
  p^.mensaje      := mensaje;
  p^.next := nil; p^.prev := nil;

  GScheduled.Enqueue(p);

  MessageDlg('Listo', 'Correo programado y agregado a la cola.', mtInformation, [mbOK], 0);
  // Limpia el formulario para otro registro
  edDest.Text := ''; edAsunto.Text := ''; memMsg.Clear; edFecha.Text := '';
end;

end.

