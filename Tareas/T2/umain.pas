unit uMain;
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Dialogs, StdCtrls, Process,
  fpjson, jsonparser, bst;

type
  TFormMain = class(TForm)
    btnLoadJson: TButton;
    btnGraph: TButton;
    dlgOpen: TOpenDialog;
    procedure btnLoadJsonClick(Sender: TObject);
    procedure btnGraphClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    FRoot: PNode;
    FJsonPath: string;
    FOutDir: string;
    function  LoadPeopleFromJSON(const FileName: string; out Count: Integer): Boolean;
    function  SaveDOTAndPNG(const DotText, DotPath, PngPath: string): Boolean;
    function  GetProjectRootFromExe: string;
  public
  end;

var
  FormMain: TFormMain;

implementation
{$R *.lfm}

procedure TFormMain.FormCreate(Sender: TObject);
begin
  Caption := 'T2 - BST desde JSON (mínimo 2 botones)';
  BST_Init(FRoot);


  FOutDir := GetProjectRootFromExe;
  if not DirectoryExists(FOutDir) then
    if not CreateDir(FOutDir) then
      raise Exception.Create('No se pudo crear carpeta: ' + FOutDir);
end;

procedure TFormMain.btnLoadJsonClick(Sender: TObject);
var
  n: Integer;
begin
  dlgOpen.Filter := 'JSON (*.json)|*.json|Todos (*.*)|*.*';
  if not dlgOpen.Execute then Exit;

  FJsonPath := dlgOpen.FileName;

  BST_Clear(FRoot);
  BST_Init(FRoot);

  if LoadPeopleFromJSON(FJsonPath, n) then
    MessageDlg(Format('JSON cargado. %d elementos insertados en el BST.', [n]),
               mtInformation, [mbOK], 0)
  else
    MessageDlg('Error al leer el JSON (debe ser un arreglo de objetos).',
               mtError, [mbOK], 0);
end;

procedure TFormMain.btnGraphClick(Sender: TObject);
var
  dotText, dotPath, pngPath: string;
begin
  if FRoot = nil then
  begin
    MessageDlg('Primero carga el JSON para construir el árbol.',
               mtWarning, [mbOK], 0);
    Exit;
  end;

  dotText := BST_GenerateDOT(FRoot);
  dotPath := FOutDir + 'tree.dot';
  pngPath := FOutDir + 'tree.png';

  if SaveDOTAndPNG(dotText, dotPath, pngPath) then
    MessageDlg('Gráfica generada en: ' + pngPath, mtInformation, [mbOK], 0)
  else
    MessageDlg('No se pudo generar la imagen. Verifica que Graphviz (dot) esté en el PATH.' + LineEnding +
               'Se guardó el DOT en: ' + dotPath, mtError, [mbOK], 0);
end;

function TFormMain.LoadPeopleFromJSON(const FileName: string; out Count: Integer): Boolean;
var
  JSON: TJSONData;
  Arr: TJSONArray;
  i: Integer;
  P: TPerson;
  Parser: TJSONParser;
  FS: TFileStream;
begin
  Result := False;
  Count := 0;

  if not FileExists(FileName) then Exit;

  FS := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    Parser := TJSONParser.Create(FS);
    try
      JSON := Parser.Parse;
    finally
      Parser.Free;
    end;
  finally
    FS.Free;
  end;
    try
    if JSON.JSONType <> jtArray then Exit;
    Arr := TJSONArray(JSON);

    for i := 0 to Arr.Count - 1 do
    begin
      if Arr.Items[i].JSONType <> jtObject then Continue;
      P.Id        := Arr.Objects[i].Get('id', 0);
      P.FirstName := Arr.Objects[i].Get('first_name', '');
      P.LastName  := Arr.Objects[i].Get('last_name', '');
      P.Email     := Arr.Objects[i].Get('email', '');
      BST_Insert(FRoot, P);
      Inc(Count);
    end;

    Result := True;
  finally
    JSON.Free;
  end;
end;

function TFormMain.SaveDOTAndPNG(const DotText, DotPath, PngPath: string): Boolean;
var
  SL: TStringList;
  Proc: TProcess;
begin
  Result := False;

  SL := TStringList.Create;
  try
    SL.Text := DotText;
    SL.SaveToFile(DotPath);
  finally
    SL.Free;
  end;

  Proc := TProcess.Create(nil);
  try
    Proc.Executable := 'dot';
    Proc.Parameters.Add('-Tpng');
    Proc.Parameters.Add(DotPath);
    Proc.Parameters.Add('-o');
    Proc.Parameters.Add(PngPath);
    Proc.Options := [poNoConsole, poWaitOnExit];
    try
      Proc.Execute;
    except
    end;
  finally
    Proc.Free;
  end;

  Result := FileExists(PngPath);
end;

function TFormMain.GetProjectRootFromExe: string;
var
  exeDir: string;
  libPos: SizeInt;
begin
  exeDir := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
  libPos := Pos(DirectorySeparator + 'lib' + DirectorySeparator, exeDir);
  if libPos > 0 then
    Result := IncludeTrailingPathDelimiter(ExtractFileDir(ExtractFileDir(exeDir))) // …/T2/
  else
    Result := exeDir;
end;

end.

