#!/usr/bin/env bash
# check-git-flow.sh — ¿existe `develop` en el remoto?
#
# CONTRIBUTING.md manda que toda rama de trabajo nazca de `develop`, y AGENTS.md
# lo repite palabra por palabra: «si develop no existe, créala desde main y
# publícala». Nada lo comprobaba.
#
# Por qué importa: una `develop` que solo existe en local cumple la regla al
# ramificar y la incumple al abrir el PR. `gh pr create --base develop` falla con
# «Base ref must be a branch», y la salida obvia ante ese error es abrir el PR
# contra `main` — justo lo que la convención prohíbe. El fallo llega tarde, con
# el trabajo ya hecho, y su arreglo aparente es el que rompe el flujo.
#
# Uso:
#   bash .github/scripts/check-git-flow.sh [raíz-del-repo]
#
# Falla ABIERTO: sin repo git, sin remoto, sin red o en un proyecto que no use
# Git Flow, no opina. Sale con 1 solo cuando el remoto existe y `develop` no.
set -uo pipefail

ROOT="${1:-.}"
cd "$ROOT" || exit 0

git rev-parse --git-dir >/dev/null 2>&1 || {
  echo "ℹ️  Esto no es un repositorio git; nada que verificar."
  exit 0
}

# Un proyecto puede haber reescrito su CONTRIBUTING para trabajar solo sobre
# `main`. Si ahí no se nombra `develop`, no hay Git Flow que hacer cumplir.
if [ -f CONTRIBUTING.md ] && ! grep -q 'develop' CONTRIBUTING.md; then
  echo "ℹ️  CONTRIBUTING.md no menciona 'develop'; este proyecto no usa Git Flow."
  exit 0
fi

git remote get-url origin >/dev/null 2>&1 || {
  echo "ℹ️  No hay remoto 'origin'; nada que verificar."
  exit 0
}

# `ls-remote` es la única fuente fiable: una `refs/remotes/origin/develop` local
# puede ser el recuerdo de una rama ya borrada en el servidor.
if ! salida="$(git ls-remote --heads origin develop 2>/dev/null)"; then
  echo "ℹ️  No se pudo consultar el remoto (sin red o sin credenciales); se omite."
  exit 0
fi

if [ -n "$salida" ]; then
  echo "✅ Git Flow: 'develop' existe en el remoto."
  exit 0
fi

echo "❌ 'develop' no existe en el remoto, pero CONTRIBUTING.md la da por hecha."
echo "→ Toda rama de trabajo nace de 'develop'. Sin ella publicada, el PR no"
echo "  tiene base: 'gh pr create --base develop' falla con «Base ref must be a"
echo "  branch», y abrirlo contra 'main' —la salida obvia— es lo que la"
echo "  convención prohíbe."
echo
echo "   git push origin develop:refs/heads/develop"
echo
echo "  (si tampoco la tienes en local: 'git branch develop origin/main' antes)"
exit 1
