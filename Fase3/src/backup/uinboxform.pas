unit uInboxForm;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, Grids, ExtCtrls, Dialogs, fgl,
  LCLType;

type

  { TfrmInbox }

  TfrmInbox = class(TForm)
    btnFavorito: TButton;
    lblFechaVal: TLabel;
    lblAsuntoVal: TLabel;
    lblRemitVal: TLabel;
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
    procedure btnFavoritoClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnVolverClick(Sender: TObject);
    procedure btnOrdenAZClick(Sender: TObject);
    procedure gridInboxDblClick(Sender: TObject);
    procedure btnEliminarClick(Sender: TObject);
    procedure gridInboxSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
    procedure gridInboxKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure pnlDetalleClick(Sender: TObject);
  private
    FEmailActual : string;
    FInboxRows   : array of Pointer; // PCorreo
    FSortAZ      : Boolean;
    FSelectedRow : Integer;
    FLoading     : Boolean;
    procedure SetupGrid;
    procedure FillInbox(const FiltroAsunto: string = '');
    procedure UpdateNoLeidos;
    procedure ShowDetailForRow(ARow: Integer);
    function  WithStars(const S: string): string;
    procedure UpdateFavButtonCaptionForRow(ARow: Integer);
  public
    procedure OpenForUser(const AEmail: string);
  end;

var
  frmInbox: TfrmInbox;

implementation

{$R *.lfm}

uses uUserMenu, uData, uListaCorreos;

type
  PCorreoList = specialize TFPGList<PCorreo>;

function CompareCorreoByAsunto(const A, B: PCorreo): Integer;
begin
  Result := AnsiCompareText(A^.asunto, B^.asunto);
end;

function TfrmInbox.WithStars(const S: string): string;
begin
  Result := '★ ' + S;
end;

procedure TfrmInbox.UpdateFavButtonCaptionForRow(ARow: Integer);
var
  P: PCorreo;
begin
  if (ARow <= 0) or (ARow > Length(FInboxRows)) then
  begin
    btnFavorito.Caption := 'Favorito';
    Exit;
  end;
  P := PCorreo(FInboxRows[ARow-1]);
  if (P <> nil) and P^.favorito then
    btnFavorito.Caption := 'Quitar favorito'
  else
    btnFavorito.Caption := 'Favorito';
end;

procedure TfrmInbox.SetupGrid;
begin
  gridInbox.Options := [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine,
                        goRowSelect, goColSizing, goThumbTracking];
  gridInbox.FixedRows := 1; gridInbox.ColCount := 3;
  gridInbox.Cells[0,0] := 'Estado';
  gridInbox.Cells[1,0] := 'Asunto';
  gridInbox.Cells[2,0] := 'Remitente';
  gridInbox.ColWidths[0] := 70; gridInbox.ColWidths[1] := 280; gridInbox.ColWidths[2] := 360;

  gridInbox.OnSelectCell := @gridInboxSelectCell;
  gridInbox.OnKeyDown    := @gridInboxKeyDown;
  gridInbox.OnDblClick   := @gridInboxDblClick;
end;

procedure TfrmInbox.FormCreate(Sender: TObject);
begin
  Caption := 'Bandeja de Entrada';
  SetupGrid;
  lblNoLeidosTxt.Caption := 'No leídos:'; lblNoLeidos.Caption := '0';
  memMensaje.ScrollBars := ssAutoBoth; memMensaje.WordWrap := True;

  btnVolver.OnClick   := @btnVolverClick;
  btnOrdenAZ.OnClick  := @btnOrdenAZClick;
  btnEliminar.OnClick := @btnEliminarClick;
  btnFavorito.Caption := 'Favorito';

  FSortAZ := False; FSelectedRow := -1; FLoading := False;
end;

procedure TfrmInbox.btnFavoritoClick(Sender: TObject);
var
  P: PCorreo;
begin
  if gridInbox.Row > 0 then
    FSelectedRow := gridInbox.Row;

  if (FSelectedRow<=0) or (FSelectedRow>Length(FInboxRows)) then Exit;
  P := PCorreo(FInboxRows[FSelectedRow-1]); if P=nil then Exit;

  // Alternar en el DATO y repintar
  P^.favorito := not P^.favorito;

  if P^.favorito then
    gridInbox.Cells[1, FSelectedRow] := WithStars(P^.asunto)
  else
    gridInbox.Cells[1, FSelectedRow] := P^.asunto;

  UpdateFavButtonCaptionForRow(FSelectedRow);
end;

procedure TfrmInbox.OpenForUser(const AEmail: string);
begin
  FEmailActual := AEmail; Caption := 'Bandeja de: ' + AEmail; FSortAZ := False;
  SetupGrid; FillInbox; Show;
end;

procedure TfrmInbox.btnVolverClick(Sender: TObject);
begin
  Hide;
  if Assigned(frmUserMenu) then frmUserMenu.Show
end;

procedure TfrmInbox.btnOrdenAZClick(Sender: TObject);
begin
  FSortAZ := not FSortAZ; FillInbox
end;

procedure TfrmInbox.gridInboxDblClick(Sender: TObject);
begin
  if gridInbox.Row>0 then ShowDetailForRow(gridInbox.Row)
end;

procedure TfrmInbox.gridInboxSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
begin
  CanSelect := True;
  if FLoading then Exit;
  if ARow>0 then
  begin
    ShowDetailForRow(ARow);
    UpdateFavButtonCaptionForRow(ARow);
  end;
end;

procedure TfrmInbox.gridInboxKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if FLoading then Exit;
  if Key = VK_DELETE then btnEliminarClick(Sender);
end;

procedure TfrmInbox.pnlDetalleClick(Sender: TObject);
begin

end;

procedure TfrmInbox.btnEliminarClick(Sender: TObject);
var
  P: PCorreo;
begin
  if (FSelectedRow<=0) or (FSelectedRow>Length(FInboxRows)) then Exit;
  P := PCorreo(FInboxRows[FSelectedRow-1]); if P=nil then Exit;
  if MessageDlg('Confirmar','¿Enviar este correo a la Papelera?',mtConfirmation,[mbYes,mbNo],0)=mrYes then
  begin
    GPapelera.Push(P);
    GCorreos.Detach(P);
    FillInbox;
  end;
end;

procedure TfrmInbox.FillInbox(const FiltroAsunto: string);
var
  L   : PCorreoList;
  cur : PCorreo;
  i   : Integer;
  pass: Boolean;
begin
  if FLoading then Exit; FLoading := True;
  gridInbox.OnSelectCell := nil; gridInbox.BeginUpdate;
  try
    gridInbox.Cells[0,0] := 'Estado';
    gridInbox.Cells[1,0] := 'Asunto';
    gridInbox.Cells[2,0] := 'Remitente';

    L := PCorreoList.Create;
    try
      cur := GCorreos.First;
      while cur<>nil do
      begin
        if SameText(cur^.destinatario,FEmailActual) then
        begin
          if FiltroAsunto<>'' then pass := Pos(UpperCase(FiltroAsunto),UpperCase(cur^.asunto))>0
                               else pass := True;
          if pass then L.Add(cur);
        end;
        cur := cur^.next;
      end;

      if FSortAZ then L.Sort(@CompareCorreoByAsunto);

      gridInbox.RowCount := L.Count+1; SetLength(FInboxRows,L.Count);
      for i:=0 to L.Count-1 do
      begin
        gridInbox.Cells[0,i+1] := L[i]^.estado;
        if L[i]^.favorito then
          gridInbox.Cells[1,i+1] := WithStars(L[i]^.asunto)
        else
          gridInbox.Cells[1,i+1] := L[i]^.asunto;
        gridInbox.Cells[2,i+1] := L[i]^.remitente;
        FInboxRows[i] := L[i];
      end;

      lblRemitVal.Caption:=''; lblAsuntoVal.Caption:=''; lblFechaVal.Caption:='';
      memMensaje.Clear; FSelectedRow := -1; UpdateNoLeidos;
      btnFavorito.Caption := 'Favorito';
    finally
      L.Free
    end;
  finally
    gridInbox.EndUpdate; gridInbox.OnSelectCell := @gridInboxSelectCell; FLoading := False;
  end;
end;

procedure TfrmInbox.UpdateNoLeidos;
var
  i,cnt: Integer;
begin
  cnt := 0;
  for i:=1 to gridInbox.RowCount-1 do
    if SameText(gridInbox.Cells[0,i],'NL') then Inc(cnt);
  lblNoLeidos.Caption := IntToStr(cnt);
end;

procedure TfrmInbox.ShowDetailForRow(ARow: Integer);
var
  P: PCorreo;
begin
  if (Length(FInboxRows)=0) or (ARow<=0) or (ARow>Length(FInboxRows)) then Exit;
  P := PCorreo(FInboxRows[ARow-1]); if P=nil then Exit;

  lblRemitVal.Caption := P^.remitente;
  lblAsuntoVal.Caption := P^.asunto; // detalle sin estrellas
  lblFechaVal.Caption  := P^.fecha;
  memMensaje.Lines.Text := P^.mensaje;

  if SameText(P^.estado,'NL') then
  begin
    P^.estado:='L';
    gridInbox.Cells[0,ARow]:='L';
    UpdateNoLeidos
  end;

  FSelectedRow := ARow;
  UpdateFavButtonCaptionForRow(ARow);
end;

end.

