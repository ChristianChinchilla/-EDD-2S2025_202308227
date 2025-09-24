program test;

{$mode ObjFPC}{$H+}


uses
    Classes, SysUtils, ListaDeListas;

var
    list: PListaDeListas;

begin
    //probar los métodos aquí:
    New(list);
    list^ := TListaDeListas.Create;
    writeln('Una inserción');
    list^.Append('España');
    list^.Print;
    list^.Append('Guatemala');
    list^.Append('Villa Nueva');
    writeln('Tres Inserciones');
    list^.Print;

    writeln('Fallo al insertar repetido');
    list^.Append('Guatemala');
    list^.Append('España');

    writeln('--- Pruebas de agregar usuario ---');
    // Caso exitoso: comunidad existe, usuario no existe
    if list^.AgregarUsuarioAComunidad('España', 'Christian') then
        writeln('Éxito: Christian agregado a España')
    else
        writeln('Error: no se pudo agregar Christian a España');

    // Caso error: usuario ya existe
    if list^.AgregarUsuarioAComunidad('España', 'Christian') then
        writeln('Éxito: Christian agregado a España')
    else
        writeln('Error: no se pudo agregar Christian a España');

    // Caso exitoso: comunidad existe, usuario no existe
    if list^.AgregarUsuarioAComunidad('Guatemala', 'David') then
        writeln('Éxito: David agregado a Guatemala')
    else
        writeln('Error: no se pudo agregar David a Guatemala');

    // Caso error: comunidad no existe
    if list^.AgregarUsuarioAComunidad('NoExiste', 'Carlos') then
        writeln('Éxito: Carlos agregado a NoExiste')
    else
        writeln('Error: no se pudo agregar Carlos a NoExiste');

    //mas casos exitosos:
    list^.AgregarUsuarioAComunidad('Guatemala', 'Fernando');
    list^.AgregarUsuarioAComunidad('Guatemala', 'Pedro');
    list^.AgregarUsuarioAComunidad('Guatemala', 'Esteban');

    list^.AgregarUsuarioAComunidad('España', 'Esteban');
    list^.AgregarUsuarioAComunidad('España', 'Sabato');
    list^.AgregarUsuarioAComunidad('España', 'Juan');

    // Imprimir estructura para verificar
    writeln('--- Estructura actual ---');
    list^.Print;

    //graficar
    list^.graph();
end.