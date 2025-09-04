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
    procedure AutoSizeColumns;
  public
    procedure RefreshQueue;
  end;

var
  frmProgList: TfrmProgList;

implementation

{$R *.lfm}

uses
  uData, uListaCorreos, uUserMenu, DateUtils, Math;

{ TfrmProgList }

procedure TfrmProgList.FormCreate(Sender: TObject);
begin
  Caption := 'Correos Programados';
  ConfigListView;
end;

procedure TfrmProgList.ConfigListView;
begin
  lvQueue.ViewStyle           := vsReport;
  lvQueue.ReadOnly            := True;
  lvQueue.RowSelect           := True;
  lvQueue.HideSelection       := False;
  lvQueue.GridLines           := True;
  lvQueue.ShowColumnHeaders   := True;
  lvQueue.AutoWidthLastColumn := True;

  // Encabezados (sin "Destinatario")
  lvQueue.Columns.Clear;
  with lvQueue.Columns.Add do
  begin
    Caption := 'Asunto';
    Width   := 220;
  end;
  with lvQueue.Columns.Add do
  begin
    Caption := 'Remitente';
    Width   := 160;
  end;
  with lvQueue.Columns.Add do
  begin
    Caption := 'Fecha de envío';
    Width   := 140;
  end;
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
      it.Caption := arr[i]^.asunto;        // Columna 1
      it.SubItems.Add(arr[i]^.remitente);  // Columna 2
      it.SubItems.Add(arr[i]^.programado); // Columna 3 (Fecha de envío)
      it.Data := arr[i];
    end;

    AutoSizeColumns;
  finally
    lvQueue.Items.EndUpdate;
  end;
end;

procedure TfrmProgList.AutoSizeColumns;
const
  PADDING = 18;
var
  i, r: Integer;
  w, maxw: Integer;
  s: String;
begin
  if lvQueue.Columns.Count = 0 then Exit;

  // Ajusta todas menos la última (se expande con AutoWidthLastColumn)
  for i := 0 to lvQueue.Columns.Count - 2 do
  begin
    maxw := lvQueue.Canvas.TextWidth(lvQueue.Columns[i].Caption) + PADDING;
    for r := 0 to lvQueue.Items.Count - 1 do
    begin
      if i = 0 then s := lvQueue.Items[r].Caption
               else s := lvQueue.Items[r].SubItems[i-1];
      w := lvQueue.Canvas.TextWidth(s) + PADDING;
      if w > maxw then maxw := w;
    end;
    maxw := Min(maxw, 600);
    lvQueue.Columns[i].Width := maxw;
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

