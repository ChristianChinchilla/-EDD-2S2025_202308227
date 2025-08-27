unit uData;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, uListaUsuarios, uListaCorreos;

var
  GUsuarios : TListaUsuarios;
  GCorreos  : TListaCorreos;

// Validación de destinatario (provisional: existe en usuarios)
function EsContacto(const OwnerEmail, DestEmail: string): Boolean;

implementation

function EsContacto(const OwnerEmail, DestEmail: string): Boolean;
begin
  // TODO: reemplazar con la verificación real de la libreta de contactos del usuario OwnerEmail
  Result := GUsuarios.ExistsEmail(DestEmail);
end;

initialization
  GUsuarios := TListaUsuarios.Create;
  GCorreos  := TListaCorreos.Create;

finalization
  GUsuarios.Free;
  GCorreos.Free;

end.

