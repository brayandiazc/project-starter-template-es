#!/usr/bin/env bash
# check-changelog.sh — hace verificable la regla "nada sin documentar": todo PR
# que cambie algo del proyecto debe traer su entrada en CHANGELOG.md bajo
# `## [Unreleased]` (docs/conventions/workflow.md, regla 5).
#
# Qué se considera suficiente:
#   - el PR modifica CHANGELOG.md, Y
#   - la sección `## [Unreleased]` tiene al menos una viñeta,
#   - o el PR es un corte de versión (añade `## [X.Y.Z] - YYYY-MM-DD`), que deja
#     Unreleased vacío a propósito.
#
# Exenciones:
#   - PRs que solo tocan el propio CHANGELOG.md.
#   - PRs con la label `sin-changelog` (pásala en PR_LABELS, separada por comas).
#
# Uso:
#   bash .github/scripts/check-changelog.sh [base-ref] [raíz-del-repo]
#   PR_LABELS="sin-changelog,docs" bash .github/scripts/check-changelog.sh main
#
# Requiere: git. Sale con 1 si falta la entrada. Ante un base-ref irresoluble
# falla ABIERTO (exit 0): el CI no es el lugar para adivinar el diff.
set -euo pipefail

BASE_REF="${1:-}"
ROOT="${2:-.}"
cd "$ROOT"

CHANGELOG="CHANGELOG.md"
SKIP_LABEL="sin-changelog"

# Rutas cuyo cambio, POR SÍ SOLO, no exige entrada en el changelog.
EXEMPT='^(CHANGELOG\.md$)'

# ── Salidas tempranas ────────────────────────────────────────────────────────
if [ ! -f "$CHANGELOG" ]; then
  echo "ℹ️  No hay $CHANGELOG en el repo; nada que verificar."
  exit 0
fi

case ",${PR_LABELS:-}," in
  *",$SKIP_LABEL,"*)
    echo "ℹ️  Label '$SKIP_LABEL' presente: se omite la verificación del changelog."
    exit 0
    ;;
esac

# Base de comparación: la que se pase, o la primera rama base que resuelva.
if [ -z "$BASE_REF" ]; then
  for candidate in origin/develop develop origin/main main; do
    if git rev-parse --verify -q "$candidate" >/dev/null; then
      BASE_REF="$candidate"
      break
    fi
  done
fi

if [ -z "$BASE_REF" ] || ! git rev-parse --verify -q "$BASE_REF" >/dev/null; then
  echo "ℹ️  No se pudo resolver la rama base ('${BASE_REF:-ninguna}'); se omite la verificación."
  exit 0
fi

# ── ¿Qué cambió respecto de la base? ─────────────────────────────────────────
# Tres puntos: solo lo que aporta esta rama desde que se separó de la base.
changed="$(git diff --name-only "$BASE_REF...HEAD" 2>/dev/null || true)"

if [ -z "$changed" ]; then
  echo "✅ Changelog: no hay cambios respecto de $BASE_REF."
  exit 0
fi

notable="$(printf '%s\n' "$changed" | grep -Ev "$EXEMPT" || true)"
if [ -z "$notable" ]; then
  echo "✅ Changelog: el PR solo toca el propio $CHANGELOG — exento."
  exit 0
fi

# ── La regla ─────────────────────────────────────────────────────────────────
if ! printf '%s\n' "$changed" | grep -qx "$CHANGELOG"; then
  echo "❌ Este PR cambia el proyecto pero no toca $CHANGELOG."
  echo "   Archivos que lo exigen (primeros 10):"
  printf '%s\n' "$notable" | head -10 | sed 's/^/     · /'
  echo "→ Añade la entrada bajo '## [Unreleased]' (skill /changelog). Si de verdad"
  echo "  no hay nada que contar, ponle al PR la label '$SKIP_LABEL' y explica por qué."
  exit 1
fi

# Corte de versión: mover Unreleased a `## [X.Y.Z] - fecha` la deja vacía a propósito.
if git diff "$BASE_REF...HEAD" -- "$CHANGELOG" \
  | grep -qE '^\+## \[[0-9]+\.[0-9]+\.[0-9]+\] - [0-9]{4}-[0-9]{2}-[0-9]{2}'; then
  echo "✅ Changelog: corte de versión detectado."
  exit 0
fi

# Contenido actual de la sección Unreleased (hasta el siguiente encabezado `## [`).
unreleased="$(awk '/^## \[Unreleased\]/ {f=1; next} /^## \[/ {f=0} f' "$CHANGELOG")"

if ! printf '%s\n' "$unreleased" | grep -qE '^[-*] '; then
  echo "❌ $CHANGELOG cambió, pero la sección '## [Unreleased]' no tiene ninguna entrada."
  echo "→ Escribe qué cambió para quien usa el proyecto, bajo la categoría que corresponda"
  echo "  (Added / Changed / Deprecated / Removed / Fixed / Security)."
  exit 1
fi

echo "✅ Changelog: hay entrada bajo '## [Unreleased]'."
