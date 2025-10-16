unit uCommunityMessagesForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls;

type
  { TfrmCommunityMessages }
  TfrmCommunityMessages = class(TForm)
    Label1: TLabel;         // Título arriba de la lista
    ListBox1: TListBox;     // Lista de mensajes (Comunidad | Autor | Fecha + cuerpo)
    Button1: TButton;       // Volver
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    procedure LoadAllMessages; // carga todos los mensajes con su nombre de comunidad
  public
    procedure Open; // muestra el form con la lista actualizada
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
  Button1.Caption := 'Volver';

  // El formulario ya no usa el ComboBox; lo ocultamos para que solo se vea la lista
  if Assigned(ComboBox1) then
    ComboBox1.Visible := False;

  if Assigned(Label1) then
    Label1.Caption := 'Mensajes (Comunidad | Autor | Fecha):';
end;

procedure TfrmCommunityMessages.Open;
begin
  LoadAllMessages;
  Show;
end;

procedure TfrmCommunityMessages.LoadAllMessages;
var
  nodes : TArrayOfBSTNodes;
  msgs  : TArrayOfMensajes;
  i, j  : Integer;
  comm  : string;
  dtStr : string;
begin
  ListBox1.Items.BeginUpdate;
  try
    ListBox1.Clear;

    if (GCommunitiesBST = nil) then
    begin
      ListBox1.Items.Add('No hay comunidades.');
      Exit;
    end;

    nodes := GCommunitiesBST.ToArray;

    // Recorremos TODAS las comunidades y agregamos sus mensajes
    for i := 0 to High(nodes) do
    begin
      if (nodes[i] = nil) then Continue;

      comm := Trim(nodes[i].GetInfo);
      if comm = '' then Continue;

      msgs := nodes[i].GetMensajes;
      for j := 0 to High(msgs) do
      begin
        dtStr := FormatDateTime('dd-mm-yyyy hh:nn', msgs[j].GetFecha);

        // Encabezado con comunidad | autor | fecha
        ListBox1.Items.Add(Format('%s | %s | %s', [comm, msgs[j].GetAutor, dtStr]));
        // Cuerpo del mensaje
        ListBox1.Items.Add(msgs[j].GetMensaje);
        // Separador
        ListBox1.Items.Add('----------------------------');
      end;
    end;

    if ListBox1.Items.Count = 0 then
      ListBox1.Items.Add('No hay mensajes publicados aún.');
  finally
    ListBox1.Items.EndUpdate;
  end;
end;

procedure TfrmCommunityMessages.Button1Click(Sender: TObject);
begin
  Hide;
end;

end.

