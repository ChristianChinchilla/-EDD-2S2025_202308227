# Manual Tecnico — EDDMail Fase 3  
**Christian David Chinchilla Santos** – **202308227**  
**Curso:** Estructuras de Datos (EDD)

---

## 1. Resumen del sistema
Simulador de correo en **Object Pascal / GTK (Lazarus)** que **evoluciona** la Fase 1 con nuevas estructuras y funciones:

- **Favoritos** por usuario (indexados en **Árbol B de orden 5**).
- **Borradores** gestionados con **AVL** (recorridos Pre/In/Post).
- **Comunidades** (árbol **BST** + lista simple de mensajes).
- **Mejoras de bandeja**: marcar/mostrar favoritos y conteo de no leídos.
- **Eliminar contacto** desde UI.
- **Carga masiva de correos** desde JSON.
- **Reportes** (Graphviz) para comunidades (BST), borradores (AVL) y favoritos (B).

> Roles: **root** (cargas masivan de contactos) y **usuario estándar** (Privados, Contactos, reportes).

---

## 2. Arquitectura general
- **Frontend (GUI):** Lazarus/GTK, formularios `*Form.pas`.
- **Dominio/Servicios:** `uData.pas`, `uListaCorreos.pas`, `uPrivados.pas`, estructuras (AVL, B, BST), y generadores de reportes (DOT/PNG).
- **Estructuras de Datos:**  
  - **BlockChain** (usuarios, mensajes de comunidad).  
  - **Lista doble** (correos).  
- **Persistencia:** JSON de usuarios y correos; DOT/PNG (Graphviz) para reportes.

---

## 3. Estructuras de datos e interfaces

### 3.1 `uPrivados.pas` — Privados
**Rol:** listar correos del usuario, detalle, marcar leído, **alternar favorito** y enviar a papelera.  
**Puntos clave en Fase 3:** Decoración de asunto con “★”, botón **Favorito/Quitar favorito**, y repintado inmediato.

**Fragmentos esenciales:**
```pascal
function TfrmInbox.IsFavForCurrent(P: Pointer): Boolean;
var C: PCorreo;
begin
  C := PCorreo(P);
  Result := (C <> nil) and GFavorites.Has(FEmailActual, C^.id);
end;

procedure TfrmInbox.UpdateFavButtonCaptionForRow(ARow: Integer);
var P: PCorreo;
begin
  if (ARow<=0) or (ARow>Length(FInboxRows)) then begin
    btnFavorito.Caption := 'Favorito'; Exit;
  end;
  P := PCorreo(FInboxRows[ARow-1]);
  if IsFavForCurrent(P) then btnFavorito.Caption := 'Quitar favorito'
                        else btnFavorito.Caption := 'Favorito';
end;

procedure TfrmInbox.PaintFavForRow(ARow: Integer);
var P: PCorreo;
begin
  if (ARow<=0) or (ARow>Length(FInboxRows)) then Exit;
  P := PCorreo(FInboxRows[ARow-1]); if P=nil then Exit;
  if IsFavForCurrent(P) then
    gridInbox.Cells[1,ARow] := '★ ' + P^.asunto
  else
    gridInbox.Cells[1,ARow] := P^.asunto;
end;

procedure TfrmInbox.btnFavoritoClick(Sender: TObject);
var P: PCorreo;
begin
  if gridInbox.Row > 0 then FSelectedRow := gridInbox.Row;
  if (FSelectedRow<=0) or (FSelectedRow>Length(FInboxRows)) then Exit;
  P := PCorreo(FInboxRows[FSelectedRow-1]); if P=nil then Exit;

  if IsFavForCurrent(P) then GFavorites.Remove(FEmailActual, P^.id)
                        else GFavorites.Add(FEmailActual, P^.id);

  PaintFavForRow(FSelectedRow);
  UpdateFavButtonCaptionForRow(FSelectedRow);
end;
```
---

### 3.3 `uBlockChain` 
**Rol:** publicar mensajes en una **comunidad existente** (validación por **BST**).  
Las comunidades mantienen una **lista simple** de mensajes (correo, mensaje, fecha).

```pascal
procedure TfrmCommunityPost.FormCreate(Sender: TObject);
begin
  Caption := 'Publicar mensaje';
  lblTitle.Caption := 'Publicar mensaje';
  lblComunidad.Caption := 'Comunidad';
  lblMensaje.Caption := 'Mensaje';
  btnPublicar.Caption := 'Publicar';
  btnVolver.Caption := 'Volver';
end;

procedure TfrmCommunityPost.OpenForUser(const AEmail: string);
begin
  FOwnerEmail := AEmail;
  edtComunidad.Text := '';
  memMensaje.Clear;
  Show;
end;

procedure TfrmCommunityPost.btnPublicarClick(Sender: TObject);
var comu, msg, fecha: string;
begin
  comu := Trim(edtComunidad.Text);
  msg  := Trim(memMensaje.Text);

  if (comu='') or (msg='') then begin
    ShowMessage('Ingresa comunidad y mensaje.'); Exit;
  end;

  if not GCommunity.Exists(comu) then begin
    ShowMessage('La comunidad "'+comu+'" no existe.'); Exit;
  end;

  fecha := FormatDateTime('dd/mm/yyyy hh:nn', Now);
  GCommunity.Post(comu, FOwnerEmail, msg, fecha);

  ShowMessage('Mensaje publicado en "'+comu+'".');
  memMensaje.Clear; memMensaje.SetFocus;
end;

procedure TfrmCommunityPost.btnVolverClick(Sender: TObject);
begin
  Hide;
  if Assigned(frmUserMenu) then frmUserMenu.Show;
end;
```

---

### 3.4 `uContacts.pas` — Navegación y **Eliminar contacto**
**Rol:** navegar contactos (lista circular lógica) y **refrescar** tras eliminar (acción típica desde otro form).


```pascal
type
  { TfrmContacts }
  TfrmContacts = class(TForm)
    btnPrev: TButton; btnNext: TButton; btnVolver: TButton;
    lblNombreT, lblNombreV: TLabel;
    lblUsuarioT, lblUsuarioV: TLabel;
    lblCorreoT, lblCorreoV: TLabel;
    lblTelefonoT, lblTelefonoV: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure btnPrevClick(Sender: TObject);
    procedure btnNextClick(Sender: TObject);
    procedure btnVolverClick(Sender: TObject);
  private
    FOwner: string;
    FList: TStringList;
    FIndex: Integer;
    procedure UpdateView;
  public
    procedure OpenForUser(const AOwnerEmail: string);
    procedure RefreshList;
  end;

procedure TfrmContacts.FormCreate(Sender: TObject);
begin
  Caption := 'Contacts';
  FList := TStringList.Create; FIndex := -1;
end;

procedure TfrmContacts.OpenForUser(const AOwnerEmail: string);
begin
  FOwner := AOwnerEmail; RefreshList; Show;
end;

procedure TfrmContacts.RefreshList;
begin
  FreeAndNil(FList);
  FList := GContacts.GetListCopy(FOwner);
  if FList.Count > 0 then FIndex := 0 else FIndex := -1;
  UpdateView;
end;

procedure TfrmContacts.UpdateView;
var u: PUsuario;
begin
  if (FIndex<0) or (FIndex>=FList.Count) then begin
    lblNombreV.Caption := '(sin contactos)';
    lblUsuarioV.Caption := ''; lblCorreoV.Caption := ''; lblTelefonoV.Caption := '';
    Exit;
  end;
  lblCorreoV.Caption := FList[FIndex];
  u := GUsuarios.FindByEmail(lblCorreoV.Caption);
  if u<>nil then begin
    lblNombreV.Caption := u^.nombre; lblUsuarioV.Caption := u^.usuario; lblTelefonoV.Caption := u^.telefono;
  end else begin
    lblNombreV.Caption := '(desconocido)'; lblUsuarioV.Caption := ''; lblTelefonoV.Caption := '';
  end;
end;

procedure TfrmContacts.btnPrevClick(Sender: TObject);
begin
  if FList.Count=0 then Exit;
  if FIndex>0 then Dec(FIndex) else FIndex := FList.Count-1;
  UpdateView;
end;

procedure TfrmContacts.btnNextClick(Sender: TObject);
begin
  if FList.Count=0 then Exit;
  if FIndex < FList.Count-1 then Inc(FIndex) else FIndex := 0;
  UpdateView;
end;

procedure TfrmContacts.btnVolverClick(Sender: TObject);
begin
  Hide; if not Assigned(frmUserMenu) then Application.CreateForm(TfrmUserMenu, frmUserMenu);
  frmUserMenu.Show;
end;

```
---

### 3.5 `uListaCorreos.pas` — Lista doble + **carga masiva de correos**
**Rol:** lista doblementre enlazada para correos (bandeja), con **carga flexible** desde JSON.  
**Novedad:** `favorito: Boolean` en `TCorreo`.

```pascal
type
  PCorreo = ^TCorreo;
  TCorreo = record
    id          : LongInt;
    remitente   : string;
    destinatario: string;
    estado      : string;  // 'NL' o 'L'
    programado  : string;  // fecha/hora si aplica
    asunto      : string;
    fecha       : string;
    mensaje     : string;
    favorito    : Boolean; // NUEVO
    next, prev  : PCorreo;
  end;

  TListaCorreos = class
  private
    FHead, FTail: PCorreo; FCount: SizeInt;
  public
    constructor Create; destructor Destroy; override;
    procedure Clear;
    function  Add(const AId: LongInt; const ARem, ADest, AEstado, AProg,
                  AAsunto, AFecha, AMsg: string): PCorreo;
    function  Count: SizeInt;
    function  First: PCorreo;
    procedure Remove(ACorreo: PCorreo);  // libera
    procedure Detach(ACorreo: PCorreo);  // sin liberar (mover a pila/cola)
    function  NextId: LongInt;
    procedure LoadFromJSON(const ARuta: string; const Usuarios: TListaUsuarios);
    procedure ExportRelacionesDOT(const ARuta: string);
    procedure ExportRelacionesMatrizDOT(const ARuta: string);
  end;
```


---

## 4. Reportes (Fase 3)
- **Comunidades (BST)**  
- **Borradores (AVL)**  
- **Favoritos (B–tree)**  
- Generación con Graphviz (`dot -Tpng`).  
- Directorios: `Root-Reportes/` y `<usuario>-Reportes/`

---

## 5. Requisitos, instalación y ejecución
- **SO:** Linux (Debian/derivados).  
- **IDE:** Lazarus + FPC.  
- **GUI:** GTK.  
- **Reportes:** Graphviz.  
- **Compilación:** abrir proyecto en Lazarus → Run.  
- **Datos:** JSON de usuarios y correos.

