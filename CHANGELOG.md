# Changelog

Todos los cambios notables de este proyecto se documentan en este archivo.

El formato se basa en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/)
y este proyecto adhiere a [Semantic Versioning](https://semver.org/lang/es/).

Este es el CHANGELOG del repo-plantilla [brayandiazc/project-starter-template-es](https://github.com/brayandiazc/project-starter-template-es).
Al instanciar se resetea: tu proyecto hereda las herramientas de la
plantilla, no su vida (ver `TEMPLATE-USAGE.md`).

## [Unreleased]

### Fixed

- **Dependabot no podía pasar el gate del CHANGELOG.** El job `changelog` exige entrada a
  todo PR que toque el proyecto; el bot toca el manifiesto y el lockfile, no escribe
  changelogs y no puede aprenderlo. Sus PRs morían con el build y los escaneos en verde.
  La excepción ya estaba diseñada —la label `sin-changelog`—, solo que nada se la ponía:
  ahora nacen con ella.
- **La vía de escape solo servía puesta antes de abrir el PR.** `PR_LABELS` sale del
  payload del evento, así que poner `sin-changelog` a mano no disparaba nada y un re-run
  replicaba el payload viejo, sin la label — justo al revés de cuando descubres que la
  necesitas. `quality.yml` escucha ahora `labeled` y `unlabeled`. Cuesta un run por cada
  cambio de label; una salida de emergencia inutilizable en la emergencia cuesta más.

- **`check-hooks-enabled.sh` no lo invocaba nadie.** Existía, tenía sus casos en el banco
  de pruebas y ninguna otra línea del repositorio lo llamaba: las dos llamadas vivían en
  skills que esta variante no tiene. Y por diseño no puede correr en el CI —no ve la
  config local de nadie— ni dentro de `pre-push` —solo se ejecuta si la config que
  verifica ya está puesta—, así que sin una instrucción que lo llame no lo llama nadie.
  `TEMPLATE-USAGE.md` lo invoca ahora en lugar de mandar el `git config` a pelo.
- **`TEMPLATE-USAGE.md` remitía a skills que aquí no existen** (`/actualizar-plantilla`).
  Ahora describe el paso en vez de delegarlo en algo que no está.

### Changed

- **Los PRs de Dependabot van agrupados**, uno con todos los bumps en vez de uno por
  paquete. Fusionar N bumps sueltos en cadena deja un lockfile que nadie compiló: git no
  marca conflicto —cada bump toca un sitio distinto del archivo— y el CI tampoco lo ve,
  porque cada PR se construye sobre su propia rama y nunca sobre el resultado de
  fusionarlos todos. El precio, escrito al lado en `dependabot.yml`: si un bump del grupo
  rompe, se bloquea el grupo entero.

## [2.1.0] - 2026-09-07

### Added

- **`check-git-flow.sh` — que `develop` exista en el remoto.** `CONTRIBUTING.md` manda
  que toda rama de trabajo nazca de `develop`; nada lo comprobaba. Una `develop` que solo existe en local cumple la regla al ramificar y la
  incumple al abrir el PR: `gh pr create --base develop` falla con «Base ref must be a
  branch», y la salida obvia ante ese error —abrirlo contra `main`— es justo lo que la
  convención prohíbe. El fallo llegaba tarde y su arreglo aparente rompía el flujo.
- **`check-workflow-identity.sh` — que ningún workflow diga ser otro repositorio.** Los
  workflows exclusivos del repo-plantilla se filtran con
  `if: github.repository == 'usuario/repo'`. Al copiar uno entre repositorios esa
  condición viaja tal cual, y entonces el job no falla: **se salta**. En la lista de
  checks de un PR, un «skipping» gris se lee casi igual que un verde, así que una
  comprobación puede llevar meses sin ejecutarse ni una vez. Solo opina en el
  repo-plantilla: en una instancia, la condición nombra a la plantilla a propósito.

  Los dos son el mismo criterio dicho dos veces: **una regla que solo vive en la prosa
  no se cumple**, y un check que no corre es peor que uno que falla, porque el que falla
  avisa. El banco de pruebas pasa de 149 a 161 casos.

## [2.0.1] - 2026-09-07

### Fixed

- **El workflow de paridad no se ejecutaba nunca en esta variante.** Su condición `if`
  y el repositorio hermano seguían nombrando a las variantes con IA, así que el job
  aparecía como «skipping» en cada PR. Un check que no corre es peor que uno que falla:
  el segundo avisa. Ahora compara contra `project-starter-template-en`.
- **Los workflows apuntaban a skills que aquí no existen** (`/instanciar`,
  `/actualizar-plantilla`) y a `AGENTS.md`, que es de las variantes con IA. Ahora
  remiten a `TEMPLATE-USAGE.md` y al bloque «Uso» del README, que es lo que hay.

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
[Unreleased]: https://github.com/brayandiazc/project-starter-template-es/compare/v2.1.0...HEAD
[2.1.0]: https://github.com/brayandiazc/project-starter-template-es/compare/v2.0.1...v2.1.0
[2.0.1]: https://github.com/brayandiazc/project-starter-template-es/compare/v2.0.0...v2.0.1
[2.0.0]: https://github.com/brayandiazc/project-starter-template-es/compare/v1.4.0...v2.0.0
-->
