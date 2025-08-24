unit uListaCorreos;

{$mode objfpc}{$H+}

interface
uses Classes, SysUtils, fpjson, jsonparser, Process;

type
  PCorreo = ^TCorreo;
  TCorreo = record
    id: LongInt;
    remitente, estado, programado, asunto, fecha, mensaje: String;
    prev, next: PCorreo;
  end;

  TListaCorreos = class
  private
    FHead, FTail: PCorreo;
    FCount: SizeInt;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure PushBack(id:LongInt; const remitente, estado, programado, asunto, fecha, mensaje:String);
    function  Count: SizeInt;
    procedure CargarDesdeJSON(const Ruta:String; UsuarioId: LongInt);
    procedure GraficarDOT(const RutaDOT, RutaPNG, Titulo:String);
  end;

implementation

constructor TListaCorreos.Create;
begin FHead:=nil; FTail:=nil; FCount:=0; end;

destructor TListaCorreos.Destroy;
begin Clear; inherited Destroy; end;

procedure TListaCorreos.Clear;
var p,t: PCorreo;
begin
  p:=FHead;
  while p<>nil do begin t:=p^.next; Dispose(p); p:=t; end;
  FHead:=nil; FTail:=nil; FCount:=0;
end;

procedure TListaCorreos.PushBack(id:LongInt; const remitente, estado, programado, asunto, fecha, mensaje:String);
var n:PCorreo;
begin
  New(n);
  n^.id:=id; n^.remitente:=remitente; n^.estado:=estado;
  n^.programado:=programado; n^.asunto:=asunto; n^.fecha:=fecha; n^.mensaje:=mensaje;
  n^.prev:=FTail; n^.next:=nil;
  if FHead=nil then FHead:=n else FTail^.next:=n;
  FTail:=n; Inc(FCount);
end;

function TListaCorreos.Count: SizeInt; begin Result:=FCount end;

//JSON
procedure TListaCorreos.CargarDesdeJSON(const Ruta:String; UsuarioId: LongInt);
var j:TJSONData; arr, inbox:TJSONArray; i,k:Integer; s:TStringStream; o,oMail:TJSONObject;
begin
  s:=TStringStream.Create('');
  try
    s.LoadFromFile(Ruta);
    j:=GetJSON(s.DataString);
    arr:=(j as TJSONObject).Arrays['correos'];
    for i:=0 to arr.Count-1 do begin
      o:=arr.Objects[i];
      if o.Integers['usuario_id']=UsuarioId then begin
        inbox:=o.Arrays['bandeja_entrada'];
        for k:=0 to inbox.Count-1 do begin
          oMail:=inbox.Objects[k];
          PushBack(
            oMail.Integers['id'],
            oMail.Strings['remitente'],
            oMail.Strings['estado'],
            oMail.Strings['programado'],
            oMail.Strings['asunto'],
            oMail.Strings['fecha'],
            oMail.Strings['mensaje']
          );
        end;
        exit;
      end;
    end;
  finally
    s.Free;
  end;
end;

procedure TListaCorreos.GraficarDOT(const RutaDOT, RutaPNG, Titulo:String);
var sl:TStringList; p:PCorreo; idx:Integer; outStr:String;
begin
  sl:=TStringList.Create;
  try
    sl.Add('digraph G { rankdir=LR; node [shape=record, style=filled, fillcolor=lightblue];');
    sl.Add(Format('labelloc="t"; label="%s";', [Titulo]));
    p:=FHead; idx:=0;
    while p<>nil do begin
      sl.Add(Format('n%d [label="Id:%d | %s | %s"];', [idx, p^.id, p^.asunto, p^.fecha]));
      if p^.next<>nil then sl.Add(Format('n%d -> n%d [dir=both];', [idx, idx+1]));
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
