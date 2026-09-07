#!/usr/bin/env bash
# check-workflow-identity.sh — un workflow que dice ser otro repositorio no corre.
#
# Los workflows exclusivos del repo-plantilla se filtran con
# `if: github.repository == 'usuario/repo'` para no ejecutarse en los proyectos
# instanciados. Al copiar uno entre repositorios, esa condición viaja tal cual:
# el job comprueba un repositorio que no es el suyo y **se salta**.
#
# Y ahí está el problema: no falla, se salta. En la lista de checks de un PR un
# «skipping» gris se lee casi igual que un verde, así que la comprobación puede
# llevar meses sin ejecutarse ni una vez sin que nadie lo note. Un check que no
# corre es peor que uno que falla, porque el que falla avisa.
#
# Solo opina en el REPO-PLANTILLA, que es donde esas condiciones se escriben a
# mano; lo reconoce por TEMPLATE-USAGE.md. En un proyecto instanciado la
# condición nombra a la plantilla A PROPÓSITO: es lo que impide que el workflow
# corra ahí, y acusarlo sería exactamente al revés.
#
# Uso:
#   bash .github/scripts/check-workflow-identity.sh [raíz-del-repo]
#
# Falla ABIERTO: fuera del repo-plantilla, o si no se puede saber qué
# repositorio es este, no opina. Sale con 1 si alguna condición nombra a otro.
set -uo pipefail

ROOT="${1:-.}"
cd "$ROOT" || exit 0

[ -f TEMPLATE-USAGE.md ] || {
  echo "ℹ️  Sin TEMPLATE-USAGE.md: esto no es el repo-plantilla; nada que verificar."
  exit 0
}

[ -d .github/workflows ] || {
  echo "ℹ️  No hay .github/workflows/; nada que verificar."
  exit 0
}

# En Actions el nombre viene dado; en local se deduce del remoto.
SLUG="${GITHUB_REPOSITORY:-}"
if [ -z "$SLUG" ]; then
  url="$(git remote get-url origin 2>/dev/null || true)"
  # Sirven las dos formas: git@host:usuario/repo.git y https://host/usuario/repo
  SLUG="$(printf '%s' "$url" | perl -ne 's/\.git$//; print "$1/$2\n" if m{[:/]([^/:]+)/([^/]+)$}')"
fi

if [ -z "$SLUG" ]; then
  echo "ℹ️  No se pudo determinar el repositorio (sin remoto ni GITHUB_REPOSITORY); se omite."
  exit 0
fi

fallos=0
condiciones=0

while IFS= read -r archivo; do
  # Cada condición `github.repository ==` con un slug literal, con su línea.
  while IFS=: read -r linea nombrado; do
    [ -n "$nombrado" ] || continue
    condiciones=$((condiciones + 1))
    if [ "$nombrado" != "$SLUG" ]; then
      if [ "$fallos" -eq 0 ]; then
        echo "❌ Hay workflows que dicen ser otro repositorio:"
      fi
      echo "   · $archivo:$linea → github.repository == '$nombrado'"
      fallos=$((fallos + 1))
    fi
  done < <(perl -ne 'print "$.:$1\n" if /github\.repository\s*==\s*[\x27"]([^\x27"]+)[\x27"]/' "$archivo")
done < <(find .github/workflows -maxdepth 1 -type f \( -name '*.yml' -o -name '*.yaml' -o -name '*.yml.example' \) | sort)

if [ "$fallos" -gt 0 ]; then
  echo
  echo "→ Este repositorio es '$SLUG'. Una condición que nombra a otro no falla:"
  echo "  el job se SALTA, y en la lista de checks un «skipping» gris se lee casi"
  echo "  igual que un verde. Cámbiala por '$SLUG' o borra el workflow si aquí"
  echo "  no pinta nada."
  exit 1
fi

if [ "$condiciones" -eq 0 ]; then
  echo "✅ Identidad de los workflows: ninguno se filtra por repositorio."
else
  echo "✅ Identidad de los workflows: $condiciones condición(es), todas dicen ser '$SLUG'."
fi
exit 0
