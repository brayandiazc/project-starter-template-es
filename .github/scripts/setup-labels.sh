#!/bin/bash

# Script para crear labels en GitHub usando gh CLI.
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

# ── Labels automáticos (usados por labeler.yml) ──────────────────────────────
echo -e "\n${GREEN}Labels automáticos (labeler)${NC}"
create_label "documentation" "0075CA" "Cambios en documentación"
create_label "frontend"      "0052CC" "Cambios en UI / cliente"
create_label "styles"        "BFD4F2" "Cambios en CSS / estilos"
create_label "backend"       "006B75" "Cambios en servidor / API / lógica"
create_label "database"      "5319E7" "Migraciones, esquema o seeds"
create_label "testing"       "FBCA04" "Cambios en tests"
create_label "dependencies"  "0366D6" "Actualizaciones de dependencias"
create_label "config"        "D4C5F9" "Cambios en configuración"
create_label "ci-cd"         "F9D0C4" "Cambios en CI/CD, workflows y Docker"
create_label "github"        "333333" "Cambios en templates y config de GitHub"

# ── Labels manuales ──────────────────────────────────────────────────────────
echo -e "\n${GREEN}Labels manuales${NC}"
create_label "bug"              "D73A4A" "Algo no funciona correctamente"
create_label "enhancement"      "A2EEEF" "Nueva funcionalidad o mejora"
create_label "breaking change"  "B60205" "Cambios que rompen compatibilidad"
create_label "needs review"     "FBCA04" "Requiere revisión"
create_label "work in progress" "FEF2C0" "Trabajo en progreso"
create_label "ready for merge"  "0E8A16" "Aprobado y listo para merge"
create_label "blocked"          "B60205" "Bloqueado por dependencias"
create_label "help wanted"      "008672" "Se necesita ayuda externa"
create_label "good first issue" "7057FF" "Bueno para nuevos contribuidores"
create_label "duplicate"        "CFD3D7" "Issue o PR duplicado"
create_label "invalid"          "E4E669" "No es válido o no procede"
create_label "wontfix"          "FFFFFF" "No se trabajará en esto"
create_label "question"         "D876E3" "Solicitud de información"

echo -e "\n${GREEN}Labels configurados exitosamente!${NC}"
echo -e "\nVer labels en: ${BLUE}https://github.com/$REPO/labels${NC}\n"
