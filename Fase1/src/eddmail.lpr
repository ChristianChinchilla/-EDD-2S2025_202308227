program eddmail;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX} cthreads, {$ENDIF}
  {$IFDEF HASAMIGA} athreads, {$ENDIF}
<<<<<<< HEAD
  Interfaces, Forms,
  uMain, uData, uRootMenu, uListaUsuarios, uListaCorreos,
  uUserMenu, uInboxForm, uComposeForm;  // <-- el unit correcto
=======
  Interfaces, Forms, uMain, uData, uRootMenu, uListaUsuarios, uListaCorreos,
  uUserMenu, uInboxForm, uComposeForm, uTrashForm,
  uScheduleForm;  // <-- el unit correcto
>>>>>>> e486c4b (actualizacion en el codigo de bandeja de entrada, interfaz y codigo de enviar correo, interfaz de programar correo, correcciones en papelera y codigo de progrgamar correo)

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
<<<<<<< HEAD
  Application.CreateForm(TfrmCompose, ComposeForm);
=======
  Application.CreateForm(TfrmCompose, frmCompose);
  Application.CreateForm(TfrmTrash, frmTrash);
  Application.CreateForm(TfrmSchedule, frmSchedule);
>>>>>>> e486c4b (actualizacion en el codigo de bandeja de entrada, interfaz y codigo de enviar correo, interfaz de programar correo, correcciones en papelera y codigo de progrgamar correo)
  Application.Run;
end.

