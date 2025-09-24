unit ListaDeListas;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Dialogs, Process;

type
  // list of users node definition
  PUsuarioNode = ^TUsuarioNode;
  TUsuarioNode = record
    usuario: String;
    siguiente: PUsuarioNode;
  end;

  // list of users definition
  PListaDeUsuarios = ^TListaDeUsuarios;
  TListaDeUsuarios = class
  private
    cabeza: PUsuarioNode;
    cola: PUsuarioNode;
  public
    constructor Create;
  end;

  // main list node definition
  PComunidadNode = ^TComunidadNode;
  TComunidadNode = record
    comunidad: String;
    siguiente: PComunidadNode;
    usuarios: PListaDeUsuarios; // list of users in the community
  end;

  // list of lists definition
  PListaDeListas = ^TListaDeListas;
  TListaDeListas = class
  private
    cabeza: PComunidadNode;
    cola: PComunidadNode;
  public
    constructor Create;
    //----------Christian-------------
    function Find(const AComunidad: String): PComunidadNode; //recorrer lista para buscar comunidad
    function Exists(const AComunidad: String): Boolean;      //verificar si ya existe
    function Append(const AComunidad: String): Boolean; //insertar al final si no existe
    procedure Print; // print all communities from head to tail

    
    function UsuarioExisteEnComunidad(const nombreComunidad, nombreUsuario: string): Boolean;
    function AgregarUsuarioAComunidad(const nombreComunidad, nombreUsuario: string): Boolean;

    procedure graph();

  end;

implementation

// TListaDeUsuarios methods
constructor TListaDeUsuarios.Create;
begin
  cabeza := nil;
  cola := nil;
end;

// TListaDeListas methods
constructor TListaDeListas.Create;
begin
  cabeza := nil;
  cola := nil;
end;

// --- FLUJO DE CREAR COMUNIDAD ---
//
// 1 -> LL.exists() retorna un booleano, comprueba si la comunidad existe, si no existe crearla
// 2 -> LL.append() inserción al final, además, inicializa su lista de usuarios

// --- FLUJO DE CREAR USUARIO ---
//
// 1 -> LL.exists() retorna un booleano, comprueba si la comunidad existe, si no existe retornar error
// 2 -> LU.exists() retorna un booleano, comprueba si el usuario ya existe en la comunidad, si no existe crearlo, si existe retornar error
// 3 -> LU.append() inserción al final del usuario

// ========================
// ===    CHRISTIAN     ===
// ========================

//recorre la lista principal y retorna el puntero a la comunidad si existe
function TListaDeListas.Find(const AComunidad: String): PComunidadNode;
var
  p: PComunidadNode;
begin
  Result := nil;
  p := cabeza;
  while p <> nil do
  begin
    if AnsiCompareText(p^.comunidad, AComunidad) = 0 then
      Exit(p); //encontrada
    p := p^.siguiente;
  end;
end;

//retorna true si la comunidad ya existe
function TListaDeListas.Exists(const AComunidad: String): Boolean;
begin
  Result := Find(AComunidad) <> nil;
end;

//inserta al final si no existe la comunidad
function TListaDeListas.Append(const AComunidad: String): Boolean;
var
  n: PComunidadNode;
begin
  Result := False;

  //validar nombre no vacio
  if Trim(AComunidad) = '' then
  begin
    MessageDlg('Error', 'El nombre de la comunidad está vacío.', mtError, [mbOK], 0);
    Exit(False);
  end;

  //1) Verificar existencia
  if Exists(AComunidad) then
  begin
    MessageDlg('Error', 'La comunidad "' + AComunidad + '" ya existe.', mtError, [mbOK], 0);
    Exit(False);
  end;

  //2) Crear nuevo nodo de comunidad
  New(n);
  n^.comunidad := AComunidad;
  n^.siguiente := nil;

  //inicializar lista de usuarios vacia para esta comunidad
  New(n^.usuarios);                         //reservar memoria para el puntero
  n^.usuarios^ := TListaDeUsuarios.Create;  //crear la instancia y guardarla

  //3) insertar al final usando tail
  if cabeza = nil then
  begin
    cabeza := n;
    cola := n;
  end
  else
  begin
    cola^.siguiente := n;
    cola := n;
  end;

  Result := True;
end;

procedure TListaDeListas.Print;
var
  p: PComunidadNode;
begin
  p := cabeza;
  while p <> nil do
  begin
    writeln('Comunidad: ', p^.comunidad);
    p := p^.siguiente;
  end;
end;


function TListaDeListas.UsuarioExisteEnComunidad(const nombreComunidad, nombreUsuario: string): Boolean;
var
  comunidadActual: PComunidadNode;
  usuarioActual: PUsuarioNode;
begin
  comunidadActual := Find(nombreComunidad);
  if comunidadActual = nil then
    Exit(False); // La comunidad no existe

  usuarioActual := comunidadActual^.usuarios^.cabeza;
  while usuarioActual <> nil do
  begin
    if usuarioActual^.usuario = nombreUsuario then
      Exit(True); // Usuario encontrado
    usuarioActual := usuarioActual^.siguiente;
  end;

  Exit(False); // Usuario no encontrado
end;

// Método para agregar usuario a una comunidad
function TListaDeListas.AgregarUsuarioAComunidad(const nombreComunidad, nombreUsuario: string): Boolean;
var
  comunidadActual: PComunidadNode;
  nuevoUsuario: PUsuarioNode;
begin
  comunidadActual := Find(nombreComunidad);
  if comunidadActual = nil then
  begin
    MessageDlg('Error', 'La comunidad no existe.', mtError, [mbOK], 0);
    Exit(False);
  end;

  if UsuarioExisteEnComunidad(nombreComunidad, nombreUsuario) then
  begin
    MessageDlg('Error', 'El usuario ya existe en la comunidad.', mtError, [mbOK], 0);
    Exit(False);
  end;

  // Crear el nuevo usuario
  New(nuevoUsuario);
  nuevoUsuario^.usuario := nombreUsuario;
  nuevoUsuario^.siguiente := nil;

  // Insertar al final de la lista de usuarios
  if comunidadActual^.usuarios^.cabeza = nil then
  begin
    comunidadActual^.usuarios^.cabeza := nuevoUsuario;
    comunidadActual^.usuarios^.cola := nuevoUsuario;
  end
  else
  begin
    comunidadActual^.usuarios^.cola^.siguiente := nuevoUsuario;
    comunidadActual^.usuarios^.cola := nuevoUsuario;
  end;

  writeln('Usuario agregado satisfactoriamente.');
  Exit(True);
end;

procedure TListaDeListas.graph();
var
    dotFile: TextFile;
    filePath: String;
    svgFilePath: String;
    AProcess: TProcess;
    basePath: String;
    currentComunidad: PComunidadNode;
    currentUsuario: PUsuarioNode;
    firstUserId, userNodeId: String;
    prevUserId, emptyNodeId: String;
    userIdx: Integer;
begin
    if Self.cabeza <> nil then
    begin
      basePath := './';    // Ensure the directory exists
      WriteLn('Base path: ', basePath);

      if not ForceDirectories(basePath) then
      begin
          //MessageDlg('Error', 'Could not create directory: ' + basePath, mtError, [mbOK], 0);
          Exit;
      end;

      filePath := basePath + 'lista_listas_comunidades.dot';
      svgFilePath := basePath + 'lista_listas_comunidades.svg';
      AssignFile(dotFile, filePath);
      Rewrite(dotFile);
      
      // beginning of dot file
      Writeln(dotFile, 'digraph Comunidades {');
      Writeln(dotFile, '    graph [splines=ortho];');
      Writeln(dotFile, '    rankdir=TB;');
      Writeln(dotFile, '    node [shape=record, style=filled, fillcolor=white];');
      Writeln(dotFile, '    label = "Lista de listas (Comunidades)";');

      // Agrupar comunidades en el mismo rank para alineación horizontal
      Writeln(dotFile, '    { rank = same;');
      currentComunidad := Self.cabeza;
      while currentComunidad <> nil do
      begin
          Writeln(dotFile, Format('        "%s";', [currentComunidad^.comunidad]));
          currentComunidad := currentComunidad^.siguiente;
      end;
      Writeln(dotFile, '    }');

      currentComunidad := Self.cabeza;
      while currentComunidad <> nil do
      begin
          // Nodo de la comunidad
          Writeln(dotFile, Format('    "%s" [label="{Comunidad: %s}"];', [currentComunidad^.comunidad, currentComunidad^.comunidad]));

          // Enlace a la siguiente comunidad (horizontal)
          if currentComunidad^.siguiente <> nil then
          begin
            Writeln(dotFile, Format('    "%s" -> "%s";', [currentComunidad^.comunidad, currentComunidad^.siguiente^.comunidad]));
          end;

          // Graficar lista de usuarios
          if (currentComunidad^.usuarios <> nil) and (currentComunidad^.usuarios^.cabeza <> nil) then
          begin
            currentUsuario := currentComunidad^.usuarios^.cabeza;
            firstUserId := '';
            prevUserId := '';
            userIdx := 0;
            // Crear nodos de usuario
            while currentUsuario <> nil do
            begin
              userNodeId := currentComunidad^.comunidad + '_usuario_' + IntToStr(userIdx);
              Writeln(dotFile, Format('    "%s" [label="Usuario: %s", shape=box, fillcolor=lightblue];', [userNodeId, currentUsuario^.usuario]));
              if userIdx = 0 then
                firstUserId := userNodeId;
              if prevUserId <> '' then
                Writeln(dotFile, Format('    "%s" -> "%s";', [prevUserId, userNodeId]));
              prevUserId := userNodeId;
              Inc(userIdx);
              currentUsuario := currentUsuario^.siguiente;
            end;
            // Conectar comunidad a la cabeza de usuarios con una arista hacia abajo
            Writeln(dotFile, Format('    "%s" -> "%s" [style=dashed, color=gray];', [currentComunidad^.comunidad, firstUserId]));
          end
          else
          begin
            // No hay usuarios
            emptyNodeId := currentComunidad^.comunidad + '_sin_usuarios';
            Writeln(dotFile, Format('    "%s" [label="Sin usuarios", shape=box, fillcolor=gray95, style=dashed];', [emptyNodeId]));
            Writeln(dotFile, Format('    "%s" -> "%s" [style=dashed, color=gray];', [currentComunidad^.comunidad, emptyNodeId]));
          end;

          currentComunidad := currentComunidad^.siguiente;
      end;
      Writeln(dotFile, '}');
      CloseFile(dotFile);

      AProcess := TProcess.Create(nil);
      try
          AProcess.CommandLine := 'dot -Tsvg ' + filePath + ' -o ' + svgFilePath;
          AProcess.Options := [poWaitOnExit];
          AProcess.Execute;
      finally
          AProcess.Free;
      end;

      // Open the generated SVG
      AProcess := TProcess.Create(nil);
      try
          AProcess.CommandLine := 'xdg-open ' + svgFilePath;
          AProcess.Options := [];
          AProcess.Execute;
      finally
          AProcess.Free;
      end;
    end
    else
    begin
      MessageDlg('Información', 'La lista está vacía.', mtInformation, [mbOK], 0);
      Exit;
    end;

end;

end.

