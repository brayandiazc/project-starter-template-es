#!/usr/bin/env bash
# check-instructions.sh — el README no manda ejecutar lo que no existe.
#
# La poda al instanciar borra bloques enteros de `.env.example` según las
# capacidades que el producto NO tiene. Cuando se podan TODOS —un producto sin
# servidor, sin build, con la clave viviendo en el navegador de quien lo usa— el
# README se queda con dos líneas que mandan hacer cosas que ya no existen:
#
#     cp .env.example .env      # ← no hay ninguna variable que completar
#     [COMANDO_MIGRACIONES]     # ← no hay base de datos
#
# Y **ningún check las reclamaba**, porque no son placeholders: son texto
# hardcodeado. Se leen como instrucciones correctas hasta que alguien las
# ejecuta. Es la misma familia que los hallazgos caros de esta plantilla: lo
# que queda plausible y falso pasa en verde.
#
# Uso:
#   bash .github/scripts/check-instructions.sh [raíz-del-repo]
#
# En modo PLANTILLA (existe TEMPLATE-USAGE.md) no impone nada: el .env.example
# de la plantilla trae todos los bloques y el README es el esqueleto que se poda.
# Sale con 1 si el README manda un paso que el proyecto no tiene.
set -euo pipefail

ROOT="${1:-.}"
cd "$ROOT"

[ -f README.md ] || { echo "ℹ️  No hay README.md; nada que verificar."; exit 0; }

if [ -f TEMPLATE-USAGE.md ]; then
  echo "ℹ️  Modo plantilla: el README todavía es el esqueleto. Nada que verificar."
  exit 0
fi

fail=0

# ── 1. `cp .env.example .env` sin una sola variable que completar ────────────
# "Tiene variables" = al menos una línea con forma NOMBRE=valor fuera de los
# comentarios. Un .env.example conservado a propósito pero vacío —con solo su
# explicación de por qué no hay ninguna, que es lo que manda la guía— cuenta
# como cero.
if [ -f .env.example ]; then
  n_vars="$(grep -cE '^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*=' .env.example || true)"
else
  n_vars=0
fi

if [ "${n_vars:-0}" -eq 0 ] && grep -qE '^[[:space:]]*cp[[:space:]]+\.env\.example[[:space:]]+\.env' README.md; then
  echo "❌ El README manda 'cp .env.example .env', pero .env.example no declara"
  echo "   ninguna variable$([ -f .env.example ] || echo ' (de hecho, no existe)')."
  echo "→ Este producto no tiene variables de entorno: quita esa línea del bloque de"
  echo "  instalación. Conserva .env.example con la explicación de por qué está vacío"
  echo "  —un archivo vacío a secas se lee como olvido— pero no mandes copiarlo."
  fail=1
fi

# ── 2. Placeholders de comando que sobrevivieron a la poda ───────────────────
# `[COMANDO_MIGRACIONES]` en el bloque de instalación de un producto sin base de
# datos es el mismo error con otro nombre. Aquí sí lo ve check-placeholders.sh,
# así que solo se avisa de lo que ese no puede saber: que el paso no aplica.
if grep -qE '^\[COMANDO_MIGRACIONES\]' README.md && [ ! -f db/schema.rb ] \
   && [ ! -d migrations ] && [ ! -d db/migrate ] && [ ! -d alembic ] \
   && [ "${n_vars:-0}" -eq 0 ]; then
  echo "❌ El README manda ejecutar [COMANDO_MIGRACIONES], pero no hay ni carpeta de"
  echo "   migraciones ni una sola variable de entorno: este producto no tiene base"
  echo "   de datos."
  echo "→ Quita esa línea del bloque de instalación (TEMPLATE-USAGE.md §7)."
  fail=1
fi

[ "$fail" -ne 0 ] && exit 1
echo "✅ Instrucciones: el README no manda pasos que el proyecto no tiene."
