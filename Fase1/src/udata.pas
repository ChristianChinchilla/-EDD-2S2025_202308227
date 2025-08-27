unit uData;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, uListaUsuarios, uListaCorreos;

var
  GUsuarios : TListaUsuarios;
  GCorreos  : TListaCorreos;

// Validación mínima de “contacto”:
// 1) El destinatario debe existir como usuario
// 2) (Opcional) No permitir enviarse a sí mismo
function EsContacto(const OwnerEmail, DestEmail: string): Boolean;

implementation

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

finalization
  GUsuarios.Free;
  GCorreos.Free;

end.

