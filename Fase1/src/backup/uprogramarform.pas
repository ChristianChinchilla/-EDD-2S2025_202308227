unit uProgListForm;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ComCtrls,
  uData, uListaCorreos, uUserMenu;

type
  { TfrmProgList }
  TfrmProgList = class(TForm)
    btnEnviar: TButton;
    btnVolver: TButton;
    lblTitle: TLabel;
    lvQueue: TListView;
    procedure btnEnviarClick(Sender: TObject);
    procedure btnVolverClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    procedure ConfigListView;
    procedure RefreshQueue;
    procedure EnviarTodos;
  public
  end;

var
  frmProgList: TfrmProgList;

implementation

{$R *.lfm}

{ TfrmProgList }

procedure TfrmProgList.FormCreate(Sender: TObject);
begin
  Caption := 'Correos Programados';
  lblTitle.Caption := 'Correos Programados';
  ConfigListView;
end;

procedure TfrmProgList.FormShow(Sender: TObject);
begin
  RefreshQueue;
end;

procedure TfrmProgList.ConfigListView;
begin
  lvQueue.ViewStyle := vsReport;
  lvQueue.ReadOnly := True;
  lvQueue.RowSelect := True;
  lvQueue.HideSelection := False;

  lvQueue.Columns.Clear;
  with lvQueue.Columns.Add do Caption := 'Asunto';
  with lvQueue.Columns.Add do Caption := 'Remitente';
  with lvQueue.Columns.Add do Caption := 'Destinatario';
  with lvQueue.Columns.Add do Caption := 'Fecha de Envío';
end;

procedure TfrmProgList.RefreshQueue;
var
  snap: TPCorreoArray;
  i: Integer;
  it: TListItem;
begin
  lvQueue.Items.BeginUpdate;
  try
    lvQueue.Items.Clear;
    snap := GScheduled.Snapshot;
    for i := 0 to High(snap) do
    begin
      it := lvQueue.Items.Add;
      it.Caption := snap[i]^.asunto;
      it.SubItems.Add(snap[i]^.remitente);
      it.SubItems.Add(snap[i]^.destinatario);
      it.SubItems.Add(snap[i]^.programado);
      // Tip: si quieres guardar el puntero por si luego haces “enviar seleccionado”:
      // it.Data := snap[i];
    end;
  finally
    lvQueue.Items.EndUpdate;
  end;
end;

procedure TfrmProgList.EnviarTodos;
var
  p: PCorreo;
begin
  // Vacía la cola GScheduled y mete los correos a la lista general GCorreos
  // Marcamos como “NL” y limpiamos “programado”. Ajusta fecha a “ahora”.
  while GScheduled.Peek <> nil do
  begin
    p := GScheduled.Dequeue;   // sale de la cola, NO se libera aún
    if p <> nil then
    begin
      GCorreos.Add(
        GCorreos.NextId,
        p^.remitente,
        p^.destinatario,
        'NL',                 // estado (no leído)
        '',                   // programado (ya se envió)
        p^.asunto,
        FormatDateTime('dd/mm/yy hh:nn', Now),
        p^.mensaje
      );
      // El programado era un nodo “solo en cola”: libéralo
      Dispose(p);
    end;
  end;
end;

procedure TfrmProgList.btnEnviarClick(Sender: TObject);
begin
  if GScheduled.Count = 0 then
  begin
    ShowMessage('No hay correos en la cola.');
    Exit;
  end;
  EnviarTodos;
  RefreshQueue;
  ShowMessage('Correos enviados.');
end;

procedure TfrmProgList.btnVolverClick(Sender: TObject);
begin
  Hide;
  if Assigned(frmUserMenu) then
    frmUserMenu.Show;
end;

end.

