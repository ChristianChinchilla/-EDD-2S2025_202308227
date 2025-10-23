unit uMain;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, Dialogs;  // Dialogs por ShowMessage

type

  { TForm1 }

  TForm1 = class(TForm)
    btnIngresar: TButton;
    btnCrear: TButton;
    edtEmail: TEdit;
    edtPass: TEdit;
    lblTitulo: TLabel;
    lblCorreo: TLabel;
    lblPass: TLabel;
    procedure btnCrearClick(Sender: TObject);
    procedure btnIngresarClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    function EsRootLogin(const Email, Pass: string): Boolean;
    procedure IrMenuUsuario(const Nombre, Email: string);
    procedure IrMenuRoot;
  public
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

uses
  uData, uListaUsuarios, uUserMenu, uRootMenu,
  uLogControlForm; // <<--- AÑADIDO: para LogRegistrarEntrada/Salida

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  Caption := 'EDD Mail - Demo';
  lblTitulo.Caption := 'EDDMail - Login';
  lblCorreo.Caption := 'Correo';
  lblPass.Caption   := 'Contraseña';
  edtEmail.TextHint := 'usuario@edd.com';
  edtPass.PasswordChar := '*';

  // POR SI SE PIERDEN EVENTOS EN EL DISEÑADOR:
  btnIngresar.OnClick := @btnIngresarClick;
  btnCrear.OnClick    := @btnCrearClick;
end;

function TForm1.EsRootLogin(const Email, Pass: string): Boolean;
begin
  // Root: root@edd.com / root123
  Result := SameText(Trim(Email), 'root@edd.com') and (Trim(Pass) = 'root123');
end;

procedure TForm1.IrMenuRoot;
begin
  if not Assigned(frmRootMenu) then
    Application.CreateForm(TfrmRootMenu, frmRootMenu);
  frmRootMenu.Show;
  Hide;
end;

procedure TForm1.IrMenuUsuario(const Nombre, Email: string);
begin
  if not Assigned(frmUserMenu) then
    Application.CreateForm(TfrmUserMenu, frmUserMenu);
  frmUserMenu.SetUser(Nombre, Email);
  frmUserMenu.Show;
  Hide;
end;

procedure TForm1.btnIngresarClick(Sender: TObject);
var
  email, pass: string;
  P: PUsuario;
begin
  email := Trim(edtEmail.Text);
  pass  := Trim(edtPass.Text);

  if (email = '') or (pass = '') then
  begin
    ShowMessage('Ingresa correo y contraseña.');
    Exit;
  end;

  // ROOT
  if EsRootLogin(email, pass) then
  begin
    // ---- LOG ENTRADA ROOT ----
    LogRegistrarEntrada('root@edd.com', Now);
    IrMenuRoot;
    Exit;
  end;

  // Usuario normal: validamos que exista el correo
  P := GUsuarios.FindByEmail(email);
  if P = nil then
  begin
    ShowMessage('El usuario no existe. Puedes crearlo con "Crear Cuenta".');
    Exit;
  end;

  // (Si más adelante implementas password por usuario, valida aquí)
  // ---- LOG ENTRADA USUARIO ----
  LogRegistrarEntrada(P^.email, Now);

  IrMenuUsuario(P^.nombre, P^.email);
end;

procedure TForm1.btnCrearClick(Sender: TObject);
var
  email, pass, nombre: string;
  nuevo: PUsuario;
  maxId, nextId: LongInt;
begin
  email := Trim(edtEmail.Text);
  pass  := Trim(edtPass.Text);

  if (email = '') or (pass = '') then
  begin
    ShowMessage('Para crear cuenta, ingresa correo y contraseña.');
    Exit;
  end;

  // ----- Caso especial: crear ROOT -----
  if SameText(email, 'root@edd.com') then
  begin
    if pass <> 'root123' then
    begin
      ShowMessage('La contraseña del root debe ser "root123".');
      Exit;
    end;

    if GUsuarios.FindByEmail(email) <> nil then
    begin
      ShowMessage('El usuario root ya existe. Ingresando como root...');
      // ---- LOG ENTRADA ROOT ----
      LogRegistrarEntrada('root@edd.com', Now);
      IrMenuRoot;
      Exit;
    end;

    nextId := 1; // root = 1
    nuevo := GUsuarios.Add(nextId, 'Root', email);
    if nuevo = nil then
    begin
      ShowMessage('No se pudo crear el usuario root.');
      Exit;
    end;

    ShowMessage('Cuenta root creada. Ingresando...');
    // ---- LOG ENTRADA ROOT ----
    LogRegistrarEntrada('root@edd.com', Now);
    IrMenuRoot;
    Exit;
  end;
  // ----- Fin caso root -----

  // Usuarios normales
  if GUsuarios.FindByEmail(email) <> nil then
  begin
    ShowMessage('Ya existe un usuario con ese correo.');
    Exit;
  end;

  // Nombre por defecto: parte antes de @
  nombre := email;
  if Pos('@', email) > 1 then
    nombre := Copy(email, 1, Pos('@', email)-1);
  if nombre <> '' then
    nombre := UpperCase(Copy(nombre,1,1)) + Copy(nombre,2,Length(nombre));

  maxId := 1; // asume root=1
  nextId := maxId + 1;

  nuevo := GUsuarios.Add(nextId, nombre, email);
  if nuevo = nil then
  begin
    ShowMessage('No se pudo crear el usuario.');
    Exit;
  end;

  ShowMessage('Cuenta creada para: ' + nombre);

  // ---- LOG ENTRADA NUEVO USUARIO ----
  LogRegistrarEntrada(nuevo^.email, Now);

  IrMenuUsuario(nuevo^.nombre, nuevo^.email);
end;

end.

