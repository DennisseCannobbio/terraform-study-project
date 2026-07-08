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

### Paso 5 — State: la memoria de Terraform (2026-07-07)

**La pregunta central:** Terraform es declarativo (compara deseado vs. existente y aplica la
diferencia). Pero ¿cómo sabe "lo que existe"? Necesita MEMORIA = el state.

**Las 4 razones del state (doc oficial):**
1. **Mapear código ↔ recursos reales.** `resource "aws_instance" "foo"` debe vincularse a la
   instancia real `i-abcd1234`. El state guarda ese vínculo (nombre local ↔ id real). En el
   ejercicio se vio: type=local_file, name=hello_world, id=<hash>. Es la razón base.
   Analogía: como el *identity map* de un ORM (EF Core) que mapea objeto ↔ fila por su PK para
   decidir INSERT vs UPDATE.
2. **Saber qué destruir.** Si borras un recurso del .tf, Terraform sabe que existía PORQUE
   está en el state; al comparar, detecta que sobra y lo destruye. Sin state, quedaría
   "huérfano" en AWS (vivo y costando, invisible para Terraform).
3. **Performance (caché).** Con cientos de recursos, consultar la API por cada uno en cada
   plan sería lento y chocaría con rate limits. El state cachea atributos (con `-refresh=false`
   se confía solo en el state). Analogía: caché de 2º nivel de un ORM / package-lock.json.
4. **Colaboración en equipo.** State compartido (remoto) = fuente única de verdad + locks
   para applies simultáneos. Es la razón detrás de la Etapa 5 (remote state, ya adelantado).

**DRIFT (deriva) — el concepto estrella:**
- Definición: la infra REAL deja de coincidir con lo que el state registra, porque algo cambió
  POR FUERA de Terraform (típico: alguien edita a mano en la Consola de AWS).
- Cómo se detecta: el `Refreshing state...` que corre antes del plan va a la API real y
  compara; si la realidad difiere del state, lo muestra en el plan.
- Es la solución al dolor del Paso 1 ("alguien tocó la Consola un viernes y nadie se enteró"):
  `plan` delata el drift, `apply` lo corrige empujando la realidad de vuelta al .tf.

**DEMO de drift EN VIVO (hecha en el ejercicio):**
1. `terraform apply` para recrear hello.txt ("Hello world!").
2. Se editó el archivo a mano: `Set-Content ./hello.txt "Editado a mano..."` → drift provocado.
3. `terraform plan` lo detectó. LECCIÓN EXTRA INESPERADA: en vez de `~` (modificar in-place),
   mostró `+ create` / `1 to add`. Por qué: el provider `local` guarda el hash del contenido
   como `id`; al cambiar el contenido a mano, el archivo real ya no coincide con ese id, así
   que el provider lo trató como "el recurso desapareció" → planea RECREARLO. El tipo de
   acción (recreate vs modify) DEPENDE DEL PROVIDER: p.ej. cambiar un tag de un aws_s3_bucket
   daría `~` (modify in-place) porque AWS puede actualizarlo sin recrear. Para local_file, el
   contenido es parte de su identidad → recrear.
4. Lo esencial SÍ ocurrió: Terraform NO adoptó la edición manual; el plan restaura
   "Hello world!". `terraform apply` → el archivo volvió a "Hello world!" (y el id volvió al
   mismo hash). Drift corregido: la fuente de verdad es el código, no el cambio manual.

**STATE vs BACKEND (duda del alumno, importante NO confundir):**
- **State** = el DATO: el archivo `.tfstate` con la info de recursos (la memoria). Existe
  siempre, uses el backend que uses.
- **Backend** = el MECANISMO/LUGAR: la config de DÓNDE y CÓMO se guarda ese state.
- Analogía: el state es un documento (memoria.docx); el backend es dónde lo guardas (disco
  local vs Google Drive vs servidor de red). Mismo documento, distinto lugar.
- El `Initializing the backend...` del init configura esto. Sin especificar nada → backend
  **local** por defecto (state en ./terraform.tfstate). Backend remoto (ej. S3) se declara con
  un bloque `backend "s3" { bucket, key, region }` dentro de `terraform {}` (Etapa 5).
- Frase correcta: "S3 es un tipo de BACKEND, y en ese backend se guarda el STATE". El colega
  que "guardaba el state en S3" en rigor configuró un backend S3.

**El state es DELICADO:**
- Puede contener SECRETOS en texto plano (→ .gitignore local; cifrado en S3 remoto).
- NO editar el .tfstate a mano (se corrompe). Usar comandos: `terraform state mv/rm`, `import`.
- Es LA fuente de verdad de Terraform, no AWS: si borras el .tfstate, Terraform "olvida" sus
  recursos aunque sigan vivos en AWS (por eso el remoto con versionado protege de perderlo).

### Paso 6 — Variables y outputs (2026-07-07) — CIERRA LA ETAPA 0

Mismo principio que en backend: separar los valores configurables del código (no hardcodear).
Dos direcciones: variables (datos que ENTRAN) y outputs (datos que SALEN).

**INPUT VARIABLES (entrada):**
- Se declaran con un bloque `variable "nombre" {}` con argumentos:
  - `type` (string, number, bool, o complejos: list/map/set/object)
  - `description` (documenta el propósito)
  - `default` (OPCIONAL). Con default → variable opcional; SIN default → obligatoria (Terraform
    pide el valor al correr).
- Se USAN con la sintaxis `var.<nombre>` (primera referencia que vimos; apunta a otra cosa en
  vez de un literal).
- Analogía: un bloque variable ≈ parámetro de constructor / entrada de appsettings.json en .NET.
  Sin default ≈ parámetro obligatorio.

**Cómo se ASIGNA valor (precedencia, de MAYOR a menor):**
1. `-var` / `-var-file` en la CLI (máxima prioridad)
2. archivos `*.auto.tfvars`
3. `terraform.tfvars`
4. variables de entorno con prefijo `TF_VAR_` (ej. TF_VAR_file_content=x)
5. el `default` del bloque variable (última prioridad)
- `terraform.tfvars` ≈ el `.env` de Node: valores concretos separados del código. Se carga
  AUTOMÁTICAMENTE si se llama terraform.tfvars o *.auto.tfvars.
- Analogía: es el mismo sistema en capas de IConfiguration de .NET (appsettings < env < CLI).
- DEMOSTRADO en vivo: el .tfvars tenía file_content="Hello World!!!!!" y el default era
  "Hello World!"; el plan mostró el valor del .tfvars → el .tfvars GANA sobre el default.

**OUTPUT VALUES (salida):**
- Se declaran con `output "nombre" {}` con: `value` (la expresión a exponer), `description`,
  `sensitive` (opcional, oculta en CLI).
- El `value` es una REFERENCIA A UN ATRIBUTO de un recurso: `<recurso>.<atributo>`, ej.
  `local_file.hello_world.id`. NO el recurso entero (bug que cometió el alumno: puso
  `local_file.hello_world` sin `.id`; corregido). Es como acceder a `objeto.Id` en C#.
- Usos: (1) mostrar info tras apply; (2) comunicar entre módulos (Etapa 5); (3) alimentar
  automatización (`terraform output -json`).
- Se ven con `terraform output` (todos) o `terraform output <nombre>` (uno).
- Analogía: si las variables son los parámetros de entrada, los outputs son el `return` /
  propiedades públicas que expones. DEMOSTRADO: file_id pasó de (known after apply) en el plan
  a un hash real tras el apply.

**Cómo se comparten las variables en equipo (gran duda del alumno):**
- `terraform.tfvars` NO se versiona (gitignored, puede tener secretos) → cada persona tiene el
  suyo localmente. ¿Cómo sabe cada uno qué poner? Tres mecanismos:
  1. Patrón `terraform.tfvars.example` (SÍ se versiona): plantilla con placeholders, sin datos
     reales. Cada dev la copia a terraform.tfvars y rellena. IDÉNTICO al .env.example de Node.
  2. Los `default` en variables.tf (que SÍ se versiona): muchas variables no necesitan estar en
     el .tfvars si tienen un default sensato.
  3. Secretos de verdad: no van en ningún archivo → variables de entorno TF_VAR_ o gestores
     (AWS Secrets Manager, Vault); en CI/CD, los secrets del repo.
- Regla mental: se versiona la ESTRUCTURA (qué variables existen + plantilla), no los VALORES.

**Reparto de archivos (layout del CLAUDE.md):**
- `variables.tf` → declaraciones (SÍ se versiona; ≈ schema de config)
- `terraform.tfvars` → valores reales (NO se versiona; ≈ .env)
- `terraform.tfvars.example` → plantilla (SÍ se versiona; ≈ .env.example)
- `main.tf` → lógica: recursos que usan var.<x>
- `outputs.tf` → qué se expone (SÍ se versiona; ≈ return)
- Modelo mental: entrada (variables) → proceso (recursos) → salida (outputs).

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
- **🗺️ State ≈ identity map de un ORM (Paso 5)** — como EF Core mapea objeto en memoria ↔ fila
  real (por su PK) para decidir INSERT vs UPDATE, el state mapea recurso declarado ↔ recurso
  real (por su id).
- **📄 State vs Backend ≈ documento vs dónde lo guardas (Paso 5)** — el state es el documento
  (memoria.docx); el backend es el lugar/mecanismo de almacenamiento (disco local vs Google
  Drive vs servidor). Mismo dato, distinta ubicación.
- **⚙️ Variables ≈ parámetros/appsettings; outputs ≈ return (Paso 6)** — un bloque `variable`
  es como un parámetro de constructor o una entrada de appsettings.json; un `output` es como el
  `return` o las propiedades públicas que una clase expone.
- **🗂️ terraform.tfvars ≈ .env; .tfvars.example ≈ .env.example (Paso 6)** — el .tfvars tiene
  los valores reales y no se versiona; el .tfvars.example es la plantilla versionada. Mismo
  patrón que Node.
- **🧅 Precedencia de variables ≈ IConfiguration en capas de .NET (Paso 6)** — CLI > .tfvars >
  TF_VAR_ (entorno) > default, igual que appsettings < env vars < args de CLI: cada capa
  sobrescribe a la anterior.

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

- **P (Paso 5): ¿Por qué Terraform necesita el state?**
  R (correcta): es la fuente de verdad; sin él Terraform no sabe qué recursos existen ni
  cuáles gestionó. (Esa es la Razón 1: el mapeo código↔realidad, base de las otras 3.)

- **P (Paso 5): ¿Qué es el drift y cómo se detecta?**
  R (correcta): diferencia entre lo que el state registra y la infra real, por cambios hechos
  fuera de Terraform (ej. a mano en la Consola). Se detecta con el `Refreshing state...` antes
  del plan, que compara la realidad contra el state.

- **P (Paso 5): ¿El backend es lo mismo que el state guardado en S3?**
  R: No. State = el dato (.tfstate, la memoria). Backend = el mecanismo/lugar donde se guarda.
  S3 es un tipo de backend; en él se guarda el state. Ver "STATE vs BACKEND" en Conceptos.

- **P (Paso 6): ¿Cómo declaras y usas una variable?**
  R (correcta): declarar con `variable "file_content" {}` (argumentos type, description,
  default); usar con `var.file_content`.

- **P (Paso 6): ¿Con qué se compara terraform.tfvars y por qué va en .gitignore?**
  R (correcta): ≈ el `.env` de Node; va en .gitignore porque puede tener info sensible.

- **P (Paso 6): ¿Diferencia entre variable y output?**
  R (correcta): variable = entrada (reemplaza el hardcodeo); output = salida que se expone tras
  apply. Refinamiento: el output no es cualquier cosa que sale, sino un valor que TÚ eliges
  exponer (típicamente un atributo de un recurso).

- **P (Paso 6): Con default="dev" y `-var="environment=prod"`, ¿cuál gana?**
  R (correcta): gana "prod". El default es el valor de último recurso (solo si nadie provee
  otro); la CLI (`-var`) es máxima prioridad y lo sobrescribe.

- **P (Paso 6, del alumno): Si terraform.tfvars no se sube a GitHub, ¿cómo llega a cada
  persona? ¿Cada uno tiene sus variables localmente?**
  R: Sí, cada quien tiene su terraform.tfvars local. Se resuelve con: (1) terraform.tfvars.example
  versionado (plantilla, ≈ .env.example) que cada dev copia y rellena; (2) defaults en
  variables.tf (versionado) para lo que no cambia; (3) secretos por TF_VAR_ / Secrets Manager /
  Vault, nunca en archivo. Se versiona la ESTRUCTURA, no los VALORES. Ver detalle en Conceptos.

- Intuición inicial incompleta sobre "declarativo": se pensó como "declarar qué recurso
  crear". Corregido a "declarar el **estado final** deseado" (un estado, no una acción).
  Ver corrección detallada en "Conceptos cubiertos → Paso 1".

- (Paso 5, demo de drift) Predije que editar hello.txt a mano daría `~` (modify in-place),
  pero dio `+ create` (recrear). Lección: el TIPO de acción ante drift depende del provider.
  El local_file usa el hash del contenido como id, así que un contenido distinto = "otro
  recurso" → recrear. Otros atributos/providers (ej. un tag de aws_s3_bucket) sí modifican
  in-place. No asumir el tipo de acción; leer siempre el plan.

- (Paso 6) En outputs.tf el alumno puso `value = local_file.hello_world` (el recurso entero)
  en vez de `value = local_file.hello_world.id` (el atributo). Lección: el value de un output
  es una referencia a un ATRIBUTO (`<recurso>.<atributo>`), como `objeto.Id` en C#, no el
  recurso completo. Corregido.

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
- [Purpose of Terraform State](https://developer.hashicorp.com/terraform/language/state/purpose)
  — las 4 razones del state: mapeo, destrucción, performance, colaboración. (Paso 5)
- [Input Variables](https://developer.hashicorp.com/terraform/language/values/variables)
  — bloque variable, tipos, asignación (.tfvars/-var/TF_VAR_), precedencia. (Paso 6)
- [Output Values](https://developer.hashicorp.com/terraform/language/values/outputs)
  — bloque output, value/description/sensitive, terraform output. (Paso 6)

## Estado

COMPLETA ✅ — 2026-07-07. Los 6 pasos de fundamentos cubiertos, cada uno con explicación,
analogías, preguntas de verificación respondidas por el alumno y (pasos 4-6) ejercicio
práctico real con el provider `local` (sin costo AWS). Ejercicios ya destruidos (destroy).
