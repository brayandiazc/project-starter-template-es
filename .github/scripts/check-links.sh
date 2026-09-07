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
scanned=0
ausentes=0

while IFS= read -r f; do
  # Se enumera lo trazado Y lo que existe sin trazar (`--others`), porque los dos casos
  # aparecen de verdad: al podar quedan archivos trazados que ya no existen, y al adoptar
  # la plantilla en un proyecto existente quedan archivos que existen y aún no se trazan.
  # `git ls-files` a secas solo veía los primeros.
  #
  # De ahí esta guarda: un archivo trazado y borrado con `rm` sigue saliendo en la lista.
  # Sin esta guarda, perl fallaba al abrirlo, escupía su error crudo por stderr y
  # el bucle continuaba — el archivo no se revisaba y el resumen final decía que
  # todo estaba bien. Un fallo en silencio dentro del propio guardrail.
  if [ ! -f "$f" ]; then
    ausentes=$((ausentes + 1))
    continue
  fi
  scanned=$((scanned + 1))
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
  # Se salta el código —en línea y en vallas— antes de buscar: un documento que CITA
  # una expresión regular o un fragmento de markdown no está enlazando a nada. Pasaba
  # de verdad: una bitácora que citaba `](?!\()` dejaba el check en rojo.
  done < <(perl -CSD -ne '
      if (/^\s*```/) { $valla = !$valla; next }
      next if $valla;
      s/`[^`]*`//g;
      while (/\]\(([^)\s]+)\)/g) { print "$1\n" }
    ' "$f")
done < <(git ls-files --cached --others --exclude-standard '*.md' | sort -u)

if [ "$ausentes" -gt 0 ]; then
  echo "ℹ️  $ausentes archivo(s) trazados por git ya no están en disco: no se revisaron."
  echo "   Es normal a mitad de una poda; confírmalo con 'git status' antes de commitear."
fi

if [ "$broken" -ne 0 ]; then
  echo "→ Corrige las rutas o borra los enlaces a documentos eliminados."
  exit 1
fi
# El número no es cosmético: un "✅ todos" nunca avisa de nada, pero un conteo que
# baja de 87 a 71 sin motivo sí se nota.
echo "✅ Enlaces internos: $scanned archivo(s) revisados, todos los destinos existen."
