#!/usr/bin/env bash
# check-project-tests.sh — corre las pruebas DEL PROYECTO, no las de la plantilla.
#
# POR QUÉ EXISTE:
#   `.github/scripts/tests/run-tests.sh` prueba los hooks y los scripts de esta
#   plantilla. Esas pruebas sobreviven a la instanciación y siguen pasando para
#   siempre, dé igual lo que haga el producto. Medido en un arranque real: con el
#   algoritmo principal roto —recomendaba al proveedor más caro— y dos pruebas del
#   proyecto en rojo, `pre-push` decía "✅ Suite de pruebas · todo verde".
#
#   Un ✅ que no prueba el producto es peor que no tener check: da confianza falsa
#   justo en el momento en que se decide abrir el PR.
#
# CÓMO SABE QUÉ EJECUTAR:
#   El comando de pruebas está declarado en el bloque «Uso» del README.md. Se lee
#   de ahí para que no haya una segunda copia que se desincronice.
#
# Uso:
#   bash .github/scripts/check-project-tests.sh [raíz-del-repo]
#
# Sale con 1 si las pruebas del proyecto fallan. Si el proyecto todavía no tiene
# pruebas, avisa y pasa — pero lo DICE, que es la diferencia entre "no hay nada que
# probar" y "todo pasa".
set -uo pipefail

ROOT="${1:-.}"
cd "$ROOT"

if [ ! -f README.md ]; then
  echo "ℹ️  Sin README.md: no sé cuál es el comando de pruebas. Nada que ejecutar."
  exit 0
fi

# El bloque «Uso» del README tiene una línea por comando, con su comentario:
#   bin/rails test                 # suite de pruebas
cmd="$(perl -ne 'print "$1\n" if /^\s*(\S.*?)\s+#\s*suite de pruebas/' README.md | head -1)"

if [ -z "$cmd" ]; then
  echo "ℹ️  El README no declara comando de pruebas todavía."
  echo "   Cuando el proyecto tenga suite, escríbelo en el bloque «Uso»."
  exit 0
fi

# Sin rellenar: el arranque aún no eligió stack. No es un fallo, pero tampoco un ✅.
case "$cmd" in
  *'['*']'*)
    echo "ℹ️  El comando de pruebas sigue sin rellenar en el README ($cmd)."
    echo "   Nada que ejecutar todavía — pero esto NO significa que el proyecto pase."
    exit 0
    ;;
esac

# El comando viene de un archivo del repo y en CI se ejecuta sobre eventos de
# PR. Esta allowlist es un BADÉN, no una barrera: reduce el abuso obvio y el
# accidente, pero un runner legítimo también ejecuta código del repo (npm test
# corre lo que diga package.json). La contención real es el token de
# `pull_request`: solo lectura y sin secretos. Reglas:
#   - Prefijos `VAR=valor` se ignoran para clasificar (RAILS_ENV=test bin/rails
#     test es un comando de test normal) pero se ejecutan con el comando.
#   - Un comando COMPUESTO (;, &&, ||, |, `, $( ) no se clasifica: se salta con
#     aviso — el prefijo permitido no dice nada del resto de la línea.
#   - Un runner desconocido no falla el check, pero lo dice (fail-open explícito).
sin_env="$cmd"
while [[ "$sin_env" =~ ^[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]* ]]; do
  sin_env="${sin_env#"${BASH_REMATCH[0]}"}"
  sin_env="${sin_env#"${sin_env%%[![:space:]]*}"}"
done

case "$cmd" in
  *';'*|*'&&'*|*'||'*|*'|'*|*'`'*|*'$('*)
    echo "⚠️  El comando de pruebas del README es compuesto: «${cmd}»."
    echo "   Por seguridad solo se ejecuta un runner simple (este comando corre en CI"
    echo "   sobre PRs de terceros). Declara el comando único de la suite; lo demás"
    echo "   (lint, build) tiene su propio paso."
    exit 0 ;;
esac

case "$sin_env" in
  npm\ *|pnpm\ *|yarn\ *|bun\ *|npx\ *|node\ *|deno\ *|\
  bundle\ *|bin/rails\ *|rails\ *|rake|rake\ *|\
  pytest|pytest\ *|python\ *|python3\ *|uv\ *|\
  go\ *|cargo\ *|make|make\ *|mix\ *|dotnet\ *|\
  flutter\ *|dart\ *|gradle\ *|./gradlew\ *|mvn\ *|composer\ *|php\ *|swift\ *)
    : ;;
  *)
    # ${cmd} con llaves: el bash 3.2 de macOS parsea mal «$cmd» (se come el
    # primer byte del «»» como si fuera parte del nombre de la variable).
    echo "⚠️  Comando de pruebas no reconocido: «${cmd}»."
    echo "   Solo se ejecutan runners conocidos (npm, pytest, go test, make…): este"
    echo "   comando sale del README y en CI corre sobre PRs de terceros. Si es"
    echo "   legítimo, añade su prefijo a la allowlist de este script."
    exit 0 ;;
esac

# El comando ya está elegido pero el proyecto aún no se ha generado: entre el PR de
# documentación y el del andamiaje, el README declara comandos que todavía no puede
# ejecutar nadie. Eso no es una suite en rojo, es una suite que no existe — y confundir
# las dos cosas bloquea el primer PR de cualquier arranque.
# Solo cuentan los comandos que NO pueden funcionar sin su manifiesto: un gestor que
# busca un script declarado. Un intérprete directo (`python3 -c …`, `node …`) sí corre
# sin proyecto, así que no entra aquí — si falla, falla de verdad.
falta_manifiesto=""
case "$sin_env" in
  npm\ *|pnpm\ *|yarn\ *|bun\ *)
    [ -f package.json ] || falta_manifiesto="package.json" ;;
  bundle\ *|bin/rails\ *|rails\ *|rake|rake\ *)
    [ -f Gemfile ] || falta_manifiesto="Gemfile" ;;
  go\ *) [ -f go.mod ] || falta_manifiesto="go.mod" ;;
  cargo\ *) [ -f Cargo.toml ] || falta_manifiesto="Cargo.toml" ;;
  mix\ *) [ -f mix.exs ] || falta_manifiesto="mix.exs" ;;
esac

if [ -n "$falta_manifiesto" ]; then
  echo "ℹ️  El comando de pruebas ya está elegido («${cmd}») pero no hay ${falta_manifiesto}:"
  echo "   el proyecto todavía no se ha generado. Nada que ejecutar — pero esto NO"
  echo "   significa que el proyecto pase."
  exit 0
fi

echo "▶ Pruebas del proyecto: $cmd"
if eval "$cmd"; then
  echo "✅ Pruebas del proyecto: pasan."
  exit 0
fi
echo "❌ Las pruebas del proyecto fallan."
echo "→ Arréglalas antes de abrir el PR. Este check es el único que mira tu código:"
echo "  la otra suite prueba la plantilla y seguiría en verde igualmente."
exit 1
