# Workflows de CI/CD

Workflows de [GitHub Actions](https://docs.github.com/actions) de este repositorio.

## Activos (agnósticos del stack)

Funcionan tal cual, sin importar el lenguaje del proyecto — no los borres al instanciar:

- [`quality.yml`](quality.yml) — salud de la documentación y del tooling: formato
  Markdown (Prettier), enlaces internos, placeholders, frontmatter de skills y agentes,
  colores crudos en las vistas, herencia de la plantilla, la suite de pruebas de
  [`../scripts/`](../scripts) y, en cada PR, la entrada en `CHANGELOG.md` bajo
  `## [Unreleased]` — el label `sin-changelog` es la excepción explícita. En los PRs
  hacia `main` añade el paso de release: nada llega a producción sin versión cortada.
- [`secret-scan.yml`](secret-scan.yml) — escaneo del historial con
  [gitleaks](https://github.com/gitleaks/gitleaks).
- [`release.yml`](release.yml) — al fusionar en `main`, crea el tag `vX.Y.Z` y el
  release de GitHub con las notas de esa sección del changelog. **No publica una versión
  heredada de la plantilla** (consulta `check-inheritance.sh --version-publicable`): un
  `main` publicado antes de resetear el CHANGELOG creaba un tag ajeno que luego hacía
  desaparecer en silencio la release propia.
- [`template-update-check.yml`](template-update-check.yml) — **solo actúa en proyectos
  instanciados** (necesita `.template-origin`). Semanalmente compara el tooling con el
  de la plantilla de origen y abre un issue si hay mejoras. Para aplicarlas, el
  apartado «Actualizar» de `TEMPLATE-USAGE.md`.

## Esqueleto incluido

- [`ci.yml.example`](ci.yml.example) — pipeline neutro (lint → test → build). La
  extensión `.example` va **al final a propósito**: GitHub ejecuta cualquier archivo
  `.yml`/`.yaml` que viva en esta carpeta, sin importar qué más lleve en el nombre.
  Al instanciar, renómbralo a `ci.yml` y sustituye los `[COMANDO_*]` por los de tu
  stack. Hasta entonces, el repositorio no ejecuta pruebas de código — solo las
  comprobaciones de documentación.

## Dos reglas de esta carpeta

**Si un archivo no debe ejecutarse, no puede terminar en `.yml` ni `.yaml`.** GitHub
ejecuta cualquiera que viva aquí, sin importar qué más lleve en el nombre. La suite de
pruebas lo verifica.

**Un job por workflow salvo que haya una razón medida para separarlo.** GitHub factura
cada job redondeando hacia arriba al minuto, así que nueve jobs de dos segundos cuestan
nueve minutos. `quality.yml` corría así y ahora es un solo job con `!cancelled()` en
cada paso —se siguen viendo todos los fallos de una vez— más `concurrency` con
`cancel-in-progress`. Separar solo tiene sentido cuando un paso tarda de verdad y
bloquea a los demás.

**Un run por cambio, no dos.** `quality.yml` se dispara **solo en `pull_request`**:
GitHub ejecuta esos eventos contra el _commit de merge simulado_, así que el run que
saltaba al fusionar comprobaba el mismo árbol otra vez. Era la mitad de los runs del
repositorio. `secret-scan.yml` sí conserva `push` en `main`, porque sin protección de
ramas nada impide técnicamente un push directo a producción y ahí el escaneo del
historial es un backstop real.

**El primer filtro es local.** El hook `.githooks/pre-push` corre estos mismos checks
en ~15 segundos antes de publicar, así que el CI es la red de seguridad y no el bucle
de verificación (ver `docs/conventions/quality-tooling.md`).

> **El coste de esto, dicho claro:** un commit que llegue a `develop` **sin pasar por
> un PR** ya no lo verifica nadie en el servidor. Lo impiden `git-guardrails.sh` (solo
> dentro de Claude Code) y `pre-push` (solo si ese clon tiene `core.hooksPath`
> configurado). Si algún día hay protección de ramas —requiere repo público o plan
> Pro—, esa es la barrera que cierra el hueco de verdad.

## Secrets

Defínelos en **Settings → Secrets and variables → Actions**. Los valores salen de
el gestor de credenciales — ver [`../../docs/conventions/secrets.md`](../../docs/conventions/secrets.md).
