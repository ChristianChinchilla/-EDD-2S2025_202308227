
# 📘 Manual Simplificado — `BST_Comunidades` (Markdown dentro de .txt)

**Resumen rápido**
`BST_Comunidades` es un módulo Pascal que implementa:
- Un árbol binario de búsqueda (TBSTree) de **Comunidades** (nodos TBSTNode).
- Cada comunidad tiene una lista enlazada de mensajes (TListaMensajes).
- Permite crear comunidades, buscar, insertar mensajes, convertir a arreglo y generar un reporte DOT/SVG con Graphviz.

---

## 🧩 API principal (qué usar)
### Clases y métodos relevantes
- **TMensajeComunidad**
  - `Create(_Autor, _Mensaje, _Fecha: TDateTime)` — constructor.
  - Propiedades: `GetAutor`, `GetMensaje`, `GetFecha`.

- **TListaMensajes**
  - `Create()` — crea la lista vacía.
  - `AddMensaje(Mensaje: TMensajeComunidad)` — añade al final.
  - `GetMensajes(): TArrayOfMensajes` — devuelve array de mensajes.
  - `IsEmpty(): Boolean`
  - `GetSize(): Integer`

- **TBSTNode**
  - `Create()` — constructor.
  - `GetInfo(): String` — devuelve el nombre de la comunidad.
  - `GetMensajes(): TArrayOfMensajes` — devuelve los mensajes de la comunidad.

- **TBSTree**
  - `Create()` — constructor.
  - `CrearComunidad(NombreComunidad: String)` — crea y ubica la comunidad en el BST (si no existe).
  - `Search(NombreComunidad: String): TBSTNode` — busca por nombre (case-insensitive).
  - `Insert(NombreComunidad: String; Mensaje: TMensajeComunidad)` — inserta mensaje en comunidad existente.
  - `ToArray(): TArrayOfBSTNodes` — obtiene array con nodos (pre-order).
  - `PrintPreOrder()` — imprime info de comunidades (con WriteLn).
  - `GenerarReporte(NombreArchivo: String = 'reporte_comunidades.dot')` — genera archivo DOT y usa `dot` para producir SVG.

---

## ✅ Uso básico (ejemplos rápidos)

```pascal
var
  Tree: TBSTree;
  Msg: TMensajeComunidad;
  Node: TBSTNode;
begin
  Tree := TBSTree.Create;

  // Crear comunidades
  Tree.CrearComunidad('Santa Ana');
  Tree.CrearComunidad('El Progreso');

  // Insertar mensaje
  Msg := TMensajeComunidad.Create('Carlos', 'Hola comunidad!', Now);
  Tree.Insert('Santa Ana', Msg);

  // Buscar y recorrer mensajes
  Node := Tree.Search('Santa Ana');
  if Node <> nil then
  begin
    // Obtener mensajes como array
    var arr := Node.GetMensajes();
    // arr[0].GetAutor, arr[0].GetMensaje, etc.
  end;

  // Imprimir árbol
  Tree.PrintPreOrder();

  // Generar reporte DOT + SVG (requiere Graphviz 'dot' en PATH)
  Tree.GenerarReporte('mis_comunidades.dot');
end;
```

---

## ⚠️ Consideraciones importantes
- **Comparación por nombre**: usa `AnsiCompareText` (case-insensitive). Asegúrate de `Trim` al usar nombres.
- **Insert**: si la comunidad no existe, `Insert` hace `Exit` (no crea la comunidad). Llama `CrearComunidad` antes si quieres crear automáticamente.
- **Liberación de memoria**: el unit no implementa destrucción completa de nodos/objetos. Si tu app crea muchas comunidades o mensajes, añade destructores para evitar leaks.
- **Graphviz**: `GenerarReporte` ejecuta el comando `dot`. Debes tener `dot` instalado y accesible desde la línea de comandos. Si no lo tienes, el .dot igualmente se escribe y puedes convertirlo manualmente.
- **Formato de fecha**: en el reporte se usa `FormatDateTime('dd/mm/yyyy', ...)`.

---


## 📎 Archivos generados
- `reporte_comunidades.dot` — archivo DOT (texto).
- `reporte_comunidades.svg` — generado si `dot` está presente.
