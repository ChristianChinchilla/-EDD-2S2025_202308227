unit uPrivadosForm;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, Grids, ExtCtrls, Dialogs, LCLType, Math;

type
  { TfrmPrivados }
  TfrmPrivados = class(TForm)
  private
    pnlTop: TPanel;
    edtBuscar: TEdit;
    btnBuscar: TButton;
    lblTotalTxt: TLabel;
    lblTotal: TLabel;
    btnVolver: TButton;

    gridPrivados: TStringGrid;

    pnlDetalle: TPanel;
    lblDRemit: TLabel;
    lblDAsunto: TLabel;
    lblDFecha: TLabel;
    lblRemitVal: TLabel;
    lblAsuntoVal: TLabel;
    lblFechaVal: TLabel;
    memMensaje: TMemo;
    btnEliminar: TButton;

    FEmailActual: string;
    FRows: array of Pointer; // PCorreo
    FLoading: Boolean;

    procedure SetupUI;
    procedure SetupGrid;
    procedure FillTable(const FiltroAsunto: string = '');
    procedure ShowDetailForRow(ARow: Integer);
    function  SelectedCorreo: Pointer;

    procedure btnVolverClick(Sender: TObject);
    procedure btnBuscarClick(Sender: TObject);
    procedure btnEliminarClick(Sender: TObject);
    procedure gridPrivadosSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
  public
    constructor Create(AOwner: TComponent); override;
    procedure OpenForUser(const AEmail: string);
  end;

var
  frmPrivados: TfrmPrivados;

implementation

{$R *.lfm}

uses
  uUserMenu, uData, uListaCorreos;

{ TfrmPrivados }

constructor TfrmPrivados.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  // Como el form no tiene .lfm, construimos todo aquí
  SetupUI;
end;

procedure TfrmPrivados.SetupUI;
begin
  Caption := 'Privados';
  Width := 900;
  Height := 560;
  Position := poScreenCenter;

  // === PANEL SUPERIOR ===
  pnlTop := TPanel.Create(Self);
  pnlTop.Parent := Self;
  pnlTop.Align := alTop;
  pnlTop.Height := 48;
  pnlTop.BevelOuter := bvNone;

  edtBuscar := TEdit.Create(Self);
  edtBuscar.Parent := pnlTop;
  edtBuscar.SetBounds(8, 10, 240, 28);
  edtBuscar.TextHint := 'Buscar en asunto…';

  btnBuscar := TButton.Create(Self);
  btnBuscar.Parent := pnlTop;
  btnBuscar.Caption := 'Buscar';
  btnBuscar.SetBounds(256, 10, 90, 28);
  btnBuscar.OnClick := @btnBuscarClick;

  lblTotalTxt := TLabel.Create(Self);
  lblTotalTxt.Parent := pnlTop;
  lblTotalTxt.Caption := 'Total:';
  lblTotalTxt.SetBounds(360, 14, 40, 24);

  lblTotal := TLabel.Create(Self);
  lblTotal.Parent := pnlTop;
  lblTotal.Caption := '0';
  lblTotal.SetBounds(404, 14, 60, 24);

  btnVolver := TButton.Create(Self);
  btnVolver.Parent := pnlTop;
  btnVolver.Caption := 'Volver';
  btnVolver.SetBounds(800, 10, 80, 28);
  btnVolver.OnClick := @btnVolverClick;

  // === GRID ===
  SetupGrid;

  // === PANEL DETALLE ===
  pnlDetalle := TPanel.Create(Self);
  pnlDetalle.Parent := Self;
  pnlDetalle.Align := alBottom;
  pnlDetalle.Height := 200;

  lblDRemit := TLabel.Create(Self);
  lblDRemit.Parent := pnlDetalle;
  lblDRemit.Caption := 'Remitente:';
  lblDRemit.Left := 8;
  lblDRemit.Top := 10;

  lblDAsunto := TLabel.Create(Self);
  lblDAsunto.Parent := pnlDetalle;
  lblDAsunto.Caption := 'Asunto:';
  lblDAsunto.Left := 8;
  lblDAsunto.Top := 34;

  lblDFecha := TLabel.Create(Self);
  lblDFecha.Parent := pnlDetalle;
  lblDFecha.Caption := 'Fecha:';
  lblDFecha.Left := 8;
  lblDFecha.Top := 58;

  lblRemitVal := TLabel.Create(Self);
  lblRemitVal.Parent := pnlDetalle;
  lblRemitVal.Left := 95;
  lblRemitVal.Top := 10;

  lblAsuntoVal := TLabel.Create(Self);
  lblAsuntoVal.Parent := pnlDetalle;
  lblAsuntoVal.Left := 95;
  lblAsuntoVal.Top := 34;

  lblFechaVal := TLabel.Create(Self);
  lblFechaVal.Parent := pnlDetalle;
  lblFechaVal.Left := 95;
  lblFechaVal.Top := 58;

  memMensaje := TMemo.Create(Self);
  memMensaje.Parent := pnlDetalle;
  memMensaje.SetBounds(8, 84, pnlDetalle.Width - 180, pnlDetalle.Height - 96);
  memMensaje.Anchors := [akLeft, akTop, akRight, akBottom];
  memMensaje.ReadOnly := True;
  memMensaje.ScrollBars := ssAutoBoth;
  memMensaje.WordWrap := True;

  btnEliminar := TButton.Create(Self);
  btnEliminar.Parent := pnlDetalle;
  btnEliminar.Caption := 'Eliminar de privados';
  btnEliminar.SetBounds(pnlDetalle.Width - 160, pnlDetalle.Height - 44, 150, 32);
  btnEliminar.Anchors := [akRight, akBottom];
  btnEliminar.OnClick := @btnEliminarClick;
end;

procedure TfrmPrivados.SetupGrid;
begin
  gridPrivados := TStringGrid.Create(Self);
  gridPrivados.Parent := Self;
  gridPrivados.Align := alClient;

  gridPrivados.FixedRows := 1;
  gridPrivados.ColCount := 3;
  gridPrivados.RowCount := 2;

  gridPrivados.Options := [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine,
                           goRowSelect, goColSizing, goThumbTracking];
  gridPrivados.Cells[0,0] := 'ID';
  gridPrivados.Cells[1,0] := 'Asunto';
  gridPrivados.Cells[2,0] := 'Remitente';
  gridPrivados.ColWidths[0] := 80;
  gridPrivados.ColWidths[1] := 360;
  gridPrivados.ColWidths[2] := 300;

  gridPrivados.OnSelectCell := @gridPrivadosSelectCell;
end;

procedure TfrmPrivados.OpenForUser(const AEmail: string);
begin
  FEmailActual := AEmail;
  Caption := 'Privados de: ' + AEmail;
  FillTable;
  Show;
end;

procedure TfrmPrivados.btnVolverClick(Sender: TObject);
begin
  Hide;
  if Assigned(frmUserMenu) then frmUserMenu.Show;
end;

procedure TfrmPrivados.btnBuscarClick(Sender: TObject);
begin
  FillTable(Trim(edtBuscar.Text));
end;

procedure TfrmPrivados.FillTable(const FiltroAsunto: string);
var
  ids: TStringList;
  i, r, id: Integer;
  mail: PCorreo;
  pass: Boolean;
begin
  if FLoading then Exit;
  FLoading := True;
  gridPrivados.BeginUpdate;
  try
    gridPrivados.RowCount := 1;
    SetLength(FRows, 0);
    lblTotal.Caption := '0';
    lblRemitVal.Caption := '';
    lblAsuntoVal.Caption := '';
    lblFechaVal.Caption := '';
    memMensaje.Clear;

    ids := GFavorites.GetIdListCopy(FEmailActual);
    try
      if ids = nil then Exit;

      gridPrivados.RowCount := ids.Count + 1;
      SetLength(FRows, ids.Count);
      r := 1;

      for i := 0 to ids.Count - 1 do
      begin
        id := StrToIntDef(ids[i], 0);
        if id <= 0 then Continue;

        mail := GetMailById(id);
        if mail = nil then Continue;

        if FiltroAsunto <> '' then
          pass := Pos(UpperCase(FiltroAsunto), UpperCase(mail^.asunto)) > 0
        else
          pass := True;

        if not pass then Continue;

        gridPrivados.Cells[0, r] := IntToStr(mail^.id);
        gridPrivados.Cells[1, r] := mail^.asunto;
        gridPrivados.Cells[2, r] := mail^.remitente;
        FRows[r-1] := mail;
        Inc(r);
      end;

      gridPrivados.RowCount := Max(1, r);
      SetLength(FRows, Max(0, r-1));
      lblTotal.Caption := IntToStr(Length(FRows));
    finally
      ids.Free;
    end;
  finally
    gridPrivados.EndUpdate;
    FLoading := False;
  end;
end;

function TfrmPrivados.SelectedCorreo: Pointer;
var
  row: Integer;
begin
  Result := nil;
  row := gridPrivados.Row;
  if (row <= 0) or (row > Length(FRows)) then Exit;
  Result := FRows[row-1];
end;

procedure TfrmPrivados.ShowDetailForRow(ARow: Integer);
var
  p: PCorreo;
begin
  if (ARow <= 0) or (ARow > Length(FRows)) then Exit;
  p := PCorreo(FRows[ARow-1]);
  if p = nil then Exit;

  lblRemitVal.Caption  := p^.remitente;
  lblAsuntoVal.Caption := p^.asunto;
  lblFechaVal.Caption  := p^.fecha;
  memMensaje.Lines.Text := p^.mensaje;
end;

procedure TfrmPrivados.gridPrivadosSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
begin
  CanSelect := True;
  if FLoading then Exit;
  if ARow > 0 then ShowDetailForRow(ARow);
end;

procedure TfrmPrivados.btnEliminarClick(Sender: TObject);
var
  p: PCorreo;
begin
  p := PCorreo(SelectedCorreo);
  if p = nil then
  begin
    ShowMessage('Selecciona un correo primero.');
    Exit;
  end;

  if MessageDlg('Quitar de privados',
                '¿Deseas quitar este correo de la lista de privados?',
                mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  if GFavorites.Remove(FEmailActual, p^.id) then
  begin
    FillTable(Trim(edtBuscar.Text));
    ShowMessage('Correo quitado de privados.');
  end
  else
    ShowMessage('No se pudo quitar.');
end;

end.

