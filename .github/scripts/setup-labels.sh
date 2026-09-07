#!/bin/bash

# Script para crear labels en GitHub usando gh CLI.
# Los labels se LEEN de las tablas de ../LABELS.md — ese archivo es la fuente de
# verdad y aquí no hay ninguna copia: antes estaban duplicados en ambos lados y
# ya habían divergido sin que nada lo detectara.
# Requiere: GitHub CLI (gh) instalado y autenticado.
# Uso: bash .github/scripts/setup-labels.sh

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}=== Configuración de Labels para GitHub ===${NC}\n"

if ! command -v gh &> /dev/null; then
	echo -e "${YELLOW}Error: GitHub CLI (gh) no está instalado.${NC}"
	echo "Instálalo desde: https://cli.github.com/"
	exit 1
fi

if ! gh auth status &> /dev/null; then
	echo -e "${YELLOW}Error: No estás autenticado en GitHub CLI.${NC}"
	echo "Ejecuta: gh auth login"
	exit 1
fi

REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)

if [ -z "$REPO" ]; then
	echo -e "${YELLOW}Error: No se pudo detectar el repositorio.${NC}"
	echo "Ejecuta este script desde el directorio del repositorio."
	exit 1
fi

echo -e "${GREEN}Configurando labels para: $REPO${NC}\n"

create_label() {
  local name=$1
  local color=$2
  local description=$3
  echo -e "Creando label: ${BLUE}$name${NC}"
  gh label create "$name" --color "$color" --description "$description" --force 2>/dev/null || true
}

# ── Leer los labels de las tablas de LABELS.md ───────────────────────────────
# Cada fila es `| `nombre` | `#HEX` | texto |`; la tercera columna hace de
# descripción (GitHub la corta a 100 caracteres, aquí también).
LABELS_MD="$(cd "$(dirname "$0")" && pwd)/../LABELS.md"

if [ ! -f "$LABELS_MD" ]; then
	echo -e "${YELLOW}Error: no se encontró $LABELS_MD (la fuente de verdad de los labels).${NC}"
	exit 1
fi

total=0
while IFS= read -r fila; do
	name="$(sed -E 's/^\|[[:space:]]*`([^`]+)`.*/\1/' <<<"$fila")"
	color="$(sed -E 's/.*`#([0-9A-Fa-f]{6})`.*/\1/' <<<"$fila")"
	desc="$(awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $4); print $4}' <<<"$fila" | tr -d '\140' | cut -c1-100)"
	create_label "$name" "$color" "$desc"
	total=$((total + 1))
done < <(grep -E '^\| *`[^`]+` *\| *`#[0-9A-Fa-f]{6}` *\|' "$LABELS_MD")

if [ "$total" -eq 0 ]; then
	echo -e "${YELLOW}Error: no se encontró ninguna fila de label en LABELS.md.${NC}"
	exit 1
fi

echo -e "\n${GREEN}$total labels configurados exitosamente!${NC}"
echo -e "\nVer labels en: ${BLUE}https://github.com/$REPO/labels${NC}\n"
