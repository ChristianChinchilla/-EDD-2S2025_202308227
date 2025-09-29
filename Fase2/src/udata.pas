unit uData;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, uListaUsuarios, uListaCorreos;

type
  { ====== PILA (Papelera) ====== }
  PTrashNode = ^TTrashNode;
  TTrashNode = record
    Mail : PCorreo;
    Next : PTrashNode;
  end;

  TPCorreoArray = array of PCorreo;

  TTrashStack = class
  private
    FTop   : PTrashNode;
    FCount : SizeInt;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure Push(AMail: PCorreo);
    function  Pop: PCorreo;
    function  Peek: PCorreo;
    function  Count: SizeInt;
    function  Snapshot: TPCorreoArray;
  end;

  { ====== COLA (Correos programados) ====== }
  PSchedNode = ^TSchedNode;
  TSchedNode = record
    Mail: PCorreo;
    Next: PSchedNode;
  end;

  TScheduledQueue = class
  private
    FHead, FTail: PSchedNode;
    FCount: SizeInt;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure Enqueue(AMail: PCorreo);
    function  Dequeue: PCorreo;
    function  Peek: PCorreo;
    function  Count: SizeInt;
    function  Snapshot: TPCorreoArray;
  end;

  { ====== CONTACTOS POR USUARIO ====== }
  TContacts = class
  private
    FOwners: TStringList;
    function IndexOfOwner(const Owner: string): Integer;
    function EnsureOwner(const Owner: string): TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure Add(const Owner, Email: string);
    function  Has(const Owner, Email: string): Boolean;
    function  Remove(const Owner, Email: string): Boolean;
    function  GetListCopy(const Owner: string): TStringList;
    function  Count(const Owner: string): Integer;
  end;

  { ====== FAVORITOS POR USUARIO (IDs de correos) ====== }
  TFavorites = class
  private
    // Mapa: Owner -> TStringList (IDs de correos en texto)
    FOwners: TStringList;
    function IndexOfOwner(const Owner: string): Integer;
    function EnsureOwner(const Owner: string): TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure Add   (const Owner: string; const MailId: LongInt);
    function  Remove(const Owner: string; const MailId: LongInt): Boolean;
    function  Has   (const Owner: string; const MailId: LongInt): Boolean;
    function  GetIdListCopy(const Owner: string): TStringList; // copia (IDs como strings)
    function  Count(const Owner: string): Integer;
  end;

  { ====== BORRADORES (BST) ====== }
  PDraft = ^TDraft;
  TDraft = record
    id          : LongInt;
    remitente   : string;
    destinatario: string;
    asunto      : string;
    fecha       : string;
    mensaje     : string;
    left, right : PDraft;
  end;

  TDraftBST = class
  private
    FRoot : PDraft;
    FAuto : LongInt;
    procedure ClearNode(N: PDraft);
    function  InsertNode(var R: PDraft; D: PDraft): PDraft;
    function  Cmp(const A, B: PDraft): Integer;
    procedure ToListPre (R: PDraft; L: TList);
    procedure ToListIn  (R: PDraft; L: TList);
    procedure ToListPost(R: PDraft; L: TList);
    function  CountNode(R: PDraft): Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function  NextId: LongInt;
    function  Add(const Rem, Dest, Asu, Fec, Msg: string): PDraft;
    procedure RemoveById(const AId: LongInt);
    function  FindById(const AId: LongInt): PDraft;
    function  Count: Integer;
    procedure ListPre (L: TList);
    procedure ListIn  (L: TList);
    procedure ListPost(L: TList);
  end;

var
  GUsuarios  : TListaUsuarios;
  GCorreos   : TListaCorreos;
  GPapelera  : TTrashStack;
  GScheduled : TScheduledQueue;
  GContacts  : TContacts;
  GFavorites : TFavorites;
  GDrafts    : TDraftBST;

function EsContacto(const OwnerEmail, DestEmail: string): Boolean;
function GetMailById(AId: LongInt): PCorreo;  // <-- HELPER NUEVO

implementation

{ ======================== TTrashStack ======================== }

constructor TTrashStack.Create;
begin
  inherited Create;
  FTop := nil; FCount := 0;
end;

destructor TTrashStack.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TTrashStack.Clear;
var n, nx: PTrashNode;
begin
  n := FTop;
  while n <> nil do
  begin
    nx := n^.Next;
    Dispose(n);
    n := nx;
  end;
  FTop := nil; FCount := 0;
end;

procedure TTrashStack.Push(AMail: PCorreo);
var n: PTrashNode;
begin
  New(n);
  n^.Mail := AMail;
  n^.Next := FTop;
  FTop := n;
  Inc(FCount);
end;

function TTrashStack.Pop: PCorreo;
var n: PTrashNode;
begin
  if FTop = nil then Exit(nil);
  n := FTop; FTop := n^.Next;
  Result := n^.Mail;
  Dispose(n);
  Dec(FCount);
end;

function TTrashStack.Peek: PCorreo;
begin
  if FTop <> nil then Result := FTop^.Mail else Result := nil;
end;

function TTrashStack.Count: SizeInt;
begin
  Result := FCount;
end;

function TTrashStack.Snapshot: TPCorreoArray;
var node: PTrashNode; i: SizeInt;
begin
  SetLength(Result, FCount);
  node := FTop; i := 0;
  while node <> nil do
  begin
    Result[i] := node^.Mail; Inc(i);
    node := node^.Next;
  end;
end;

{ ====================== TScheduledQueue ====================== }

constructor TScheduledQueue.Create;
begin
  inherited Create;
  FHead := nil; FTail := nil; FCount := 0;
end;

destructor TScheduledQueue.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TScheduledQueue.Clear;
var n, nx: PSchedNode;
begin
  n := FHead;
  while n <> nil do
  begin
    nx := n^.Next;
    Dispose(n);
    n := nx;
  end;
  FHead := nil; FTail := nil; FCount := 0;
end;

procedure TScheduledQueue.Enqueue(AMail: PCorreo);
var n: PSchedNode;
begin
  New(n);
  n^.Mail := AMail;
  n^.Next := nil;
  if FTail <> nil then FTail^.Next := n else FHead := n;
  FTail := n;
  Inc(FCount);
end;

function TScheduledQueue.Dequeue: PCorreo;
var n: PSchedNode;
begin
  if FHead = nil then Exit(nil);
  n := FHead;
  FHead := n^.Next; if FHead = nil then FTail := nil;
  Result := n^.Mail;
  Dispose(n);
  Dec(FCount);
end;

function TScheduledQueue.Peek: PCorreo;
begin
  if FHead <> nil then Result := FHead^.Mail else Result := nil;
end;

function TScheduledQueue.Count: SizeInt;
begin
  Result := FCount;
end;

function TScheduledQueue.Snapshot: TPCorreoArray;
var n: PSchedNode; i: SizeInt;
begin
  SetLength(Result, FCount);
  n := FHead; i := 0;
  while n <> nil do
  begin
    Result[i] := n^.Mail; Inc(i);
    n := n^.Next;
  end;
end;

{ ========================= TContacts ========================= }

constructor TContacts.Create;
begin
  inherited Create;
  FOwners := TStringList.Create;
  FOwners.Sorted := True;
  FOwners.Duplicates := dupIgnore;
end;

destructor TContacts.Destroy;
begin
  Clear;
  FOwners.Free;
  inherited Destroy;
end;

procedure TContacts.Clear;
var
  i: Integer; L: TStringList;
begin
  for i := 0 to FOwners.Count-1 do
  begin
    L := TStringList(FOwners.Objects[i]);
    L.Free;
  end;
  FOwners.Clear;
end;

function TContacts.IndexOfOwner(const Owner: string): Integer;
begin
  Result := FOwners.IndexOf(Owner);
end;

function TContacts.EnsureOwner(const Owner: string): TStringList;
var idx: Integer;
begin
  idx := IndexOfOwner(Owner);
  if idx < 0 then
  begin
    Result := TStringList.Create;
    Result.Sorted := True;
    Result.Duplicates := dupIgnore;
    FOwners.AddObject(Owner, Result);
  end
  else
    Result := TStringList(FOwners.Objects[idx]);
end;

procedure TContacts.Add(const Owner, Email: string);
var L: TStringList;
begin
  L := EnsureOwner(Owner);
  L.Add(Email);
end;

function TContacts.Has(const Owner, Email: string): Boolean;
var idx: Integer; L: TStringList;
begin
  idx := IndexOfOwner(Owner);
  if idx < 0 then Exit(False);
  L := TStringList(FOwners.Objects[idx]);
  Result := L.IndexOf(Email) >= 0;
end;

function TContacts.Remove(const Owner, Email: string): Boolean;
var idx, p: Integer; L: TStringList;
begin
  Result := False;
  idx := IndexOfOwner(Owner);
  if idx < 0 then Exit(False);
  L := TStringList(FOwners.Objects[idx]);
  p := L.IndexOf(Email);
  if p >= 0 then
  begin
    L.Delete(p);
    Result := True;
  end;
end;

function TContacts.GetListCopy(const Owner: string): TStringList;
var idx: Integer; L: TStringList;
begin
  Result := TStringList.Create;
  idx := IndexOfOwner(Owner);
  if idx < 0 then Exit; // vacía
  L := TStringList(FOwners.Objects[idx]);
  Result.Assign(L);
end;

function TContacts.Count(const Owner: string): Integer;
var idx: Integer; L: TStringList;
begin
  idx := IndexOfOwner(Owner);
  if idx < 0 then Exit(0);
  L := TStringList(FOwners.Objects[idx]);
  Result := L.Count;
end;

function EsContacto(const OwnerEmail, DestEmail: string): Boolean;
begin
  Result := (GContacts <> nil) and GContacts.Has(OwnerEmail, DestEmail);
end;

{ ========================= TFavorites ========================= }

constructor TFavorites.Create;
begin
  inherited Create;
  FOwners := TStringList.Create;
  FOwners.Sorted := True;
  FOwners.Duplicates := dupIgnore;
end;

destructor TFavorites.Destroy;
begin
  Clear;
  FOwners.Free;
  inherited Destroy;
end;

procedure TFavorites.Clear;
var
  i: Integer; L: TStringList;
begin
  for i := 0 to FOwners.Count-1 do
  begin
    L := TStringList(FOwners.Objects[i]);
    L.Free;
  end;
  FOwners.Clear;
end;

function TFavorites.IndexOfOwner(const Owner: string): Integer;
begin
  Result := FOwners.IndexOf(Owner);
end;

function TFavorites.EnsureOwner(const Owner: string): TStringList;
var idx: Integer;
begin
  idx := IndexOfOwner(Owner);
  if idx < 0 then
  begin
    Result := TStringList.Create;
    Result.Sorted := True;
    Result.Duplicates := dupIgnore; // evita IDs duplicados
    FOwners.AddObject(Owner, Result);
  end
  else
    Result := TStringList(FOwners.Objects[idx]);
end;

procedure TFavorites.Add(const Owner: string; const MailId: LongInt);
var L: TStringList;
begin
  L := EnsureOwner(Owner);
  L.Add(IntToStr(MailId));
end;

function TFavorites.Remove(const Owner: string; const MailId: LongInt): Boolean;
var idx, p: Integer; L: TStringList;
begin
  Result := False;
  idx := IndexOfOwner(Owner);
  if idx < 0 then Exit(False);
  L := TStringList(FOwners.Objects[idx]);
  p := L.IndexOf(IntToStr(MailId));
  if p >= 0 then
  begin
    L.Delete(p);
    Result := True;
  end;
end;

function TFavorites.Has(const Owner: string; const MailId: LongInt): Boolean;
var idx: Integer; L: TStringList;
begin
  idx := IndexOfOwner(Owner);
  if idx < 0 then Exit(False);
  L := TStringList(FOwners.Objects[idx]);
  Result := L.IndexOf(IntToStr(MailId)) >= 0;
end;

function TFavorites.GetIdListCopy(const Owner: string): TStringList;
var idx: Integer; L: TStringList;
begin
  Result := TStringList.Create;
  idx := IndexOfOwner(Owner);
  if idx < 0 then Exit; // vacía
  L := TStringList(FOwners.Objects[idx]);
  Result.Assign(L);
end;

function TFavorites.Count(const Owner: string): Integer;
var idx: Integer; L: TStringList;
begin
  idx := IndexOfOwner(Owner);
  if idx < 0 then Exit(0);
  L := TStringList(FOwners.Objects[idx]);
  Result := L.Count;
end;

{ ========================= TDraftBST ========================= }

constructor TDraftBST.Create;
begin
  inherited Create;
  FRoot := nil;
  FAuto := 0;
end;

destructor TDraftBST.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TDraftBST.ClearNode(N: PDraft);
begin
  if N=nil then Exit;
  ClearNode(N^.left);
  ClearNode(N^.right);
  Dispose(N);
end;

procedure TDraftBST.Clear;
begin
  ClearNode(FRoot);
  FRoot := nil;
end;

function TDraftBST.NextId: LongInt;
begin
  Inc(FAuto);
  Result := FAuto;
end;

function TDraftBST.Cmp(const A, B: PDraft): Integer;
begin
  Result := AnsiCompareText(A^.asunto, B^.asunto);
  if Result=0 then
    Result := A^.id - B^.id;
end;

function TDraftBST.InsertNode(var R: PDraft; D: PDraft): PDraft;
begin
  if R=nil then
  begin
    R := D; Exit(D);
  end;
  if Cmp(D, R) < 0 then Exit(InsertNode(R^.left, D))
  else Exit(InsertNode(R^.right, D));
end;

function TDraftBST.Add(const Rem, Dest, Asu, Fec, Msg: string): PDraft;
var n: PDraft;
begin
  New(n);
  n^.id := NextId;
  n^.remitente := Rem;
  n^.destinatario := Dest;
  n^.asunto := Asu;
  n^.fecha := Fec;
  n^.mensaje := Msg;
  n^.left := nil; n^.right := nil;
  Result := InsertNode(FRoot, n);
end;

function TDraftBST.FindById(const AId: LongInt): PDraft;
type
  PDraftArray = array of PDraft;
var
  cur: PDraft;
  stk: PDraftArray;
begin
  Result := nil;
  cur := FRoot;
  SetLength(stk,0);
  while (cur<>nil) or (Length(stk)>0) do
  begin
    while cur<>nil do
    begin
      SetLength(stk,Length(stk)+1);
      stk[High(stk)] := cur;
      cur := cur^.left;
    end;
    cur := stk[High(stk)];
    SetLength(stk,High(stk));
    if cur^.id = AId then Exit(cur);
    cur := cur^.right;
  end;
end;

procedure TDraftBST.RemoveById(const AId: LongInt);
  function Del(var R: PDraft; const Id: LongInt): PDraft;
  var tmp, parent, succ: PDraft;
  begin
    if R=nil then Exit(nil);
    if R^.id = Id then
    begin
      if (R^.left=nil) and (R^.right=nil) then
      begin tmp := R; R := nil; Exit(tmp); end
      else if (R^.left=nil) then
      begin tmp := R; R := R^.right; Exit(tmp); end
      else if (R^.right=nil) then
      begin tmp := R; R := R^.left;  Exit(tmp); end
      else
      begin
        parent := R; succ := R^.right;
        while succ^.left<>nil do begin parent := succ; succ := succ^.left end;
        R^.id:=succ^.id; R^.remitente:=succ^.remitente; R^.destinatario:=succ^.destinatario;
        R^.asunto:=succ^.asunto; R^.fecha:=succ^.fecha; R^.mensaje:=succ^.mensaje;
        if parent^.left = succ then parent^.left := succ^.right
        else parent^.right := succ^.right;
        Exit(succ);
      end;
    end
    else
    begin
      Result := Del(R^.left, Id);
      if Result=nil then Result := Del(R^.right, Id);
    end;
  end;
var dead: PDraft;
begin
  dead := Del(FRoot, AId);
  if dead<>nil then Dispose(dead);
end;

procedure TDraftBST.ToListPre (R: PDraft; L: TList);
begin
  if R=nil then Exit;
  L.Add(R);
  ToListPre(R^.left, L);
  ToListPre(R^.right, L);
end;

procedure TDraftBST.ToListIn  (R: PDraft; L: TList);
begin
  if R=nil then Exit;
  ToListIn(R^.left, L);
  L.Add(R);
  ToListIn(R^.right, L);
end;

procedure TDraftBST.ToListPost(R: PDraft; L: TList);
begin
  if R=nil then Exit;
  ToListPost(R^.left, L);
  ToListPost(R^.right, L);
  L.Add(R);
end;

function TDraftBST.CountNode(R: PDraft): Integer;
begin
  if R=nil then Exit(0);
  Result := 1 + CountNode(R^.left) + CountNode(R^.right);
end;

function TDraftBST.Count: Integer;
begin
  Result := CountNode(FRoot);
end;

procedure TDraftBST.ListPre (L: TList);  begin L.Clear; ToListPre (FRoot, L) end;
procedure TDraftBST.ListIn  (L: TList);  begin L.Clear; ToListIn  (FRoot, L) end;
procedure TDraftBST.ListPost(L: TList);  begin L.Clear; ToListPost(FRoot, L) end;

{ ===================== Helpers públicos ====================== }

function GetMailById(AId: LongInt): PCorreo;
var cur: PCorreo;
begin
  Result := nil;
  if GCorreos = nil then Exit;
  cur := GCorreos.First;
  while cur <> nil do
  begin
    if cur^.id = AId then Exit(cur);
    cur := cur^.next;
  end;
end;

{ ==================== Init / Final =========================== }

initialization
  GUsuarios  := TListaUsuarios.Create;
  GCorreos   := TListaCorreos.Create;
  GPapelera  := TTrashStack.Create;
  GScheduled := TScheduledQueue.Create;
  GContacts  := TContacts.Create;
  GFavorites := TFavorites.Create;
  GDrafts    := TDraftBST.Create;

finalization
  GUsuarios.Free;
  GCorreos.Free;
  GPapelera.Free;
  GScheduled.Free;
  GContacts.Free;
  GFavorites.Free;
  GDrafts.Free;
end.

