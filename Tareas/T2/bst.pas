unit bst;
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  TPerson = record
    Id: Integer;
    FirstName: string;
    LastName: string;
    Email: string;
  end;

  PNode = ^TNode;
  TNode = record
    Key: Integer;
    Data: TPerson;
    Left, Right: PNode;
  end;

procedure BST_Init(out Root: PNode);
procedure BST_Clear(var Root: PNode);
procedure BST_Insert(var Root: PNode; const P: TPerson);
function  BST_Search(Root: PNode; Key: Integer): PNode;

procedure BST_InOrder(Root: PNode; SL: TStrings);
procedure BST_PreOrder(Root: PNode; SL: TStrings);
procedure BST_PostOrder(Root: PNode; SL: TStrings);

function  BST_GenerateDOT(Root: PNode): string;

implementation

procedure BST_Init(out Root: PNode);
begin
  Root := nil;
end;

procedure BST_ClearNode(var N: PNode);
begin
  if N = nil then Exit;
  BST_ClearNode(N^.Left);
  BST_ClearNode(N^.Right);
  Dispose(N);
  N := nil;
end;

procedure BST_Clear(var Root: PNode);
begin
  BST_ClearNode(Root);
end;

procedure BST_Insert(var Root: PNode; const P: TPerson);
var
  Cur, Prev, NewNode: PNode;
begin
  if Root = nil then
  begin
    New(NewNode);
    NewNode^.Key := P.Id;
    NewNode^.Data := P;
    NewNode^.Left := nil;
    NewNode^.Right := nil;
    Root := NewNode;
    Exit;
  end;

  Cur := Root;
  Prev := nil;
  while Cur <> nil do
  begin
    Prev := Cur;
    if P.Id < Cur^.Key then
      Cur := Cur^.Left
    else if P.Id > Cur^.Key then
      Cur := Cur^.Right
    else
    begin

      Cur^.Data := P;
      Exit;
    end;
  end;

  New(NewNode);
  NewNode^.Key := P.Id;
  NewNode^.Data := P;
  NewNode^.Left := nil;
  NewNode^.Right := nil;

  if P.Id < Prev^.Key then Prev^.Left := NewNode
                      else Prev^.Right := NewNode;
end;

function BST_Search(Root: PNode; Key: Integer): PNode;
begin
  Result := Root;
  while Result <> nil do
  begin
    if Key < Result^.Key then
      Result := Result^.Left
    else if Key > Result^.Key then
      Result := Result^.Right
    else
      Exit;
  end;
end;

procedure BST_InOrder(Root: PNode; SL: TStrings);
begin
  if Root = nil then Exit;
  BST_InOrder(Root^.Left, SL);
  SL.Add(Format('(%d) %s %s <%s>',
          [Root^.Data.Id, Root^.Data.FirstName, Root^.Data.LastName, Root^.Data.Email]));
  BST_InOrder(Root^.Right, SL);
end;

procedure BST_PreOrder(Root: PNode; SL: TStrings);
begin
  if Root = nil then Exit;
  SL.Add(Format('(%d) %s %s <%s>',
          [Root^.Data.Id, Root^.Data.FirstName, Root^.Data.LastName, Root^.Data.Email]));
  BST_PreOrder(Root^.Left, SL);
  BST_PreOrder(Root^.Right, SL);
end;

procedure BST_PostOrder(Root: PNode; SL: TStrings);
begin
  if Root = nil then Exit;
  BST_PostOrder(Root^.Left, SL);
  BST_PostOrder(Root^.Right, SL);
  SL.Add(Format('(%d) %s %s <%s>',
          [Root^.Data.Id, Root^.Data.FirstName, Root^.Data.LastName, Root^.Data.Email]));
end;



procedure DOT_AddNodes(Root: PNode; SL: TStrings);
begin
  if Root = nil then Exit;
  SL.Add(Format('  n%d [label="{%d|%s %s|%s}"];',
        [Root^.Key, Root^.Data.Id, Root^.Data.FirstName, Root^.Data.LastName, Root^.Data.Email]));
  DOT_AddNodes(Root^.Left, SL);
  DOT_AddNodes(Root^.Right, SL);
end;

procedure DOT_AddEdges(Root: PNode; SL: TStrings);
begin
  if Root = nil then Exit;
  if Root^.Left <> nil then
    SL.Add(Format('  n%d -> n%d [label="L"];', [Root^.Key, Root^.Left^.Key]));
  if Root^.Right <> nil then
    SL.Add(Format('  n%d -> n%d [label="R"];', [Root^.Key, Root^.Right^.Key]));
  DOT_AddEdges(Root^.Left, SL);
  DOT_AddEdges(Root^.Right, SL);
end;

function BST_GenerateDOT(Root: PNode): string;
var
  SL: TStringList;
begin
  SL := TStringList.Create;
  try
    SL.Add('digraph BST {');
    SL.Add('  node [shape=record, fontsize=10];');
    SL.Add('  rankdir=TB;');
    DOT_AddNodes(Root, SL);
    DOT_AddEdges(Root, SL);
    SL.Add('}');
    Result := SL.Text;
  finally
    SL.Free;
  end;
end;

end.

