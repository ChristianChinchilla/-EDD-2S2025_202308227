program eddmail;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  {$IFDEF HASAMIGA}athreads,{$ENDIF}
  Interfaces, Forms, uMain, uData, uRootMenu, uListaUsuarios, uListaCorreos,
  uUserMenu, uInboxForm, uComposeForm, uTrashForm, uScheduleForm, uProgListForm,
  uContacts, uNewContactForm, uProfileForm, uUserReports, comunidadesMenu,
  ListaDeListas;

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
  Application.CreateForm(TfrmInbox,    frmInbox);
  Application.CreateForm(TfrmCompose,  frmCompose);
  Application.CreateForm(TfrmTrash,    frmTrash);
  Application.CreateForm(TfrmSchedule, frmSchedule);
  Application.CreateForm(TfrmProgList, frmProgList);
  Application.CreateForm(TfrmNewContact, frmNewContact);
  Application.CreateForm(TfrmProfile, frmProfile);
  Application.CreateForm(TcomunidadesForm, comunidadesForm);
  Application.Run;
end.

