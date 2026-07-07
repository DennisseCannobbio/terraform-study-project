# Progreso de aprendizaje

Última actualización: 2026-07-07 (sesión 5)

## Etapa actual

Etapa 0 — Conceptos de Terraform (en progreso)

## Checklist

- [ ] Etapa 0 — Conceptos de Terraform
  - [x] 1. Qué es Infrastructure as Code y por qué usarlo ✅ (2026-07-07)
  - [x] 2. Sintaxis básica de HCL ✅ (2026-07-07)
  - [x] 3. Providers ✅ (2026-07-07)
  - [x] 4. Workflow principal (init → plan → apply → destroy) ✅ (2026-07-07)
  - [x] 5. State (archivo de estado, drift) ✅ (2026-07-07)
  - [ ] 6. Variables y outputs
- [ ] Etapa 1 — Primeros recursos reales de AWS
  - [ ] 7. Bucket S3 con versioning
  - [ ] 8. Rol IAM + policy para Lambda
- [ ] Etapa 2 — Cómputo + servicios conocidos
- [ ] Etapa 3 — Redes (networking)
- [ ] Etapa 4 — Orquestación
- [ ] Etapa 5 — Madurez en el manejo de state
- [ ] Etapa 6 — Desacoplamiento orientado a eventos (SNS/SQS/DynamoDB)

## Preguntas abiertas / cosas para revisar

- (ninguna aún)

## Notas para la próxima sesión

- Configuración del entorno lista: Git 2.51.1 presente; Terraform CLI v1.15.7 instalado vía
  winget (PATH actualizado — usar una terminal nueva).
- AWS CLI v2 TODAVÍA NO instalado — pospuesto hasta la Etapa 1 (primer recurso real de AWS).
  No bloquea la Etapa 0.
- Repo inicializado (git init, rama main, .gitignore para Terraform). Estructura /docs creada.
- Paso 1 (¿Qué es IaC?) COMPLETADO y documentado en detalle en
  docs/context/stage-00-fundamentals.md. Se cubrió: el problema (drift, trazabilidad,
  reproducibilidad), definición de IaC, declarativo vs imperativo + idempotencia, y
  analogías (Docker, Git, taxi, migraciones de EF Core).
- Convención acordada con el alumno: todo el material de docs/context/ y docs/progress/ se
  escribe en español neutro (material de repaso), y se registra CADA explicación, duda
  resuelta y corrección en docs/context/ en cada sesión.
- Paso 2 (sintaxis de HCL) COMPLETADO y documentado. Se cubrió: HCL vs JSON/YAML, las 2
  construcciones (argumentos y bloques), anatomía del bloque (tipo/etiquetas/cuerpo), el
  patrón resource "tipo" "nombre" (con la distinción nombre local vs nombre real en AWS),
  comentarios (#, //, /* */), identificadores + convención snake_case, y argumento vs bloque
  anidado (pista: el `=`). El alumno respondió correctamente ambas preguntas de verificación.
- Paso 3 (Providers) COMPLETADO y documentado. Se cubrió: por qué existen (mantenibilidad,
  modelo de plugins), qué aportan (vocabulario de tipos de recurso), el Registry + tiers, las
  2 piezas de declaración (required_providers = qué+versión; bloque provider = cómo/región),
  que las credenciales NO van en el código (se toman del entorno/perfil AWS CLI), y que init
  descarga los providers (≈ npm install). Analogía central: provider ≈ paquete NuGet/pip/npm.
  El alumno respondió bien ambas preguntas y aportó intuiciones correctas (varios providers a
  la vez; versionado independiente).

- FLUJO GIT establecido y en uso: repo en GitHub (DennisseCannobbio/terraform-study-project,
  privado). Ramas de entorno main/qa/dev sembradas desde un commit vacío inicial. Modelo:
  feature branch DESDE dev → PR a dev → (luego) promoción dev→qa→main. Convención de nombres:
  feat/<algo>, docs/<algo>, etc. + Conventional Commits con scope de etapa (ej.
  "chore(stage-0): ..."). El ALUMNO ejecuta todos los comandos de git y hace los PR/merge en
  GitHub; Claude solo sugiere nombres de rama/commit y los comandos. Primer bloque (setup +
  Paso 1) ya mergeado a dev vía PR. El Paso 2 aún NO está commiteado (docs recién escritos).

- Pasos 1, 2 y 3 ya mergeados a dev vía PR.
- Paso 4 (workflow) COMPLETADO y documentado. Incluyó el PRIMER ejercicio práctico real:
  el alumno escribió stage-00-fundamentals/main.tf (provider `local` + recurso `local_file`)
  y corrió init → plan → apply → destroy en vivo, más una 2ª corrida de plan que demostró la
  idempotencia ("No changes"). Vio el terraform.tfstate por dentro (la "memoria"). Surgió una
  gran pregunta suya sobre guardar el state en S3 (remote state) — respondida y conectada con
  la Etapa 5. El código del alumno estaba correcto; se le comentó (sin obligar a cambiar) la
  alineación de `=` (excusa para presentar `terraform fmt` más adelante) y el atajo de
  interpolación (path.module sin comillas cuando va solo).

- Pasos 1-4 ya mergeados a dev vía PR. El flujo git del alumno es sólido (branch desde dev →
  add con verificación --ignored/--dry-run → commit conventional → PR a dev → pull). Aprendió
  a verificar que el .tfstate NO entre al repo antes de cada add.
- Paso 5 (State) COMPLETADO y documentado. Se cubrió: las 4 razones del state (mapeo,
  destrucción, performance/caché, colaboración), DRIFT (definición + detección vía Refreshing
  state), la distinción STATE vs BACKEND (duda del alumno, ya registrada), y que el state es
  delicado (secretos, no editar a mano, es la fuente de verdad). DEMO DE DRIFT en vivo: editar
  hello.txt a mano → plan lo detectó → apply lo revirtió. Lección extra: el tipo de acción
  (recreate vs modify) depende del provider (local_file recrea porque el id es el hash del
  contenido). El alumno respondió bien las 2 preguntas de verificación.

- PENDIENTE DE COMMIT: el Paso 5 no está commiteado. Es SOLO documentación (docs/context y
  docs/progress); el main.tf no cambió y ya hicimos destroy (no hay infra viva ni state con
  recursos). Sugerir rama docs/stage-0-state desde dev → commit docs(stage-0): ... → PR a dev.
- Siguiente contenido: Paso 6 — Variables y outputs (CIERRA la Etapa 0). variables.tf (input
  vars con type/description/default), terraform.tfvars (≈ .env), outputs.tf. Analogías:
  variables ≈ parámetros de constructor/appsettings en .NET, .tfvars ≈ .env de Node. Probable
  ejercicio práctico: parametrizar el main.tf del local_file (ej. el content/filename por
  variable) y exponer algo por output. Recordar: explicar primero, el alumno escribe el código.
