#!/usr/bin/env bash
# check-placeholders.sh — verifica los placeholders `[ASÍ]` de la plantilla.
#
# Dos modos, autodetectados:
#   - Modo PLANTILLA (existe TEMPLATE-USAGE.md): todo placeholder usado en el
#     repo debe estar documentado en el catálogo de TEMPLATE-USAGE.md (§3),
#     de forma literal o cubierto por un comodín como `[COMANDO_*]`.
#   - Modo INSTANCIA (TEMPLATE-USAGE.md ya fue borrado): no debe quedar ningún
#     placeholder sin rellenar, salvo en los esqueletos intencionales.
#
# Uso:
#   bash .github/scripts/check-placeholders.sh [raíz-del-repo]
#
# Requiere: git, perl. Sale con 1 si encuentra problemas.
set -euo pipefail

ROOT="${1:-.}"
cd "$ROOT"

CATALOG="TEMPLATE-USAGE.md"

# Rutas que se saltan en ambos modos:
#   - esqueletos que conservan placeholders a propósito (plantillas de docs);
#   - .github/ (sus corchetes son prefijos de títulos de issue como "[BUG] …").
SKIP='^(\.github/|docs/conventions/_template\.md|docs/decisions/0000-template\.md)'

# Menciones "meta" sobre el propio sistema de placeholders (no son placeholders
# que haya que rellenar; aparecen en instrucciones de la plantilla).
META='^(PLACEHOLDER|PLACEHOLDERS|CORCHETES_EN_MAYÚSCULAS)$'

# Extrae placeholders [MAYÚSCULAS] de un archivo, ignorando los enlaces
# markdown `[TEXTO](destino)` gracias al lookahead negativo.
extract() {
  perl -CSD -ne 'while (/\[([A-ZÁÉÍÓÚÑ0-9_\/]{2,})\](?!\()/g) { print "$ARGV:$.: [$1]\n" }' "$1"
}

files() {
  git ls-files '*.md' '.env.example' | grep -Ev "$SKIP" || true
}

if [ -f "$CATALOG" ]; then
  # ── Modo PLANTILLA: consistencia del catálogo ──────────────────────────────
  # Prefijos comodín documentados en el catálogo, p. ej. `[COMANDO_*]` → COMANDO_.
  wildcards="$(perl -CSD -ne 'while (/\[([A-ZÁÉÍÓÚÑ0-9_\/]+_)\*\]/g) { print "$1\n" }' "$CATALOG" | sort -u)"

  missing=0
  placeholders="$(
    files | grep -v "^$CATALOG$" | while IFS= read -r f; do extract "$f"; done \
      | sed -E 's/^.*\[([^]]+)\]$/\1/' | sort -u
  )"

  while IFS= read -r p; do
    [ -z "$p" ] && continue
    printf '%s' "$p" | grep -Eq "$META" && continue
    grep -qF "[$p]" "$CATALOG" && continue
    covered=0
    while IFS= read -r w; do
      [ -n "$w" ] && case "$p" in "$w"*) covered=1 ;; esac
    done <<<"$wildcards"
    [ "$covered" -eq 1 ] && continue
    echo "❌ [$p] se usa en el repo pero no está en el catálogo de $CATALOG (§3)."
    missing=1
  done <<<"$placeholders"

  if [ "$missing" -ne 0 ]; then
    echo "→ Añade los placeholders faltantes al catálogo de $CATALOG."
    exit 1
  fi
  echo "✅ Placeholders: todos los usados están documentados en el catálogo."
else
  # ── Modo INSTANCIA: no deben quedar placeholders sin rellenar ──────────────
  leftovers="$(files | while IFS= read -r f; do extract "$f"; done || true)"
  # También aquí las menciones meta no cuentan como pendientes.
  leftovers="$(printf '%s' "$leftovers" | grep -Ev '\[(PLACEHOLDER|PLACEHOLDERS|CORCHETES_EN_MAYÚSCULAS)\]' || true)"

  if [ -n "$leftovers" ]; then
    echo "❌ Quedan placeholders sin rellenar:"
    printf '%s\n' "$leftovers"
    echo "→ Rellénalos o borra el documento si no aplica (la plantilla original trae la guía en TEMPLATE-USAGE.md)."
    exit 1
  fi
  echo "✅ Placeholders: no queda ninguno sin rellenar."
fi
