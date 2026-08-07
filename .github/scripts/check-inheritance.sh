#!/usr/bin/env bash
# check-herencia.sh — un proyecto instanciado no arrastra la vida de la plantilla.
#
# Todo lo de producto (specs/, roadmap, definición) llega vacío al usuario, pero el
# CHANGELOG y los ADRs se colaban llenos del historial del repositorio origen. Este
# check lo impide, y usa un criterio determinista en vez de heurísticas de texto:
#
#   `.template-origin` guarda la FECHA de instanciación. Un proyecto creado el día X
#   no puede tener versiones publicadas ni decisiones tomadas antes del día X. Lo que
#   esté fechado antes, es herencia y sobra.
#
# Verifica tres cosas:
#   1. CHANGELOG.md sin versiones anteriores a la instanciación.
#   2. docs/decisions/ sin ADRs anteriores a la instanciación (salvo el 0001, que es
#      el ADR canónico sobre por qué se registran las decisiones: ese sí se hereda).
#   3. Sin los archivos exclusivos del repo-plantilla.
#
# Uso:
#   bash .github/scripts/check-herencia.sh [raíz-del-repo]
#
# En la plantilla misma no hay `.template-origin`, así que no impone nada: solo
# actúa en proyectos ya instanciados. Sale con 1 si encuentra herencia.
set -euo pipefail

ROOT="${1:-.}"
cd "$ROOT"

ORIGEN=".template-origin"

if [ ! -f "$ORIGEN" ]; then
  echo "ℹ️  Sin $ORIGEN: esto no es un proyecto instanciado. Nada que verificar."
  exit 0
fi

fecha="$(grep -m1 '^fecha=' "$ORIGEN" | cut -d= -f2- | tr -d '[:space:]' || true)"

if ! printf '%s' "$fecha" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'; then
  echo "ℹ️  $ORIGEN no trae una fecha válida ('${fecha:-vacía}'); se omite la verificación."
  exit 0
fi

fail=0

# ── 1. Versiones heredadas en el CHANGELOG ───────────────────────────────────
if [ -f CHANGELOG.md ]; then
  heredadas="$(grep -E '^## \[[0-9]+\.[0-9]+\.[0-9]+\] - [0-9]{4}-[0-9]{2}-[0-9]{2}' CHANGELOG.md \
    | awk -v f="$fecha" '{ if ($NF < f) print "   · " $0 }' || true)"
  if [ -n "$heredadas" ]; then
    echo "❌ El CHANGELOG arrastra versiones anteriores a la instanciación ($fecha):"
    printf '%s\n' "$heredadas"
    echo "→ Son de la plantilla, no de tu proyecto. Deja el CHANGELOG con tu propia"
    echo "  primera versión; la historia de la plantilla vive en su repositorio."
    fail=1
  fi
fi

# ── 2. ADRs heredados ────────────────────────────────────────────────────────
# Se exceptúa el 0001: es el ADR canónico sobre por qué se registran decisiones,
# y su sitio es cualquier proyecto que use ADRs.
if [ -d docs/decisions ]; then
  adrs=""
  for f in docs/decisions/*.md; do
    [ -f "$f" ] || continue
    case "$(basename "$f")" in
      0000-template.md | 0001-record-architecture-decisions.md | README.md) continue ;;
    esac
    d="$(grep -m1 -oE '\*\*Fecha\*\*:[[:space:]]*[0-9]{4}-[0-9]{2}-[0-9]{2}' "$f" \
      | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' || true)"
    [ -z "$d" ] && continue
    if [ "$d" \< "$fecha" ]; then
      adrs="$adrs   · $f (fecha: $d)"$'\n'
    fi
  done
  if [ -n "$adrs" ]; then
    echo "❌ Hay ADRs anteriores a la instanciación ($fecha):"
    printf '%s' "$adrs"
    echo "→ Son decisiones de la plantilla, no tuyas. Retíralos: el ADR de"
    echo "  instanciación ya documenta qué se heredó y enlaza al repositorio origen."
    fail=1
  fi
fi

# ── 3. Archivos exclusivos del repo-plantilla ────────────────────────────────
declare -a sobrantes=()
for ruta in \
  ".github/workflows/template-parity.yml" \
  ".github/scripts/check-parity.sh"; do
  [ -e "$ruta" ] && sobrantes+=("$ruta")
done

if [ "${#sobrantes[@]}" -gt 0 ]; then
  echo "❌ Quedan archivos que solo tienen sentido en el repo-plantilla:"
  printf '   · %s\n' "${sobrantes[@]}"
  echo "→ Bórralos (regla de poda de /instanciar): mantienen la paridad entre las"
  echo "  variantes de la plantilla, algo que tu proyecto no necesita."
  fail=1
fi

if [ "$fail" -ne 0 ]; then
  exit 1
fi

echo "✅ Herencia: el proyecto no arrastra historial ni archivos de la plantilla."
