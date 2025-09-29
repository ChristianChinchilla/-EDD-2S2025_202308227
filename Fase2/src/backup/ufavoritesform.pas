unit uFavoritesForm;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ComCtrls, Dialogs;

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
  private
    FOwnerEmail: string;
    procedure BuildColumns;
    procedure RebuildList;
    procedure ShowDetailById(AId: LongInt);
  public
    procedure OpenForUser(const AEmail: string);
  end;

var
  frmFavorites: TfrmFavorites;

implementation

{$R *.lfm}

uses
  uData, uUserMenu, uListaCorreos;  // PCorreo está en uListaCorreos

{ TfrmFavorites }

procedure TfrmFavorites.FormCreate(Sender: TObject);
begin
  BuildColumns;
  Caption := 'Favoritos';
  lvFavs.ReadOnly := True;
  lvFavs.ViewStyle := vsReport;
  lvFavs.RowSelect := True;
  lvFavs.OnSelectItem := @lvFavsSelectItem;

  btnVolver.Caption := 'Volver';
end;

procedure TfrmFavorites.btnVolverClick(Sender: TObject);
begin
  Hide;
  if Assigned(frmUserMenu) then
    frmUserMenu.Show;
end;

procedure TfrmFavorites.BuildColumns;
begin
  lvFavs.Columns.Clear;
  with lvFavs.Columns.Add do begin Caption := 'ID'; Width := 60; end;
  with lvFavs.Columns.Add do begin Caption := 'Asunto'; Width := 220; end;
  with lvFavs.Columns.Add do begin Caption := 'Remitente'; Width := 220; end;
end;

procedure TfrmFavorites.OpenForUser(const AEmail: string);
begin
  FOwnerEmail := AEmail;
  Caption := 'Favoritos de: ' + AEmail;
  RebuildList;
  Show;
end;

procedure TfrmFavorites.RebuildList;
var
  ids : TStringList;
  i, id: Integer;
  mail: PCorreo;
  item: TListItem;
begin
  lvFavs.Items.BeginUpdate;
  try
    lvFavs.Items.Clear;

    ids := GFavorites.GetIdListCopy(FOwnerEmail);
    try
      for i := 0 to ids.Count-1 do
      begin
        id := StrToIntDef(ids[i], 0);
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

  lblRemitVal.Caption := '';
  lblAsuntoVal.Caption := '';
  lblFechaVal.Caption := '';
  memMensaje.Clear;
end;

procedure TfrmFavorites.ShowDetailById(AId: LongInt);
var
  mail: PCorreo;
begin
  mail := GetMailById(AId);
  if mail = nil then Exit;

  lblRemitVal.Caption   := mail^.remitente;
  lblAsuntoVal.Caption  := mail^.asunto;
  lblFechaVal.Caption   := mail^.fecha;
  memMensaje.Lines.Text := mail^.mensaje;
end;

procedure TfrmFavorites.lvFavsSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
begin
  if Selected then
    ShowDetailById(StrToIntDef(Item.Caption, 0));
end;

procedure TfrmFavorites.btnEliminarClick(Sender: TObject);
var
  id: Integer;
  it: TListItem;
begin
  it := lvFavs.Selected;
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

