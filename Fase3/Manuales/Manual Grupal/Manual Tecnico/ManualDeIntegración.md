# 📘 Manual de Integración: `UndirectedGraph.pas`

## 🧩 Descripción general

El módulo **`UndirectedGraph`** implementa un grafo **no dirigido** que conecta usuarios entre sí.  
Cada nodo del grafo representa un **usuario**, y cada conexión (arista) representa una **relación o vínculo** entre ellos.

En otras palabras:  
> Este módulo permite crear una red de usuarios y visualizarla gráficamente usando Graphviz.

---

## ⚙️ Dependencias

Para funcionar correctamente, esta unidad utiliza:

- `User`: contiene la definición del tipo `PUser`, que debe incluir al menos un método `getEmail` para identificar usuarios.
- `Process`, `Forms`, `Dialogs`, `SysUtils`, etc.: necesarias para manejo de archivos, ejecución de comandos y ventanas emergentes.
- **Graphviz** (instalado en el sistema): para generar el archivo `.svg` con el grafo visual.

---

## 🏗️ Estructura general

```pascal
unit UndirectedGraph;

type
  TNodoGrafo = class
  private
    value: PUser;
    next: TNodoGrafo;
  public
    constructor Create(avalue: PUser);
  end;

  edge = record
    rootNode: TNodoGrafo;
    destinationNode: TNodoGrafo;
  end;

  Graph = class
  public
    root: TNodoGrafo;
    connectionCounter: integer;
    connections: array of edge;

    constructor Create;
    procedure CreateNode(value: PUser);
    procedure CreateConnection(rootNode, destinationNode: string);
    function SearchNode(value: string): TNodoGrafo;
    function CheckDuplicateConnection(rootNode, destinationNode: TNodoGrafo): boolean;
    procedure TraverseGraph;
    function GenDot: string;
  end;
```

---

## 🧠 Concepto básico

El grafo funciona como una lista enlazada de nodos (`TNodoGrafo`) donde cada nodo guarda un **usuario (PUser)**.  
Además, cada conexión (`edge`) enlaza dos nodos distintos, **simulando una relación bidireccional**.

Ejemplo mental:
```
juan@edd.com  —  maria@edd.com  —  pedro@edd.com
```

---

## 🔌 Integración con el módulo `User`

Cada nodo del grafo usa un puntero a un usuario (`PUser`).  
Esto significa que antes de crear nodos en el grafo, **ya deben existir los usuarios cargados en memoria**.

Ejemplo:
```pascal
var
  g: Graph;
  u1, u2: PUser;
begin
  g := Graph.Create;
  g.CreateNode(u1);
  g.CreateNode(u2);
  g.CreateConnection(u1^.getEmail, u2^.getEmail);
  g.TraverseGraph;
end;
```

> **Importante:** el método `getEmail` del usuario se usa como identificador único dentro del grafo.

---

## 🧩 Funciones principales

### 🧱 `CreateNode(value: PUser)`
Agrega un nuevo nodo al grafo con el usuario indicado.  
Evita duplicados verificando el correo (`getEmail`).

---

### 🔗 `CreateConnection(rootNode, destinationNode: string)`
Crea una conexión entre dos usuarios (nodos).  
Verifica que ambos existan y que la conexión no se repita.

---

### 🔍 `SearchNode(value: string)`
Busca un nodo dentro del grafo por el correo del usuario.  
Retorna el nodo si existe, o `nil` si no.

---

### 🔄 `TraverseGraph`
Imprime en consola todos los nodos y sus conexiones actuales.

Ejemplo de salida:
```
--- Nodos ---
Email: juan@edd.com
Email: maria@edd.com

--- Lista de adyacencia ---
Conexion: juan@edd.com -> maria@edd.com
Conexion: maria@edd.com -> juan@edd.com
```

---

### 🖼️ `GenDot`
Genera un archivo `.dot` y un `.svg` con la representación visual del grafo.  
El archivo se guarda automáticamente en la carpeta:

```
../Root-Reportes/
```

Y se abre en el visor predeterminado usando `xdg-open`.

> ⚠️ Requiere tener instalado **Graphviz** en el sistema.

---

## 💡 Recomendaciones

- Asegúrate de que todos los usuarios tengan un **email único**, ya que se usa como identificador.  
- Antes de generar el gráfico (`GenDot`), crea primero los nodos y conexiones.  
- Verifica que Graphviz esté instalado (usa `dot -V` en consola para comprobarlo).  
- Puedes ajustar el límite del arreglo `connections` (actualmente 100) según tus necesidades.

---

## ✅ Ejemplo completo

```pascal
var
  G: Graph;
  U1, U2: PUser;
begin
  // Crear usuarios (ejemplo)
  New(U1);
  New(U2);
  U1^.setEmail('juan@edd.com');
  U2^.setEmail('maria@edd.com');

  // Crear el grafo y conectarlos
  G := Graph.Create;
  G.CreateNode(U1);
  G.CreateNode(U2);
  G.CreateConnection('juan@edd.com', 'maria@edd.com');

  // Mostrar en consola
  G.TraverseGraph;

  // Generar gráfico visual
  G.GenDot;
end;
```

---

## 🧾 Resumen rápido

| Método | Descripción breve |
|--------|-------------------|
| `CreateNode` | Crea un nuevo nodo (usuario) |
| `CreateConnection` | Conecta dos nodos |
| `SearchNode` | Busca un usuario en el grafo |
| `TraverseGraph` | Muestra los nodos y conexiones |
| `GenDot` | Genera visualización SVG del grafo |

---

## 🧱 Autor e integración

Módulo desarrollado para integrarse con el sistema **EDDMail**, encargado de manejar las relaciones entre usuarios registrados.  
Permite generar visualizaciones gráficas de red de contactos, facilitando análisis y reportes visuales.

