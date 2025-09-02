unit uUserMenu;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls;

type
  { TfrmUserMenu }
  TfrmUserMenu = class(TForm)
    btnBandeja: TButton;
    btnEnviar: TButton;
    btnPapelera: TButton;
    btnPerfil: TButton;        // Name=btnPerfil, Caption='Actualizar Perfil'
    btnProgramar: TButton;
    btnProgList: TButton;
    btnCerrarSesion: TButton;
    btnNewContact: TButton;    // Name=btnNewContact, Caption='Nuevo Contacto'
    btnContactos: TButton;
    btnGenerarReportes: TButton; // <-- NUEVO | Name=btnGenerarReportes, Caption='Generar reportes'
    lblHola: TLabel;
    tmrScheduler: TTimer;
    procedure btnBandejaClick(Sender: TObject);
    procedure btnCerrarSesionClick(Sender: TObject);
    procedure btnEnviarClick(Sender: TObject);
    procedure btnPapeleraClick(Sender: TObject);
    procedure btnProgListClick(Sender: TObject);
    procedure btnProgramarClick(Sender: TObject);
    procedure btnNewContactClick(Sender: TObject);
    procedure btnContactosClick(Sender: TObject);
    procedure btnPerfilClick(Sender: TObject);
    procedure btnGenerarReportesClick(Sender: TObject);  // <-- NUEVO
    procedure FormCreate(Sender: TObject);
  private
    FEmailActual: string;
    procedure SchedulerTimer(Sender: TObject);
    function  TryParseProgDate(const S: string; out D: TDateTime): Boolean;
    procedure ProcessDueScheduled;
  public
    procedure SetUser(const ANombre, AEmail: string);
  end;

var
  frmUserMenu: TfrmUserMenu;

implementation

{$R *.lfm}

uses
  uMain, uData, uInboxForm, uComposeForm, uTrashForm,
  uScheduleForm, uProgListForm, DateUtils, uListaCorreos,
  uContacts, uNewContactForm, uProfileForm,
  uUserReports;  // <-- NUEVO: generador de reportes

{ TfrmUserMenu }

procedure TfrmUserMenu.FormCreate(Sender: TObject);
begin
  Caption := 'Usuario estándar';
  lblHola.Caption := 'Hola';
  tmrScheduler := TTimer.Create(Self);
  tmrScheduler.Interval := 30000;
  tmrScheduler.Enabled  := True;
  tmrScheduler.OnTimer  := @SchedulerTimer;

  // por si no lo diste en el diseñador
  if Assigned(btnGenerarReportes) then
    btnGenerarReportes.Caption := 'Generar reportes';
end;

procedure TfrmUserMenu.SetUser(const ANombre, AEmail: string);
begin
  FEmailActual := AEmail;
  if ANOMBRE <> '' then
    lblHola.Caption := 'Hola: ' + ANOMBRE
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
  if not Assigned(frmCompose) then
    Application.CreateForm(TfrmCompose, frmCompose);
  frmCompose.OpenForUser(FEmailActual);
  Hide;
end;

procedure TfrmUserMenu.btnBandejaClick(Sender: TObject);
begin
  if not Assigned(frmInbox) then
    Application.CreateForm(TfrmInbox, frmInbox);
  frmInbox.OpenForUser(FEmailActual);
  Hide;
end;

procedure TfrmUserMenu.btnPapeleraClick(Sender: TObject);
begin
  if not Assigned(frmTrash) then
    Application.CreateForm(TfrmTrash, frmTrash);
  frmTrash.OpenForUser(FEmailActual);
  Hide;
end;

procedure TfrmUserMenu.btnProgListClick(Sender: TObject);
begin
  if not Assigned(frmProgList) then
    Application.CreateForm(TfrmProgList, frmProgList);
  frmProgList.RefreshQueue;
  frmProgList.Show;
  Hide;
end;

procedure TfrmUserMenu.btnProgramarClick(Sender: TObject);
begin
  if not Assigned(frmSchedule) then
    Application.CreateForm(TfrmSchedule, frmSchedule);
  frmSchedule.OpenForUser(FEmailActual);
  Hide;
end;

procedure TfrmUserMenu.btnContactosClick(Sender: TObject);
begin
  if not Assigned(frmContacts) then
    Application.CreateForm(TfrmContacts, frmContacts);
  frmContacts.OpenForUser(FEmailActual);
  Hide;
end;

procedure TfrmUserMenu.btnPerfilClick(Sender: TObject);
begin
  if not Assigned(frmProfile) then
    Application.CreateForm(TfrmProfile, frmProfile);
  frmProfile.OpenForUser(FEmailActual);
  Hide; // opcional
end;

procedure TfrmUserMenu.btnNewContactClick(Sender: TObject);
begin
  if not Assigned(frmNewContact) then
    Application.CreateForm(TfrmNewContact, frmNewContact);
  frmNewContact.OpenForUser(FEmailActual);
  Hide; // opcional
end;

// === NUEVO: generar reportes del usuario ===
procedure TfrmUserMenu.btnGenerarReportesClick(Sender: TObject);
var
  outDir, _ : string;
begin
  _ := GenerateAllUserReports(FEmailActual, outDir);
  ShowMessage(
    'Se generaron los reportes de:' + LineEnding +
    '- correos (inbox)' + LineEnding +
    '- correos eliminados (papelera)' + LineEnding +
    '- correos programados' + LineEnding +
    '- contactos' + LineEnding + LineEnding +
    'Carpeta: ' + outDir
  );
end;

{=====================  AUTOMÁTICO  =====================}

procedure TfrmUserMenu.SchedulerTimer(Sender: TObject);
begin
  ProcessDueScheduled;
  if Assigned(frmProgList) and frmProgList.Visible then
    frmProgList.RefreshQueue;
end;

function TfrmUserMenu.TryParseProgDate(const S: string; out D: TDateTime): Boolean;
var
  fs: TFormatSettings;
begin
  fs := DefaultFormatSettings;
  fs.DateSeparator  := '/';
  fs.TimeSeparator  := ':';
  fs.ShortDateFormat := 'dd/mm/yyyy';
  fs.LongTimeFormat  := 'hh:nn';
  Result := TryStrToDateTime(S, D, fs);
end;

procedure TfrmUserMenu.ProcessDueScheduled;
var
  n: Integer;
  p: PCorreo;
  d: TDateTime;
begin
  n := GScheduled.Count;
  while n > 0 do
  begin
    p := GScheduled.Dequeue;
    if p = nil then Break;

    if TryParseProgDate(p^.programado, d) and (d <= Now) then
    begin
      p^.fecha  := FormatDateTime('dd/mm/yyyy hh:nn', Now);
      p^.estado := 'NL';
      GCorreos.Add(GCorreos.NextId, p^.remitente, p^.destinatario,
                   p^.estado, p^.programado, p^.asunto, p^.fecha, p^.mensaje);
      Dispose(p);
    end
    else
      GScheduled.Enqueue(p);

    Dec(n);
  end;
end;

end.

