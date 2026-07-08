# Progreso de aprendizaje

Última actualización: 2026-07-07 (sesión 6)

## Etapa actual

Etapa 0 — Conceptos de Terraform (COMPLETA ✅) → siguiente: Etapa 1 (primeros recursos AWS)

## Checklist

- [x] Etapa 0 — Conceptos de Terraform ✅ (2026-07-07)
  - [x] 1. Qué es Infrastructure as Code y por qué usarlo ✅ (2026-07-07)
  - [x] 2. Sintaxis básica de HCL ✅ (2026-07-07)
  - [x] 3. Providers ✅ (2026-07-07)
  - [x] 4. Workflow principal (init → plan → apply → destroy) ✅ (2026-07-07)
  - [x] 5. State (archivo de estado, drift) ✅ (2026-07-07)
  - [x] 6. Variables y outputs ✅ (2026-07-07)
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

- Pasos 1-5 ya mergeados a dev vía PR. El flujo git del alumno es sólido (branch desde dev →
  add con verificación --ignored/--dry-run → commit conventional → PR a dev → pull). Aprendió
  a verificar que el .tfstate NO entre al repo antes de cada add.
- Paso 6 (Variables y outputs) COMPLETADO → **ETAPA 0 COMPLETA** 🏁. Se cubrió: bloque
  `variable` (type/description/default), uso con `var.<x>`, asignación y PRECEDENCIA (CLI >
  .tfvars > TF_VAR_ > default) demostrada en vivo (el .tfvars ganó al default); bloque `output`
  (value = referencia a atributo, `terraform output`); y la gran duda del alumno sobre cómo se
  comparten variables en equipo (patrón .tfvars.example ≈ .env.example, defaults versionados,
  secretos por TF_VAR_/Secrets Manager). Ejercicio práctico: parametrizó el local_file
  (variables.tf, terraform.tfvars, main.tf con var.<x>, outputs.tf con .id). Bug que cometió y
  corrigió: output apuntaba al recurso entero, no a `.id`. Respondió bien las 4 preguntas.

- PENDIENTE DE COMMIT: el Paso 6 no está commiteado. Hay CÓDIGO nuevo (variables.tf,
  outputs.tf, main.tf modificado) + docs. OJO: terraform.tfvars está gitignored (bien) →
  verificar con --ignored/--dry-run que NO entre, y que SÍ entren variables.tf, outputs.tf,
  main.tf, .terraform.lock.hcl y los docs. Ya se hizo destroy (sin infra viva). Sugerir rama
  feat/stage-0-variables-outputs desde dev → commit feat(stage-0): ... (+ docs) → PR a dev.
  NOTA para futuro: valdría la pena crear un terraform.tfvars.example versionado como buena
  práctica (se habló en la teoría), por si se quiere reforzar el patrón.

=== SIGUIENTE: ETAPA 1 — Primeros recursos AWS reales ===
- ⚠️ ANTES de tocar AWS, hacer el SETUP que se venía posponiendo (requisitos del CLAUDE.md):
  1. Instalar AWS CLI v2 (winget: Amazon.AWSCLI) — verificar con `aws --version`.
  2. Configurar un PERFIL DEDICADO del AWS CLI (no default/root). Nunca pedir/pegar access keys
     en el chat ni en archivos.
  3. BILLING: confirmar que el alumno creó un AWS Budget con alertas ($1/$5/$10) en la Billing
     Console — paso manual, previo a crear cualquier recurso (cuenta free-tier).
  4. Elegir UNA región para todo el proyecto (ej. us-east-1) y fijarla vía variable, no
     hardcodeada.
- Contenido Etapa 1: Paso 7 — bucket S3 (con versioning + bucket policy): primer provider aws
  real (providers.tf con required_providers aws ~> 5.0 + provider "aws" region). Refrescar QUÉ
  es S3 antes del Terraform. Paso 8 — rol IAM + policy para Lambda (data source
  aws_iam_policy_document, dependencias entre recursos).
- Recordar SIEMPRE: regla de oro CLAUDE.md (no escribir el código por el alumno salvo que lo
  pida), explicar el servicio AWS primero (refresher), consultar docs oficiales, flag de costos,
  plan antes de apply, destroy al final. Tags obligatorios cuando lleguen (Project/Environment/
  ManagedBy=terraform).
