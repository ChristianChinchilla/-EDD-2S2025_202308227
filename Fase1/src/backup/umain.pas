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

// IMPORTANTE: estas units en IMPLEMENTATION (no en interface)
uses
  uRootMenu,      // frmRootMenu (menú Root)
  uData,          // GUsuarios
  uListaUsuarios; // TryLogin / Count

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  // Nada por ahora
end;

procedure TForm1.btnIngresarClick(Sender: TObject);
const
  ROOT_EMAIL = 'root@edd.com';
  ROOT_PASS  = 'root123';
var
  P: PUsuario;
  E, PW: string;
begin
  E  := Trim(edtEmail.Text);
  PW := Trim(edtPass.Text);

  // 1) ROOT
  if (CompareText(E, ROOT_EMAIL) = 0) and (PW = ROOT_PASS) then
  begin
    ShowMessage('Bienvenido, ROOT');
    frmRootMenu.Show;
    Self.Hide;
    Exit;
  end;

  // 2) Usuarios estándar (tras Carga Masiva)
  if GUsuarios.Count = 0 then
  begin
    ShowMessage('No hay usuarios cargados. Usa "Carga Masiva" como ROOT antes de iniciar sesión.');
    Exit;
  end;

  P := GUsuarios.FindLogin(E, PW);
  if P <> nil then
  begin
    ShowMessage('Bienvenido, ' + P^.nombre);
    // TODO: aquí abrirás el menú de usuario estándar (nuevo formulario)
    // por ahora nos quedamos en el login hasta que lo construyamos
  end
  else
    ShowMessage('Credenciales inválidas');
end;

end.

