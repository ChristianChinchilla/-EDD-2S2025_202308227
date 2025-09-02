unit uData;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, uListaUsuarios, uListaCorreos;

type
  // ====== PILA (Papelera) ======
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

  // ====== COLA (Correos programados) ======
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
    procedure Clear;              // no libera los PCorreo
    procedure Enqueue(AMail: PCorreo);
    function  Dequeue: PCorreo;   // nil si vacío
    function  Peek: PCorreo;
    function  Count: SizeInt;
    function  Snapshot: TPCorreoArray;
  end;

  // ====== CONTACTOS POR USUARIO ======
  // Guardamos, para cada propietario (email), una lista de correos de contacto.
  TContacts = class
  private
    FOwners: TStringList; // FOwners[i] = owner; FOwners.Objects[i] = TStringList de contactos
    function IndexOfOwner(const Owner: string): Integer;
    function EnsureOwner(const Owner: string): TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure Add(const Owner, Email: string);           // agrega (ignora duplicados)
    function  Has(const Owner, Email: string): Boolean;  // ¿Owner tiene a Email?
    function  GetListCopy(const Owner: string): TStringList; // devuelve COPIA; el llamador debe Free
    function  Count(const Owner: string): Integer;
  end;

var
  GUsuarios  : TListaUsuarios;
  GCorreos   : TListaCorreos;
  GPapelera  : TTrashStack;
  GScheduled : TScheduledQueue;
  GContacts  : TContacts;

function EsContacto(const OwnerEmail, DestEmail: string): Boolean;

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
  L.Add(Email); // dupIgnore por estar Sorted+dupIgnore
end;

function TContacts.Has(const Owner, Email: string): Boolean;
var idx: Integer; L: TStringList;
begin
  idx := IndexOfOwner(Owner);
  if idx < 0 then Exit(False);
  L := TStringList(FOwners.Objects[idx]);
  Result := L.IndexOf(Email) >= 0;
end;

function TContacts.GetListCopy(const Owner: string): TStringList;
var idx: Integer; L: TStringList;
begin
  Result := TStringList.Create;
  idx := IndexOfOwner(Owner);
  if idx < 0 then Exit; // vacía
  L := TStringList(FOwners.Objects[idx]);
  Result.Assign(L); // copia para que el llamador pueda liberar
end;

function TContacts.Count(const Owner: string): Integer;
var idx: Integer; L: TStringList;
begin
  idx := IndexOfOwner(Owner);
  if idx < 0 then Exit(0);
  L := TStringList(FOwners.Objects[idx]);
  Result := L.Count;
end;

{ ======================= Helpers globales ==================== }

function EsContacto(const OwnerEmail, DestEmail: string): Boolean;
begin
  // Ahora verificamos contra la lista de contactos del usuario (OwnerEmail)
  Result := (GContacts <> nil) and GContacts.Has(OwnerEmail, DestEmail);
end;

{ ==================== Init / Final =========================== }

initialization
  GUsuarios  := TListaUsuarios.Create;
  GCorreos   := TListaCorreos.Create;
  GPapelera  := TTrashStack.Create;
  GScheduled := TScheduledQueue.Create;
  GContacts  := TContacts.Create;

finalization
  GUsuarios.Free;
  GCorreos.Free;
  GPapelera.Free;
  GScheduled.Free;
  GContacts.Free;
end.

