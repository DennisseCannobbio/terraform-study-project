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

## Estado

En progreso — 2026-07-07
