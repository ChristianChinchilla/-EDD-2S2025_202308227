unit uProgListForm;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ComCtrls, Dialogs;

type
  { TfrmProgList }
  TfrmProgList = class(TForm)
    btnEnviar: TButton;
    btnVolver: TButton;
    lvQueue: TListView;
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

{ TfrmProgList }

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

  // Fuerza columnas por si en el diseñador no quedaron
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
    arr := GScheduled.Snapshot; // de uData
    for i := Low(arr) to High(arr) do
    begin
      it := lvQueue.Items.Add;
      it.Caption := arr[i]^.asunto;            // col 0
      it.SubItems.Add(arr[i]^.remitente);      // col 1
      it.SubItems.Add(arr[i]^.destinatario);   // col 2
      it.SubItems.Add(arr[i]^.programado);     // col 3
      it.Data := arr[i];                       // guardo el puntero por si acaso
    end;
  finally
    lvQueue.Items.EndUpdate;
  end;
end;

procedure TfrmProgList.btnEnviarClick(Sender: TObject);
var
  p: PCorreo;
begin
  // “Envía” todos: saca de la cola y los añade a la lista de correos
  while GScheduled.Count > 0 do
  begin
    p := GScheduled.Dequeue;    // NO liberar p: lo reaprovechamos en GCorreos
    if p = nil then Break;

    p^.fecha  := FormatDateTime('dd/mm/yyyy hh:nn', Now);
    p^.estado := 'NL';
    // Ojo: Add crea un nuevo nodo; si prefieres reutilizar p, podrías copiar campos y Dispose(p)
    GCorreos.Add(GCorreos.NextId, p^.remitente, p^.destinatario, p^.estado,
                 p^.programado, p^.asunto, p^.fecha, p^.mensaje);
    Dispose(p); // ya no necesitamos el puntero de la cola
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

