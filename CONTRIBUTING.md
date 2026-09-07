# Guía de Contribución

Flujo de trabajo, branching y formato de commits de **[NOMBRE_DEL_PROYECTO]**. Al
participar aceptas el [Código de Conducta](CODE_OF_CONDUCT.md).

## Configuración del Entorno

Sigue las instrucciones de instalación del [README](README.md#instalación). Asegúrate de que los tests pasen localmente antes de empezar a trabajar.

Activa los git hooks del repositorio (**una vez por clon**; no viajan en el repo):

```bash
git config core.hooksPath .githooks
```

Dos hooks: **`pre-commit` formatea** lo que está en stage y lo vuelve a agregar —nunca
bloquea— y **`pre-push` corre los mismos checks que el CI** (~15 s) y **sí bloquea**. Con
eso llegas al PR sabiendo que va a pasar, que es lo que hace que el CI cueste un solo
run por feature.
Ver [`docs/conventions/quality-tooling.md`](docs/conventions/quality-tooling.md).

## Flujo de Trabajo

Usamos un flujo **Git Flow** simplificado.

### Estrategia de Branching

| Rama       | Propósito                                        | Origen    | Destino            |
| ---------- | ------------------------------------------------ | --------- | ------------------ |
| `main`     | Código en producción. Siempre estable.           | —         | —                  |
| `develop`  | Integración de funcionalidades. Pre-release.     | `main`    | `main`             |
| `feat/*`   | Nueva funcionalidad.                             | `develop` | `develop`          |
| `fix/*`    | Corrección de bug no urgente.                    | `develop` | `develop`          |
| `hotfix/*` | Corrección urgente en producción.                | `main`    | `main` y `develop` |
| `docs/*`   | Cambios solo de documentación.                   | `develop` | `develop`          |
| `chore/*`  | Tareas de mantenimiento, tooling, configuración. | `develop` | `develop`          |

### Flujo de una funcionalidad

```bash
# 1. Parte de develop actualizado
git checkout develop
git pull origin develop

# 2. Crea tu rama
git checkout -b feat/nombre-descriptivo

# 3. Trabaja y commitea (ver formato abajo)
git add .
git commit -m "feat: agrega X"

# 4. Sube tu rama las veces que haga falta — esto NO consume CI
git push origin feat/nombre-descriptivo

# 5. Cuando la feature esté terminada, abre el PR hacia develop
```

> **Abre el PR cuando la feature esté lista, no al empezar.** Los workflows solo se
> disparan con `push` en `main`/`develop` y con eventos de PR: mientras no exista el
> PR, empujar a tu rama **cuesta cero CI**. Con el PR abierto, en cambio, cada push
> vuelve a lanzar la tanda completa. Si necesitas abrirlo antes para ir anotando, usa
> un **draft**.

### Flujo de hotfix

Los hotfix parten de `main`, se mergean a `main` y luego se sincronizan a `develop`.
Como van directo a producción, **también publican versión** (siempre un `patch`): el
corte se hace en la propia rama de hotfix, antes del PR.

```bash
git checkout main
git pull origin main
git checkout -b hotfix/descripcion-del-fix
# ... fix + commit ...
# entrada en CHANGELOG.md (Unreleased → Fixed) y corte de versión
git push origin hotfix/descripcion-del-fix
# PR hacia main → al fusionar, release.yml publica el tag y el release
# y después: PR main → develop para sincronizar el fix y el CHANGELOG
```

### Releases

Cada merge a `main` publica una versión. El corte se hace **antes** de fusionar, con la
mano (mueve `## [Unreleased]` a `## [X.Y.Z] - fecha` y sincroniza la versión del
manifiesto si el stack tiene uno); al llegar a `main`, el workflow
`release.yml` crea el tag `vX.Y.Z` y el release de GitHub con las notas de esa sección.

El job `release` de `quality.yml` bloquea los PRs hacia `main` en tres casos: si la
versión de arriba ya está publicada, si quedan entradas sueltas en `## [Unreleased]`, o
si esa versión es **heredada de la plantilla** y no del proyecto. **Nada llega a
producción sin versión, y ninguna versión es de otro repositorio.**

**Tras fusionar el release, sincroniza `develop`**: el merge commit del PR la deja
detrás de `main` y GitHub empieza a sugerir un PR vacío. Como no hay contenido nuevo,
basta un fast-forward (no crea historial y el guardrail lo permite):

```bash
git checkout develop && git pull --ff-only origin main
```

Eso sincroniza tu `develop` **local**; la de GitHub sigue detrás hasta que alguien la
mueva. Un push desde `develop` está bloqueado (hook y política), así que el
fast-forward del remoto se hace por la API — sin `force`, el servidor solo acepta
fast-forwards, que es exactamente la garantía que queremos:

```bash
gh api -X PATCH repos/[USUARIO_GITHUB]/[SLUG_REPOSITORIO]/git/refs/heads/develop \
  -f sha="$(git rev-parse origin/main)" -F force=false
```

Si el fast-forward no es posible es que las ramas divergieron (p. ej. un hotfix):
entonces sí, PR `main` → `develop`, como en el flujo de hotfix.

### Nombrado de ramas

- En minúsculas, con prefijo de tipo y descripción en `kebab-case`: `feat/login-google`, `fix/timeout-pagos`, `docs/actualizar-readme`.

### Políticas de ramas

- **`develop` es la rama por defecto del repositorio en GitHub**: los PRs nuevos y los
  de Dependabot apuntan ahí; `main` solo recibe merges de `develop` (release) o
  `hotfix/*`.
- `main` y `develop` están protegidas: no se permite push directo, solo vía PR aprobado.
- Mantén tu rama actualizada con `develop` (rebase o merge) antes de abrir el PR.

## Estándares de Código

Formato e indentación los fija [`.editorconfig`](.editorconfig) y el linter; el estilo
por lenguaje, [`docs/conventions/`](docs/conventions/README.md). Lo único que no puede
automatizarse: **comenta el _por qué_, no el _qué_**, y enlaza al ADR cuando la decisión
no sea obvia.

## Commits y Mensajes

Usamos [Conventional Commits](https://www.conventionalcommits.org/es/v1.0.0/):

```
<tipo>(<ámbito opcional>): <descripción breve en imperativo>

<cuerpo opcional>

<footer opcional: BREAKING CHANGE, Closes #123>
```

Tipos comunes: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`.

Ejemplos:

```
feat(auth): agrega login con Google
fix(api): corrige timeout en el endpoint de pagos
docs: actualiza la guía de instalación
```

## Pull Requests

- Usa la [plantilla de PR](.github/PULL_REQUEST_TEMPLATE.md) (se carga automáticamente).
- Un PR por cambio lógico; mantenlos pequeños y enfocados.
- Vincula los issues relacionados (`Closes #123`).
- Asegúrate de que CI pase (tests, linting, build).

## Revisión

Una persona es responsable de cada merge: no implica leer cada línea, implica que nadie
más carga con el resultado.

Lo que **sí** se revisa siempre a mano es el **esquema de datos**. Es poco (una migración,
un archivo de esquema), es lo más caro de cambiar después, y es lo único que ni los tests
ni el monitoreo detectan: un modelo de datos mal pensado pasa todos los tests y no genera
un solo error en el monitor.

## Testing

- Acompaña cada cambio funcional con tests.
- Ejecuta la suite completa antes de abrir el PR (el comando está en el bloque «Uso»
  del [README](README.md#uso)).
- Sigue las [convenciones de testing](docs/conventions/testing.md).

## Nada sin documentar

Todo cambio actualiza `CHANGELOG.md` y los `docs/` afectados **en el mismo PR** que el
código; toda decisión difícil de revertir deja un [ADR](docs/decisions/README.md); y el
PR que implementa algo marca su ítem en [`docs/product/roadmap.md`](docs/product/roadmap.md).
Los tres viajan en el mismo commit-set: el estado del proyecto es lo que está fusionado,
no lo que se prometió.

No es una recomendación: el job `changelog` de `quality.yml` lo verifica en cada PR. Sin
entrada bajo `## [Unreleased]`, el CI falla; la excepción se pide con la label
`sin-changelog` y una razón escrita.
