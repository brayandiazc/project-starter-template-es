#!/bin/bash

# Formatea con Prettier todos los archivos del repo que él entiende sin plugins:
# Markdown, HTML, CSS, JSON y YAML. El código de la aplicación NO se toca aquí —
# ese lo formatea el linter del stack (ver docs/conventions/quality-tooling.md).
#
# No requiere instalar Prettier: lo ejecuta vía npx (necesita Node.js).
#
# Uso:
#   bash .github/scripts/format.sh          # formatea (--write)
#   bash .github/scripts/format.sh --check  # solo verifica, no escribe

set -e

MODE="--write"
if [ "$1" = "--check" ]; then
	MODE="--check"
fi

if ! command -v npx &> /dev/null; then
	echo "Error: se necesita Node.js (npx) para ejecutar Prettier." >&2
	echo "Instálalo desde https://nodejs.org/" >&2
	exit 1
fi

echo "Ejecutando Prettier ($MODE) sobre Markdown, HTML, CSS, JSON y YAML…"
npx --yes prettier@3 "$MODE" "**/*.{md,html,css,json,yml,yaml}"
echo "Listo."
