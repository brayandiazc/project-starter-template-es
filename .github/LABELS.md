# Labels del repositorio

Los labels categorizan issues y pull requests. Este archivo es la fuente de verdad:
[`scripts/setup-labels.sh`](scripts/setup-labels.sh) **parsea estas tablas** y los crea
en GitHub — no hay ninguna otra copia que mantener.

No hay auto-etiquetado por rutas: en un repositorio de una sola persona, un label que
hay que aplicar a mano y que nadie consulta es ruido. Los que están aquí, o los aplica
una automatización, o cambian el comportamiento del CI, o sirven para buscar.

## Aplicados automáticamente

| Label          | Color     | Quién lo aplica                              |
| -------------- | --------- | -------------------------------------------- |
| `dependencies` | `#0366D6` | Dependabot (`dependabot.yml`)                |
| `ci-cd`        | `#F9D0C4` | Dependabot, en las updates de GitHub Actions |

## Tipo

| Label           | Color     | Cuándo                         |
| --------------- | --------- | ------------------------------ |
| `bug`           | `#D73A4A` | Algo no funciona correctamente |
| `enhancement`   | `#A2EEEF` | Nueva funcionalidad o mejora   |
| `documentation` | `#0075CA` | Cambios solo de documentación  |
| `question`      | `#D876E3` | Solicitud de información       |

## Estado

| Label             | Color     | Cuándo                        |
| ----------------- | --------- | ----------------------------- |
| `breaking change` | `#B60205` | Rompe compatibilidad          |
| `blocked`         | `#B60205` | Bloqueado por una dependencia |
| `duplicate`       | `#CFD3D7` | Ya existe                     |
| `wontfix`         | `#FFFFFF` | No se trabajará en esto       |

## Excepciones de CI

| Label           | Color     | Efecto                                                                           |
| --------------- | --------- | -------------------------------------------------------------------------------- |
| `sin-changelog` | `#C5DEF5` | El job `changelog` de `quality.yml` deja pasar el PR sin entrada en el CHANGELOG |

> Es el **único** label que cambia el resultado del CI. Úsalo con una razón escrita en
> el PR: la regla es que todo cambio se documenta.

## Crear los labels

```bash
bash .github/scripts/setup-labels.sh
```

Requiere [`gh`](https://cli.github.com) autenticado. Es idempotente: crea los que
falten y actualiza color y descripción de los existentes.

## Añadir uno nuevo

1. Añádelo a la tabla que corresponda en este archivo (nombre y color entre
   backticks; la tercera columna hace de descripción) y vuelve a correr el script.
2. Si no lo aplica una automatización ni afecta al CI, pregúntate primero si lo vas a
   usar de verdad.
