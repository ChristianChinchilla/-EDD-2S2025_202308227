unit frminbox;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, Grids, ExtCtrls, Dialogs,
  fgl; // TFPGList

type
  { TfrmInbox }
  TfrmInbox = class(TForm)
    pnlToolbar: TPanel;
    btnVolver: TButton;
    btnOrdenAZ: TButton;
    lblNoLeidosTxt: TLabel;
    lblNoLeidos: TLabel;

    gridInbox: TStringGrid;

    pnlDetalle: TPanel;
    lblDRemit: TLabel;
    lblDAsunto: TLabel;
    lblDFecha: TLabel;
    memMensaje: TMemo;
    btnEliminar: TButton;

    procedure FormCreate(Sender: TObject);
    procedure btnVolverClick(Sender: TObject);
    procedure btnOrdenAZClick(Sender: TObject);
    procedure gridInboxDblClick(Sender: TObject);
    procedure btnEliminarClick(Sender: TObject);
  private
    FEmailActual : string;
    FInboxRows   : array of Pointer; // PCorreo por fila (sin encabezado)
    FSortAZ      : Boolean;
    FSelectedRow : Integer;

    procedure FillInbox;
    procedure UpdateNoLeidos;
    procedure ShowDetailForRow(ARow: Integer);
  public
    procedure OpenForUser(const AEmail: string);
  end;

var
  frmInbox: TfrmInbox;

implementation

{$R *.lfm}

uses
  uUserMenu, uData, uListaCorreos;

type
  PCorreoList = specialize TFPGList<PCorreo>;

// === Comparador a nivel de unidad (no anidado) ===
function CompareCorreoByAsunto(const A, B: PCorreo): Integer;
begin
  Result := AnsiCompareText(A^.asunto, B^.asunto);
end;

{ TfrmInbox }

procedure TfrmInbox.FormCreate(Sender: TObject);
begin
  Caption := 'Bandeja de Entrada';

  // Config del grid (encabezado en fila 0)
  gridInbox.ColCount  := 3;
  gridInbox.RowCount  := 1;
  gridInbox.FixedRows := 1;
  gridInbox.Options   := gridInbox.Options + [goRowSelect] - [goEditing];
  // gridInbox.ReadOnly := True;  // <-- NO existe en TStringGrid: ¡quitar!

  // Encabezados
  gridInbox.Cells[0,0] := 'Estado';
  gridInbox.Cells[1,0] := 'Asunto';
  gridInbox.Cells[2,0] := 'Remitente';
  gridInbox.ColWidths[0] := 60;
  gridInbox.ColWidths[1] := 340;
  gridInbox.ColWidths[2] := 240;

  lblNoLeidosTxt.Caption := 'No leídos:';
  lblNoLeidos.Caption    := '0';

  // Por si el diseñador no ató eventos
  btnVolver.OnClick    := @btnVolverClick;
  btnOrdenAZ.OnClick   := @btnOrdenAZClick;
  btnEliminar.OnClick  := @btnEliminarClick;
  gridInbox.OnDblClick := @gridInboxDblClick;

  FSortAZ      := False;
  FSelectedRow := -1;
end;

procedure TfrmInbox.OpenForUser(const AEmail: string);
begin
  FEmailActual := AEmail;
  Caption := 'Bandeja de: ' + AEmail;
  FSortAZ := False;
  FillInbox;
  Show;
end;

procedure TfrmInbox.btnVolverClick(Sender: TObject);
begin
  Hide;
  if Assigned(frmUserMenu) then frmUserMenu.Show;
end;

procedure TfrmInbox.btnOrdenAZClick(Sender: TObject);
begin
  FSortAZ := not FSortAZ; // alterna
  FillInbox;
end;

procedure TfrmInbox.gridInboxDblClick(Sender: TObject);
begin
  if gridInbox.Row > 0 then
    ShowDetailForRow(gridInbox.Row);
end;

procedure TfrmInbox.btnEliminarClick(Sender: TObject);
var
  P: PCorreo;
begin
  if (FSelectedRow <= 0) or (FSelectedRow >= gridInbox.RowCount) then Exit;
  P := PCorreo(FInboxRows[FSelectedRow-1]);
  if P = nil then Exit;

  if MessageDlg('Confirmar', '¿Eliminar este correo?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    GCorreos.Remove(P);  // asumiendo que tienes este helper en uListaCorreos
    FillInbox;
  end;
end;

procedure TfrmInbox.FillInbox;
var
  L  : PCorreoList;
  cur: PCorreo;
  i  : Integer;
begin
  L := PCorreoList.Create;
  try
    // Recolecta correos destinados a este usuario
    cur := GCorreos.First; // helper en uListaCorreos
    while cur <> nil do
    begin
      if SameText(cur^.destinatario, FEmailActual) then
        L.Add(cur);
      cur := cur^.next;
    end;

    if FSortAZ then
      L.Sort(@CompareCorreoByAsunto);

    // Llenar grid
    gridInbox.RowCount := L.Count + 1;
    SetLength(FInboxRows, L.Count);
    for i := 0 to L.Count-1 do
    begin
      gridInbox.Cells[0, i+1] := L[i]^.estado;   // 'NL' o 'L'
      gridInbox.Cells[1, i+1] := L[i]^.asunto;
      gridInbox.Cells[2, i+1] := L[i]^.remitente;
      FInboxRows[i] := L[i];
    end;

    // Reset detalle
    lblDRemit.Caption := 'Remitente:';
    lblDAsunto.Caption := 'Asunto:';
    lblDFecha.Caption  := 'Fecha:';
    memMensaje.Lines.Text := '';
    FSelectedRow := -1;

    UpdateNoLeidos;
  finally
    L.Free;
  end;
end;

procedure TfrmInbox.UpdateNoLeidos;
var
  i, cnt: Integer;
begin
  cnt := 0;
  for i := 1 to gridInbox.RowCount-1 do
    if SameText(gridInbox.Cells[0,i], 'NL') then
      Inc(cnt);
  lblNoLeidos.Caption := IntToStr(cnt);
end;

procedure TfrmInbox.ShowDetailForRow(ARow: Integer);
var
  P: PCorreo;
begin
  if (ARow <= 0) or (ARow >= gridInbox.RowCount) then Exit;
  P := PCorreo(FInboxRows[ARow-1]);
  if P = nil then Exit;

  lblDRemit.Caption := 'Remitente: ' + P^.remitente;
  lblDAsunto.Caption := 'Asunto: ' + P^.asunto;
  lblDFecha.Caption  := 'Fecha: ' + P^.fecha;
  memMensaje.Lines.Text := P^.mensaje;

  // Marcar como leído si estaba NL
  if SameText(P^.estado, 'NL') then
  begin
    P^.estado := 'L';
    gridInbox.Cells[0, ARow] := 'L';
    UpdateNoLeidos;
  end;

  FSelectedRow := ARow;
end;

end.

