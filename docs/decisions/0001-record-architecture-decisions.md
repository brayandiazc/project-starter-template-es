# 0001. Registrar las decisiones de arquitectura

- **Estado**: Aceptada
- **Fecha**: [FECHA]
- **Decisores**: [NOMBRES]

## Contexto y problema

A medida que el proyecto evoluciona se toman decisiones de arquitectura cuyo
contexto y motivación se pierden con el tiempo. Sin un registro, el equipo repite
debates ya resueltos y las nuevas personas no entienden por qué el sistema es como
es.

## Opciones consideradas

- **No documentar** — confiar en la memoria del equipo y el historial de commits.
- **Documentar en una wiki** — fácil de editar pero desligado del código.
- **Architecture Decision Records (ADRs)** — archivos versionados junto al código.

## Decisión

Adoptamos **Architecture Decision Records (ADRs)** ligeros (estilo MADR),
versionados en `docs/decisions/`. Cada decisión relevante se documenta con la
plantilla [`0000-template.md`](0000-template.md) y se numera secuencialmente.

## Consecuencias

**Positivas:**

- El "por qué" de cada decisión queda registrado junto al código.
- Las nuevas personas se ponen al día más rápido.
- Se evita re-litigar decisiones ya tomadas.

**Negativas / costos:**

- Requiere disciplina para crear el ADR en el momento de decidir.

**Neutras / a vigilar:**

- Mantener el índice del [README](README.md) actualizado.

## Referencias

- [Documenting Architecture Decisions — Michael Nygard](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions)
- [MADR — Markdown Architectural Decision Records](https://adr.github.io/madr/)
