unit uListaUsuarios;

{$mode objfpc}{$H+}

interface
uses Classes, SysUtils, fpjson, jsonparser, Process;

type
  PUsuario = ^TUsuario;
  TUsuario = record
    id: LongInt;
    nombre, usuario, password, email, telefono: String;
    next: PUsuario;
  end;

  TListaUsuarios = class
  private
    FHead, FTail: PUsuario;
    FCount: SizeInt;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure PushBack(id:LongInt; const nombre, usuario, password, email, telefono:String);
    function  FindById(AId: LongInt): PUsuario;
    function  Count: SizeInt;
    procedure CargarDesdeJSON(const Ruta:String);
    procedure GraficarDOT(const RutaDOT, RutaPNG:String);
  end;

implementation

constructor TListaUsuarios.Create;
begin FHead:=nil; FTail:=nil; FCount:=0; end;

destructor TListaUsuarios.Destroy;
begin Clear; inherited Destroy; end;

procedure TListaUsuarios.Clear;
var p,t: PUsuario;
begin
  p:=FHead;
  while p<>nil do begin t:=p^.next; Dispose(p); p:=t; end;
  FHead:=nil; FTail:=nil; FCount:=0;
end;

procedure TListaUsuarios.PushBack(id:LongInt; const nombre, usuario, password, email, telefono:String);
var n:PUsuario;
begin
  New(n);
  n^.id:=id; n^.nombre:=nombre; n^.usuario:=usuario;
  n^.password:=password; n^.email:=email; n^.telefono:=telefono;
  n^.next:=nil;
  if FHead=nil then begin FHead:=n; FTail:=n end
  else begin FTail^.next:=n; FTail:=n end;
  Inc(FCount);
end;

function TListaUsuarios.FindById(AId: LongInt): PUsuario;
var p:PUsuario;
begin
  p:=FHead;
  while p<>nil do begin
    if p^.id=AId then exit(p);
    p:=p^.next;
  end;
  Result:=nil;
end;

function TListaUsuarios.Count: SizeInt; begin Result:=FCount end;

procedure TListaUsuarios.CargarDesdeJSON(const Ruta:String);
var j:TJSONData; arr:TJSONArray; i:Integer; s:TStringStream;
begin
  s:=TStringStream.Create('');
  try
    s.LoadFromFile(Ruta);
    j:=GetJSON(s.DataString);
    arr:=(j as TJSONObject).Arrays['usuarios'];
    for i:=0 to arr.Count-1 do
      with arr.Objects[i] do
        PushBack(Integers['id'], Strings['nombre'], Strings['usuario'],
                 Strings['password'], Strings['email'], Strings['telefono']);
  finally
    s.Free;
  end;
end;

procedure TListaUsuarios.GraficarDOT(const RutaDOT, RutaPNG:String);
var sl:TStringList; p:PUsuario; idx:Integer; outStr:String;
begin
  sl:=TStringList.Create;
  try
    sl.Add('digraph G { rankdir=LR; node [shape=record, style=filled, fillcolor=lightgray];');
    p:=FHead; idx:=0;
    while p<>nil do begin
      sl.Add(Format('n%d [label="Id:%d | %s | %s | %s"];',
        [idx, p^.id, p^.usuario, p^.email, p^.telefono]));
      if p^.next<>nil then sl.Add(Format('n%d -> n%d;', [idx, idx+1]));
      Inc(idx); p:=p^.next;
    end;
    sl.Add('}');
    sl.SaveToFile(RutaDOT);
  finally
    sl.Free;
  end;
  RunCommand('dot', ['-Tpng', RutaDOT, '-o', RutaPNG], outStr);
end;

end.

