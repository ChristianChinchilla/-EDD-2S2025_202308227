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

var
  GUsuarios  : TListaUsuarios;
  GCorreos   : TListaCorreos;
  GPapelera  : TTrashStack;
  GScheduled : TScheduledQueue;

function EsContacto(const OwnerEmail, DestEmail: string): Boolean;

implementation

{ TTrashStack }

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

{ TScheduledQueue }

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

function EsContacto(const OwnerEmail, DestEmail: string): Boolean;
begin
  Result := (GUsuarios <> nil) and (GUsuarios.FindByEmail(DestEmail) <> nil);
end;

initialization
  GUsuarios  := TListaUsuarios.Create;
  GCorreos   := TListaCorreos.Create;
  GPapelera  := TTrashStack.Create;
  GScheduled := TScheduledQueue.Create;

finalization
  GUsuarios.Free;
  GCorreos.Free;
  GPapelera.Free;
  GScheduled.Free;
end.

