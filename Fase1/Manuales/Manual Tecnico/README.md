# Manual Tecnico — EDDMail Fase 1
**Christian David Chinchilla Santos** - **202308227**

**Curso:** Estructuras de Datos (EDD)   

---

## 1. Resumen del sistema
Simulador de correo en Object Pascal/GTK que implementa listas/pila/cola/matriz dispersa, con usuario root (carga masiva y reportes) y usuarios estándar (bandeja, contactos, programados, papelera). Requisitos según enunciado del curso.

## 2. Arquitectura general
- **Frontend (GUI):** Lazarus/GTK, formularios `*form.pas`.
- **Dominio (modelos/servicios):** `udata.pas`, controladores de UI, generadores de reportes.
- **Estructuras de Datos:** lista simple (usuarios y comunidades), doble (correos), circular (contactos), cola (programados), pila (papelera), matriz dispersa (relaciones).
- **Persistencia:** JSON de usuarios, archivos DOT/PNG para reportes.

## 3. Estructuras de datos e interfaces
## 3.1 Módulo `uMain.pas` – Pantalla de inicio de sesión

Este módulo implementa la ventana inicial de **login/registro** de usuarios en EDDMail.

### Clases principales
- **`TForm1`**  
  Clase principal del formulario de inicio. Contiene controles para ingresar correo y contraseña, así como botones de **Ingresar** y **Crear cuenta**.

### Métodos relevantes
- `FormCreate`  
  Inicializa la ventana, define títulos, etiquetas y configura hints (ejemplo: placeholder del correo y máscara de contraseña).

- `EsRootLogin(const Email, Pass: string): Boolean`  
  Función auxiliar que valida si las credenciales ingresadas corresponden al **usuario root** (`root@edd.com` / `root123`).

- `IrMenuRoot`  
  Crea y muestra el menú root (`urootmenu.pas`) ocultando el login.

- `IrMenuUsuario(const Nombre, Email: string)`  
  Crea y muestra el menú de usuario (`uusermenu.pas`) y pasa el contexto del usuario autenticado.

- `btnIngresarClick`  
  Controlador del botón **Ingresar**.  
  Flujo:
  1. Verifica campos vacíos.  
  2. Valida root.  
  3. Busca al usuario en `GUsuarios`.  
  4. Si existe, abre su menú; si no, muestra mensaje.

- `btnCrearClick`  
  Controlador del botón **Crear cuenta**.  
  Flujo:
  1. Verifica campos vacíos.  
  2. Caso especial root: crea o redirige al menú root.  
  3. Caso usuario normal: valida duplicados, genera ID, y añade al `GUsuarios`.  
  4. Muestra mensaje y abre menú usuario.

### Observaciones técnicas
- El sistema maneja root como un caso especial con credenciales fijas.  
- Los IDs de usuario se generan de manera incremental simple (se asume root=1).  
- Se recomienda extender `TListaUsuarios` con un método `NextId` para evitar lógica duplicada.  

---

## 3.2 Módulo `uData.pas` – Estructuras globales

Este módulo centraliza la definición e instanciación de las estructuras de datos usadas globalmente en el sistema.

### Estructuras implementadas

#### **`TTrashStack`** (Pila – Papelera)
Implementación de una pila de correos eliminados.

- **Operaciones:**  
  - `Push(AMail)` → Inserta correo en la cima.  
  - `Pop` → Extrae correo de la cima.  
  - `Peek` → Consulta correo sin eliminar.  
  - `Count` → Retorna cantidad.  
  - `Snapshot` → Copia de los elementos actuales.

- **Complejidad:**  
  - Push/Pop en O(1).  
  - Snapshot en O(n).

#### **`TScheduledQueue`** (Cola – Correos programados)
Implementación de una cola FIFO para correos programados.

- **Operaciones:**  
  - `Enqueue(AMail)` → Inserta al final.  
  - `Dequeue` → Extrae del inicio.  
  - `Peek`, `Count`, `Snapshot`.

- **Complejidad:**  
  - Enqueue/Dequeue en O(1).  
  - Snapshot en O(n).

#### **`TContacts`** (Lista de contactos por usuario)
Gestión de contactos de cada usuario mediante listas asociadas.

- **Operaciones:**  
  - `Add(Owner, Email)` → Agrega contacto único.  
  - `Has(Owner, Email)` → Verifica existencia.  
  - `GetListCopy(Owner)` → Retorna copia de contactos.  
  - `Count(Owner)` → Cantidad de contactos.

- **Internamente:**  
  Usa un `TStringList` ordenado para cada usuario propietario.  

### Variables globales
- `GUsuarios` → Lista de usuarios (`TListaUsuarios`).  
- `GCorreos` → Lista doble de correos (`TListaCorreos`).  
- `GPapelera` → Instancia de `TTrashStack`.  
- `GScheduled` → Instancia de `TScheduledQueue`.  
- `GContacts` → Instancia de `TContacts`.

### Observaciones técnicas
- Todas las estructuras se inicializan en `initialization` y se liberan en `finalization`.  
- Esto asegura su disponibilidad en todo el ciclo de vida de la aplicación.  
- El helper `EsContacto` facilita validar contactos antes de enviar correos.  

---

## 3.3 `uListaUsuarios.pas` — Lista simple (usuarios)

**Estructura:** lista enlazada simple de `TUsuario` (nodos `PUsuario`), con cabeza `FHead` y contador `FCount`.

**Registro `TUsuario`:**
- `id: LongInt`
- `nombre, usuario, email, telefono: string`
- `next: PUsuario`

**API pública principal:**
- `Add(AId, ANombre, AEmail)` / `Add(AId, ANombre, AUsuario, AEmail, ATelefono)`: inserta al inicio. **O(1)**  
- `FindByEmail(AEmail)`: búsqueda lineal por email. **O(n)**
- `EmailById(AId)`: búsqueda por id. **O(n)**
- `Count`: retorna `FCount`. **O(1)**
- `NextId`: recorre y devuelve `max(id)+1`. **O(n)**
- `LoadFromJSON(AFile)`: limpia la lista y carga desde JSON.
- `ExportToDOT(AFile)`: genera un `.dot` con tarjetas por nodo y enlaces `uX -> uY`.

**Formato de carga soportado (flexible):**
- Arreglo plano  
  ```json
  [
    {"id":1,"nombre":"Ana","usuario":"ana","email":"ana@edd.com","telefono":"555-1"},
    {"id":2,"nombre":"Bob","email":"bob@edd.com"} 
  ]

## 3.4 `uListaCorreos.pas` — Lista doble (bandeja de correos)

**Estructura:** lista doblemente enlazada de `TCorreo` con `FHead`/`FTail` y `FCount`.

**Registro `TCorreo`:**
- `id`, `remitente`, `destinatario`, `estado` (`'NL'`/`'L'`), `programado`, `asunto`, `fecha`, `mensaje`
- `next`, `prev`

**API pública principal:**
- `Add(...)`: inserta **al final** (cola visual de bandeja). **O(1)**
- `First`: retorna `FHead` para recorridos. **O(1)**
- `Remove(ACorreo)`: desenlaza y **libera** memoria. **O(1)**
- `Detach(ACorreo)`: desenlaza **sin liberar** (útil para mover a papelera o programados). **O(1)**
- `NextId`: `max(id)+1`. **O(n)**
- `LoadFromJSON(ARuta, Usuarios)`: soporta dos formas de carga (A y B).
- `ExportRelacionesDOT(ARuta)`: grafo dirigido Remitente→Destinatario con peso (conteo de mensajes).
- `ExportRelacionesMatrizDOT(ARuta)`: “matriz dispersa” visual (remitentes vs destinatarios) con conteos.

**Formas de carga soportadas:**
- **Forma A (plana):**
  ```json
  {
    "correos": [
      {"id":1,"remitente":"a@edd.com","destinatario":"b@edd.com",
       "estado":"NL","programado":"","asunto":"Hola","fecha":"2025-09-01","mensaje":"..." }
    ]
  }

## 4. Logica de UI (Controladores)
## 4.1 `uRootMenu.pas` — Menú Root (administrador)

**Rol:** interfaz del usuario **root** para carga masiva y reportes globales.

**Funciones clave**
- `btnCargaMasivaClick`  
  Abre un `OpenDialog`, carga usuarios desde JSON vía `GUsuarios.LoadFromJSON(...)` y muestra conteo. Maneja excepciones de E/S y parseo.
- `btnRepUsuariosClick`  
  Genera `usuarios.dot` (lista enlazada de usuarios) con `GUsuarios.ExportToDOT(...)` y, si hay Graphviz (`dot`), renderiza `usuarios.png`.
- `btnRepRelacionesClick`  
  Genera **matriz de relaciones** de correos con `GCorreos.ExportRelacionesMatrizDOT(...)` y renderiza PNG si `dot` está disponible.
- `btnLogoutClick`  
  Regresa al `MainForm`.

**Infraestructura**
- `GetReportsDir` → crea `./Reportes/Root-Reportes/` junto al ejecutable.  
- `RunDot(dotFile, pngFile)` → ejecuta `dot -Tpng`, captura error y deja al menos el `.dot`.

**Notas**
- No escribe correos; opera sobre usuarios y reportes del sistema completo.
- Requiere **Graphviz** en PATH para los PNG (los `.dot` siempre se generan).

## 4.2 `uUserMenu.pas` — Menú de usuario estándar

**Rol:** hub de navegación del usuario autenticado y **scheduler** automático de correos programados.

**Estado**
- `FEmailActual: string` → contexto del usuario activo.

**Navegación / Acciones**
- `SetUser(nombre, email)` → fija contexto y saludo.
- `btnEnviarClick` → abre `TfrmCompose` en contexto del usuario.
- `btnBandejaClick` → abre `TfrmInbox`.
- `btnPapeleraClick` → abre `TfrmTrash`.
- `btnProgramarClick` → abre `TfrmSchedule`.
- `btnProgListClick` → abre `TfrmProgList` y actualiza cola.
- `btnContactosClick` / `btnNewContactClick` → gestión de contactos.
- `btnPerfilClick` → actualización de perfil.
- `btnGenerarReportesClick` → invoca `GenerateAllUserReports(...)` y muestra carpeta de salida.

**Scheduler (envío automático)**
- `tmrScheduler` (cada 30 s) → `SchedulerTimer` → `ProcessDueScheduled`.
- `TryParseProgDate` → parsea `dd/mm/yyyy hh:nn`.
- `ProcessDueScheduled`  
  - `Dequeue` de `GScheduled`.  
  - Si fecha ≤ `Now`: fija `fecha`, `estado := 'NL'`, agrega a `GCorreos` (inbox) y **libera** el nodo programado.  
  - Si aún no vence: devuelve a la cola con `Enqueue`.  
  - Refresca `frmProgList` si está visible.

**Notas**
- Las estructuras globales se acceden vía `uData`.  
- El temporizador mantiene “vivo” el envío de programados incluso si la vista no está abierta.

## 4.3 `uInboxForm.pas` — Bandeja de entrada

**Rol:** listar correos del usuario, mostrar detalle, marcar como leídos y eliminar.

**UI principal**
- `TStringGrid gridInbox` (3 columnas: Estado, Asunto, Remitente).  
- Panel de detalle (remitente, asunto, fecha, cuerpo).  
- Botones: **Volver**, **Orden A–Z**, **Eliminar**.

**Estado interno**
- `FEmailActual` → dueño de la bandeja.  
- `FInboxRows: array of Pointer` → mapea cada fila a `PCorreo`.  
- `FSortAZ: Boolean` → alterna ordenamiento por asunto.  
- `FSelectedRow` → fila seleccionada.

**Flujos**
- `OpenForUser(email)` → fija contexto, resetea orden y llama `FillInbox`.
- `FillInbox`  
  - Recolecta con `GCorreos.First` los correos cuyo `destinatario = FEmailActual`.  
  - Opcionalmente ordena (`AnsiCompareText` por asunto).  
  - Pinta el grid y guarda punteros en `FInboxRows`.  
  - Llama `UpdateNoLeidos`.
- `gridInboxDblClick` → `ShowDetailForRow(row)`  
  - Muestra detalle y, si `estado='NL'`, marca **'L'** y actualiza contador.
- `btnOrdenAZClick` → alterna `FSortAZ` y repinta.  
- `btnEliminarClick`  
  - Confirma y elimina con `GCorreos.Remove(P)` (libera memoria y saca de la lista) y repinta.

**Complejidad (por operación)**
- Llenado de bandeja: O(n) respecto al total de correos del sistema.  
- Orden A–Z: O(m log m), m = correos del usuario.  
- Marcar leído / eliminar: O(1).

**Recomendación (papelera)**
- Si quieres mantener histórico en papelera, usa `GCorreos.Detach(P)` + `GPapelera.Push(P)` en lugar de `Remove(P)`. El manual puede documentar ambas variantes.

## 4.4 `uTrashForm.pas` — Papelera (pila)

**Rol:** mostrar correos eliminados (pila `GPapelera`), buscar por asunto y eliminar **definitivamente**.

**Estado interno**
- `FEmailActual: string` (contexto)
- `FRows: array of PCorreo` (mapea filas ↔ nodos)
- `FLoading: Boolean` (evita repintados reentrantes)

**Flujos**
- `OpenForUser(email)` → configura grid y llama `FillTrash('')`.
- `FillTrash([FiltroAsunto])`  
  - Obtiene snapshot **LIFO** con `GPapelera.Snapshot`.  
  - Filtra por `Pos(UpperCase(filtro), UpperCase(asunto))`.  
  - Pinta `TStringGrid` y actualiza `FRows`.
- `btnBuscarClick` → vuelve a llenar con filtro.
- `btnEliminarClick`  
  - Confirma y **remueve definitivamente** un `PCorreo` de la pila: hace pop uno a uno a un buffer (`tmp: TTrashStack`), descarta el objetivo (llama `Dispose`), y reinyecta el resto.  
  - Repinta `FillTrash('')`.
- `gridTrashKeyDown` → tecla **Delete** invoca eliminación.

**Complejidad**
- Pintado: O(n) por snapshot.  
- Eliminar uno: O(n) (hay que “desapilar” hasta encontrarlo).

**Notas**
- `UpdateCount` refleja `GPapelera.Count`.  
- Si quisieras restaurar un correo, podrías **sacarlo de pila** (Pop hasta hallar) y reinsertarlo en `GCorreos`.

## 4.5 `uContacts.pas` — Navegación de contactos (lista circular lógica)

**Rol:** navegar de forma circular por los contactos del usuario (prev/next) y mostrar metadatos.

**Estado**
- `FOwner: string` (email del dueño)
- `FList: TStringList` (copia de `GContacts.GetListCopy(FOwner)`)
- `FIndex: Integer` (posición actual)

**Flujos**
- `OpenForUser(owner)` → `RefreshList` y `Show`.
- `RefreshList` → reemplaza `FList` por una **copia** y coloca `FIndex` en 0 si hay elementos.
- `UpdateView`  
  - Muestra correo (`lblCorreoV`) y busca datos en `GUsuarios.FindByEmail(...)` para llenar `nombre`, `usuario`, `telefono`.  
  - Si no existe en usuarios, marca “(desconocido)”.
- `btnPrevClick` / `btnNextClick`  
  - Decrementa/incrementa `FIndex` con **wrap-around** (circular).  
  - Llama `UpdateView`.
- `btnVolverClick` → vuelve a `TfrmUserMenu`.

**Notas**
- `FList` es una **copia**: modificaciones de contactos se hacen fuera (p. ej., en “Nuevo Contacto”) y luego `RefreshList`.
- Si se desea mostrar el **total** de contactos, usar `FList.Count` o `GContacts.Count(FOwner)`.


## 4.6 `uComposeForm.pas` — Componer y enviar

**Rol:** redactar y enviar correos **solo** a contactos permitidos del remitente.

**Estado**
- `FRemitente: string` (usuario autenticado)

**Flujo principal**
- `OpenForUser(email)` → limpia campos y muestra el form.
- `ValidarCampos(out dest, asunto, msg)`  
  - Verifica no vacíos.  
  - Usa `EsContacto(FRemitente, dest)` para **autorizar el envío**.  
- `btnEnviarClick`  
  - `GCorreos.Add(GCorreos.NextId, FRemitente, dest, 'NL', '', asunto, now, cuerpo)`  
  - Notifica y limpia formulario.

**Notas**
- El formato de fecha es `dd/mm/yyyy hh:nn` (con `Now`).  
- La restricción “solo a contactos” está centralizada en `EsContacto(...)`.
- Para adjuntar archivos o validar formato de email, ampliar `ValidarCampos`.

## 4.7 `uProfileForm.pas` — Actualización de perfil

**Rol:** leer/modificar los campos básicos del usuario activo (nombre y teléfono) y reflejarlos en la UI.

**Estado**
- `FEmailActual: string` — identifica al usuario autenticado.

**Flujos**
- `OpenForUser(ownerEmail)`  
  - Busca `PUsuario` con `GUsuarios.FindByEmail`.  
  - Carga valores en `edtNombre`, `edtUsuario` (solo lectura), `edtCorreo` (solo lectura), `edtTelefono`.  
  - Muestra el formulario.
- `btnActualizarClick`  
  - Relee el `PUsuario` y aplica cambios **in-memory** a `nombre` y/o `telefono`.  
  - Si `frmContacts` está visible, llama `RefreshList` para reflejar cambios.  
  - Muestra confirmación.
- `btnVolverClick`  
  - Oculta el form y vuelve a `TfrmUserMenu`.

**UI / Validaciones**
- `edtUsuario` y `edtCorreo` son **ReadOnly**; el login y las relaciones se basan en email.  
- Se evita persistencia en disco (comentado): si se implementa, agregar `SaveToFile`.

**Notas**
- No cambia `email`/`usuario` para evitar inconsistencias con contactos y correos.
- Si se requiere auditar cambios, agregar capa de persistencia y validación de formato de teléfono.

## 4.8 `uUserReports.pas` — Generación de reportes por usuario

**Rol:** producir reportes en **Graphviz DOT** (y PNG si hay `dot` instalado) para inbox, papelera, programados y contactos de un usuario.

**API pública**
- `GenerateAllUserReports(AEmail, out ABaseDir): string`  
  - Crea `Reportes/Usuario-Reportes/<email_sanitizado>/`.  
  - Genera:  
    - `inbox.dot/png` — lista doble (correos recibidos).  
    - `papelera.dot/png` — pila (correos eliminados).  
    - `programados.dot/png` — cola (correos por enviar).  
    - `contactos.dot/png` — lista circular (contactos).  
  - Retorna la ruta base.

**Estructura interna / helpers**
- `Sanitize(s)` — sanea el email para usarlo en rutas.  
- `HTMLEscape(s)` — escapa HTML para etiquetas `<table>` dentro del DOT.  
- `RunDot(dotFile, pngFile)` — intenta `dot -Tpng`; si falla, al menos queda el `.dot`.  
- `SaveAndMaybePng(dot, png, lines)` — asegura directorio, guarda y rindea.

**Exportadores**
- `ExportInboxDOT(owner, dot, png)`  
  - Recorre `GCorreos.First` → `next`.  
  - Filtra `destinatario == owner` y estado distinto de `"EL"`.  
  - Dibuja nodos en **amarillo** con metadata (id, remitente, estado, programado, asunto, fecha, mensaje) y enlaces dobles (lista doble).
- `ExportTrashDOT(owner, dot, png)`  
  - Usa `GPapelera.Snapshot` (tope→fondo).  
  - Filtra por `destinatario == owner`.  
  - Dibuja pila **vertical** en **rojo** con “Estado: Eliminado”.
- `ExportScheduledDOT(owner, dot, png)`  
  - Itera la **cola** sin consumirla (`Dequeue` + `Enqueue`).  
  - Filtra por `remitente == owner` y `programado` no vacío.  
  - Dibuja cola **vertical** en **celeste** (enlaces hacia abajo).
- `ExportContactsDOT(owner, dot, png)`  
  - Toma `GContacts.GetListCopy(owner)`.  
  - Para cada email, busca `PUsuario` (si existe) y muestra tarjeta con id/nombre/usuario/email/teléfono en **azul**.  
  - Enlaces circulares `n1 -> n2 -> ... -> n1`.

**Entradas/Salidas**
- **Entrada:** estructuras globales (`GCorreos`, `GPapelera`, `GScheduled`, `GContacts`, `GUsuarios`).  
- **Salida:** archivos `.dot` siempre; `.png` si Graphviz está disponible en PATH.

**Consideraciones**
- Reportes son **read-only**; no alteran estructuras.  
- Si se desea internacionalizar fechas/etiquetas, centralizar en utilidades.  
- Para volúmenes grandes, considerar paginar o limitar nodos por reporte.

## 4.9 `uProgListForm.pas` — Lista de correos programados (cola)

**Rol:** visualizar la **cola** de correos programados (`GScheduled`) y forzar su envío inmediato.

**UI**
- `TListView lvQueue` con columnas: Asunto, Remitente, Destinatario, Fecha de envío.
- Botones: **Enviar** (procesa toda la cola), **Volver**.

**Flujos**
- `FormCreate` → configura `ListView` en modo `vsReport`.
- `FormShow` → `RefreshQueue`.
- `RefreshQueue`  
  - Usa `GScheduled.Snapshot` (no consume la cola).  
  - Llena filas y guarda el puntero `PCorreo` en `TListItem.Data`.
- `btnEnviarClick`  
  - Mientras `GScheduled.Count > 0`:  
    - `Dequeue`, setea `fecha := Now`, `estado := 'NL'`.  
    - Inserta en bandeja con `GCorreos.Add(GCorreos.NextId, ...)`.  
    - `Dispose(p)` del nodo de cola (el **nodo** de cola se descarta; el contenido se replica en la lista de correos).  
  - Muestra confirmación y `RefreshQueue`.

**Complejidad**
- `RefreshQueue`: O(n) por tamaño de la cola.  
- Envío masivo: O(n) por número de elementos.

**Notas**
- La cola se **consume** en `btnEnviarClick`.  
- El temporizador del `UserMenu` también procesa vencidos automáticamente; este form permite forzar el envío aún si no han vencido.
- Si se quisiera **reusar** el nodo de cola en la lista de correos (sin `Dispose` + `Add`), habría que mover punteros entre estructuras (no implementado aquí).

## 4.10 `uNewContactForm.pas` — Alta de contacto

**Rol:** agregar un correo a la lista de contactos del usuario actual (`GContacts`).

**Estado**
- `FOwner: string` — email del dueño de la agenda.

**Flujos**
- `OpenForUser(owner)` → limpia `edtCorreo` y muestra el formulario.
- `btnAgregarClick`  
  - Validaciones:  
    - No vacío.  
    - No autoinclusión (`SameText(correo, FOwner)`).  
    - Debe existir en `GUsuarios` (solo se agregan usuarios válidos).  
    - No duplicado (`GContacts.Has(...)`).  
  - `GContacts.Add(FOwner, correo)`; notifica y, si `frmContacts` está visible, `RefreshList`.  
  - Limpia campo y mantiene foco para altas consecutivas.
- `btnVolverClick` → regresa a `TfrmUserMenu`.

**Notas**
- `GContacts` almacena por dueño una `TStringList` **ordenada** y sin duplicados; `Has/Add` ya operan en O(log n)/O(log n) amortizado por `TStringList` ordenado (búsqueda binaria).
- Si se requiere validar formato de email, extender con una expresión regular antes de `FindByEmail`.

## Conclusión

El sistema implementado integra múltiples estructuras de datos (listas simples y dobles, pilas y colas) para gestionar usuarios, correos y contactos de manera eficiente, al mismo tiempo que ofrece una interfaz gráfica modular con formularios específicos para cada funcionalidad (login, bandeja, papelera, programados, contactos, reportes, etc.).  
La documentación presentada asegura que cada unidad (`unit`) quede claramente descrita en cuanto a su rol, flujos y consideraciones técnicas, facilitando tanto el mantenimiento como la futura ampliación del proyecto.  
Con esta base, el sistema puede evolucionar hacia nuevas características (persistencia en base de datos, adjuntos, autenticación más robusta) sin perder claridad en su diseño ni comprometer la coherencia de su arquitectura.
