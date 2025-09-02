unit uTrashForm;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, Grids, Dialogs, ExtCtrls, LCLType,
  uListaCorreos;

type

  { TfrmTrash }

  TfrmTrash = class(TForm)
    btnBuscar: TButton;
    btnEliminar: TButton;
    btnVolver: TButton;
    edtBuscar: TEdit;
    gridTrash: TStringGrid;
    lblCountTxt: TLabel;
    lblCount: TLabel;
    pnlToolbar: TPanel;
    procedure FormCreate(Sender: TObject);
    procedure btnBuscarClick(Sender: TObject);
    procedure btnEliminarClick(Sender: TObject);
    procedure btnVolverClick(Sender: TObject);
    procedure gridTrashKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure gridTrashSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
  private
    FEmailActual: string;
    FRows: array of PCorreo;
    FLoading: Boolean;
    procedure SetupGrid;
    procedure FillTrash(const FiltroAsunto: string = '');
    procedure UpdateCount;
  public
    procedure OpenForUser(const AEmail: string);
  end;

var frmTrash: TfrmTrash;

implementation

{$R *.lfm}

uses uUserMenu, uData;

procedure TfrmTrash.SetupGrid;
begin
  gridTrash.Options := [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine,
                        goRowSelect, goColSizing, goThumbTracking];
  gridTrash.FixedRows := 1; gridTrash.ColCount := 3;
  gridTrash.Cells[0,0] := 'Asunto';
  gridTrash.Cells[1,0] := 'Remitente';
  gridTrash.Cells[2,0] := 'Mensaje';
  gridTrash.ColWidths[0] := 220; gridTrash.ColWidths[1] := 220; gridTrash.ColWidths[2] := 380;

  gridTrash.OnSelectCell := @gridTrashSelectCell;
  gridTrash.OnKeyDown    := @gridTrashKeyDown;
end;

procedure TfrmTrash.FormCreate(Sender: TObject);
begin
  Caption := 'Papelera';
  SetupGrid;
  lblCountTxt.Caption := 'En Papelera:'; lblCount.Caption := '0';
  btnBuscar.OnClick := @btnBuscarClick;
  btnEliminar.OnClick := @btnEliminarClick;
  btnVolver.OnClick := @btnVolverClick;
  FLoading := False;
end;

procedure TfrmTrash.OpenForUser(const AEmail: string);
begin
  FEmailActual := AEmail;
  SetupGrid; FillTrash(''); Show;
end;

procedure TfrmTrash.UpdateCount;
begin
  if Assigned(GPapelera) then
    lblCount.Caption := IntToStr(GPapelera.Count)
  else
    lblCount.Caption := '0';
end;

procedure TfrmTrash.FillTrash(const FiltroAsunto: string);
var snap: TPCorreoArray; i,n: Integer; pass: Boolean; p: PCorreo;
begin
  if FLoading then Exit; FLoading := True;
  gridTrash.BeginUpdate;
  try
    gridTrash.Cells[0,0] := 'Asunto';
    gridTrash.Cells[1,0] := 'Remitente';
    gridTrash.Cells[2,0] := 'Mensaje';

    if Assigned(GPapelera) then snap := GPapelera.Snapshot
                           else SetLength(snap,0);

    n := Length(snap);
    gridTrash.RowCount := n + 1;
    SetLength(FRows, n);

    for i := 0 to n-1 do
    begin
      p := snap[i];
      if FiltroAsunto<>'' then pass := Pos(UpperCase(FiltroAsunto),UpperCase(p^.asunto))>0
                          else pass := True;

      if pass then
      begin
        gridTrash.Cells[0,i+1] := p^.asunto;
        gridTrash.Cells[1,i+1] := p^.remitente;
        if Length(p^.mensaje)>70 then
          gridTrash.Cells[2,i+1] := Copy(p^.mensaje,1,67) + '...'
        else
          gridTrash.Cells[2,i+1] := p^.mensaje;
        FRows[i] := p;
      end
      else
      begin
        gridTrash.Cells[0,i+1] := ''; gridTrash.Cells[1,i+1] := ''; gridTrash.Cells[2,i+1] := '';
        FRows[i] := nil;
      end;
    end;
    UpdateCount;
  finally
    gridTrash.EndUpdate; FLoading := False;
  end;
end;

procedure TfrmTrash.btnBuscarClick(Sender: TObject);
begin
  FillTrash(Trim(edtBuscar.Text));
end;

procedure TfrmTrash.btnEliminarClick(Sender: TObject);
var row: Integer; p,x: PCorreo; tmp: TTrashStack;
begin
  row := gridTrash.Row; if (row<=0) or (row>Length(FRows)) then Exit;
  p := FRows[row-1]; if p=nil then Exit;
  if MessageDlg('Eliminar','¿Eliminar definitivamente de la papelera?',mtConfirmation,[mbYes,mbNo],0)<>mrYes then Exit;

  tmp := TTrashStack.Create;
  try
    while GPapelera.Count>0 do
    begin
      x := GPapelera.Pop;
      if x = p then begin Dispose(p); Break end
      else tmp.Push(x);
    end;
    while tmp.Count>0 do GPapelera.Push(tmp.Pop);
  finally
    tmp.Free;
  end;

  FillTrash('');
end;

procedure TfrmTrash.btnVolverClick(Sender: TObject);
begin Hide; if Assigned(frmUserMenu) then frmUserMenu.Show end;

procedure TfrmTrash.gridTrashKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin if FLoading then Exit; if Key = VK_DELETE then btnEliminarClick(Sender) end;

procedure TfrmTrash.gridTrashSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
begin CanSelect := True end;

end.

