unit uLZWCompressor;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

function LZWCompress(const InputText: string): string;

implementation

function LZWCompress(const InputText: string): string;
var
  dict: TStringList;
  p, c, pc: string;
  code, i: Integer;
  output: TStringList;
begin
  if InputText = '' then Exit('');

  dict := TStringList.Create;
  output := TStringList.Create;
  try
    dict.Sorted := False;
    dict.Duplicates := dupIgnore;

    // Inicializar diccionario con todos los caracteres ASCII
    for i := 0 to 255 do
      dict.Add(Chr(i));

    p := InputText[1];
    for i := 2 to Length(InputText) do
    begin
      c := InputText[i];
      pc := p + c;
      if dict.IndexOf(pc) <> -1 then
        p := pc
      else
      begin
        output.Add(IntToStr(dict.IndexOf(p)));
        dict.Add(pc);
        p := c;
      end;
    end;

    // Último símbolo
    if p <> '' then
      output.Add(IntToStr(dict.IndexOf(p)));

    // Unir con espacios
    Result := output.Text.Replace(LineEnding, ' ');
  finally
    dict.Free;
    output.Free;
  end;
end;

end.

