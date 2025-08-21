unit uMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls;

type

  { TForm1 }

  TForm1 = class(TForm)
    btnIngresar: TButton;
    edtEmail: TEdit;
    edtPass: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    procedure btnIngresarClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private

  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin

end;

procedure TForm1.btnIngresarClick(Sender: TObject);
const
  ROOT_EMAIL = 'root@edd.com';
  ROOT_PASS  = 'root123';
begin
  if (edtEmail.Text = ROOT_EMAIL) and (edtPass.Text = ROOT_PASS) then
    ShowMessage('Login ROOT OK')
  else
    ShowMessage('Credenciales inválidas');
end;

end.

