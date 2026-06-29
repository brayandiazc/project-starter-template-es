# Diseño — [NOMBRE_DEL_PROYECTO]

> Decisiones de diseño técnico y de producto: cómo se resuelve el problema y
> cómo se ve y se siente el producto. Las decisiones relevantes se promueven a
> ADRs en [`../decisions/`](../decisions/README.md).
>
> **Última actualización**: [FECHA]

## Contexto y objetivos

- **Problema**: [Qué se resuelve].
- **Objetivos**: [Qué debe lograr el diseño].
- **No-objetivos**: [Qué queda explícitamente fuera].

## Requisitos

### Funcionales

- [Requisito funcional].

### No funcionales

- [Rendimiento, escalabilidad, disponibilidad, seguridad, accesibilidad…].

## Diseño propuesto

- **Enfoque general**: [Descripción de la solución].
- **Componentes y flujos**: [Cómo encajan las piezas → enlaza a `architecture.md`].

## Alternativas consideradas

| Alternativa   | Pros   | Contras   | ¿Por qué se descartó? |
| ------------- | ------ | --------- | --------------------- |
| [ALTERNATIVA] | [Pros] | [Contras] | [Razón]               |

## Identidad visual y sistema de diseño

- **Principios de diseño**: [Claridad, consistencia, etc.].
- **Tokens**: colores, tipografía, espaciado.
- **Componentes**: librería/primitivas permitidas.

## Accesibilidad

- Contraste de color (objetivo WCAG [AA/AAA]).
- Navegación por teclado y foco visible.
- Roles/atributos ARIA donde corresponda.

## Estados de la interfaz

Cada vista debe contemplar: **carga**, **vacío**, **error** y **éxito**.

## Modelo de datos afectado

Enlaza a [`database.md`](database.md) si el diseño introduce o cambia entidades.

## Riesgos y mitigaciones

| Riesgo   | Impacto           | Mitigación       |
| -------- | ----------------- | ---------------- |
| [RIESGO] | [Alto/Medio/Bajo] | [Cómo se mitiga] |

## Preguntas abiertas

- [ ] [Pregunta pendiente de resolver].
