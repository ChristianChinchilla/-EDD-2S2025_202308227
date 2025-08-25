unit uData;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, uListaUsuarios, uListaCorreos;

var
  GUsuarios : TListaUsuarios;
  GCorreos  : TListaCorreos;

implementation

initialization
  GUsuarios := TListaUsuarios.Create;
  GCorreos  := TListaCorreos.Create;

finalization
  GUsuarios.Free;
  GCorreos.Free;

end.

