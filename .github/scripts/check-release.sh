#!/usr/bin/env bash
# check-release.sh — nada llega a producción sin versión.
#
# Se ejecuta en los PRs hacia `main` (el merge que publica). Verifica dos cosas
# que el workflow release.yml da por hechas y no puede exigir por sí mismo —
# cuando él corre, el merge ya ocurrió:
#
#   1. La versión de arriba del CHANGELOG está SIN publicar (no tiene tag).
#      Si ya tiene tag, este merge no publicaría nada: release.yml lo daría por
#      hecho y el cambio entraría a producción sin versión, en silencio.
#   2. `## [Unreleased]` está vacía. Si tiene entradas, hay trabajo que llegaría
#      a main fuera de toda versión. El corte se hace al final, justo antes de
#      fusionar.
#
# Uso:
#   bash .github/scripts/check-release.sh [raíz-del-repo]
#
# Requiere: git (con los tags disponibles: checkout con fetch-depth 0).
# Sale con 1 si falta cortar la versión. Sin CHANGELOG.md no impone nada.
set -euo pipefail

# La ruta del script se resuelve ANTES del cd: después, $0 apunta a otro sitio.
SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ROOT="${1:-.}"
cd "$ROOT"

CHANGELOG="CHANGELOG.md"

if [ ! -f "$CHANGELOG" ]; then
  echo "ℹ️  No hay $CHANGELOG en el repo; nada que verificar."
  exit 0
fi

# ── 1. ¿Hay una versión cortada y sin publicar? ──────────────────────────────
# Solo cuentan las versiones con fecha real (ignora plantillas tipo "[FECHA]"),
# igual que hace release.yml.
line="$(grep -m1 -E '^## \[[0-9]+\.[0-9]+\.[0-9]+\] - [0-9]{4}-[0-9]{2}-[0-9]{2}' "$CHANGELOG" || true)"

if [ -z "$line" ]; then
  echo "❌ El $CHANGELOG no tiene ninguna versión fechada."
  echo "→ Corta la versión con /release (mueve '## [Unreleased]' a '## [X.Y.Z] - $(date +%F)')"
  echo "  antes de fusionar a main. Sin eso, release.yml no publica nada."
  exit 1
fi

version="$(sed -E 's/^## \[([0-9]+\.[0-9]+\.[0-9]+)\].*/\1/' <<<"$line")"

# ¿Y es una versión de este proyecto? Un CHANGELOG sin resetear deja arriba la
# última versión de la plantilla, y fusionar eso a main la publicaría como propia.
# El criterio no se repite aquí: lo decide check-inheritance.sh.
if ! bash "$SCRIPTS/check-inheritance.sh" --version-publicable .; then
  echo "→ Este merge publicaría la release de la plantilla, no la tuya."
  exit 1
fi

if git rev-parse -q --verify "refs/tags/v$version" >/dev/null; then
  echo "❌ La versión de arriba del $CHANGELOG (v$version) ya está publicada."
  echo "→ Este merge llegaría a producción sin versión propia: release.yml vería"
  echo "  v$version, la daría por publicada y no crearía ningún release."
  echo "  Corta una versión nueva con /release antes de fusionar."
  exit 1
fi

# ── 2. ¿Queda trabajo fuera de la versión? ───────────────────────────────────
unreleased="$(awk '/^## \[Unreleased\]/ {f=1; next} /^## \[/ {f=0} f' "$CHANGELOG")"

if printf '%s\n' "$unreleased" | grep -qE '^[-*] '; then
  echo "❌ v$version está cortada, pero '## [Unreleased]' todavía tiene entradas:"
  printf '%s\n' "$unreleased" | grep -E '^[-*] ' | sed -n '1,5s|^|   · |p'
  echo "→ Ese trabajo llegaría a main fuera de toda versión. Inclúyelo en el corte"
  echo "  (vuelve a correr /release) o déjalo en develop para la siguiente."
  exit 1
fi

echo "✅ Release: v$version está cortada, sin publicar y sin trabajo suelto en Unreleased."
