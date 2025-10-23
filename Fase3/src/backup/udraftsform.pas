unit uDraftsForm;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls, Dialogs;

type
  { TfrmDrafts }
  TfrmDrafts = class(TForm)
    // Barra superior
    Button1: TButton;   // Pre-Orden
    Button2: TButton;   // In-Orden
    Button3: TButton;   // Post-Orden
    Button4: TButton;   // Enviar
    Button5: TButton;   // Volver
    btnEliminar: TButton;  // << NUEVO: Eliminar borrador
    btnEliminar: TButton;
    lblDestinatario: TLabel;
    Panel1: TPanel;

    // Lista + detalle
    lstDrafts: TListBox;

    lblRemitente: TLabel;   // títulos (lo usamos como “Destinatario:”)
    lblAsunto:    TLabel;
    lblFecha:     TLabel;

    lblRemitVal:  TLabel;   // valores (aquí mostramos el DESTINATARIO)
    lblAsuntoVal: TLabel;
    lblFechaVal:  TLabel;

    Memo1: TMemo;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Button1Click(Sender: TObject);  // Pre
    procedure Button2Click(Sender: TObject);  // In
    procedure Button3Click(Sender: TObject);  // Post
    procedure Button4Click(Sender: TObject);  // Enviar
    procedure Button5Click(Sender: TObject);  // Volver
    procedure btnEliminarClick(Sender: TObject); // << NUEVO
    procedure lstDraftsClick(Sender: TObject);
    procedure Memo1Change(Sender: TObject);
  private
    FOwnerEmail : string;
    FOrderMode  : Integer;   // 0=Pre, 1=In, 2=Post
    FView       : TList;     // elementos = PDraft (NO se liberan aquí)
    FSelIndex   : Integer;
    FIgnoreMemo : Boolean;

    procedure RebuildView;                // usa FOrderMode
    procedure FillListBox;                // volcar FView -> lstDrafts
    procedure ShowDetailByIndex(AIndex: Integer);
    procedure ClearDetail;
  public
    procedure OpenForUser(const AEmail: string);
  end;

// Helper para refrescar desde el editor
procedure RefreshDraftsView(const AEmail: string);

var
  frmDrafts: TfrmDrafts;

implementation

{$R *.lfm}

uses
  uUserMenu, uData, uListaCorreos; // <- EsContacto, GDrafts, GPapelera, GCorreos

type
  PDraft = ^TDraft;

{----------- Helper global -----------}
procedure RefreshDraftsView(const AEmail: string);
begin
  if not Assigned(frmDrafts) then
    Application.CreateForm(TfrmDrafts, frmDrafts);

  frmDrafts.FOwnerEmail := AEmail;
  if frmDrafts.FView = nil then
    frmDrafts.FView := TList.Create;
  frmDrafts.RebuildView;
end;

{ TfrmDrafts }

procedure TfrmDrafts.FormCreate(Sender: TObject);
begin
  // Etiquetas
  lblRemitente.Caption := 'Destinatario:';  // antes: 'Remitente:'
  lblAsunto.Caption    := 'Asunto:';
  lblFecha.Caption     := 'Fecha:';

  // Botones
  Button1.Caption := 'Pre-Orden';
  Button2.Caption := 'In-Orden';
  Button3.Caption := 'Post-Orden';
  Button4.Caption := 'Enviar';
  Button5.Caption := 'Volver';

  // << NUEVO: botón eliminar
  if not Assigned(btnEliminar) then
    btnEliminar := TButton.Create(Self);
  btnEliminar.Parent   := Panel1;
  btnEliminar.Caption  := 'Eliminar';
  btnEliminar.Left     := Button4.Left + Button4.Width + 12; // a la derecha de "Enviar"
  btnEliminar.Top      := Button4.Top;
  btnEliminar.Height   := Button4.Height;
  btnEliminar.Width    := 90;
  btnEliminar.OnClick  := @btnEliminarClick;

  // Estado
  FView       := TList.Create;
  FOrderMode  := 1;   // In-orden por defecto
  FSelIndex   := -1;
  FIgnoreMemo := False;

  // Eventos
  lstDrafts.Clear;
  lstDrafts.OnClick  := @lstDraftsClick;
  Memo1.OnChange     := @Memo1Change;
end;

procedure TfrmDrafts.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FView);
end;

procedure TfrmDrafts.OpenForUser(const AEmail: string);
begin
  FOwnerEmail := AEmail;
  Caption := 'Borradores de: ' + AEmail;
  RebuildView;
  Show;
end;

procedure TfrmDrafts.Button1Click(Sender: TObject);
begin
  FOrderMode := 0;   // Pre
  RebuildView;
end;

procedure TfrmDrafts.Button2Click(Sender: TObject);
begin
  FOrderMode := 1;   // In
  RebuildView;
end;

procedure TfrmDrafts.Button3Click(Sender: TObject);
begin
  FOrderMode := 2;   // Post
  RebuildView;
end;

procedure TfrmDrafts.Button4Click(Sender: TObject);
var
  D : PDraft;
  id: LongInt;
begin
  if (FSelIndex<0) or (FSelIndex>=FView.Count) then Exit;
  D := PDraft(FView[FSelIndex]); if D=nil then Exit;

  // Validar que el destinatario esté en tus contactos
  if not EsContacto(FOwnerEmail, Trim(D^.destinatario)) then
  begin
    ShowMessage('El destinatario no está en tus contactos.');
    Exit;
  end;

  // Asegurar remitente
  if Trim(D^.remitente) = '' then
    D^.remitente := FOwnerEmail;

  // Crear el correo enviado (para = D^.destinatario)
  id := GCorreos.NextId;
  GCorreos.Add(
    id,
    D^.remitente,           // remitente
    D^.destinatario,        // destinatario del borrador
    'NL',                   // estado normal
    '',                     // programado vacío
    D^.asunto,
    FormatDateTime('dd/mm/yyyy hh:nn', Now),
    D^.mensaje
  );

  // Eliminar el borrador
  GDrafts.RemoveById(D^.id);

  // Refrescar vista
  ClearDetail;
  RebuildView;
  ShowMessage('Borrador enviado.');
end;

procedure TfrmDrafts.Button5Click(Sender: TObject);
begin
  Hide;
  if Assigned(frmUserMenu) then frmUserMenu.Show;
end;

procedure TfrmDrafts.btnEliminarClick(Sender: TObject);
var
  D : PDraft;
  M : PCorreo;
begin
  if (FSelIndex<0) or (FSelIndex>=FView.Count) then
  begin
    ShowMessage('Selecciona un borrador primero.');
    Exit;
  end;

  D := PDraft(FView[FSelIndex]); if D=nil then Exit;

  if MessageDlg('Eliminar borrador',
                '¿Deseas eliminar este borrador? Se enviará a la papelera.',
                mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  // 1) Enviar a la papelera como correo marcado BOR
  New(M);
  M^.id           := GCorreos.NextId;
  if Trim(D^.remitente) <> '' then
    M^.remitente  := D^.remitente
  else
    M^.remitente  := FOwnerEmail;
  M^.destinatario := D^.destinatario;
  M^.estado       := 'BOR';                      // <- identificador de borrador eliminado
  M^.programado   := '';
  M^.asunto       := D^.asunto;
  M^.fecha        := D^.fecha;                   // puedes usar Now si prefieres marca de eliminación
  M^.mensaje      := D^.mensaje;
  M^.next         := nil;
  GPapelera.Push(M);

  // 2) Eliminar del BST de borradores
  GDrafts.RemoveById(D^.id);

  // 3) Refrescar UI
  ClearDetail;
  RebuildView;
end;

procedure TfrmDrafts.lstDraftsClick(Sender: TObject);
begin
  ShowDetailByIndex(lstDrafts.ItemIndex);
end;

procedure TfrmDrafts.Memo1Change(Sender: TObject);
var
  D: PDraft;
begin
  if FIgnoreMemo then Exit;
  if (FSelIndex<0) or (FSelIndex>=FView.Count) then Exit;
  D := PDraft(FView[FSelIndex]); if D=nil then Exit;
  D^.mensaje := Memo1.Lines.Text;
end;

procedure TfrmDrafts.RebuildView;
var
  tmp : TList;
  i   : Integer;
  D   : PDraft;
begin
  if FView = nil then
    FView := TList.Create;

  FView.Clear;

  tmp := TList.Create;
  try
    case FOrderMode of
      0: GDrafts.ListPre (tmp);
      1: GDrafts.ListIn  (tmp);
      2: GDrafts.ListPost(tmp);
    else
      GDrafts.ListIn(tmp);
    end;

    // Filtrar solo borradores del usuario actual (remitente = FOwnerEmail)
    for i := 0 to tmp.Count-1 do
    begin
      D := PDraft(tmp[i]);
      if (D<>nil) and SameText(D^.remitente, FOwnerEmail) then
        FView.Add(D);
    end;
  finally
    tmp.Free;
  end;

  FillListBox;
  ClearDetail;

  if lstDrafts.Count>0 then
  begin
    lstDrafts.ItemIndex := 0;
    ShowDetailByIndex(0);
  end;
end;

procedure TfrmDrafts.FillListBox;
var
  i: Integer;
  D: PDraft;
  s: string;
begin
  lstDrafts.Items.BeginUpdate;
  try
    lstDrafts.Clear;
    for i := 0 to FView.Count-1 do
    begin
      D := PDraft(FView[i]);
      if D<>nil then
      begin
        // Mostrar asunto — DESTINATARIO en la lista
        s := Format('[BOR] %s — %s', [D^.asunto, D^.destinatario]);
        lstDrafts.Items.Add(s);
      end;
    end;
  finally
    lstDrafts.Items.EndUpdate;
  end;
end;

procedure TfrmDrafts.ShowDetailByIndex(AIndex: Integer);
var
  D: PDraft;
begin
  if (AIndex<0) or (AIndex>=FView.Count) then Exit;

  FSelIndex := AIndex;
  D := PDraft(FView[FSelIndex]); if D=nil then Exit;

  // Mostrar DESTINATARIO en el detalle
  lblRemitVal.Caption  := D^.destinatario;
  lblAsuntoVal.Caption := D^.asunto;
  lblFechaVal.Caption  := D^.fecha;

  FIgnoreMemo := True;
  Memo1.Lines.Text := D^.mensaje;
  FIgnoreMemo := False;
end;

procedure TfrmDrafts.ClearDetail;
begin
  FSelIndex := -1;
  lblRemitVal.Caption  := '';
  lblAsuntoVal.Caption := '';
  lblFechaVal.Caption  := '';
  Memo1.Clear;
end;

end.

