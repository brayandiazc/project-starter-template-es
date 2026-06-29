# Configuración de Labels en GitHub

Los labels categorizan Issues y Pull Requests. El archivo [`labeler.yml`](labeler.yml)
asigna automáticamente labels a los PRs según los archivos modificados.

## Labels Automáticos (asignados por labeler)

Deben existir en el repositorio para que el labeler funcione.

| Label           | Color     | Descripción                             |
| --------------- | --------- | --------------------------------------- |
| `documentation` | `#0075CA` | Cambios en documentación                |
| `frontend`      | `#0052CC` | Cambios en UI / cliente                 |
| `styles`        | `#BFD4F2` | Cambios en CSS / estilos                |
| `backend`       | `#006B75` | Cambios en servidor / API / lógica      |
| `database`      | `#5319E7` | Migraciones, esquema o seeds            |
| `testing`       | `#FBCA04` | Cambios en tests                        |
| `dependencies`  | `#0366D6` | Actualizaciones de dependencias         |
| `config`        | `#D4C5F9` | Cambios en configuración                |
| `ci-cd`         | `#F9D0C4` | Cambios en CI/CD, workflows y Docker    |
| `github`        | `#333333` | Cambios en templates y config de GitHub |

## Labels Manuales

| Label              | Color     | Descripción                       |
| ------------------ | --------- | --------------------------------- |
| `bug`              | `#D73A4A` | Algo no funciona correctamente    |
| `enhancement`      | `#A2EEEF` | Nueva funcionalidad o mejora      |
| `breaking change`  | `#B60205` | Cambios que rompen compatibilidad |
| `needs review`     | `#FBCA04` | Requiere revisión                 |
| `work in progress` | `#FEF2C0` | Trabajo en progreso               |
| `ready for merge`  | `#0E8A16` | Aprobado y listo para merge       |
| `blocked`          | `#B60205` | Bloqueado por dependencias        |
| `help wanted`      | `#008672` | Se necesita ayuda externa         |
| `good first issue` | `#7057FF` | Bueno para nuevos contribuidores  |
| `duplicate`        | `#CFD3D7` | Issue o PR duplicado              |
| `invalid`          | `#E4E669` | No es válido o no procede         |
| `wontfix`          | `#FFFFFF` | No se trabajará en esto           |
| `question`         | `#D876E3` | Solicitud de información          |

## Crear Labels

### Opción 1: Script automático (recomendado)

```bash
gh auth login
bash .github/scripts/setup-labels.sh
```

### Opción 2: Manual en GitHub

1. Ve a tu repositorio → **Issues** → **Labels**.
2. Click en **New label**.
3. Crea cada label con el nombre, color y descripción de las tablas anteriores.

## Personalizar

Para agregar un nuevo label automático:

1. Crea el label en GitHub (manual o con el script).
2. Agrega la regla en [`labeler.yml`](labeler.yml).
3. Documéntalo en este archivo y en `setup-labels.sh`.
