#!/usr/bin/env bash
# check-labels.sh — las labels de LABELS.md, ¿existen de verdad en el repositorio?
#
# `.github/LABELS.md` es la fuente única y `setup-labels.sh` las crea a partir de
# sus tablas. Pero crear las labels es un paso MANUAL que se hace una vez por
# repositorio, y nada comprobaba que se hubiera hecho.
#
# Por qué importa más de lo que parece: hay mecanismos que dependen de que la
# label exista, no de que esté escrita. `dependabot.yml` declara `sin-changelog`
# en sus PRs para que el job del changelog los deje pasar — si la label no está
# creada, Dependabot no puede aplicarla, el gate los tumba igual, y el arreglo
# parece hecho porque el archivo dice lo correcto. La vía de escape manual
# tampoco sirve: no puedes ponerle al PR una label que no existe.
#
# Uso:
#   bash .github/scripts/check-labels.sh [raíz-del-repo]
#
# Falla ABIERTO: sin `gh`, sin autenticación, sin remoto o sin LABELS.md, no
# opina. Sale con 1 solo cuando puede listar las labels y falta alguna.
set -uo pipefail

ROOT="${1:-.}"
cd "$ROOT" || exit 0

LABELS_MD=".github/LABELS.md"

[ -f "$LABELS_MD" ] || {
  echo "ℹ️  No hay $LABELS_MD; nada que verificar."
  exit 0
}

command -v gh >/dev/null 2>&1 || {
  echo "ℹ️  No está instalado 'gh'; se omite la verificación de labels."
  exit 0
}

# El repositorio: en Actions viene dado; en local se deduce del remoto.
SLUG="${GITHUB_REPOSITORY:-}"
if [ -z "$SLUG" ]; then
  url="$(git remote get-url origin 2>/dev/null || true)"
  SLUG="$(printf '%s' "$url" | perl -ne 's/\.git$//; print "$1/$2\n" if m{[:/]([^/:]+)/([^/]+)$}')"
fi

[ -n "$SLUG" ] || {
  echo "ℹ️  No se pudo determinar el repositorio; se omite."
  exit 0
}

if ! existentes="$(gh label list -R "$SLUG" --limit 200 --json name -q '.[].name' 2>/dev/null)"; then
  echo "ℹ️  No se pudieron listar las labels (sin autenticación o sin red); se omite."
  exit 0
fi

# Las tablas de LABELS.md: | `nombre` | `#RRGGBB` | descripción |
declaradas="$(perl -ne 'print "$1\n" if /^\|\s*`([^`]+)`\s*\|\s*`#[0-9A-Fa-f]{6}`\s*\|/' "$LABELS_MD")"

[ -n "$declaradas" ] || {
  echo "ℹ️  $LABELS_MD no declara ninguna label parseable; nada que verificar."
  exit 0
}

faltan=""
total=0
while IFS= read -r l; do
  [ -n "$l" ] || continue
  total=$((total + 1))
  printf '%s\n' "$existentes" | grep -qxF "$l" || faltan="$faltan $l"
done <<EOF
$declaradas
EOF

if [ -n "$faltan" ]; then
  echo "❌ Estas labels están en $LABELS_MD pero no existen en $SLUG:"
  for l in $faltan; do echo "   · $l"; done
  echo "→ Declararlas no las crea. Y hay mecanismos que dependen de que existan:"
  echo "  'dependabot.yml' pone 'sin-changelog' a sus PRs para pasar el gate del"
  echo "  changelog — sin la label creada, el gate los tumba igual y el arreglo"
  echo "  parece hecho porque el archivo dice lo correcto."
  echo
  echo "   bash .github/scripts/setup-labels.sh"
  exit 1
fi

echo "✅ Labels: las $total de $LABELS_MD existen en $SLUG."
exit 0
