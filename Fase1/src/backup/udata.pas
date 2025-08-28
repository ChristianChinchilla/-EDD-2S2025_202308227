unit uData;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, uListaUsuarios, uListaCorreos;

<<<<<<< HEAD
var
  GUsuarios : TListaUsuarios;
  GCorreos  : TListaCorreos;

// Validación de destinatario (provisional: existe en usuarios)
=======
type
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

var
  GUsuarios : TListaUsuarios;
  GCorreos  : TListaCorreos;
  GPapelera : TTrashStack;

// Validación provisional del destinatario
>>>>>>> e486c4b (actualizacion en el codigo de bandeja de entrada, interfaz y codigo de enviar correo, interfaz de programar correo, correcciones en papelera y codigo de progrgamar correo)
function EsContacto(const OwnerEmail, DestEmail: string): Boolean;

implementation

<<<<<<< HEAD
function EsContacto(const OwnerEmail, DestEmail: string): Boolean;
begin
  // TODO: reemplazar con la verificación real de la libreta de contactos del usuario OwnerEmail
  Result := GUsuarios.ExistsEmail(DestEmail);
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

function EsContacto(const OwnerEmail, DestEmail: string): Boolean;
begin
  // Usa FindByEmail para evitar depender de un método ExistsEmail
  Result := (GUsuarios <> nil) and (GUsuarios.FindByEmail(DestEmail) <> nil);
>>>>>>> e486c4b (actualizacion en el codigo de bandeja de entrada, interfaz y codigo de enviar correo, interfaz de programar correo, correcciones en papelera y codigo de progrgamar correo)
end;

initialization
  GUsuarios := TListaUsuarios.Create;
  GCorreos  := TListaCorreos.Create;
<<<<<<< HEAD
=======
  GPapelera := TTrashStack.Create;
>>>>>>> e486c4b (actualizacion en el codigo de bandeja de entrada, interfaz y codigo de enviar correo, interfaz de programar correo, correcciones en papelera y codigo de progrgamar correo)

finalization
  GUsuarios.Free;
  GCorreos.Free;
<<<<<<< HEAD
=======
  GPapelera.Free;
>>>>>>> e486c4b (actualizacion en el codigo de bandeja de entrada, interfaz y codigo de enviar correo, interfaz de programar correo, correcciones en papelera y codigo de progrgamar correo)

end.

