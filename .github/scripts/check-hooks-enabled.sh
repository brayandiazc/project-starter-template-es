#!/usr/bin/env bash
# check-hooks-enabled.sh — ¿están corriendo los git hooks de este clon?
#
# `core.hooksPath` NO viaja en el repositorio: es config local, manual, una vez
# por clon. Así que el estado por DEFECTO de cualquier clon nuevo es «sin
# ninguna verificación local»: `pre-commit` no formatea y `pre-push` no corre
# los checks antes de publicar.
#
# Por qué esto importa más de lo que parece: en un repositorio privado de plan
# gratuito **GitHub no ofrece protección de ramas**, así que las reglas que
# CONTRIBUTING.md declara —PR obligatorio, nada de push directo a
# main/develop— no las hace cumplir nadie. En esa configuración estos hooks son
# la ÚNICA defensa que queda, y es la que se olvida.
#
# Este check no vive en el CI ni dentro de `pre-push`, y no por descuido: el CI
# no ve la config local de nadie, y meterlo en `pre-push` sería circular —ese
# hook solo corre si la config que queremos verificar ya está puesta—. Lo
# corre a mano al clonar, que es el momento en que se decide.
#
# Uso:
#   bash .github/scripts/check-hooks-enabled.sh [raíz-del-repo]
#   bash .github/scripts/check-hooks-enabled.sh --arreglar [raíz-del-repo]
#
# Sale con 1 si los hooks no están activos. Fuera de un repo git, no opina.
set -euo pipefail

ARREGLAR=0
if [ "${1:-}" = "--arreglar" ]; then
  ARREGLAR=1
  shift
fi

ROOT="${1:-.}"
cd "$ROOT"

git rev-parse --git-dir >/dev/null 2>&1 || {
  echo "ℹ️  Esto no es un repositorio git; nada que verificar."
  exit 0
}

# Sin la carpeta, no hay nada que activar: un proyecto puede haberla borrado.
[ -d .githooks ] || {
  echo "ℹ️  No hay carpeta .githooks/ en este repo; nada que activar."
  exit 0
}

actual="$(git config --get core.hooksPath || true)"

if [ "$actual" = ".githooks" ]; then
  # Que apunte bien no basta: los hooks tienen que poder ejecutarse.
  sin_permiso=""
  for h in .githooks/*; do
    [ -f "$h" ] || continue
    [ -x "$h" ] || sin_permiso="$sin_permiso $(basename "$h")"
  done
  if [ -n "$sin_permiso" ]; then
    echo "❌ core.hooksPath apunta a .githooks, pero estos no son ejecutables:$sin_permiso"
    if [ "$ARREGLAR" -eq 1 ]; then
      chmod +x .githooks/* && echo "✅ Permisos corregidos."
      exit 0
    fi
    echo "→ chmod +x .githooks/*"
    exit 1
  fi
  echo "✅ Git hooks activos: core.hooksPath = .githooks"
  exit 0
fi

if [ "$ARREGLAR" -eq 1 ]; then
  git config core.hooksPath .githooks
  chmod +x .githooks/* 2>/dev/null || true
  echo "✅ Git hooks activados: core.hooksPath = .githooks"
  exit 0
fi

echo "❌ Los git hooks NO están activos en este clon."
echo "   core.hooksPath: ${actual:-(sin definir)}"
echo "→ Sin ellos, 'pre-commit' no formatea y 'pre-push' no verifica antes de"
echo "  publicar: los fallos se descubren en el CI, más lento y —en un repositorio"
echo "  privado— con minutos contados."
echo
echo "   git config core.hooksPath .githooks"
echo
echo "  (o 'bash .github/scripts/check-hooks-enabled.sh --arreglar')"
echo "  Si este repositorio no tiene protección de ramas —GitHub no la ofrece en"
echo "  repos privados de plan gratuito—, esta es la ÚNICA defensa que queda."
exit 1
