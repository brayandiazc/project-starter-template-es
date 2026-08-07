#!/usr/bin/env bash
# run-tests.sh — pruebas de los scripts y hooks de la plantilla.
# Se ejecutan en CI (workflow quality.yml) y localmente con:
#   bash .github/scripts/tests/run-tests.sh
#
# Requiere: git, perl. Sale con 1 si alguna prueba falla.
set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
PRE_COMMIT="$REPO_ROOT/.githooks/pre-commit"
PRE_PUSH="$REPO_ROOT/.githooks/pre-push"
CHECK_PLACEHOLDERS="$REPO_ROOT/.github/scripts/check-placeholders.sh"
CHECK_LINKS="$REPO_ROOT/.github/scripts/check-links.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass=0
fail=0

# check <descripción> <exit-esperado> <exit-obtenido>
check() {
  if [ "$2" -eq "$3" ]; then
    echo "  ✅ $1"
    pass=$((pass + 1))
  else
    echo "  ❌ $1 (esperado exit=$2, obtenido exit=$3)"
    fail=$((fail + 1))
  fi
}

# Repos git de utilería: en main, en develop y en una rama de feature.
git -C "$TMP" init -q -b main repo-main
git -C "$TMP" init -q -b develop repo-develop
git -C "$TMP" init -q -b feat/x repo-feat

# ── .githooks/pre-commit (protección de ramas) ────────────────────────────────
echo ".githooks/pre-commit:"
run_pre_commit() { (cd "$1" && bash "$PRE_COMMIT" 2>/dev/null); }

run_pre_commit "$TMP/repo-main"; check "commit en main → bloquea" 1 $?
run_pre_commit "$TMP/repo-develop"; check "commit en develop → bloquea" 1 $?
run_pre_commit "$TMP/repo-feat"; check "commit en rama feat → permite" 0 $?

# ── .githooks/pre-commit (secretos en stage) ──────────────────────────────────
# Solo si el hook ya trae el check de secretos (guard para commits antiguos).
if grep -q 'secret-guardrails' "$PRE_COMMIT"; then
  echo ".githooks/pre-commit (secretos):"
  # stage_and_check <ruta relativa> <descripción> <exit esperado>
  stage_and_check() {
    (cd "$TMP/repo-feat" && mkdir -p "$(dirname "$1")" && printf 'x\n' >"$1" && git add -f "$1")
    run_pre_commit "$TMP/repo-feat"; check "$2" "$3" $?
    (cd "$TMP/repo-feat" && git rm -q --cached -f "$1" >/dev/null && rm -f "$1")
  }

  stage_and_check ".env" "stage .env → bloquea" 1
  stage_and_check ".env.local" "stage .env.local → bloquea" 1
  stage_and_check ".env.example" "stage .env.example → permite" 0
  stage_and_check "certs/server.pem" "stage *.pem → bloquea" 1
  stage_and_check "certs/server.key" "stage *.key → bloquea" 1
  stage_and_check "id_rsa" "stage id_rsa → bloquea" 1
  stage_and_check "notas.md" "stage archivo normal → permite" 0
fi

# ── .githooks/pre-push (protección de ramas) ──────────────────────────────────
# El hook lee por stdin una línea por ref: <local ref> <local sha> <remote ref> <remote sha>
echo ".githooks/pre-push:"
run_pre_push() { (cd "$TMP/repo-feat" && printf '%s\n' "$1" | bash "$PRE_PUSH" 2>/dev/null); }

run_pre_push "refs/heads/main aaa refs/heads/main bbb"; check "push a main → bloquea" 1 $?
run_pre_push "refs/heads/x aaa refs/heads/develop bbb"; check "push a develop → bloquea" 1 $?
run_pre_push "refs/heads/feat/x aaa refs/heads/feat/x bbb"; check "push a rama feat → permite" 0 $?
(cd "$TMP/repo-feat" && printf '' | bash "$PRE_PUSH" 2>/dev/null); check "push sin refs → permite" 0 $?

# ── check-placeholders.sh ─────────────────────────────────────────────────────
echo "check-placeholders.sh:"
make_repo() { # $1 = nombre; crea un repo git en $TMP/$1
  mkdir -p "$TMP/$1" && git -C "$TMP/$1" init -q -b main
}
commit_all() { git -C "$1" add -A && git -C "$1" -c user.email=t@t -c user.name=t commit -qm t; }

# Modo plantilla: placeholder catalogado → pasa.
make_repo tpl-ok
printf '| `[NOMBRE_DEL_PROYECTO]` | nombre |\n' >"$TMP/tpl-ok/TEMPLATE-USAGE.md"
printf '# [NOMBRE_DEL_PROYECTO]\n' >"$TMP/tpl-ok/README.md"
commit_all "$TMP/tpl-ok"
(bash "$CHECK_PLACEHOLDERS" "$TMP/tpl-ok" >/dev/null); check "plantilla: catalogado → pasa" 0 $?

# Modo plantilla: placeholder sin catalogar → falla.
make_repo tpl-bad
printf '| `[NOMBRE_DEL_PROYECTO]` | nombre |\n' >"$TMP/tpl-bad/TEMPLATE-USAGE.md"
printf '# [SIN_CATALOGAR]\n' >"$TMP/tpl-bad/README.md"
commit_all "$TMP/tpl-bad"
(bash "$CHECK_PLACEHOLDERS" "$TMP/tpl-bad" >/dev/null); check "plantilla: sin catalogar → falla" 1 $?

# Modo plantilla: comodín `[COMANDO_*]` cubre COMANDO_TEST → pasa.
make_repo tpl-wild
printf '| `[COMANDO_*]` | comandos |\n' >"$TMP/tpl-wild/TEMPLATE-USAGE.md"
printf 'Corre [COMANDO_TEST]\n' >"$TMP/tpl-wild/README.md"
commit_all "$TMP/tpl-wild"
(bash "$CHECK_PLACEHOLDERS" "$TMP/tpl-wild" >/dev/null); check "plantilla: comodín cubre → pasa" 0 $?

# Modo instancia: queda un placeholder → falla.
make_repo inst-bad
printf '# Mi proyecto\nFalta [COMANDO_TEST]\n' >"$TMP/inst-bad/README.md"
commit_all "$TMP/inst-bad"
(bash "$CHECK_PLACEHOLDERS" "$TMP/inst-bad" >/dev/null); check "instancia: placeholder pendiente → falla" 1 $?

# Modo instancia: limpio (los enlaces markdown [X](y) no cuentan) → pasa.
make_repo inst-ok
printf '# Mi proyecto\nVer [MIT](LICENSE).\n' >"$TMP/inst-ok/README.md"
commit_all "$TMP/inst-ok"
(bash "$CHECK_PLACEHOLDERS" "$TMP/inst-ok" >/dev/null); check "instancia: limpio → pasa" 0 $?

# ── check-links.sh ────────────────────────────────────────────────────────────
echo "check-links.sh:"
make_repo links-ok
printf 'Ver [docs](docs/guia.md) y [web](https://example.com) y [ancla](#uso).\n' >"$TMP/links-ok/README.md"
mkdir -p "$TMP/links-ok/docs" && printf 'hola\n' >"$TMP/links-ok/docs/guia.md"
commit_all "$TMP/links-ok"
(bash "$CHECK_LINKS" "$TMP/links-ok" >/dev/null); check "enlaces válidos → pasa" 0 $?

make_repo links-bad
printf 'Ver [docs](docs/no-existe.md).\n' >"$TMP/links-bad/README.md"
commit_all "$TMP/links-bad"
(bash "$CHECK_LINKS" "$TMP/links-bad" >/dev/null); check "enlace roto → falla" 1 $?

# ── check-inheritance.sh ─────────────────────────────────────────────────────────
CHECK_INHERITANCE="$REPO_ROOT/.github/scripts/check-inheritance.sh"
if [ -f "$CHECK_INHERITANCE" ]; then
  echo "check-inheritance.sh:"

  instancia() { # $1 = nombre, $2 = fecha de instanciación
    mkdir -p "$TMP/$1/docs/decisions"
    printf 'repo=https://github.com/x/y\ncommit=abc\nfecha=%s\n' "$2" >"$TMP/$1/.template-origin"
  }
  run_herencia() { (bash "$CHECK_INHERITANCE" "$TMP/$1" > /dev/null 2>&1); }

  # Sin .template-origin no es una instancia: la plantilla misma no se toca.
  mkdir -p "$TMP/hr-plantilla"
  run_herencia hr-plantilla; check "sin .template-origin → permite" 0 $?

  # Proyecto recién instanciado y limpio.
  instancia hr-ok 2026-08-07
  printf '# Changelog\n\n## [Unreleased]\n\n## [0.1.0] - 2026-08-08\n\n- Inicio.\n' \
    >"$TMP/hr-ok/CHANGELOG.md"
  run_herencia hr-ok; check "instancia limpia → pasa" 0 $?

  # Versión del CHANGELOG anterior a la instanciación = herencia.
  instancia hr-changelog 2026-08-07
  printf '# Changelog\n\n## [Unreleased]\n\n## [0.3.0] - 2026-08-02\n\n- De la plantilla.\n' \
    >"$TMP/hr-changelog/CHANGELOG.md"
  run_herencia hr-changelog; check "CHANGELOG con versión previa → falla" 1 $?

  # ADR anterior a la instanciación = decisión de la plantilla.
  instancia hr-adr 2026-08-07
  printf '# 0004. Guardrails\n\n- **Fecha**: 2026-08-02\n' \
    >"$TMP/hr-adr/docs/decisions/0004-guardrails.md"
  run_herencia hr-adr; check "ADR con fecha previa → falla" 1 $?

  # …pero el 0001 es el ADR canónico y SÍ se hereda.
  instancia hr-adr-canonico 2026-08-07
  printf '# 0001. Registrar decisiones\n\n- **Fecha**: 2026-07-01\n' \
    >"$TMP/hr-adr-canonico/docs/decisions/0001-record-architecture-decisions.md"
  run_herencia hr-adr-canonico; check "ADR 0001 canónico → se hereda, pasa" 0 $?

  # Archivos exclusivos del repo-plantilla.
  instancia hr-parity 2026-08-07
  mkdir -p "$TMP/hr-parity/.github/scripts"
  printf '#!/bin/bash\n' >"$TMP/hr-parity/.github/scripts/check-parity.sh"
  run_herencia hr-parity; check "check-parity.sh sobrante → falla" 1 $?

  # Fecha ilegible: falla abierto, no traba el flujo.
  mkdir -p "$TMP/hr-fecha"
  printf 'repo=x\nfecha=ayer\n' >"$TMP/hr-fecha/.template-origin"
  run_herencia hr-fecha; check "fecha inválida → permite" 0 $?
fi

# ── Estructura de .github/workflows/ ──────────────────────────────────────────
# GitHub ejecuta CUALQUIER .yml/.yaml de esa carpeta, sin mirar el resto del
# nombre: un `ci.example.yml` se ejecuta de verdad y sale en verde sin probar
# nada. Lo que no deba ejecutarse no puede terminar en .yml/.yaml.
WORKFLOWS="$REPO_ROOT/.github/workflows"
if [ -d "$WORKFLOWS" ]; then
  echo "estructura de .github/workflows:"
  ejemplos_ejecutables="$(ls "$WORKFLOWS" | grep -Ei '(example|sample|plantilla|template)\.ya?ml$' || true)"
  [ -z "$ejemplos_ejecutables" ]
  check "ningún workflow de ejemplo termina en .yml/.yaml" 0 $?
  [ -n "$ejemplos_ejecutables" ] && printf '     · %s\n' $ejemplos_ejecutables
fi

# ── Resumen ───────────────────────────────────────────────────────────────────
echo ""
echo "Resultado: $pass OK, $fail fallidas."
[ "$fail" -eq 0 ] || exit 1
