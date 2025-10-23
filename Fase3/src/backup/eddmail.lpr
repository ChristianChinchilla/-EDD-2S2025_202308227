program eddmail;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  {$IFDEF HASAMIGA}athreads,{$ENDIF}
  Interfaces, Forms, uMain, uData, uRootMenu, uListaUsuarios, uListaCorreos,
  uUserMenu, uInboxForm, uComposeForm, uTrashForm, uScheduleForm, uProgListForm,
  uContacts, uNewContactForm, uProfileForm, uUserReports, comunidadesMenu,
  ListaDeListas, uDraftsForm, uFavoritesForm, uCommunityPostForm,
  BST_Comunidades, uCommunityMessagesForm, uLogControlForm,
  uLZWCompressor, uPrivadosForm;  // <- el form existe, pero NO se autocrea

{$R *.res}

begin
  // Permitir formularios sin .lfm (resource-less), como TfrmLoginLog
  RequireDerivedFormResource := False;

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
  Application.CreateForm(TfrmProfile,  frmProfile);
  Application.CreateForm(TcomunidadesForm, comunidadesForm);
  Application.CreateForm(TfrmDrafts,   frmdrafts);
  Application.CreateForm(TfrmFavorites, frmFavorites);
  Application.CreateForm(TfrmCommunityPost, frmCommunityPost);
  Application.CreateForm(TfrmCommunityMessages, frmCommunityMessages);

  // OJO: ya no hay "Application.CreateForm(TfrmLoginLog, frmLoginLog);"
  Application.CreateForm(TForm2, Form2);
  Application.Run;
end.

