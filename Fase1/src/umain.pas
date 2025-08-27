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
  uListaUsuarios, // manejo de usuarios
  uUserMenu;      // frmUserMenu, SetUser

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
  email, pass: string;
begin
  email := Trim(edtEmail.Text);
  pass  := Trim(edtPass.Text);

  // ROOT primero
  if (SameText(email, ROOT_EMAIL)) and (pass = ROOT_PASS) then
  begin
    ShowMessage('Bienvenido administrador');
    frmRootMenu.Show;
    Self.Hide;
    Exit;
  end;

  // Usuarios estándar (cargados desde JSON)
  P := GUsuarios.FindLogin(email, pass);
  if P <> nil then
  begin
    ShowMessage('Bienvenido, ' + P^.nombre);

    // Crear formulario de menú si no existe
    if not Assigned(frmUserMenu) then
      Application.CreateForm(TfrmUserMenu, frmUserMenu);

    // Pasar datos al menú
    frmUserMenu.SetUser(P^.nombre, P^.email);

    // Mostrar menú estándar
    frmUserMenu.Show;

    // Ocultar login
    Self.Hide;
    Exit;
  end;

  ShowMessage('Credenciales inválidas');
end;

end.

