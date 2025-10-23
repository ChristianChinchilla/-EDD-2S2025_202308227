unit uLogControlForm;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, Grids, Dialogs, ExtCtrls,
  fpjson, Math, StrUtils;

type
  TLogEntry = record
    Usuario : string;
    Entrada : TDateTime;
    Salida  : TDateTime;
  end;

  TLoginLog = class
  private
    FItems: array of TLogEntry;
  public
    procedure Clear;
    procedure Add(const AUsuario: string; const AEntrada, ASalida: TDateTime);
    function  Count: Integer;
    function  GetItem(Index: Integer): TLogEntry;
    procedure SetSalidaForUser(const AUsuario: string; const ASalida: TDateTime);
    function  ToJSONArray: TJSONArray;
  end;

  TfrmLoginLog = class(TForm)
  private
    pnlTop: TPanel;
    grid: TStringGrid;
    btnExport: TButton;
    procedure BuildUI;
    procedure AdjustLayout;
    procedure LoadGrid;
    procedure btnExportClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    procedure Open;
  end;

var
  frmLoginLog: TfrmLoginLog;
  GLoginLog  : TLoginLog;

procedure LogRegistrarEntrada(const Usuario: string; const FechaHora: TDateTime);
procedure LogRegistrarSalida (const Usuario: string; const FechaHora: TDateTime);

implementation

{$R *.lfm}

{ ===================== TLoginLog ===================== }

procedure TLoginLog.Clear;
begin
  SetLength(FItems, 0);
end;

procedure TLoginLog.Add(const AUsuario: string; const AEntrada, ASalida: TDateTime);
var
  n: Integer;
begin
  n := Length(FItems);
  SetLength(FItems, n+1);
  FItems[n].Usuario := AUsuario;
  FItems[n].Entrada := AEntrada;
  FItems[n].Salida  := ASalida;
end;

function TLoginLog.Count: Integer;
begin
  Result := Length(FItems);
end;

function TLoginLog.GetItem(Index: Integer): TLogEntry;
begin
  if (Index >= 0) and (Index < Length(FItems)) then
    Result := FItems[Index]
  else
    FillChar(Result, SizeOf(Result), 0);
end;

procedure TLoginLog.SetSalidaForUser(const AUsuario: string; const ASalida: TDateTime);
var
  i: Integer;
begin
  for i := High(FItems) downto 0 do
    if SameText(FItems[i].Usuario, AUsuario) and (FItems[i].Salida = 0) then
    begin
      FItems[i].Salida := ASalida;
      Exit;
    end;
  Add(AUsuario, 0, ASalida);
end;

function TLoginLog.ToJSONArray: TJSONArray;

  function ISO(dt: TDateTime): String;
  begin
    if dt = 0 then Result := ''
    else Result := FormatDateTime('yyyy-mm-dd hh:nn:ss', dt);
  end;

var
  arr: TJSONArray;
  obj: TJSONObject;
  i: Integer;
begin
  arr := TJSONArray.Create;
  for i := 0 to High(FItems) do
  begin
    obj := TJSONObject.Create;
    obj.Add('usuario', FItems[i].Usuario);
    obj.Add('entrada', ISO(FItems[i].Entrada));
    obj.Add('salida',  ISO(FItems[i].Salida));
    arr.Add(obj);
  end;
  Result := arr;
end;

{ ===================== TfrmLoginLog ===================== }

constructor TfrmLoginLog.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Caption := 'Control de Logueo';
  Position := poScreenCenter;
  Width := 800;
  Height := 480;
  OnResize := @FormResize;

  BuildUI;
  LoadGrid;
  AdjustLayout;
end;

procedure TfrmLoginLog.BuildUI;
begin
  // Panel superior (solo para exportar)
  pnlTop := TPanel.Create(Self);
  pnlTop.Parent := Self;
  pnlTop.Align := alTop;
  pnlTop.Height := 60;
  pnlTop.BevelOuter := bvNone;
  pnlTop.BorderSpacing.Around := 8;

  // Botón Exportar
  btnExport := TButton.Create(Self);
  btnExport.Parent := pnlTop;
  btnExport.Caption := 'Exportar (JSON)';
  btnExport.SetBounds(8, 8, 160, 32);
  btnExport.Anchors := [akLeft, akTop];
  btnExport.OnClick := @btnExportClick;

  // Grid
  grid := TStringGrid.Create(Self);
  grid.Parent := Self;
  grid.Align := alClient;
  grid.BorderSpacing.Left := 8;
  grid.BorderSpacing.Right := 8;
  grid.BorderSpacing.Bottom := 8;

  grid.ColCount := 3;
  grid.FixedCols := 0;
  grid.RowCount := 2;
  grid.FixedRows := 1;
  grid.DefaultColWidth := 220;
  grid.Options := grid.Options + [goRowSelect, goColSizing, goFixedVertLine, goFixedHorzLine];

  grid.Cells[0,0] := 'USUARIO';
  grid.Cells[1,0] := 'ENTRADA';
  grid.Cells[2,0] := 'SALIDA';
end;

procedure TfrmLoginLog.AdjustLayout;
var
  w: Integer;
begin
  w := grid.ClientWidth;
  if w <= 0 then Exit;
  grid.ColWidths[0] := EnsureRange(Round(w * 0.34), 120, 400);
  grid.ColWidths[1] := EnsureRange(Round(w * 0.33), 160, 420);
  grid.ColWidths[2] := EnsureRange(Round(w * 0.33), 160, 420);
end;

procedure TfrmLoginLog.FormResize(Sender: TObject);
begin
  AdjustLayout;
end;

procedure TfrmLoginLog.LoadGrid;

  function S(dt: TDateTime): string;
  begin
    if dt = 0 then Result := ''
    else Result := FormatDateTime('yyyy-mm-dd hh:nn:ss', dt);
  end;

var
  i, r: Integer;
  e: TLogEntry;
begin
  if GLoginLog = nil then Exit;

  grid.RowCount := Max(2, GLoginLog.Count + 1);
  for r := 1 to grid.RowCount-1 do
  begin
    grid.Cells[0, r] := '';
    grid.Cells[1, r] := '';
    grid.Cells[2, r] := '';
  end;

  for i := 0 to GLoginLog.Count - 1 do
  begin
    e := GLoginLog.GetItem(i);
    r := i + 1;
    grid.Cells[0, r] := e.Usuario;
    grid.Cells[1, r] := S(e.Entrada);
    grid.Cells[2, r] := S(e.Salida);
  end;
end;

procedure TfrmLoginLog.btnExportClick(Sender: TObject);
var
  sd: TSaveDialog;
  arr: TJSONArray;
  s: TStringStream;
begin
  sd := TSaveDialog.Create(Self);
  try
    sd.Title := 'Exportar Control de Logueo';
    sd.Filter := 'Archivo JSON|*.json';
    sd.DefaultExt := 'json';
    sd.FileName := 'control_logueo.json';
    if sd.Execute then
    begin
      arr := GLoginLog.ToJSONArray;
      try
        s := TStringStream.Create(arr.FormatJSON([]));
        try
          s.SaveToFile(sd.FileName);
          MessageDlg('Exportación completa', mtInformation, [mbOK], 0);
        finally
          s.Free;
        end;
      finally
        arr.Free;
      end;
    end;
  finally
    sd.Free;
  end;
end;

procedure TfrmLoginLog.Open;
begin
  LoadGrid;
  Show;
end;

{ ===================== Registro global ===================== }

procedure LogRegistrarEntrada(const Usuario: string; const FechaHora: TDateTime);
begin
  if GLoginLog = nil then Exit;
  GLoginLog.Add(Usuario, FechaHora, 0);
end;

procedure LogRegistrarSalida(const Usuario: string; const FechaHora: TDateTime);
begin
  if GLoginLog = nil then Exit;
  GLoginLog.SetSalidaForUser(Usuario, FechaHora);
end;

initialization
  GLoginLog := TLoginLog.Create;

finalization
  FreeAndNil(GLoginLog);

end.

