unit uProgListForm;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ComCtrls, Dialogs;

type

  { TfrmProgList }

  TfrmProgList = class(TForm)
    lblTitle: TLabel;
    lvQueue : TListView;
    btnEnviar: TButton;
    btnVolver: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnEnviarClick(Sender: TObject);
    procedure btnVolverClick(Sender: TObject);
  private
    procedure ConfigListView;
  public
    procedure RefreshQueue;
  end;

var
  frmProgList: TfrmProgList;

implementation

{$R *.lfm}

uses uData, uListaCorreos, uUserMenu, DateUtils;

procedure TfrmProgList.FormCreate(Sender: TObject);
begin
  Caption := 'Correos Programados';
  ConfigListView;
end;

procedure TfrmProgList.ConfigListView;
begin
  lvQueue.ViewStyle    := vsReport;
  lvQueue.ReadOnly     := True;
  lvQueue.RowSelect    := True;
  lvQueue.HideSelection:= False;
  lvQueue.Columns.Clear;
  with lvQueue.Columns.Add do begin Caption := 'Asunto';        Width := 180; end;
  with lvQueue.Columns.Add do begin Caption := 'Remitente';     Width := 160; end;
  with lvQueue.Columns.Add do begin Caption := 'Destinatario';  Width := 160; end;
  with lvQueue.Columns.Add do begin Caption := 'Fecha de envío';Width := 130; end;
end;

procedure TfrmProgList.FormShow(Sender: TObject);
begin
  RefreshQueue;
end;

procedure TfrmProgList.RefreshQueue;
var
  arr: TPCorreoArray;
  i  : SizeInt;
  it : TListItem;
begin
  lvQueue.Items.BeginUpdate;
  try
    lvQueue.Items.Clear;
    arr := GScheduled.Snapshot;
    for i := Low(arr) to High(arr) do
    begin
      it := lvQueue.Items.Add;
      it.Caption := arr[i]^.asunto;
      it.SubItems.Add(arr[i]^.remitente);
      it.SubItems.Add(arr[i]^.destinatario);
      it.SubItems.Add(arr[i]^.programado);
      it.Data := arr[i];
    end;
  finally
    lvQueue.Items.EndUpdate;
  end;
end;

procedure TfrmProgList.btnEnviarClick(Sender: TObject);
var
  p: PCorreo;
begin
  while GScheduled.Count > 0 do
  begin
    p := GScheduled.Dequeue;
    if p = nil then Break;
    p^.fecha  := FormatDateTime('dd/mm/yyyy hh:nn', Now);
    p^.estado := 'NL';
    GCorreos.Add(GCorreos.NextId, p^.remitente, p^.destinatario, p^.estado,
                 p^.programado, p^.asunto, p^.fecha, p^.mensaje);
    Dispose(p);
  end;
  ShowMessage('Correos enviados.');
  RefreshQueue;
end;

procedure TfrmProgList.btnVolverClick(Sender: TObject);
begin
  Hide;
  if Assigned(frmUserMenu) then frmUserMenu.Show;
end;

end.
