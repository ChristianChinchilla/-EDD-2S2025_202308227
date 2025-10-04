unit uCommunityMessagesForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls;

type
  { TfrmCommunityMessages }
  TfrmCommunityMessages = class(TForm)
    ComboBox1: TComboBox;  // comunidades
    Label1: TLabel;        // "Comunidad:"
    ListBox1: TListBox;    // mensajes
    Button1: TButton;      // "Volver"
    procedure Button1Click(Sender: TObject);
    procedure ComboBox1Change(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    procedure FillCommunities;
    procedure LoadMessagesFor(const AName: string);
  public
    procedure Open; // carga comunidades y muestra el form
  end;

var
  frmCommunityMessages: TfrmCommunityMessages;

implementation

{$R *.lfm}

uses
  uData, BST_Comunidades;

{ TfrmCommunityMessages }

procedure TfrmCommunityMessages.FormCreate(Sender: TObject);
begin
  Caption := 'Mensajes de Comunidad';
  Label1.Caption := 'Comunidad:';
  Button1.Caption := 'Volver';
end;

procedure TfrmCommunityMessages.Open;
begin
  FillCommunities;
  if (ComboBox1.Items.Count > 0) then
  begin
    ComboBox1.ItemIndex := 0;
    LoadMessagesFor(ComboBox1.Items[0]);
  end
  else
    ListBox1.Items.Clear;

  Show;
end;

procedure TfrmCommunityMessages.FillCommunities;
var
  arr: TArrayOfBSTNodes;
  i: Integer;
begin
  ComboBox1.Items.BeginUpdate;
  try
    ComboBox1.Items.Clear;
    if (GCommunitiesBST <> nil) then
    begin
      arr := GCommunitiesBST.ToArray;
      for i := 0 to High(arr) do
        if (arr[i] <> nil) and (Trim(arr[i].GetInfo) <> '') then
          ComboBox1.Items.Add(arr[i].GetInfo);
    end;
  finally
    ComboBox1.Items.EndUpdate;
  end;
end;

procedure TfrmCommunityMessages.LoadMessagesFor(const AName: string);
var
  msgs: TArrayOfMensajes;
  i: Integer;
  dtStr: string;
begin
  ListBox1.Items.BeginUpdate;
  try
    ListBox1.Items.Clear;
    msgs := CommunityListMessages(Trim(AName));
    for i := 0 to High(msgs) do
    begin
      dtStr := FormatDateTime('dd/mm/yyyy hh:nn', msgs[i].GetFecha);
      ListBox1.Items.Add(
        msgs[i].GetAutor + ' | ' + dtStr + LineEnding +
        msgs[i].GetMensaje + LineEnding + '----------------------------'
      );
    end;
  finally
    ListBox1.Items.EndUpdate;
  end;
end;

procedure TfrmCommunityMessages.ComboBox1Change(Sender: TObject);
begin
  if ComboBox1.ItemIndex >= 0 then
    LoadMessagesFor(ComboBox1.Items[ComboBox1.ItemIndex]);
end;

procedure TfrmCommunityMessages.Button1Click(Sender: TObject);
begin
  Hide;
end;

end.

