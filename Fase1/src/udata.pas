unit uData;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, uListaUsuarios, uListaCorreos;

<<<<<<< HEAD
var
  GUsuarios : TListaUsuarios;
  GCorreos  : TListaCorreos;

// Validación mínima de “contacto”:
// 1) El destinatario debe existir como usuario
// 2) (Opcional) No permitir enviarse a sí mismo
=======
type
  // ====== PILA (Papelera) =====================================================

  // Nodo para la pila de papelera (punteros)
  PTrashNode = ^TTrashNode;
  TTrashNode = record
    Mail : PCorreo;     // correo eliminado (puntero)
    Next : PTrashNode;  // siguiente nodo en la pila
  end;

  // Arreglo de punteros a correos (para snapshots)
  TPCorreoArray = array of PCorreo;

  // Pila LIFO para la papelera
  TTrashStack = class
  private
    FTop   : PTrashNode;
    FCount : SizeInt;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear;
    procedure Push(AMail: PCorreo);   // apila el puntero
    function  Pop: PCorreo;           // desapila y devuelve el puntero
    function  Peek: PCorreo;          // mira el tope sin desapilar
    function  Count: SizeInt;

    // “Foto” de la pila de arriba hacia abajo (sin exponer campos privados)
    function  Snapshot: TPCorreoArray;
  end;

  // ====== COLA (Correos programados) =========================================

  PSchedNode = ^TSchedNode;
  TSchedNode = record
    Mail: PCorreo;
    Next: PSchedNode;
  end;

  // Cola FIFO para correos programados (almacena punteros PCorreo)
  TScheduledQueue = class
  private
    FHead, FTail: PSchedNode;
    FCount: SizeInt;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear;              // NO libera los PCorreo, solo nodos
    procedure Enqueue(AMail: PCorreo);
    function  Dequeue: PCorreo;   // nil si vacío
    function  Peek: PCorreo;      // sin quitar
    function  Count: SizeInt;

    function  Snapshot: TPCorreoArray; // para listados/depuración
  end;

var
  GUsuarios  : TListaUsuarios;
  GCorreos   : TListaCorreos;
  GPapelera  : TTrashStack;
  GScheduled : TScheduledQueue;   // <-- NUEVO: cola de programados

// Validación provisional del destinatario
>>>>>>> e486c4b (actualizacion en el codigo de bandeja de entrada, interfaz y codigo de enviar correo, interfaz de programar correo, correcciones en papelera y codigo de progrgamar correo)
function EsContacto(const OwnerEmail, DestEmail: string): Boolean;

implementation

<<<<<<< HEAD
function EsContacto(const OwnerEmail, DestEmail: string): Boolean;
begin
  // Si no quieres bloquear envío a uno mismo, elimina la primera condición.
  Result :=
    (CompareText(OwnerEmail, DestEmail) <> 0) and
    (GUsuarios.FindByEmail(DestEmail) <> nil);
end;

initialization
  GUsuarios := TListaUsuarios.Create;
  GCorreos  := TListaCorreos.Create;
=======
{ TTrashStack }

constructor TTrashStack.Create;
begin
  inherited Create;
  FTop := nil;
  FCount := 0;
end;

destructor TTrashStack.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TTrashStack.Clear;
var
  n, nx: PTrashNode;
begin
  n := FTop;
  while n <> nil do
  begin
    nx := n^.Next;
    Dispose(n);
    n := nx;
  end;
  FTop := nil;
  FCount := 0;
end;

procedure TTrashStack.Push(AMail: PCorreo);
var
  n: PTrashNode;
begin
  New(n);
  n^.Mail := AMail;
  n^.Next := FTop;
  FTop := n;
  Inc(FCount);
end;

function TTrashStack.Pop: PCorreo;
var
  n: PTrashNode;
begin
  if FTop = nil then Exit(nil);
  n := FTop;
  FTop := n^.Next;
  Result := n^.Mail;
  Dispose(n);
  Dec(FCount);
end;

function TTrashStack.Peek: PCorreo;
begin
  if FTop <> nil then
    Result := FTop^.Mail
  else
    Result := nil;
end;

function TTrashStack.Count: SizeInt;
begin
  Result := FCount;
end;

function TTrashStack.Snapshot: TPCorreoArray;
var
  node: PTrashNode;
  i: SizeInt;
begin
  SetLength(Result, FCount);
  node := FTop;
  i := 0;
  while node <> nil do
  begin
    Result[i] := node^.Mail;
    Inc(i);
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
var
  n, nx: PSchedNode;
begin
  n := FHead;
  while n <> nil do
  begin
    nx := n^.Next;
    // ¡OJO! No liberamos n^.Mail aquí; lo hará quien despache/elimine el correo
    Dispose(n);
    n := nx;
  end;
  FHead := nil; FTail := nil; FCount := 0;
end;

procedure TScheduledQueue.Enqueue(AMail: PCorreo);
var
  n: PSchedNode;
begin
  New(n);
  n^.Mail := AMail;
  n^.Next := nil;
  if FTail <> nil then
    FTail^.Next := n
  else
    FHead := n;
  FTail := n;
  Inc(FCount);
end;

function TScheduledQueue.Dequeue: PCorreo;
var
  n: PSchedNode;
begin
  if FHead = nil then Exit(nil);
  n := FHead;
  FHead := n^.Next;
  if FHead = nil then FTail := nil;
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
var
  n: PSchedNode;
  i: SizeInt;
begin
  SetLength(Result, FCount);
  n := FHead; i := 0;
  while n <> nil do
  begin
    Result[i] := n^.Mail;
    Inc(i);
    n := n^.Next;
  end;
end;

function EsContacto(const OwnerEmail, DestEmail: string): Boolean;
begin
  // Usa FindByEmail para evitar depender de un método ExistsEmail
  Result := (GUsuarios <> nil) and (GUsuarios.FindByEmail(DestEmail) <> nil);
end;

initialization
  GUsuarios  := TListaUsuarios.Create;
  GCorreos   := TListaCorreos.Create;
  GPapelera  := TTrashStack.Create;
  GScheduled := TScheduledQueue.Create;  // <-- NUEVO
>>>>>>> e486c4b (actualizacion en el codigo de bandeja de entrada, interfaz y codigo de enviar correo, interfaz de programar correo, correcciones en papelera y codigo de progrgamar correo)

finalization
  GUsuarios.Free;
  GCorreos.Free;
<<<<<<< HEAD
=======
  GPapelera.Free;
  GScheduled.Free;                       // <-- NUEVO
>>>>>>> e486c4b (actualizacion en el codigo de bandeja de entrada, interfaz y codigo de enviar correo, interfaz de programar correo, correcciones en papelera y codigo de progrgamar correo)

end.

