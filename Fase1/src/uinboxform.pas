unit uInboxForm;

{$mode ObjFPC}{$H+}

interface

uses
<<<<<<< HEAD
  Classes, SysUtils, Forms, Controls, StdCtrls, Grids, ExtCtrls, Dialogs,
  fgl; // TFPGList
=======
  Classes, SysUtils, Forms, Controls, StdCtrls, Grids, ExtCtrls, Dialogs, fgl,
  LCLType; // VK_DELETE
>>>>>>> e486c4b (actualizacion en el codigo de bandeja de entrada, interfaz y codigo de enviar correo, interfaz de programar correo, correcciones en papelera y codigo de progrgamar correo)

type
  { TfrmInbox }
  TfrmInbox = class(TForm)
<<<<<<< HEAD
=======
    lblFechaVal: TLabel;
    lblAsuntoVal: TLabel;
    lblRemitVal: TLabel;

>>>>>>> e486c4b (actualizacion en el codigo de bandeja de entrada, interfaz y codigo de enviar correo, interfaz de programar correo, correcciones en papelera y codigo de progrgamar correo)
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
<<<<<<< HEAD
=======

    // selección y tecla Supr
    procedure gridInboxSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
    procedure gridInboxKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
>>>>>>> e486c4b (actualizacion en el codigo de bandeja de entrada, interfaz y codigo de enviar correo, interfaz de programar correo, correcciones en papelera y codigo de progrgamar correo)
  private
    FEmailActual : string;
    FInboxRows   : array of Pointer; // PCorreo por fila (sin encabezado)
    FSortAZ      : Boolean;
    FSelectedRow : Integer;
<<<<<<< HEAD

    procedure FillInbox;
=======
    FLoading     : Boolean;

    procedure SetupGrid;
    procedure FillInbox(const FiltroAsunto: string = '');
>>>>>>> e486c4b (actualizacion en el codigo de bandeja de entrada, interfaz y codigo de enviar correo, interfaz de programar correo, correcciones en papelera y codigo de progrgamar correo)
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

<<<<<<< HEAD
// === Comparador a nivel de unidad (no anidado) ===
=======
>>>>>>> e486c4b (actualizacion en el codigo de bandeja de entrada, interfaz y codigo de enviar correo, interfaz de programar correo, correcciones en papelera y codigo de progrgamar correo)
function CompareCorreoByAsunto(const A, B: PCorreo): Integer;
begin
  Result := AnsiCompareText(A^.asunto, B^.asunto);
end;

{ TfrmInbox }

<<<<<<< HEAD
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
=======
procedure TfrmInbox.SetupGrid;
begin
  // opciones explícitas (sin edición)
  gridInbox.Options := [
    goFixedVertLine, goFixedHorzLine,
    goVertLine, goHorzLine,
    goRowSelect,
    goColSizing,
    goThumbTracking
  ];
  gridInbox.FixedRows := 1;
  gridInbox.ColCount  := 3;

  // encabezados
  gridInbox.Cells[0,0] := 'Estado';
  gridInbox.Cells[1,0] := 'Asunto';
  gridInbox.Cells[2,0] := 'Remitente';

  // anchos cómodos
  gridInbox.ColWidths[0] := 70;   // Estado
  gridInbox.ColWidths[1] := 280;  // Asunto
  gridInbox.ColWidths[2] := 360;  // Remitente (email completo)

  // eventos por si el diseñador se “desengancha”
  gridInbox.OnSelectCell := @gridInboxSelectCell;
  gridInbox.OnKeyDown    := @gridInboxKeyDown;
  gridInbox.OnDblClick   := @gridInboxDblClick;
end;

procedure TfrmInbox.FormCreate(Sender: TObject);
begin
  Caption := 'Bandeja de Entrada';
  SetupGrid;

  lblNoLeidosTxt.Caption := 'No leídos:';
  lblNoLeidos.Caption    := '0';
  memMensaje.ScrollBars  := ssAutoBoth;
  memMensaje.WordWrap    := True;

  btnVolver.OnClick   := @btnVolverClick;
  btnOrdenAZ.OnClick  := @btnOrdenAZClick;
  btnEliminar.OnClick := @btnEliminarClick;

  FSortAZ      := False;
  FSelectedRow := -1;
  FLoading     := False;
>>>>>>> e486c4b (actualizacion en el codigo de bandeja de entrada, interfaz y codigo de enviar correo, interfaz de programar correo, correcciones en papelera y codigo de progrgamar correo)
end;

procedure TfrmInbox.OpenForUser(const AEmail: string);
begin
  FEmailActual := AEmail;
  Caption := 'Bandeja de: ' + AEmail;
  FSortAZ := False;
<<<<<<< HEAD
=======

  SetupGrid;
>>>>>>> e486c4b (actualizacion en el codigo de bandeja de entrada, interfaz y codigo de enviar correo, interfaz de programar correo, correcciones en papelera y codigo de progrgamar correo)
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
<<<<<<< HEAD
  FSortAZ := not FSortAZ; // alterna
=======
  FSortAZ := not FSortAZ; // alterna orden A-Z por asunto
>>>>>>> e486c4b (actualizacion en el codigo de bandeja de entrada, interfaz y codigo de enviar correo, interfaz de programar correo, correcciones en papelera y codigo de progrgamar correo)
  FillInbox;
end;

procedure TfrmInbox.gridInboxDblClick(Sender: TObject);
begin
  if gridInbox.Row > 0 then
    ShowDetailForRow(gridInbox.Row);
end;

<<<<<<< HEAD
=======
procedure TfrmInbox.gridInboxSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
begin
  CanSelect := True;
  if FLoading then Exit;
  if ARow > 0 then
    ShowDetailForRow(ARow);
end;

procedure TfrmInbox.gridInboxKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if FLoading then Exit;
  if Key = VK_DELETE then
    btnEliminarClick(Sender);
end;

>>>>>>> e486c4b (actualizacion en el codigo de bandeja de entrada, interfaz y codigo de enviar correo, interfaz de programar correo, correcciones en papelera y codigo de progrgamar correo)
procedure TfrmInbox.btnEliminarClick(Sender: TObject);
var
  P: PCorreo;
begin
<<<<<<< HEAD
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
=======
  if (FSelectedRow <= 0) or (FSelectedRow > Length(FInboxRows)) then Exit;
  P := PCorreo(FInboxRows[FSelectedRow-1]);
  if P = nil then Exit;

  if MessageDlg('Confirmar', '¿Enviar este correo a la Papelera?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    GPapelera.Push(P);
    GCorreos.Detach(P);   // quitar de la lista principal
    FillInbox;           // refrescar bandeja y contador
  end;
end;

procedure TfrmInbox.FillInbox(const FiltroAsunto: string);
>>>>>>> e486c4b (actualizacion en el codigo de bandeja de entrada, interfaz y codigo de enviar correo, interfaz de programar correo, correcciones en papelera y codigo de progrgamar correo)
var
  L  : PCorreoList;
  cur: PCorreo;
  i  : Integer;
<<<<<<< HEAD
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

=======
  pass: Boolean;
begin
  if FLoading then Exit;
  FLoading := True;

  // desengancha para que no dispare mientras llenamos
  gridInbox.OnSelectCell := nil;
  gridInbox.BeginUpdate;
  try
    // encabezados
    gridInbox.Cells[0,0] := 'Estado';
    gridInbox.Cells[1,0] := 'Asunto';
    gridInbox.Cells[2,0] := 'Remitente';

    // recolecta correos del usuario
    L := PCorreoList.Create;
    try
      cur := GCorreos.First;
      while cur <> nil do
      begin
        if SameText(cur^.destinatario, FEmailActual) then
        begin
          if FiltroAsunto <> '' then
            pass := Pos(UpperCase(FiltroAsunto), UpperCase(cur^.asunto)) > 0
          else
            pass := True;
          if pass then
            L.Add(cur);
        end;
        cur := cur^.next;
      end;

      if FSortAZ then
        L.Sort(@CompareCorreoByAsunto);

      // llenar grid
      gridInbox.RowCount := L.Count + 1;
      SetLength(FInboxRows, L.Count);
      for i := 0 to L.Count-1 do
      begin
        gridInbox.Cells[0, i+1] := L[i]^.estado;   // 'NL' o 'L'
        gridInbox.Cells[1, i+1] := L[i]^.asunto;
        gridInbox.Cells[2, i+1] := L[i]^.remitente;
        FInboxRows[i]          := L[i];
      end;

      // limpiar detalle
      lblRemitVal.Caption  := '';
      lblAsuntoVal.Caption := '';
      lblFechaVal.Caption  := '';
      memMensaje.Clear;
      FSelectedRow := -1;

      UpdateNoLeidos;
    finally
      L.Free;
    end;
  finally
    gridInbox.EndUpdate;
    // volvemos a enganchar nuestro handler
    gridInbox.OnSelectCell := @gridInboxSelectCell;
    FLoading := False;
  end;
end;


>>>>>>> e486c4b (actualizacion en el codigo de bandeja de entrada, interfaz y codigo de enviar correo, interfaz de programar correo, correcciones en papelera y codigo de progrgamar correo)
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
<<<<<<< HEAD
  if (ARow <= 0) or (ARow >= gridInbox.RowCount) then Exit;
  P := PCorreo(FInboxRows[ARow-1]);
  if P = nil then Exit;

  lblDRemit.Caption := 'Remitente: ' + P^.remitente;
  lblDAsunto.Caption := 'Asunto: ' + P^.asunto;
  lblDFecha.Caption  := 'Fecha: ' + P^.fecha;
  memMensaje.Lines.Text := P^.mensaje;

  // Marcar como leído si estaba NL
=======
  if (Length(FInboxRows) = 0) then Exit;
  if (ARow <= 0) or (ARow > Length(FInboxRows)) then Exit;

  P := PCorreo(FInboxRows[ARow-1]);
  if P = nil then Exit;

  // rellena detalle
  lblRemitVal.Caption  := P^.remitente;
  lblAsuntoVal.Caption := P^.asunto;
  lblFechaVal.Caption  := P^.fecha;
  memMensaje.Lines.Text := P^.mensaje;

  // marcar como leído si corresponde
>>>>>>> e486c4b (actualizacion en el codigo de bandeja de entrada, interfaz y codigo de enviar correo, interfaz de programar correo, correcciones en papelera y codigo de progrgamar correo)
  if SameText(P^.estado, 'NL') then
  begin
    P^.estado := 'L';
    gridInbox.Cells[0, ARow] := 'L';
    UpdateNoLeidos;
  end;

  FSelectedRow := ARow;
end;

end.

