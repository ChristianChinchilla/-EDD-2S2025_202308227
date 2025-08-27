program eddmail;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX} cthreads, {$ENDIF}
  {$IFDEF HASAMIGA} athreads, {$ENDIF}
  Interfaces, Forms,
  uMain, uData, uRootMenu, uListaUsuarios, uListaCorreos,
  uUserMenu, uInboxForm, uComposeForm;  // <-- el unit correcto

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Scaled := True;
  {$PUSH}{$WARN 5044 OFF}
  Application.MainFormOnTaskbar := True;
  {$POP}
  Application.Initialize;
  Application.CreateForm(TForm1,       Form1);
  Application.CreateForm(TfrmRootMenu, frmRootMenu);
  Application.CreateForm(TfrmUserMenu, frmUserMenu);
  Application.CreateForm(TfrmInbox,    frmInbox);   // <-- variable frmInbox, NO uInboxForm
  Application.CreateForm(TfrmCompose, frmCompose);
  Application.Run;
end.

