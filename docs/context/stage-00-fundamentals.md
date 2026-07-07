# Etapa 0 — Conceptos de Terraform (fundamentos)

## Objetivo

Construir la base conceptual de Infrastructure as Code y de la mecánica de Terraform
ANTES de tocar cualquier recurso de AWS. Con los ejemplos más pequeños posibles
(providers `local_file` / `random`), para que no haya costo ni complejidad de AWS:
solo Terraform en sí mismo.

## Conceptos cubiertos

### Paso 1 — ¿Qué es Infrastructure as Code (IaC) y por qué existe? (2026-07-07)

**El problema que resuelve.** Gestionar infraestructura haciendo clic en la Consola de
AWS (o con scripts sueltos de AWS CLI) no escala ni deja rastro. Cuatro dolores típicos:
1. **Falta de trazabilidad** — meses después nadie recuerda cómo estaba configurado un
   recurso ni por qué. El conocimiento vive en la cabeza de quien lo hizo.
2. **No reproducible** — replicar un entorno (ej. `staging`) obliga a repetir los mismos
   clics sin equivocarse. Con muchos recursos, algo siempre se olvida → **configuration
   drift** (dos entornos que deberían ser idénticos pero divergen en silencio).
3. **Sin historial** — no se sabe quién cambió qué ni cuándo (ej. alguien toca un security
   group un viernes y rompe producción, sin diff ni autor).
4. **Onboarding lento** — levantar la infra en otra cuenta requiere que alguien te guíe
   clic por clic.

**Definición.** IaC = gestionar la infraestructura (servidores, redes, buckets, roles,
colas…) escribiéndola en **archivos de configuración versionables**, en lugar de crearla a
mano. HashiCorp: *"definir recursos cloud y on-prem en archivos legibles por humanos que
se pueden versionar, reutilizar y compartir"* (los 3 verbos = los dolores dados vuelta).

**Concepto clave: declarativo vs. imperativo.**
- **Imperativo** (script de AWS CLI) = describes el **paso a paso** ("crea el bucket, activa
  versioning…"). Re-ejecutarlo desde otro estado rompe (ej. "el bucket ya existe" 💥). Tú
  cargas con la lógica de "si existe actualiza, si no crea".
- **Declarativo** (Terraform) = describes el **estado final deseado** ("quiero que exista un
  bucket con estas características"). Terraform mira qué hay, calcula la diferencia y hace
  **solo** lo necesario. Re-ejecutar es inofensivo → propiedad llamada **idempotencia**.

  Corrección importante a la intuición inicial:
  - ❌ "Declarativo es declarar qué recurso quiero crear."
  - ✅ "Declarativo es declarar el **estado final** que quiero, y dejar que la herramienta
    calcule qué acciones (crear, modificar o destruir) hacen falta para llegar ahí desde
    donde está hoy." No es una acción ("creá"), es un estado ("quiero que exista").

**Beneficios concretos (tabla dolor → solución):**
| Dolor con Consola/scripts | Cómo lo resuelve IaC |
|---|---|
| ¿Cómo estaba configurado? | La config *es* la documentación, siempre actualizada |
| Replicar en staging | `terraform apply` con otras variables → entorno idéntico |
| ¿Quién cambió qué? | Historial de Git, con diffs y autores |
| Onboarding lento | `git clone` + `terraform apply` |
| Drift silencioso | Terraform *detecta* la deriva y la muestra |
| Miedo a aplicar cambios | `terraform plan` muestra el diff antes |

### Paso 2 — Sintaxis de HCL (2026-07-07)

**Qué es HCL.** HashiCorp Configuration Language: el lenguaje de los archivos `.tf`. Diseñado
para configuración escrita por humanos. Comparado con lo que ya conocemos:
- JSON: legible para máquinas, sin comentarios, ruidoso (comillas y comas por todos lados).
- YAML: más legible, pero sensible a la indentación (un espacio de más rompe todo).
- HCL: legible como YAML pero **NO depende de la indentación** (delimita con llaves `{}`,
  como C#/JS), permite comentarios, y agrega variables/expresiones/funciones.

**Las DOS únicas construcciones del lenguaje** (según doc oficial, todo HCL se reduce a esto):
1. **Argumento** = asigna un valor a un nombre: `image_id = "abc123"`. Es `nombre = valor`,
   sin comillas en el nombre ni coma al final. Equivale a una asignación (`var x = ...`).
2. **Bloque** = contenedor de otro contenido. Anatomía:
   ```hcl
   resource "aws_instance" "example" {   # encabezado del bloque
     ami           = "abc123"            # cuerpo: argumentos
     instance_type = "t2.micro"
   }
   ```
   - **Tipo de bloque** (block type): `resource` — la palabra clave que dice qué clase de
     bloque es.
   - **Etiquetas** (labels): `"aws_instance"` y `"example"` — identificadores tras el tipo;
     cuántas y qué significan depende del tipo de bloque.
   - **Cuerpo** (body): lo que va entre `{ }` — argumentos y/o bloques anidados.

**El patrón `resource "tipo" "nombre"` (el corazón de Terraform):**
```hcl
resource "aws_s3_bucket" "mi_bucket" { ... }
```
- `resource` = tipo de bloque ("declaro un recurso de infraestructura").
- `"aws_s3_bucket"` = **1ª etiqueta = TIPO de recurso**, definido por el provider; le dice a
  Terraform QUÉ cosa de AWS quieres. Análogo al **tipo/clase** en .NET.
- `"mi_bucket"` = **2ª etiqueta = NOMBRE local**, lo eliges tú; solo existe dentro del código
  Terraform para referenciar el recurso. Análogo al **nombre de la variable/instancia**.
- ⚠️ CRÍTICO: `"mi_bucket"` NO es el nombre real del bucket en AWS. El nombre real de AWS se
  define DENTRO del cuerpo con un argumento (`bucket = "..."`). El nombre local es solo el
  "apodo" interno de Terraform. Son dos cosas distintas.

**Comentarios (3 estilos):**
- `#` una línea — **estilo preferido/idiomático** (usar este).
- `//` una línea — válido (estilo C/JS), menos usado.
- `/* ... */` multilínea.

**Identificadores (reglas de nombres):** pueden tener letras, dígitos, `_` y `-`; NO pueden
empezar con dígito. Convención del proyecto (CLAUDE.md): **snake_case** para nombres de
recursos (ej. `learning_lambda_role`) — es lo idiomático en Terraform, como en Python.

**Argumento vs. bloque anidado (distinción visual clave):**
- **Argumento** → lleva `=`. Es `nombre = valor` (ej. `instance_type = "t2.micro"`).
- **Bloque anidado** → NO lleva `=`. Es `nombre { ... }` (ej. `network_interface { ... }`).
  La pista de un vistazo para leer la doc de cualquier recurso: ¿hay `=`? → argumento; ¿hay
  `{` sin `=`? → bloque anidado.

**Modelo mental final:** todo `.tf`, por grande que sea, es solo bloques con argumentos (y a
veces bloques anidados) adentro, anidados como muñecas rusas. Dos construcciones, nada más.

### Paso 3 — Providers (2026-07-07)

**El problema que resuelve.** Terraform "vacío" sabe leer HCL y correr el workflow, pero NO
sabe qué es un bucket S3, un rol IAM, etc. No conoce ninguna plataforma. Meter el
conocimiento de todas las plataformas dentro del binario sería inmantenible (las plataformas
cambian y crecen constantemente). Solución: arquitectura de **plugins** = providers.

**Definición.** Un provider es un plugin que le enseña a Terraform a hablar con una plataforma
específica (AWS, Azure, GitHub…), traduciendo los bloques de HCL en llamadas a la API de esa
plataforma. Doc oficial: *"cada tipo de recurso está implementado por un provider; sin
providers, Terraform no puede gestionar ningún tipo de infraestructura."* El provider aporta
el **vocabulario**: el tipo `aws_s3_bucket` existe porque el provider de AWS lo trae.

**El Registry.** Los providers viven en el Terraform Registry (registry.terraform.io) =
equivalente a nuget.org / PyPI / npmjs.com. Clasificados por tiers: Official (HashiCorp, ej.
AWS), Partner (verificado por HashiCorp), Community (revisar antes de depender). Usaremos el
oficial `hashicorp/aws`.

**Se declara en DOS piezas distintas:**
1. `required_providers` (dentro del bloque `terraform {}`) = **QUÉ provider + QUÉ versión**.
   Es la "lista de dependencias" (como package.json / <PackageReference>).
   ```hcl
   terraform {
     required_providers {
       aws = { source = "hashicorp/aws", version = "~> 5.0" }
     }
   }
   ```
   - `source` = dirección en el Registry (namespace/nombre, como el ID de un paquete NuGet).
   - `version = "~> 5.0"` = restricción de versión (el CLAUDE.md pide pinnear con `~>`).
   - Pueden ir VARIOS providers a la vez (ej. aws + random + google/azurerm). Nota de nombre:
     el provider de GCP se llama `google`; el de Azure, `azurerm` ("gcp" es el concepto).
2. `provider "aws"` (bloque aparte) = **CÓMO se configura** ese provider (ej. región).
   ```hcl
   provider "aws" { region = "us-east-1" }
   ```
   - Es un bloque con UNA etiqueta (el nombre del provider).

   Distinción clave: `required_providers` = "necesito el plugin AWS 5.x" (qué instalar);
   `provider "aws"` = "y cuando lo uses, trabaja en us-east-1" (cómo comportarse).

**Credenciales de AWS: NO van en el bloque provider.** El provider las busca automáticamente
en el entorno (variables de entorno, perfiles del AWS CLI, roles IAM) — igual que boto3 / el
SDK de AWS. Por eso en la Etapa 1 se configura un perfil dedicado del AWS CLI, y las
credenciales nunca aparecen en el código (regla del CLAUDE.md).

**Dónde vive en el proyecto:** archivo `providers.tf` (convención; Terraform lee todos los
`.tf` de la carpeta igual). Ahí irán el bloque `terraform{}` y el `provider "aws"{}`.

**Init lo descarga:** `terraform init` lee `required_providers` y descarga los plugins del
Registry, como `npm install` lee package.json y baja las dependencias (se ve en Paso 4).

### Paso 4 — El workflow: init → plan → apply → destroy (2026-07-07)

Primer ejercicio práctico REAL: se creó `stage-00-fundamentals/main.tf` con el provider
`local` (sin AWS, sin costo, sin credenciales) y un recurso `local_file` que escribe un
archivo `hello.txt` en disco. Se recorrió el ciclo de vida completo en vivo.

**`terraform init`** — prepara el directorio; lee `required_providers` y DESCARGA los
providers del Registry a `.terraform/`. Genera `.terraform.lock.hcl` (lockfile).
- Cuándo: la 1ª vez, o al cambiar providers/módulos/backend. No en cada cambio de recurso.
- Analogía: ≈ `npm install` / `dotnet restore` / `pip install -r`. `.terraform/` ≈ node_modules
  (va en .gitignore); `.terraform.lock.hcl` ≈ package-lock.json (SÍ se versiona — el propio
  init lo dice: "Include this file in your version control repository").
- En vivo: bajó `hashicorp/local v2.9.0` respetando `~> 2.0` (no saltó a 3.x); "(signed by
  HashiCorp)" = verificación de firma (provider Official). Mencionó "Initializing the
  backend..." → backend LOCAL por defecto (dónde se guarda el state; ver Paso 5).

**`terraform plan`** — genera un PLAN DE EJECUCIÓN (preview del diff) SIN cambiar nada.
- Analogía: ≈ `git diff` / `git status`. Leerlo SIEMPRE antes de aplicar.
- Símbolos: `+` crear, `-` destruir, `~` modificar in-place, `-/+` reemplazar.
- Mirar SIEMPRE el resumen: `Plan: X to add, Y to change, Z to destroy`. En vivo dio
  `1 to add`. Si esperabas crear 1 y dice "3 to destroy", PARÁS y revisás.
- `(known after apply)` = valor que no se sabe hasta crear el recurso (ej. el `id`).
- Argumentos opcionales no definidos aparecen con su default (ej. file_permission = "0777").

**`terraform apply`** — ejecuta los cambios de verdad. Incluye un `plan` implícito y PIDE
confirmación: hay que escribir literalmente `yes` (nada más lo aprueba).
- Analogía: ≈ `git commit` (confirmás y se hace permanente). Flujo real = loop:
  editar .tf → plan → ¿ok? no: re-editar / sí: apply.
- En vivo: creó el archivo; el `id` que era (known after apply) pasó a tener valor (hash SHA1
  del contenido). Resumen: `1 added` (coincide con lo que prometió el plan).

**`terraform destroy`** — elimina TODA la infra gestionada. Muestra plan lleno de `-`,
`There is no undo`, pide `yes`.
- Analogía: ≈ `docker-compose down`. Hábito clave del proyecto: destruir al final de cada
  sesión para no dejar recursos con costo (regla del CLAUDE.md).
- En vivo: cada atributo mostró la transición `"valor" -> null`; resumen `1 to destroy`.
  Después: `hello.txt` desapareció (Test-Path → False) y el state quedó con `"resources": []`.

**IDEMPOTENCIA demostrada en vivo:** tras el apply, correr `terraform plan` de nuevo SIN
cambios dio `No changes. Your infrastructure matches the configuration.` Terraform hace un
`Refreshing state...` (sincroniza el state con la realidad → esto detecta drift, Paso 5) y
compara .tf (deseado) vs state/realidad; como son iguales, no actúa. Esto es lo que hace
SEGURO re-aplicar (contraste con el script imperativo que fallaba con "el bucket ya existe").

**El STATE FILE (`terraform.tfstate`) — antesala del Paso 5:** el apply generó este JSON = la
"memoria" de Terraform. Guarda type/name del recurso y todos sus atributos reales (id,
content, hashes…). Es lo que Terraform compara en cada `plan`: .tf (deseado) vs .tfstate (lo
que sabe que existe) → por eso plan ≈ git diff (necesita ambos lados). Campos vistos:
`serial` (contador de versión del state, subió 1→3 con los cambios), `lineage` (id único del
state). El `.tfstate` va en .gitignore porque puede contener SECRETOS en texto plano.

## Analogías usadas

- **🐳 Docker** — Terraform es el `Dockerfile` de tu infraestructura: describes el estado
  final en un archivo de texto y la herramienta lo materializa igual en cualquier lado.
  Más fino: `docker-compose.yml` = estado deseado; contenedor corriendo = estado real;
  Docker compara y actúa → Terraform hace lo mismo con su *state file* (se ve en Paso 5).
- **🌿 Git** — la infra pasa a ser código en un repo: historial (`git log`/`git blame` →
  quién y por qué), code review vía PR, rollback (`git revert`). Y `terraform plan` ≈
  `git diff`/`git status`: muestra qué va a cambiar antes de aplicarlo.
- **🚕 Taxi (declarativo vs imperativo)** — imperativo = instrucciones paso a paso ("avanza
  200m, dobla a la derecha…"); repetirlas desde otro punto te lleva mal. Declarativo = das
  el destino ("llévame a Av. Central 1234"); si ya estás ahí, no hace nada. El "no hace
  nada si ya está" = idempotencia.
- **🟣 Migraciones de EF Core (.NET)** — declaras el modelo/esquema final deseado y la
  herramienta calcula el `ALTER TABLE` necesario desde el estado actual. Terraform es a la
  infraestructura lo que las migraciones de EF Core son a la base de datos.
- **🔷 HCL vs JSON/YAML (Paso 2)** — HCL es como escribir configuración con la comodidad de
  un lenguaje: comentarios + referencias + lógica, pero sin la fragilidad de indentación de
  YAML (usa llaves como C#/JS).
- **🟣 `resource "tipo" "nombre"` ≈ instanciación en .NET (Paso 2)** —
  `resource "aws_s3_bucket" "mi_bucket"` es como `AwsS3Bucket miBucket = new AwsS3Bucket{}`:
  `aws_s3_bucket` = el tipo/clase; `mi_bucket` = el nombre de la instancia/variable.
- **📦 Provider ≈ paquete NuGet/pip/npm (Paso 3)** — la analogía central. Un provider es una
  dependencia versionada que le da a Terraform un vocabulario nuevo, igual que instalar
  `Microsoft.Data.SqlClient` te da `SqlConnection`/`SqlCommand`. Paralelos exactos:
  required_providers ≈ package.json; .terraform.lock.hcl ≈ package-lock.json; `terraform init`
  ≈ `npm install`; el Registry ≈ nuget.org/PyPI/npmjs.com.
- **🐳 Provider ≈ imagen base de Docker (Paso 3)** — como `FROM python:3.11` te da un
  vocabulario listo sobre el que construir, el provider es la "base" que te da el vocabulario
  de recursos de AWS.
- **🟣 required_providers vs provider ≈ .csproj vs appsettings.json (Paso 3)** —
  required_providers (qué librería y versión traer) es como el <PackageReference> del .csproj;
  el bloque provider (cómo se comporta en runtime: región, etc.) es como el appsettings.json /
  cadena de conexión que configura esa librería.
- **🔄 El workflow ≈ comandos git/docker (Paso 4)** — `init` ≈ npm install/dotnet restore;
  `plan` ≈ git diff/git status; `apply` ≈ git commit (con confirmación "yes"); `destroy` ≈
  docker-compose down.
- **🐙 Remote state en S3 ≈ GitHub para el state (Paso 4/Etapa 5)** — el `.tfstate` local es
  como un repo git que solo vive en tu laptop; guardarlo en un bucket S3 compartido es como
  GitHub: la fuente de verdad central de la que todo el equipo lee/escribe.

## Preguntas y respuestas

- **P (Paso 1): ¿Cuál es la diferencia entre declarativo e imperativo y por qué importa
  para no romper cosas al re-aplicar?**
  R: Imperativo describe los *pasos*; re-ejecutarlos desde un estado distinto rompe.
  Declarativo describe el *estado final*; Terraform compara "dónde estoy" vs. "dónde quiero
  estar" y hace solo la diferencia, por eso re-aplicar es seguro (idempotencia). Ver
  analogía del taxi y de EF Core arriba.

- **Caso real del alumno que aterriza el problema:** en su equipo se crearon muchos buckets
  S3 con nombres distintos para la misma función, sin saber por qué había tantos duplicados.
  Mapea a dos dolores de IaC: (A) falta de trazabilidad — sin registro de intención;
  con IaC cada bucket vive en un `.tf` versionado y `git blame` dice quién/por qué. (B)
  proliferación descontrolada — sin fuente única de verdad cada uno crea "el suyo"; con IaC
  hay un solo lugar donde está declarada la infra y el code review del PR frena duplicados
  antes de que ocurran. (Bonus: `terraform import`, Stage 5, ayuda a detectar recursos
  huérfanos no gestionados.)

- **P (Paso 2): En `resource "aws_s3_bucket" "mi_bucket"`, ¿qué es cada etiqueta?**
  R (correcta): `aws_s3_bucket` = el tipo de recurso (viene dado por el provider);
  `mi_bucket` = el nombre local dentro del código Terraform, elegido por mí, y NO es el
  nombre real del bucket en AWS (ese va por argumento `bucket = "..."`).

- **P (Paso 2): De `instance_type = "t2.micro"` y `network_interface { ... }`, ¿cuál es
  argumento y cuál bloque anidado?**
  R (correcta): `instance_type` es argumento (tiene `=`); `network_interface` es bloque
  anidado (no tiene `=`). La pista es el signo `=`.

- **P (Paso 3): ¿Por qué Terraform necesita providers en vez de traer todo AWS incluido?**
  R (correcta): por mantenibilidad — las plataformas cambian y crecen constantemente, meter
  todo en el binario sería inmantenible. El alumno lo comparó (bien) con "librerías/packages".
  Beneficio derivado: al versionarse aparte, un servicio nuevo de AWS solo requiere actualizar
  ESE provider, no Terraform entero.

- **P (Paso 3): ¿Diferencia entre required_providers y el bloque provider "aws"?**
  R (correcta): required_providers = el "qué" (qué provider + versión); provider "aws" = el
  "cómo" (config: región, etc.). El alumno notó bien que en required_providers pueden ir
  varios providers, no solo aws (ej. google, azurerm, random).

- **P (Paso 4): "Un colega me dijo que guardaban el state en un bucket S3, ¿estoy cerca?"**
  R: Totalmente correcto. El `.tfstate` local no sirve para equipos: (1) no se comparte —
  otro dev sin tu state creería que no existe nada e intentaría recrear todo; (2) puede tener
  secretos en texto plano (por eso va en .gitignore); (3) dos `apply` simultáneos pueden
  corromperlo. Solución = REMOTE STATE: guardar el .tfstate en un backend central compartido,
  el más común en AWS = un bucket S3 (con versionado y cifrado), + un LOCK para evitar applies
  simultáneos (tradicionalmente tabla DynamoDB; hoy S3 puede hacer lock nativo). El
  "Initializing the backend..." del init es justo el mecanismo (por defecto = backend local).
  Analogía: state local ≈ repo git solo en tu laptop; state en S3 ≈ GitHub (fuente de verdad
  central del equipo). Esto es EXACTAMENTE la Etapa 5 del roadmap (migrar a S3 + DynamoDB);
  se deja para más adelante para primero entender el state local y simple.

## Errores y lecciones

- Intuición inicial incompleta sobre "declarativo": se pensó como "declarar qué recurso
  crear". Corregido a "declarar el **estado final** deseado" (un estado, no una acción).
  Ver corrección detallada en "Conceptos cubiertos → Paso 1".

## Configuración del entorno

- Git 2.51.1 (ya estaba instalado).
- Terraform CLI v1.15.7 instalado vía winget (Hashicorp.Terraform). PATH actualizado;
  las terminales nuevas lo reconocen como `terraform`.
- AWS CLI v2 pospuesto hasta la Etapa 1 (no hace falta para los fundamentos de Terraform).

## Documentación consultada

- [Terraform intro — Qué es Terraform / IaC](https://developer.hashicorp.com/terraform/intro)
  — definición de IaC, workflow write/plan/apply, declarativo vs. imperativo. (Paso 1)
- [Configuration Syntax (HCL)](https://developer.hashicorp.com/terraform/language/syntax/configuration)
  — argumentos, bloques, etiquetas, identificadores, comentarios. (Paso 2)
- [Providers](https://developer.hashicorp.com/terraform/language/providers)
  — qué son, modelo de plugins, Registry, required_providers, bloque provider, init. (Paso 3)
- [Core workflow](https://developer.hashicorp.com/terraform/intro/core-workflow)
  — Write → Plan → Apply como loop; qué hace init/plan/apply. (Paso 4)
- [Recurso local_file](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file)
  — argumentos filename (requerido), content, defaults de permisos. (Paso 4)

## Estado

En progreso — 2026-07-07
