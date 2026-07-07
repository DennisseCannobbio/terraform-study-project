# Progreso de aprendizaje

Última actualización: 2026-07-07 (sesión 1)

## Etapa actual

Etapa 0 — Conceptos de Terraform (en progreso)

## Checklist

- [ ] Etapa 0 — Conceptos de Terraform
  - [x] 1. Qué es Infrastructure as Code y por qué usarlo ✅ (2026-07-07)
  - [ ] 2. Sintaxis básica de HCL
  - [ ] 3. Providers
  - [ ] 4. Workflow principal (init → plan → apply → destroy)
  - [ ] 5. State (archivo de estado, drift)
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
- Siguiente: Paso 2 — sintaxis de HCL (bloques, argumentos, resource type/name, comentarios),
  comparado con JSON/YAML. Explicación primero, sin código aún salvo que el alumno lo pida.
