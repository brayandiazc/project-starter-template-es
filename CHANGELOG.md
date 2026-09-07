# Changelog

Todos los cambios notables de este proyecto se documentan en este archivo.

El formato se basa en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/)
y este proyecto adhiere a [Semantic Versioning](https://semver.org/lang/es/).

Este es el CHANGELOG del repo-plantilla [brayandiazc/project-starter-template-es](https://github.com/brayandiazc/project-starter-template-es).
Al instanciar se resetea: tu proyecto hereda las herramientas de la
plantilla, no su vida (ver `TEMPLATE-USAGE.md`).

## [Unreleased]

## [2.0.0] - 2026-09-07

### Added

- **`design/` — identidad visual con tokens semánticos**: paleta en `:root` como custom
  properties de CSS estándar, dos temas, contraste AA y los cuatro estados de datos.
  **Agnóstico de framework a propósito**: el enganche a una librería concreta vive en un
  solo bloque marcado como adaptador, que se reemplaza. El diseño se puede montar como
  quieras. Con él llega `docs/architecture/screens.md`, el mapa de pantallas.
- **Seis checks nuevos**, porque una regla que solo se cumple leyendo no se cumple:
  `check-changelog`, `check-design-tokens`, `check-hooks-enabled`, `check-inheritance`,
  `check-instructions`, `check-project-tests` y `check-release`. El banco de pruebas pasa
  de 25 a **149 casos**.
- **`.githooks/pre-commit` y `pre-push`**: `pre-commit` formatea lo que está en stage y
  nunca bloquea; `pre-push` corre los mismos checks que el CI en ~15 segundos y sí
  bloquea. En local son gratis; en Actions, minutos.

### Changed

- **`architecture/` responde qué construye el proyecto; `conventions/`, cómo se
  trabaja.** Los pares que se rellenaban y podaban siempre juntos se fusionaron.

  **Si actualizas un proyecto que ya usaba una versión anterior, esta tabla es lo que
  hay que aplicar a mano.** Un documento renombrado no se sustituye: **se duplica**.
  Quedan los dos —el tuyo con contenido y el nuevo vacío—, los dos son markdown válido,
  los enlaces resuelven y ningún check lo detecta.

  | Antes                                   | Ahora                          | Qué hacer con tu contenido                                                                                                     |
  | --------------------------------------- | ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------ |
  | `docs/architecture/design.md`           | `docs/architecture/screens.md` | Migrar el mapa de pantallas y borrar el viejo                                                                                  |
  | `docs/conventions/design-system.md`     | `docs/conventions/ui.md`       | Fusionar: `ui.md` reúne design system, marca y layouts                                                                         |
  | `docs/conventions/branding.md`          | `docs/conventions/ui.md`       | Ídem                                                                                                                           |
  | `docs/conventions/views-and-layouts.md` | `docs/conventions/ui.md`       | Ídem                                                                                                                           |
  | `docs/conventions/authentication.md`    | `docs/architecture/auth.md`    | Mover las reglas transversales a la sección «Reglas» de `auth.md` y borrar el viejo. El par era la misma tabla en dos archivos |
  | `docs/glossary.md`                      | —                              | Eliminado (huérfano: nada lo referenciaba). Si el tuyo tiene contenido, muévelo a `docs/product/business-model.md`             |
  | `.github/labeler.yml`                   | —                              | Eliminado: configuración huérfana de 82 líneas; ningún workflow la leía                                                        |

- **`.github/LABELS.md` es la única fuente de los labels**: `setup-labels.sh` parsea sus
  tablas en vez de tener una segunda copia. Estaban duplicados y ya habían divergido.
- **La versión de Prettier va fija y en un solo sitio** (`format.sh`), que `pre-commit`
  lee. Un formateador que cambia de minor cambia su salida: el mismo archivo pasa en una
  máquina y falla en el CI.
- **Los servicios de `.env.example` van por categoría, no por proveedor**
  (`PAYMENTS_API_KEY`, `STORAGE_*`, `ERROR_TRACKING_DSN`…), y `scripts/backup-db.sh`
  habla S3 genérico en vez de nombrar un proveedor.

### Removed

- `.github/FUNDING.yml`, `.github/CODEOWNERS.example` y las plantillas de issue
  `support_question` y `documentation_request`. Quedan bug, funcionalidad y tarea.
- `docs/glossary.md` y `.github/labeler.yml` (ver la tabla de arriba).

### Fixed

- **`check-links.sh` y `check-placeholders.sh` fallaban en silencio** cuando un archivo
  trazado por git ya no estaba en disco: perl escupía su error crudo, el archivo no se
  revisaba y el resumen daba todo por bueno. Ahora se cuentan y se avisan.
- **`check-links.sh` no veía los archivos sin trazar**, que es el estado exacto al
  adoptar la plantilla en un proyecto existente.
- **`ci.example.yml` se ejecutaba de verdad.** GitHub corre cualquier `.yml` de
  `.github/workflows/`: aparecía como workflow «CI» en verde sin probar nada. Ahora es
  `ci.yml.example`, y una prueba del banco lo verifica.

### Security

## v1.4.0 y anteriores

El historial hasta la `v1.4.0` vive en las [notas de release](https://github.com/brayandiazc/project-starter-template-es/releases)
del repositorio. No se reconstruye aquí: inventarlo sería peor que no tenerlo.

<!--
Enlaces de comparación entre versiones:
[Unreleased]: https://github.com/brayandiazc/project-starter-template-es/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/brayandiazc/project-starter-template-es/compare/v1.4.0...v2.0.0
-->
