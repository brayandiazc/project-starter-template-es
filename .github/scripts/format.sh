#!/bin/bash

# Formatea con Prettier todos los archivos del repo que él entiende sin plugins:
# Markdown, HTML, CSS, JSON y YAML. El código de la aplicación NO se toca aquí —
# ese lo formatea el linter del stack (ver docs/conventions/quality-tooling.md).
#
# No requiere instalar Prettier: lo ejecuta vía npx (necesita Node.js).
#
# LA VERSIÓN VA FIJA, y no es por rendimiento. Un `prettier@3` flotante resuelve a
# un minor distinto según el día, y un formateador que cambia de versión cambia su
# salida: el mismo archivo pasa en una máquina y falla en el CI, o un PR que no iba
# de eso reformatea medio repositorio. Es un fallo de reproducibilidad.
#
# El efecto secundario es que deja de doler: `npx` cachea por especificador exacto,
# así que solo la primera llamada resuelve. Con `@3` cada invocación volvía a
# resolver, y el `pre-commit` la llama cuatro veces — el `pre-push` entero se iba a
# minutos y parecía colgado.
#
# Para subirla: cambia esta línea, corre el script y commitea el reformateo aparte.
# No corre prisa —una versión vieja formatea como el año pasado, no rompe nada— pero
# revísala cuando salga un major.
PRETTIER="prettier@3.9.6"
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
npx --yes "$PRETTIER" "$MODE" "**/*.{md,html,css,json,yml,yaml}"
echo "Listo."
