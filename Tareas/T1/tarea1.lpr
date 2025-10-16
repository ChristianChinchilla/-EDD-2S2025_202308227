program tarea1;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  uListaUsuarios, uListaCorreos;

function BaseDir: string;
begin
  Result := ExtractFileDir(ParamStr(0)); // carpeta donde queda el ejecutable (src)
end;

function Join(const A,B:string):string;
begin
  if (A<>'') and (A[Length(A)]<>DirectorySeparator) then
    Result := A + DirectorySeparator + B
  else
    Result := A + B;
end;

var
  usuarios: TListaUsuarios;
  corrU1, corrU2: TListaCorreos;
  srcDir, imgsDir, dotDir: string;

  function TituloUsuario(id: LongInt): string;
  var p: PUsuario;
  begin
    p := usuarios.FindById(id);
    if p<>nil then
      Result := Format('Correos de %s (%s)', [p^.nombre, p^.email])
    else
      Result := Format('Correos de usuario id=%d', [id]);
  end;

begin
  srcDir  := BaseDir;                         // .../Tareas/Tarea1/src
  imgsDir := ExpandFileName(Join(srcDir, '../imgs'));
  dotDir  := imgsDir;

  usuarios := TListaUsuarios.Create;
  corrU1   := TListaCorreos.Create;
  corrU2   := TListaCorreos.Create;
  try
    usuarios.CargarDesdeJSON(Join(srcDir,'usuarios.json'));
    usuarios.GraficarDOT(Join(dotDir,'usuarios.dot'), Join(imgsDir,'usuarios.png'));

    // Graficar correos de 2 usuarios (id 1 y 2 según tu JSON)
    corrU1.CargarDesdeJSON(Join(srcDir,'correos.json'), 1);
    corrU1.GraficarDOT(Join(dotDir,'correos_u1.dot'), Join(imgsDir,'correos_u1.png'), TituloUsuario(1));

    corrU2.CargarDesdeJSON(Join(srcDir,'correos.json'), 2);
    corrU2.GraficarDOT(Join(dotDir,'correos_u2.dot'), Join(imgsDir,'correos_u2.png'), TituloUsuario(2));

    WriteLn('Listo. Revisa las imágenes en: ', imgsDir);
  finally
    corrU2.Free; corrU1.Free; usuarios.Free;
  end;
end.
