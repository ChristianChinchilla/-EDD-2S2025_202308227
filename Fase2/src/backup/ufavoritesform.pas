unit uFavoritesForm;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ComCtrls, Dialogs, TypInfo, LCLType;

type
  { TfrmFavorites }
  TfrmFavorites = class(TForm)
    btnEliminar: TButton;
    btnVolver: TButton;
    Label1: TLabel;
    Label2: TLabel;
    Label4: TLabel;
    lblTotal: TLabel;
    lvFavs: TListView;
    lblRemitVal: TLabel;
    lblAsuntoVal: TLabel;
    lblFechaVal: TLabel;
    memMensaje: TMemo;
    procedure btnVolverClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnEliminarClick(Sender: TObject);
    procedure lvFavsSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure lvFavsChange(Sender: TObject; Item: TListItem; Change: TItemChange);
    procedure lvFavsClick(Sender: TObject);
    procedure lvFavsKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure lvFavsItemFocused(Sender: TObject; Item: TListItem);
  private
    FOwnerEmail: string;
    procedure EnableHeadersIfAvailable;
    procedure BuildColumns;
    procedure RebuildList;
    procedure ShowDetailById(AId: LongInt);
    procedure ClearDetail;
    function   CurrentListItem: TListItem;
    procedure UpdateDetailFromCurrent;
  public
    procedure OpenForUser(const AEmail: string);
  end;

var
  frmFavorites: TfrmFavorites;

implementation

{$R *.lfm}

uses
  uData, uUserMenu, uListaCorreos;

procedure TfrmFavorites.EnableHeadersIfAvailable;
begin
  if IsPublishedProp(lvFavs, 'ShowColumnHeaders') then
    SetPropValue(lvFavs, 'ShowColumnHeaders', True);
end;

procedure TfrmFavorites.BuildColumns;
begin
  lvFavs.Columns.BeginUpdate;
  try
    lvFavs.Columns.Clear;
    with lvFavs.Columns.Add do begin Caption := 'ID';        Width := 90;  end;
    with lvFavs.Columns.Add do begin Caption := 'Asunto';    Width := 280; end;
    with lvFavs.Columns.Add do begin Caption := 'Remitente'; Width := 280; end;
  finally
    lvFavs.Columns.EndUpdate;
  end;
end;

procedure TfrmFavorites.FormCreate(Sender: TObject);
begin
  lvFavs.ViewStyle     := vsReport;
  lvFavs.OwnerData     := False;
  lvFavs.ReadOnly      := True;
  lvFavs.RowSelect     := True;
  lvFavs.GridLines     := True;
  lvFavs.HideSelection := False;
  lvFavs.MultiSelect   := False;
  EnableHeadersIfAvailable;

  lvFavs.OnSelectItem := @lvFavsSelectItem;
  lvFavs.OnChange     := @lvFavsChange;
  lvFavs.OnClick      := @lvFavsClick;
  lvFavs.OnKeyUp      := @lvFavsKeyUp;
  lvFavs.OnItemFocused:= @lvFavsItemFocused;

  BuildColumns;

  Caption := 'Favoritos';
  btnVolver.Caption := 'Volver';
end;

procedure TfrmFavorites.btnVolverClick(Sender: TObject);
begin
  Hide;
  if Assigned(frmUserMenu) then
    frmUserMenu.Show;
end;

procedure TfrmFavorites.OpenForUser(const AEmail: string);
begin
  FOwnerEmail := AEmail;
  Caption := 'Favoritos de: ' + AEmail;
  RebuildList;
  Show;
end;

procedure TfrmFavorites.RebuildList;

  function CleanId(const S: string): Integer;
  var t: string;
  begin
    t := Trim(S);
    t := StringReplace(t, '"', '', [rfReplaceAll]);
    Result := StrToIntDef(t, 0);
  end;

var
  ids : TStringList;
  i, id: Integer;
  mail: PCorreo;
  item: TListItem;
begin
  lvFavs.ViewStyle := vsReport;
  lvFavs.OwnerData := False;
  EnableHeadersIfAvailable;
  BuildColumns;

  lvFavs.Items.BeginUpdate;
  try
    lvFavs.Items.Clear;

    ids := GFavorites.GetIdListCopy(FOwnerEmail);
    try
      for i := 0 to ids.Count-1 do
      begin
        id := CleanId(ids[i]);
        if id = 0 then Continue;

        mail := GetMailById(id);
        if mail = nil then Continue;

        item := lvFavs.Items.Add;
        item.Caption := IntToStr(mail^.id);
        item.SubItems.Add(mail^.asunto);
        item.SubItems.Add(mail^.remitente);
      end;
    finally
      ids.Free;
    end;
  finally
    lvFavs.Items.EndUpdate;
  end;

  lblTotal.Caption := IntToStr(GFavorites.Count(FOwnerEmail));
  ClearDetail;

  if lvFavs.Items.Count > 0 then
  begin
    lvFavs.ItemIndex         := 0;
    lvFavs.Items[0].Selected := True;
    lvFavs.Items[0].Focused  := True;
    lvFavs.Items[0].MakeVisible(False);
    UpdateDetailFromCurrent;
  end;

  lvFavs.Invalidate;
end;

procedure TfrmFavorites.ClearDetail;
begin
  lblRemitVal.Caption  := '';
  lblAsuntoVal.Caption := '';
  lblFechaVal.Caption  := '';
  memMensaje.Clear;
end;

procedure TfrmFavorites.ShowDetailById(AId: LongInt);
var
  mail: PCorreo;
begin
  mail := GetMailById(AId);
  if mail = nil then
  begin
    ClearDetail;
    Exit;
  end;

  lblRemitVal.Caption   := mail^.remitente;
  lblAsuntoVal.Caption  := mail^.asunto;
  lblFechaVal.Caption   := mail^.fecha;
  memMensaje.Lines.Text := mail^.mensaje;
end;

function TfrmFavorites.CurrentListItem: TListItem;
begin
  // Preferimos el item con foco, luego el seleccionado, luego ItemIndex
  Result := lvFavs.ItemFocused;
  if Result = nil then Result := lvFavs.Selected;
  if (Result = nil) and (lvFavs.ItemIndex >= 0) and (lvFavs.ItemIndex < lvFavs.Items.Count) then
    Result := lvFavs.Items[lvFavs.ItemIndex];
end;

procedure TfrmFavorites.UpdateDetailFromCurrent;
var
  it: TListItem;
begin
  it := CurrentListItem;
  if it <> nil then
    ShowDetailById(StrToIntDef(it.Caption, 0))
  else
    ClearDetail;
end;

procedure TfrmFavorites.lvFavsSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
begin
  if Selected then UpdateDetailFromCurrent;
end;

procedure TfrmFavorites.lvFavsChange(Sender: TObject; Item: TListItem; Change: TItemChange);
begin
  UpdateDetailFromCurrent;
end;

procedure TfrmFavorites.lvFavsClick(Sender: TObject);
begin
  UpdateDetailFromCurrent;
end;

procedure TfrmFavorites.lvFavsKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (Key in [VK_UP, VK_DOWN, VK_PRIOR, VK_NEXT, VK_HOME, VK_END]) then
    UpdateDetailFromCurrent;
end;

procedure TfrmFavorites.lvFavsItemFocused(Sender: TObject; Item: TListItem);
begin
  UpdateDetailFromCurrent;
end;

procedure TfrmFavorites.btnEliminarClick(Sender: TObject);
var
  id: Integer;
  it: TListItem;
begin
  it := CurrentListItem;
  if it = nil then Exit;
  id := StrToIntDef(it.Caption, 0);
  if id = 0 then Exit;

  if GFavorites.Remove(FOwnerEmail, id) then
  begin
    ShowMessage('Eliminado de favoritos.');
    RebuildList;
  end
  else
    ShowMessage('No se pudo eliminar.');
end;

end.

