# Roadmap — [NOMBRE_DEL_PROYECTO]

> Estado y dirección del producto. Documento vivo.
> **Última actualización**: [FECHA]

## Leyenda

- ✅ Hecho
- 🚧 En curso
- 📋 Planificado
- ⏸️ Diferido

## Visión

[Un párrafo describiendo hacia dónde va el producto a largo plazo — el "norte".]

## Estado actual

[Qué está en producción hoy y qué madurez tiene.]

## Por versión / fase

Cada ítem se marca cuando la spec que lo implementa se fusiona — no antes. Anota
entre paréntesis la spec responsable en cuanto exista, para que el ítem y su
contrato queden atados:

### v0.1 — [NOMBRE / OBJETIVO]

- [ ] [Objetivo o entregable].
- [ ] [Objetivo o entregable].

### v0.2 — [NOMBRE / OBJETIVO]

- [ ] [Objetivo o entregable].

### v1.0 — [NOMBRE / OBJETIVO]

- [ ] [Objetivo o entregable].

## Backlog / ideas sin agendar

- [Idea pendiente de priorizar].

## Fuera de alcance

Lo que quedó fuera **de una versión concreta** al recortarla, y —esto es lo que hace
útil la sección— **qué lo reabriría**. Sin esa condición de reapertura, un ítem fuera de
alcance se re-discute cada trimestre desde cero.

| Qué                | Por qué quedó fuera | Qué lo reabriría       |
| ------------------ | ------------------- | ---------------------- |
| [Ítem fuera de v1] | [RAZON]             | [Condición observable] |

## Cómo se actualiza este documento

Este archivo **no se revisa solo al cerrar una versión**: se mueve con cada cambio.

- **Al abrir el trabajo**: declara qué ítem de este roadmap viene a completar. Si el
  ítem no existe, se crea aquí primero — y si no encaja en ninguna versión, la pregunta
  es si entra en esta o qué sale a cambio, no si se cuela sin decidirlo.
- **Al cerrarlo**: el mismo PR que implementa el cambio marca el ítem como hecho aquí y
  actualiza el `CHANGELOG.md`. Los tres viajan juntos — ver
  [`../../CONTRIBUTING.md`](../../CONTRIBUTING.md).
- **Al cerrar la versión**: se revisa el conjunto (qué quedó 📋, qué se difiere ⏸️)
  antes de cortar el release.
- Las decisiones que cambian el rumbo se registran como ADRs en [`../decisions/`](../decisions/README.md).
