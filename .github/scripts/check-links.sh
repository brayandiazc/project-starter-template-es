#!/usr/bin/env bash
# check-links.sh — verifica que los enlaces relativos entre archivos del repo
# apunten a archivos que existen. No revisa URLs externas (http/https/mailto)
# ni destinos con placeholders `[ASÍ]` — solo la red de enlaces internos.
#
# Uso:
#   bash .github/scripts/check-links.sh [raíz-del-repo]
#
# Requiere: git, perl. Sale con 1 si hay enlaces rotos.
set -euo pipefail

ROOT="${1:-.}"
cd "$ROOT"

broken=0

while IFS= read -r f; do
  dir="$(dirname "$f")"
  while IFS= read -r target; do
    case "$target" in
      http://*|https://*|mailto:*) continue ;;   # externos: fuera de alcance
      *'['*) continue ;;                          # contiene un placeholder
      '') continue ;;
    esac
    # Quitar el fragmento #ancla si lo hay.
    path="${target%%#*}"
    [ -z "$path" ] && continue
    if [ ! -e "$dir/$path" ] && [ ! -e "$path" ]; then
      echo "❌ $f: enlace roto → $target"
      broken=1
    fi
  done < <(perl -CSD -ne 'while (/\]\(([^)\s]+)\)/g) { print "$1\n" }' "$f")
done < <(git ls-files '*.md')

if [ "$broken" -ne 0 ]; then
  echo "→ Corrige las rutas o borra los enlaces a documentos eliminados."
  exit 1
fi
echo "✅ Enlaces internos: todos apuntan a archivos existentes."
