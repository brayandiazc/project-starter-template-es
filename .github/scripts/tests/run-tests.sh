#!/usr/bin/env bash
# run-tests.sh — pruebas de los scripts y hooks de la plantilla.
# Se ejecutan en CI (workflow quality.yml) y localmente con:
#   bash .github/scripts/tests/run-tests.sh
#
# Requiere: git, perl, python3. Sale con 1 si alguna prueba falla.
set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECK_PLACEHOLDERS="$REPO_ROOT/.github/scripts/check-placeholders.sh"
CHECK_LINKS="$REPO_ROOT/.github/scripts/check-links.sh"
CHECK_CHANGELOG="$REPO_ROOT/.github/scripts/check-changelog.sh"
CHECK_RELEASE="$REPO_ROOT/.github/scripts/check-release.sh"
CHECK_INSTRUCCIONES="$REPO_ROOT/.github/scripts/check-instructions.sh"
CHECK_HOOKS="$REPO_ROOT/.github/scripts/check-hooks-enabled.sh"

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

# Modo instancia: placeholder MARCADO como pendiente → pasa.
# /instanciar dice "no inventes datos, deja el placeholder"; sin esta excepción esa
# regla y este check se contradicen y el primer PR de todo proyecto sale en rojo.
make_repo inst-pend
printf '# Mi proyecto\nContacto: [EMAIL_SOPORTE] <!-- pendiente: aún sin buzón -->\n' >"$TMP/inst-pend/README.md"
commit_all "$TMP/inst-pend"
(bash "$CHECK_PLACEHOLDERS" "$TMP/inst-pend" >/dev/null); check "instancia: marcado pendiente → pasa" 0 $?

# …pero se lista, para que no se vuelva permanente por inercia.
salida="$(bash "$CHECK_PLACEHOLDERS" "$TMP/inst-pend" 2>&1 || true)"
printf '%s' "$salida" | grep -q "EMAIL_SOPORTE"
check "instancia: el pendiente se reporta" 0 $?

# La marca es por línea: otro placeholder sin marcar en el mismo archivo sigue fallando.
make_repo inst-mix
printf '# Mi proyecto\nContacto: [EMAIL_SOPORTE] <!-- pendiente -->\nCorre [COMANDO_TEST]\n' >"$TMP/inst-mix/README.md"
commit_all "$TMP/inst-mix"
(bash "$CHECK_PLACEHOLDERS" "$TMP/inst-mix" >/dev/null); check "instancia: marca por línea, no por archivo → falla" 1 $?

# La marca también en sintaxis de comentario bash: los [COMANDO_*] viven en bloques
# ```bash y en .env.example, donde un comentario HTML saldría literal.
make_repo inst-bash
printf '# Mi proyecto\n\n```bash\n[COMANDO_TEST]   # pendiente: falta el scaffolding\n```\n' >"$TMP/inst-bash/README.md"
commit_all "$TMP/inst-bash"
(bash "$CHECK_PLACEHOLDERS" "$TMP/inst-bash" >/dev/null); check "instancia: marca '# pendiente' en bash → pasa" 0 $?

# El CHANGELOG es historia, no formulario: mencionar un placeholder no es tener uno.
make_repo inst-chlog
printf '# Mi proyecto\nTodo bien.\n' >"$TMP/inst-chlog/README.md"
printf '# Changelog\n\n- Se elimina el bloque con [BASE_DE_DATOS] y [PROVEEDOR].\n' >"$TMP/inst-chlog/CHANGELOG.md"
commit_all "$TMP/inst-chlog"
(bash "$CHECK_PLACEHOLDERS" "$TMP/inst-chlog" >/dev/null); check "instancia: CHANGELOG no cuenta → pasa" 0 $?

# La marca vale también en la línea SIGUIENTE: Prettier parte las líneas dentro de
# los bloques ```html y deja el comentario debajo. Exigir la misma línea hacía que
# marcar bien y commitear rompiera el check (prueba de arranque 2, fricción 7).
make_repo inst-nextline
printf '# Mi proyecto\n\n```html\n<meta content="[URL_IMAGEN_OG]" />\n<!-- pendiente: falta la imagen -->\n```\n' >"$TMP/inst-nextline/README.md"
commit_all "$TMP/inst-nextline"
(bash "$CHECK_PLACEHOLDERS" "$TMP/inst-nextline" >/dev/null); check "instancia: marca en la línea siguiente → pasa" 0 $?

# Pero solo si el comentario ABRE la línea: si no, un marcador ajeno excusaría al
# placeholder de arriba por simple vecindad.
make_repo inst-nextline-no
printf '# Mi proyecto\n\n[URL_DEV]\ntexto [URL_PRODUCCION] <!-- pendiente: sin dominio -->\n' >"$TMP/inst-nextline-no/README.md"
commit_all "$TMP/inst-nextline-no"
(bash "$CHECK_PLACEHOLDERS" "$TMP/inst-nextline-no" >/dev/null); check "instancia: marca ajena no excusa al vecino → falla" 1 $?

# Un archivo que git traza pero que ya no está en disco (poda con 'rm' en vez de
# 'git rm') no puede revisarse — y antes se saltaba en silencio, con el resumen en
# verde y un error crudo de perl por stderr (fricción 3).
make_repo inst-ausente
printf '# Mi proyecto\nTodo bien.\n' >"$TMP/inst-ausente/README.md"
printf 'Con [NOMBRE_DEL_PROYECTO].\n' >"$TMP/inst-ausente/OTRO.md"
commit_all "$TMP/inst-ausente"
rm "$TMP/inst-ausente/OTRO.md"
salida="$(bash "$CHECK_PLACEHOLDERS" "$TMP/inst-ausente" 2>&1)"; ec=$?
check "instancia: archivo trazado y ausente no rompe → pasa" 0 $ec
# Lo que de verdad cambió: antes el exit ya era 0, pero perl escupía su error crudo
# y el archivo no se revisaba. El exit por sí solo no distingue el arreglo.
printf '%s' "$salida" | grep -qi "can't open"; check "instancia: sin error crudo de perl" 1 $?

# Pendientes DE PROYECTO: un dato que falta en todas partes se declara una vez en
# `.pendientes` en vez de con decenas de comentarios — que en legal/, que se publica,
# irían dentro de los términos del producto (prueba de arranque 2, fricción 8).
make_repo inst-globales
printf '# Mi proyecto\n\nContacto: [EMAIL_SOPORTE]\n' >"$TMP/inst-globales/README.md"
printf 'Escribe a [EMAIL_SOPORTE].\n' >"$TMP/inst-globales/SECURITY.md"
printf 'EMAIL_SOPORTE=el cliente aún no da el buzón\n' >"$TMP/inst-globales/.pendientes"
commit_all "$TMP/inst-globales"
salida="$(bash "$CHECK_PLACEHOLDERS" "$TMP/inst-globales" 2>&1)"; ec=$?
check "instancia: pendiente declarado en .pendientes → pasa" 0 $ec
printf '%s' "$salida" | grep -q "Pendientes de proyecto"; check "instancia: los globales se listan aparte" 0 $?

# Sin el archivo, los mismos placeholders siguen fallando: declarar es un acto explícito.
make_repo inst-globales-no
printf '# Mi proyecto\n\nContacto: [EMAIL_SOPORTE]\n' >"$TMP/inst-globales-no/README.md"
commit_all "$TMP/inst-globales-no"
(bash "$CHECK_PLACEHOLDERS" "$TMP/inst-globales-no" >/dev/null 2>&1); check "instancia: sin .pendientes → falla igual" 1 $?

# Y declarar uno no tapa a su vecino en la misma línea.
make_repo inst-globales-vecino
printf '# Mi proyecto\n\n[EMAIL_SOPORTE] y [URL_PRODUCCION]\n' >"$TMP/inst-globales-vecino/README.md"
printf 'EMAIL_SOPORTE=sin buzón\n' >"$TMP/inst-globales-vecino/.pendientes"
commit_all "$TMP/inst-globales-vecino"
(bash "$CHECK_PLACEHOLDERS" "$TMP/inst-globales-vecino" >/dev/null 2>&1); check "instancia: un global no tapa al vecino de su línea" 1 $?

# Archivos que EXISTEN pero git aún no traza: es el estado exacto al adoptar la
# plantilla en un proyecto existente — se copian y todavía no se han commiteado. Antes
# eran invisibles y el check respondía "no queda ninguno" (prueba de adopción, fricción 3).
make_repo inst-untracked
printf '# Mi proyecto\nTodo bien.\n' >"$TMP/inst-untracked/README.md"
commit_all "$TMP/inst-untracked"
printf 'Recien copiado con [NOMBRE_DEL_PROYECTO].\n' >"$TMP/inst-untracked/NUEVO.md"
(bash "$CHECK_PLACEHOLDERS" "$TMP/inst-untracked" >/dev/null 2>&1); check "instancia: archivo sin trazar también se revisa → falla" 1 $?

# Pero lo ignorado por .gitignore sigue fuera: --exclude-standard lo respeta.
make_repo inst-ignorado
printf '# Mi proyecto\nTodo bien.\n' >"$TMP/inst-ignorado/README.md"
printf 'borrador/\n' >"$TMP/inst-ignorado/.gitignore"
commit_all "$TMP/inst-ignorado"
mkdir -p "$TMP/inst-ignorado/borrador"
printf 'Con [NOMBRE_DEL_PROYECTO].\n' >"$TMP/inst-ignorado/borrador/notas.md"
(bash "$CHECK_PLACEHOLDERS" "$TMP/inst-ignorado" >/dev/null 2>&1); check "instancia: lo ignorado por .gitignore no cuenta → pasa" 0 $?

# Huecos EN PROSA: no siguen la convención [MAYÚSCULAS] y por eso nadie los veía —
# un roadmap íntegramente sin rellenar pasaba en verde (prueba del ciclo, fricción 2).
make_repo inst-prosa
printf '# Mi proyecto\n\n## v0.1 — [NOMBRE / OBJETIVO]\n\n[Un párrafo describiendo el norte.]\n' >"$TMP/inst-prosa/README.md"
commit_all "$TMP/inst-prosa"
(bash "$CHECK_PLACEHOLDERS" "$TMP/inst-prosa" >/dev/null 2>&1); check "instancia: hueco en prosa → falla" 1 $?

# La misma marca de pendiente vale para ellos.
make_repo inst-prosa-marcada
printf '# Mi proyecto\n\n[Un párrafo describiendo el norte.] <!-- pendiente: sin cerrar la visión -->\n' >"$TMP/inst-prosa-marcada/README.md"
commit_all "$TMP/inst-prosa-marcada"
(bash "$CHECK_PLACEHOLDERS" "$TMP/inst-prosa-marcada" >/dev/null 2>&1); check "instancia: hueco en prosa marcado → pasa" 0 $?

# Las cuatro exclusiones, una prueba cada una: si alguna falla, el check se vuelve
# ruido que nadie mira, que es peor que no tenerlo.
make_repo inst-prosa-falsos
{
  printf '# Mi proyecto\n\n'
  printf 'Un [enlace normal](https://example.com) no es un hueco.\n\n'
  printf -- '- [ ] una tarea pendiente\n- [x] una tarea hecha\n\n'
  printf '> [!NOTE]\n> Una admonición de GitHub.\n\n'
  printf 'El selector `[data-theme="dark"]` va entre acentos graves.\n\n'
  printf 'La sección [Unreleased] del changelog es sintaxis, no un hueco.\n'
} >"$TMP/inst-prosa-falsos/README.md"
commit_all "$TMP/inst-prosa-falsos"
(bash "$CHECK_PLACEHOLDERS" "$TMP/inst-prosa-falsos" >/dev/null 2>&1); check "instancia: enlaces, tareas, admoniciones, código y changelog no cuentan" 0 $?

# Los bloques de código vallados no son prosa: los nodos de Mermaid usan corchetes con
# todo derecho (A["Anfitrión"], Inicio([Entrada])) y la plantilla recomienda Mermaid en
# architecture.md, database.md y screens.md — sin la exclusión el choque era seguro
# en toda instancia (fricción 3 de un arranque real).
make_repo inst-prosa-mermaid
{
  printf '# Arquitectura\n\n'
  printf '```mermaid\nflowchart LR\n'
  printf '  A["Anfitrión — Chrome/Edge<br/>React + Vite"] --> B(Worker)\n'
  printf '  Inicio([Entrada]) --> A\n'
  printf '```\n'
} >"$TMP/inst-prosa-mermaid/README.md"
commit_all "$TMP/inst-prosa-mermaid"
(bash "$CHECK_PLACEHOLDERS" "$TMP/inst-prosa-mermaid" >/dev/null 2>&1); check "instancia: corchetes de Mermaid dentro de valla → pasa" 0 $?

# Pero la valla no amnistía nada fuera de ella ni a los [MAYÚSCULAS] de dentro:
# un hueco en prosa después del diagrama sigue fallando, y un [COMANDO_TEST] en un
# bloque ```bash sigue siendo un valor por sustituir.
make_repo inst-prosa-tras-valla
{
  printf '# Arquitectura\n\n'
  printf '```mermaid\nflowchart LR\n  A["Anfitrión"] --> B(Worker)\n```\n\n'
  printf '[Un párrafo describiendo el despliegue.]\n'
} >"$TMP/inst-prosa-tras-valla/README.md"
commit_all "$TMP/inst-prosa-tras-valla"
(bash "$CHECK_PLACEHOLDERS" "$TMP/inst-prosa-tras-valla" >/dev/null 2>&1); check "instancia: hueco en prosa tras la valla → falla" 1 $?

make_repo inst-valla-mayusculas
printf '# Setup\n\n```bash\n[COMANDO_TEST]\n```\n' >"$TMP/inst-valla-mayusculas/README.md"
commit_all "$TMP/inst-valla-mayusculas"
(bash "$CHECK_PLACEHOLDERS" "$TMP/inst-valla-mayusculas" >/dev/null 2>&1); check "instancia: [MAYÚSCULAS] dentro de valla → sigue fallando" 1 $?

# En modo PLANTILLA los huecos en prosa son legítimos: el esqueleto está hecho de ellos.
make_repo tpl-prosa
printf '# Plantilla\n\nCatálogo: nada.\n' >"$TMP/tpl-prosa/TEMPLATE-USAGE.md"
printf '# Mi proyecto\n\n[Un párrafo describiendo el norte.]\n' >"$TMP/tpl-prosa/README.md"
commit_all "$TMP/tpl-prosa"
(bash "$CHECK_PLACEHOLDERS" "$TMP/tpl-prosa" >/dev/null 2>&1); check "plantilla: los huecos en prosa no se exigen" 0 $?

# --marcar: adoptar el check en un proyecto existente pondría 160 huecos en rojo de
# golpe. Los marca en una pasada, diciendo que están sin revisar.
make_repo inst-marcar
printf '# Mi proyecto\n\n[Un párrafo describiendo el norte.]\n\n[Otro hueco sin escribir.]\n' >"$TMP/inst-marcar/README.md"
commit_all "$TMP/inst-marcar"
(bash "$CHECK_PLACEHOLDERS" "$TMP/inst-marcar" >/dev/null 2>&1); check "marcar: antes de marcar, falla" 1 $?
bash "$CHECK_PLACEHOLDERS" --marcar "$TMP/inst-marcar" >/dev/null 2>&1
(bash "$CHECK_PLACEHOLDERS" "$TMP/inst-marcar" >/dev/null 2>&1); check "marcar: después de marcar, pasa" 0 $?
grep -q "sin revisar" "$TMP/inst-marcar/README.md"; check "marcar: la marca dice que está sin revisar" 0 $?
grep -c "pendiente:" "$TMP/inst-marcar/README.md" | grep -q "^2$"; check "marcar: marca cada hueco, no solo el primero" 0 $?

# Los placeholders [MAYÚSCULAS] NO se marcan en bloque: son valores por sustituir, y
# marcarlos sería esconderlos.
make_repo inst-marcar-solo-prosa
printf '# Mi proyecto\n\nContacto: [EMAIL_SOPORTE]\n' >"$TMP/inst-marcar-solo-prosa/README.md"
commit_all "$TMP/inst-marcar-solo-prosa"
bash "$CHECK_PLACEHOLDERS" --marcar "$TMP/inst-marcar-solo-prosa" >/dev/null 2>&1
(bash "$CHECK_PLACEHOLDERS" "$TMP/inst-marcar-solo-prosa" >/dev/null 2>&1); check "marcar: no toca los placeholders [MAYÚSCULAS]" 1 $?

# .github/ ya no se salta entero: el [URL_REPOSITORIO] de config.yml quedaba
# como enlace roto para siempre en la UI de GitHub de cada instancia.
make_repo inst-github
mkdir -p "$TMP/inst-github/.github/ISSUE_TEMPLATE"
printf '# Proyecto listo\n' >"$TMP/inst-github/README.md"
printf 'contact_links:\n  - url: [URL_REPOSITORIO]/discussions\n' \
  >"$TMP/inst-github/.github/ISSUE_TEMPLATE/config.yml"
commit_all "$TMP/inst-github"
(bash "$CHECK_PLACEHOLDERS" "$TMP/inst-github" >/dev/null 2>&1); check "instancia: [URL_REPOSITORIO] en config.yml → falla" 1 $?

# …pero los prefijos de título ([BUG]) y los huecos de prosa de los formularios
# de issue ([Ej. iPhone 13]) sobreviven por diseño: instancia limpia = verde.
make_repo inst-github-ok
mkdir -p "$TMP/inst-github-ok/.github/ISSUE_TEMPLATE"
printf '# Proyecto listo\n' >"$TMP/inst-github-ok/README.md"
printf -- '---\ntitle: "[BUG] "\n---\n\n- Dispositivo: [Ej. iPhone 13, Samsung Galaxy S22]\n' \
  >"$TMP/inst-github-ok/.github/ISSUE_TEMPLATE/bug_report.md"
commit_all "$TMP/inst-github-ok"
(bash "$CHECK_PLACEHOLDERS" "$TMP/inst-github-ok" >/dev/null 2>&1); check "instancia: [BUG] y prosa de ISSUE_TEMPLATE → pasa" 0 $?
# Y el resumen no los cuenta como "pendientes" (conteo falso permanente).
salida_gh="$(bash "$CHECK_PLACEHOLDERS" "$TMP/inst-github-ok" 2>&1 || true)"
printf '%s' "$salida_gh" | grep -q "no queda ninguno"; check "instancia: el resumen no lista [BUG] como pendiente" 0 $?

# --rutas-sustituibles: el alcance de la pasada de relleno de /instanciar. La pasada
# global corrompió los fixtures de ESTE banco y rellenó las plantillas internas de
# specs/ y docs/, que existen para conservar sus placeholders — lo segundo se cobró
# semanas después, cuando spec-guardrails acusó de "sin rellenar" la línea que sí lo
# estaba. La lista ya existía (SKIP); solo faltaba que se pudiera pedir.
make_repo rutas
mkdir -p "$TMP/rutas/.github/scripts/tests" "$TMP/rutas/.github/workflows" \
  "$TMP/rutas/.github/ISSUE_TEMPLATE" "$TMP/rutas/docs/decisions" \
  "$TMP/rutas/docs/conventions"
printf '# [NOMBRE_DEL_PROYECTO]\n'      >"$TMP/rutas/README.md"
printf 'url: [URL_REPOSITORIO]\n'       >"$TMP/rutas/.github/ISSUE_TEMPLATE/config.yml"
printf '# se toca: [PUERTO]\n'          >"$TMP/rutas/.env.example"
printf '# fixture con [FECHA]\n'        >"$TMP/rutas/.github/scripts/tests/run-tests.sh"
printf '# comentario con [FECHA]\n'     >"$TMP/rutas/.github/workflows/release.yml"
printf '# ADR [NNNN] — [TÍTULO]\n'      >"$TMP/rutas/docs/decisions/0000-template.md"
printf '# [TEMA]\n'                     >"$TMP/rutas/docs/conventions/_template.md"
printf '## [1.0.0] - 2026-01-01\n'      >"$TMP/rutas/CHANGELOG.md"
commit_all "$TMP/rutas"
rutas="$(bash "$CHECK_PLACEHOLDERS" --rutas-sustituibles "$TMP/rutas")"

# Lo que SÍ se sustituye. config.yml entra aunque viva en .github/: son los enlaces de
# contacto que GitHub muestra en "New issue", y saltarlos los dejaba rotos para siempre.
printf '%s\n' "$rutas" | grep -qx 'README.md'; check "rutas: la documentación entra" 0 $?
printf '%s\n' "$rutas" | grep -qx '.env.example'; check "rutas: .env.example entra" 0 $?
printf '%s\n' "$rutas" | grep -qx '.github/ISSUE_TEMPLATE/config.yml'; check "rutas: config.yml entra pese a vivir en .github/" 0 $?

# Lo que NO: en un script un placeholder es fixture o texto explicativo; en una
# plantilla interna es lo único que la hace útil.
for exento in \
  '.github/scripts/tests/run-tests.sh' \
  '.github/workflows/release.yml' \
  'docs/decisions/0000-template.md' \
  'docs/conventions/_template.md' \
  'CHANGELOG.md'; do
  printf '%s\n' "$rutas" | grep -qx "$exento"
  check "rutas: $exento queda fuera" 1 $?
done

# La regresión que de verdad importa: sustituir por las rutas de la lista deja
# intactos los fixtures de este mismo banco de pruebas.
printf '%s\n' "$rutas" | tr '\n' '\0' | (cd "$TMP/rutas" && xargs -0 perl -pi -e 's/\[FECHA\]/2026-09-01/g')
grep -q '\[FECHA\]' "$TMP/rutas/.github/scripts/tests/run-tests.sh"
check "rutas: tras la pasada, el fixture del banco sigue intacto" 0 $?

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

# Archivo trazado pero borrado del disco: se cuenta y se avisa, no se salta en
# silencio dejando que perl escupa su error mientras el resumen dice que todo bien.
# Enlaces dentro de un archivo sin trazar: mismo caso de la adopción.
# Un documento que CITA markdown o una regex entre acentos graves no enlaza a nada.
make_repo links-inline
printf 'La regex `(?!\\()` y el ejemplo `[texto](destino.md)` van entre acentos graves.\n' >"$TMP/links-inline/README.md"
commit_all "$TMP/links-inline"
(bash "$CHECK_LINKS" "$TMP/links-inline" >/dev/null 2>&1); check "enlaces: el código en línea no cuenta como enlace" 0 $?

# Y tampoco lo que va dentro de una valla de código.
make_repo links-valla
printf '# Doc\n\n```perl\n/\\](?!\\()/\n```\n\nVer [de verdad](README.md).\n' >"$TMP/links-valla/README.md"
commit_all "$TMP/links-valla"
(bash "$CHECK_LINKS" "$TMP/links-valla" >/dev/null 2>&1); check "enlaces: el código en valla no cuenta como enlace" 0 $?

make_repo links-untracked
printf 'ok\n' >"$TMP/links-untracked/README.md"
commit_all "$TMP/links-untracked"
printf 'Ver [guia](docs/no-existe.md).\n' >"$TMP/links-untracked/NUEVO.md"
(bash "$CHECK_LINKS" "$TMP/links-untracked" >/dev/null 2>&1); check "enlaces: archivo sin trazar también se revisa → falla" 1 $?

make_repo links-ausente
printf 'Ver [docs](docs/guia.md).\n' >"$TMP/links-ausente/README.md"
mkdir -p "$TMP/links-ausente/docs" && printf 'hola\n' >"$TMP/links-ausente/docs/guia.md"
printf 'Otro archivo.\n' >"$TMP/links-ausente/OTRO.md"
commit_all "$TMP/links-ausente"
rm "$TMP/links-ausente/OTRO.md"
salida="$(bash "$CHECK_LINKS" "$TMP/links-ausente" 2>&1)"; ec=$?
check "enlaces: archivo ausente no rompe → pasa" 0 $ec
printf '%s' "$salida" | grep -q "no se revisaron"; check "enlaces: el ausente se avisa" 0 $?
printf '%s' "$salida" | grep -qi "can't open"; check "enlaces: sin error crudo de perl" 1 $?

# ── check-changelog.sh ────────────────────────────────────────────────────────
if [ -f "$CHECK_CHANGELOG" ]; then
  echo "check-changelog.sh:"

  # Repo con CHANGELOG publicado en main y una rama de trabajo encima.
  changelog_repo() { # $1 = nombre
    make_repo "$1"
    printf '# Changelog\n\n## [Unreleased]\n\n### Added\n\n### Fixed\n\n## [0.1.0] - 2026-01-01\n\n### Added\n\n- Primera versión.\n' \
      >"$TMP/$1/CHANGELOG.md"
    printf 'contenido\n' >"$TMP/$1/README.md"
    commit_all "$TMP/$1"
    git -C "$TMP/$1" checkout -q -b feat/x
  }
  # Reescribe el CHANGELOG con las entradas dadas bajo Unreleased.
  set_unreleased() { # $1 = repo, $2 = cuerpo de Unreleased
    printf '# Changelog\n\n## [Unreleased]\n\n### Added\n\n%s\n\n## [0.1.0] - 2026-01-01\n\n### Added\n\n- Primera versión.\n' \
      "$2" >"$TMP/$1/CHANGELOG.md"
  }
  run_changelog() { (bash "$CHECK_CHANGELOG" main "$TMP/$1" >/dev/null 2>&1); }

  # Cambio de código sin tocar el CHANGELOG.
  changelog_repo cl-missing
  printf 'puts 1\n' >"$TMP/cl-missing/app.rb"
  commit_all "$TMP/cl-missing"
  run_changelog cl-missing; check "código sin entrada → falla" 1 $?

  # Cambio de código con su entrada bajo Unreleased.
  changelog_repo cl-ok
  printf 'puts 1\n' >"$TMP/cl-ok/app.rb"
  set_unreleased cl-ok '- Se puede entrar con Google.'
  commit_all "$TMP/cl-ok"
  run_changelog cl-ok; check "código con entrada → pasa" 0 $?

  # CHANGELOG tocado pero Unreleased sigue vacía (p. ej. solo se movió un enlace).
  changelog_repo cl-empty
  printf 'puts 1\n' >"$TMP/cl-empty/app.rb"
  printf '# Changelog\n\n## [Unreleased]\n\n### Added\n\n## [0.1.0] - 2026-01-01\n\n### Added\n\n- Primera versión (redactada).\n' \
    >"$TMP/cl-empty/CHANGELOG.md"
  commit_all "$TMP/cl-empty"
  run_changelog cl-empty; check "CHANGELOG tocado con Unreleased vacía → falla" 1 $?

  # PR que solo toca el propio CHANGELOG (p. ej. redactar una entrada anterior).
  changelog_repo cl-solo
  set_unreleased cl-solo '- Se reescribe una entrada vieja.'
  commit_all "$TMP/cl-solo"
  run_changelog cl-solo; check "PR solo del propio CHANGELOG → pasa (exento)" 0 $?

  # Excepción explícita por label.
  changelog_repo cl-label
  printf 'puts 1\n' >"$TMP/cl-label/app.rb"
  commit_all "$TMP/cl-label"
  (PR_LABELS="documentation,sin-changelog" bash "$CHECK_CHANGELOG" main "$TMP/cl-label" >/dev/null 2>&1)
  check "label sin-changelog → pasa" 0 $?

  # Corte de versión: Unreleased queda vacía a propósito.
  changelog_repo cl-release
  printf '# Changelog\n\n## [Unreleased]\n\n### Added\n\n## [0.2.0] - 2026-02-01\n\n### Added\n\n- Se puede entrar con Google.\n\n## [0.1.0] - 2026-01-01\n\n### Added\n\n- Primera versión.\n' \
    >"$TMP/cl-release/CHANGELOG.md"
  printf 'v2\n' >"$TMP/cl-release/VERSION"
  commit_all "$TMP/cl-release"
  run_changelog cl-release; check "corte de versión → pasa" 0 $?

  # Base irresoluble: falla abierto para no bloquear el CI por un ref raro.
  changelog_repo cl-nobase
  printf 'puts 1\n' >"$TMP/cl-nobase/app.rb"
  commit_all "$TMP/cl-nobase"
  (bash "$CHECK_CHANGELOG" no-existe "$TMP/cl-nobase" >/dev/null 2>&1)
  check "base irresoluble → permite" 0 $?

  # Repo sin CHANGELOG.md: no se impone nada.
  make_repo cl-none
  printf 'hola\n' >"$TMP/cl-none/README.md"
  commit_all "$TMP/cl-none"
  git -C "$TMP/cl-none" checkout -q -b feat/x
  printf 'puts 1\n' >"$TMP/cl-none/app.rb"
  commit_all "$TMP/cl-none"
  run_changelog cl-none; check "repo sin CHANGELOG.md → permite" 0 $?
fi

# ── check-release.sh ──────────────────────────────────────────────────────────
if [ -f "$CHECK_RELEASE" ]; then
  echo "check-release.sh:"

  # $1 = nombre, $2 = contenido del CHANGELOG, $3 = tag a crear (o vacío)
  release_repo() {
    make_repo "$1"
    printf '%s' "$2" >"$TMP/$1/CHANGELOG.md"
    commit_all "$TMP/$1"
    [ -n "${3:-}" ] && git -C "$TMP/$1" tag "$3"
    return 0
  }
  CORTADA='# Changelog\n\n## [Unreleased]\n\n### Added\n\n## [0.2.0] - 2026-02-01\n\n### Added\n\n- Login con Google.\n'
  run_release() { (bash "$CHECK_RELEASE" "$TMP/$1" >/dev/null 2>&1); }

  # Versión cortada y todavía sin tag: es exactamente lo que debe publicarse.
  release_repo rl-ok "$(printf "$CORTADA")" ""
  run_release rl-ok; check "versión cortada sin publicar → pasa" 0 $?

  # La versión de arriba ya tiene tag: este merge no publicaría nada.
  release_repo rl-tagged "$(printf "$CORTADA")" "v0.2.0"
  run_release rl-tagged; check "versión ya publicada → falla" 1 $?

  # Nunca se cortó: solo hay Unreleased.
  release_repo rl-nocut "$(printf '# Changelog\n\n## [Unreleased]\n\n### Added\n\n- Algo.\n')" ""
  run_release rl-nocut; check "sin versión fechada → falla" 1 $?

  # Cortada, pero quedó trabajo suelto fuera de la versión.
  release_repo rl-leftover \
    "$(printf '# Changelog\n\n## [Unreleased]\n\n### Added\n\n- Quedó fuera del corte.\n\n## [0.2.0] - 2026-02-01\n\n### Added\n\n- Login con Google.\n')" ""
  run_release rl-leftover; check "Unreleased con entradas → falla" 1 $?

  # Placeholder sin fecha real (plantilla recién instanciada) no cuenta como versión.
  release_repo rl-placeholder \
    "$(printf '# Changelog\n\n## [Unreleased]\n\n### Added\n\n## [0.1.0] - [FECHA]\n\n- Inicio.\n')" ""
  run_release rl-placeholder; check "versión con fecha placeholder → falla" 1 $?

  # Repo sin CHANGELOG.md: no se impone nada.
  make_repo rl-none
  printf 'hola\n' >"$TMP/rl-none/README.md"
  commit_all "$TMP/rl-none"
  run_release rl-none; check "repo sin CHANGELOG.md → permite" 0 $?
fi

# ── .githooks/pre-commit ──────────────────────────────────────────────────────
# Necesita npx (Prettier). Sin Node.js se salta: el hook mismo también se salta.
PRECOMMIT="$REPO_ROOT/.githooks/pre-commit"
if [ -f "$PRECOMMIT" ] && command -v npx > /dev/null 2>&1; then
  echo ".githooks/pre-commit:"

  hook_repo() { # $1 = nombre; repo con el hook activado
    mkdir -p "$TMP/$1" && git -C "$TMP/$1" init -q -b main
    git -C "$TMP/$1" config core.hooksPath "$(dirname "$PRECOMMIT")"
  }
  hook_commit() { git -C "$TMP/$1" -c user.email=t@t -c user.name=t commit -qm t > /dev/null 2>&1; }

  # Formatea lo que está en stage y lo re-agrega: el commit sale ya formateado.
  hook_repo hk-fmt
  printf '#  Hola   \n\n\n*  uno\n' >"$TMP/hk-fmt/doc.md"
  git -C "$TMP/hk-fmt" add doc.md
  hook_commit hk-fmt
  [ "$(git -C "$TMP/hk-fmt" show HEAD:doc.md)" = "$(printf '# Hola\n\n- uno')" ]
  check "formatea el .md en stage y lo re-agrega" 0 $?

  # Un archivo con cambios sin agregar no se toca: meteríamos en el commit
  # trabajo que se decidió dejar fuera.
  hook_repo hk-partial
  printf '# Uno\n' >"$TMP/hk-partial/otro.md"
  git -C "$TMP/hk-partial" add otro.md
  printf '# Uno\n\nsin  agregar\n' >"$TMP/hk-partial/otro.md"
  hook_commit hk-partial
  [ "$(git -C "$TMP/hk-partial" show HEAD:otro.md)" = "# Uno" ]
  check "archivo con cambios sin agregar → no se toca" 0 $?

  # El código de la aplicación es del linter del stack, no de Prettier.
  hook_repo hk-code
  printf 'puts    1\n' >"$TMP/hk-code/a.rb"
  git -C "$TMP/hk-code" add a.rb
  hook_commit hk-code
  [ "$(git -C "$TMP/hk-code" show HEAD:a.rb)" = "puts    1" ]
  check "código del stack → Prettier no lo toca" 0 $?

  # Nombres con acentos: git los escapa por defecto y el hook los perdería.
  hook_repo hk-acentos
  printf '#  Documentación   \n\n\n*  uno\n' >"$TMP/hk-acentos/documentación.md"
  git -C "$TMP/hk-acentos" add "documentación.md"
  hook_commit hk-acentos
  [ "$(git -C "$TMP/hk-acentos" show "HEAD:documentación.md")" = "$(printf '# Documentación\n\n- uno')" ]
  check "nombre con acentos → también se formatea" 0 $?

  # Nunca bloquea: ni con un archivo que Prettier no puede parsear.
  hook_repo hk-bad
  printf '{roto,,,\n' >"$TMP/hk-bad/bad.json"
  git -C "$TMP/hk-bad" add bad.json
  hook_commit hk-bad; check "archivo inválido → no bloquea el commit" 0 $?
fi

# ── check-design-tokens.sh ────────────────────────────────────────────────────
CHECK_DESIGN="$REPO_ROOT/.github/scripts/check-design-tokens.sh"
if [ -f "$CHECK_DESIGN" ]; then
  echo "check-design-tokens.sh:"

  # Repo de utilería con una vista en una carpeta de producto real.
  design_repo() { # $1 = nombre, $2 = ruta relativa de la vista
    mkdir -p "$TMP/$1/$(dirname "$2")"
  }
  run_design() { (bash "$CHECK_DESIGN" "$TMP/$1" > /dev/null 2>&1); }

  design_repo dz-ok app/views/v.html
  printf '<div class="bg-primary text-base-content">ok</div>\n' >"$TMP/dz-ok/app/views/v.html"
  run_design dz-ok; check "vista con tokens semánticos → pasa" 0 $?

  design_repo dz-paleta app/views/v.html
  printf '<div class="bg-blue-500">x</div>\n' >"$TMP/dz-paleta/app/views/v.html"
  run_design dz-paleta; check "utilidad de paleta cruda (Tailwind) → falla" 1 $?

  # El check es agnóstico del framework: la misma regla, escrita como la escribe
  # Sass/Bootstrap. Sin esto, un proyecto que no usa Tailwind pasaba en verde sin
  # que se mirara una sola de sus infracciones.
  design_repo dz-sass src/estilos.scss
  printf '.card { background: $gray-700; }\n' >"$TMP/dz-sass/src/estilos.scss"
  run_design dz-sass; check "variable de paleta cruda en Sass → falla" 1 $?

  design_repo dz-cp src/estilos.css
  printf '.btn { color: var(--ui-red); }\n' >"$TMP/dz-cp/src/estilos.css"
  run_design dz-cp; check "custom property con nombre de color → falla" 1 $?

  design_repo dz-cp-num src/estilos.css
  printf '.btn { color: var(--gray-700); }\n' >"$TMP/dz-cp-num/src/estilos.css"
  run_design dz-cp-num; check "custom property de paleta numerada → falla" 1 $?

  # …y los tokens del sistema pasan, aunque `neutral` sea también un nombre de
  # color: aquí es un ROL. Sin esta prueba, el patrón de arriba se los comía y el
  # check fallaba contra el propio design system que verifica.
  design_repo dz-cp-ok src/estilos.css
  printf '.btn { color: var(--neutral); background: var(--neutral-content); }\n' >"$TMP/dz-cp-ok/src/estilos.css"
  run_design dz-cp-ok; check "tokens semánticos del sistema → pasa" 0 $?

  design_repo dz-hex app/views/v.html
  printf '<div style="color:#ff0000">x</div>\n' >"$TMP/dz-hex/app/views/v.html"
  run_design dz-hex; check "color hex crudo → falla" 1 $?

  design_repo dz-arb app/views/v.html
  printf '<div class="bg-[#0A7A9D]">x</div>\n' >"$TMP/dz-arb/app/views/v.html"
  run_design dz-arb; check "valor arbitrario bg-[#…] → falla" 1 $?

  # `bg-neutral` es un token semántico del sistema; `bg-neutral-500` es paleta.
  design_repo dz-semantico app/views/v.html
  printf '<div class="bg-neutral text-neutral-content">x</div>\n' >"$TMP/dz-semantico/app/views/v.html"
  run_design dz-semantico; check "bg-neutral (semántico) → pasa" 0 $?

  # Enlaces internos con # no son colores.
  design_repo dz-ancla app/views/v.html
  printf '<a href="#precios">x</a><a href="#features">y</a>\n' >"$TMP/dz-ancla/app/views/v.html"
  run_design dz-ancla; check "anclas #… no cuentan como color → pasa" 0 $?

  # Logos de terceros: llevan SUS colores de marca; se marcan con data-brand.
  design_repo dz-marca app/views/v.html
  printf '<svg data-brand="google" viewBox="0 0 48 48"><path fill="#EA4335" d="M24 9.5z"/></svg>\n' \
    >"$TMP/dz-marca/app/views/v.html"
  run_design dz-marca; check "logo con data-brand → pasa" 0 $?

  # …pero la excepción es acotada: fuera del svg marcado, sigue fallando.
  design_repo dz-marca-fuera app/views/v.html
  printf '<svg data-brand="google"><path fill="#EA4335" d="M0 0z"/></svg>\n<div style="color:#ff0000">x</div>\n' \
    >"$TMP/dz-marca-fuera/app/views/v.html"
  run_design dz-marca-fuera; check "hex fuera de data-brand → falla igual" 1 $?

  # Cubre los otros dos stacks: Jinja (templates/) y React (src/).
  design_repo dz-jinja templates/v.j2
  printf '<div class="bg-red-400">x</div>\n' >"$TMP/dz-jinja/templates/v.j2"
  run_design dz-jinja; check "plantilla Jinja con paleta → falla" 1 $?

  design_repo dz-react src/App.tsx
  printf 'export default () => <div className="bg-[#123456]" />\n' >"$TMP/dz-react/src/App.tsx"
  run_design dz-react; check "componente React con valor arbitrario → falla" 1 $?

  # Sin vistas no se impone nada (repo recién instanciado o sin UI).
  mkdir -p "$TMP/dz-none"
  run_design dz-none; check "repo sin vistas → permite" 0 $?

  # …pero lo DICE, y dice qué buscó: "nada que verificar" era indistinguible de un ✅
  # real, y se leía como "no aplica" en vez de "no sé mirar esto".
  salida_dz="$(bash "$CHECK_DESIGN" "$TMP/dz-none" 2>&1 || true)"
  printf '%s' "$salida_dz" | grep -q 'Extensiones:'
  check "repo sin vistas → dice qué extensiones buscó" 0 $?

  # ── El agujero grande: el CSS y el JS no se miraban ────────────────────────
  # El CSS es donde viven los colores crudos en CUALQUIER stack, no solo en uno sin
  # framework: un Rails con app/assets/stylesheets/*.css tampoco se revisaba. Y un
  # proyecto sin framework pasaba en verde sin que se abriera un solo archivo.
  design_repo dz-css src/styles.css
  printf '.boton { background: #0a7a9d; }\n' >"$TMP/dz-css/src/styles.css"
  run_design dz-css; check "hex en un .css → falla" 1 $?

  design_repo dz-js src/vista.js
  printf 'export const tpl = () => `<div style="color:#ff0000">x</div>`;\n' >"$TMP/dz-js/src/vista.js"
  run_design dz-js; check "hex en una plantilla .js → falla" 1 $?

  # Y la raíz: en un proyecto sin framework la página vive en ./index.html y ninguna
  # carpeta de DIRS la cubre.
  mkdir -p "$TMP/dz-raiz"
  printf '<div style="color:#ff0000">x</div>\n' >"$TMP/dz-raiz/index.html"
  run_design dz-raiz; check "index.html en la raíz → se revisa" 1 $?

  # El archivo que DEFINE los tokens es la excepción: ahí el color crudo es el
  # contenido. Sin eximirlo, migrar design/tokens.css dentro de src/ ponía el check
  # en rojo permanente, que es la forma más rápida de que alguien lo borre.
  mkdir -p "$TMP/dz-tokens/src"
  printf ':root { --color-primary: #0a7a9d; }\n' >"$TMP/dz-tokens/src/tokens.css"
  run_design dz-tokens; check "tokens.css define los colores → exento" 0 $?

  # Documentar la regla no puede infringir la regla: los comentarios no llegan al
  # navegador. Este fue un falso positivo real — la cabecera de una hoja de estilos
  # que deletreaba los patrones prohibidos salía como hallazgo.
  design_repo dz-comentario src/styles.css
  printf '/* Regla de oro: nunca #ff0000 ni rgb(0,0,0). Solo tokens. */\n.b { color: var(--color-primary); }\n' \
    >"$TMP/dz-comentario/src/styles.css"
  run_design dz-comentario; check "hex dentro de un comentario CSS → no cuenta" 0 $?

  design_repo dz-comentario-js src/vista.js
  printf '// no uses #ff0000\nexport const c = "var(--color-primary)";\n' \
    >"$TMP/dz-comentario-js/src/vista.js"
  run_design dz-comentario-js; check "hex dentro de un comentario JS → no cuenta" 0 $?

  # Pero la exclusión de `//` no puede comerse el resto de la línea tras una URL:
  # sin el lookbehind, `https://` blanqueaba el hex que venía después.
  design_repo dz-url src/vista.js
  printf 'const doc = "https://example.com"; const c = "#ff0000";\n' >"$TMP/dz-url/src/vista.js"
  run_design dz-url; check "https:// no blanquea el resto de la línea → falla" 1 $?
fi

# ── check-inheritance.sh ─────────────────────────────────────────────────────────
CHECK_HERENCIA="$REPO_ROOT/.github/scripts/check-inheritance.sh"
if [ -f "$CHECK_HERENCIA" ]; then
  echo "check-inheritance.sh:"

  instancia() { # $1 = nombre, $2 = fecha de instanciación
    mkdir -p "$TMP/$1/docs/decisions"
    printf 'repo=https://github.com/x/y\ncommit=abc\nfecha=%s\n' "$2" >"$TMP/$1/.template-origin"
  }
  run_herencia() { (bash "$CHECK_HERENCIA" "$TMP/$1" > /dev/null 2>&1); }

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
  printf '# guía\n' >"$TMP/hr-parity/TEMPLATE-USAGE.md"
  run_herencia hr-parity; check "TEMPLATE-USAGE.md sobrante → falla" 1 $?

  # Fecha ilegible: falla abierto, no traba el flujo.
  mkdir -p "$TMP/hr-fecha"
  printf 'repo=x\nfecha=ayer\n' >"$TMP/hr-fecha/.template-origin"
  run_herencia hr-fecha; check "fecha inválida → permite" 0 $?

  # Mismo día: la plantilla publica y el proyecto instancia en la misma fecha.
  # Con `<` estricto esto pasaba y la herencia se colaba — bug real: las tres
  # versiones de la plantilla y una instanciación compartían el 2026-08-10.
  instancia hr-mismodia 2026-08-07
  printf '# Changelog\n\n## [Unreleased]\n\n## [0.2.1] - 2026-08-07\n\n- De la plantilla.\n' \
    >"$TMP/hr-mismodia/CHANGELOG.md"
  run_herencia hr-mismodia; check "CHANGELOG con versión del mismo día → falla" 1 $?

  # Con `versiones=` el criterio es exacto: una versión de la lista es herencia…
  mkdir -p "$TMP/hr-vers/docs/decisions"
  printf 'repo=x\ncommit=abc\nfecha=2026-08-07\nversiones=0.2.1,0.2.0,0.1.0\n' \
    >"$TMP/hr-vers/.template-origin"
  printf '# Changelog\n\n## [Unreleased]\n\n## [0.2.1] - 2026-08-07\n\n- De la plantilla.\n' \
    >"$TMP/hr-vers/CHANGELOG.md"
  run_herencia hr-vers; check "versiones=: versión de la plantilla → falla" 1 $?

  # …y un release PROPIO cortado el mismo día de instanciar NO se acusa.
  mkdir -p "$TMP/hr-vers-ok/docs/decisions"
  printf 'repo=x\ncommit=abc\nfecha=2026-08-07\nversiones=0.2.1,0.2.0\n' \
    >"$TMP/hr-vers-ok/.template-origin"
  printf '# Changelog\n\n## [Unreleased]\n\n## [0.1.0] - 2026-08-07\n\n- Primer release propio.\n' \
    >"$TMP/hr-vers-ok/CHANGELOG.md"
  run_herencia hr-vers-ok; check "versiones=: release propio del mismo día → pasa" 0 $?

  # …incluso cuando el número COINCIDE con una versión de la plantilla, que es el caso
  # normal y no el raro: toda plantilla tuvo una 0.1.0 y todo proyecto nuevo corta la
  # suya. Sin la exención, ningún arranque podía cortar su primera versión.
  mkdir -p "$TMP/hr-vers-primera/docs/decisions"
  printf 'repo=x\ncommit=abc\nfecha=2026-08-07\nversiones=0.4.0,0.3.0,0.2.0,0.1.0\n' \
    >"$TMP/hr-vers-primera/.template-origin"
  printf '# Changelog\n\n## [Unreleased]\n\n## [0.1.0] - 2026-08-07\n\n- Arranque propio.\n' \
    >"$TMP/hr-vers-primera/CHANGELOG.md"
  run_herencia hr-vers-primera
  check "versiones=: primera propia con número de la plantilla → pasa" 0 $?

  # Pero la exención NO tapa un reseteo olvidado: ahí lo que queda arriba es la versión
  # MÁS NUEVA de la plantilla, y las suyas siguen debajo.
  mkdir -p "$TMP/hr-vers-olvido/docs/decisions"
  printf 'repo=x\ncommit=abc\nfecha=2026-08-07\nversiones=0.4.0,0.3.0\n' \
    >"$TMP/hr-vers-olvido/.template-origin"
  printf '# Changelog\n\n## [Unreleased]\n\n## [0.4.0] - 2026-08-07\n\n- De la plantilla.\n\n## [0.3.0] - 2026-08-01\n\n- De la plantilla.\n' \
    >"$TMP/hr-vers-olvido/CHANGELOG.md"
  run_herencia hr-vers-olvido
  check "versiones=: reseteo olvidado (la más nueva arriba) → falla" 1 $?

  # El ADR de instanciación PROPIO (el 0002) se fecha el mismo día de
  # instanciar: aquí el `<` estricto es deliberado — con `<=` todo proyecto
  # sano saldría en rojo. (Asimetría documentada en el propio script.)
  instancia hr-adr-mismodia 2026-08-07
  printf '# 0002. Instanciación\n\n- **Fecha**: 2026-08-07\n' \
    >"$TMP/hr-adr-mismodia/docs/decisions/0002-instanciacion.md"
  run_herencia hr-adr-mismodia; check "ADR propio del mismo día → pasa" 0 $?

  # La fecha se extrae por patrón: texto tras la fecha no rompe la comparación
  # ("## [1.0.0] - 2026-08-08 (beta)" es POSTERIOR a la instanciación → pasa).
  instancia hr-sufijo 2026-08-07
  printf '# Changelog\n\n## [Unreleased]\n\n## [1.0.0] - 2026-08-08 (beta)\n\n- Propio.\n' \
    >"$TMP/hr-sufijo/CHANGELOG.md"
  run_herencia hr-sufijo; check "fecha con sufijo, posterior → pasa" 0 $?

  # ── --version-publicable ───────────────────────────────────────────────────
  # La guarda que impide publicar la release DE LA PLANTILLA. Pasó de verdad:
  # /instanciar crea main en el Paso 0 apuntando al commit inicial (CHANGELOG
  # heredado) y el push de main dispara release.yml, que publicó un v1.0.0 con
  # las notas del repo origen. Y lo caro venía después: el día que el proyecto
  # llegue a su propia v1.0.0, release.yml diría "ya tiene tag" y se saltaría
  # esa release en silencio.
  run_publicable() { (bash "$CHECK_HERENCIA" --version-publicable "$TMP/$1" >/dev/null 2>&1); }

  # El caso exacto del hallazgo: reseteo olvidado, la versión más nueva de la
  # plantilla arriba, fechada el día de instanciar.
  run_publicable hr-vers-olvido; check "publicable: reseteo olvidado → NO publica" 1 $?

  # Y el que no debe romperse nunca: la primera versión propia, mismo día,
  # con un número que la plantilla también tuvo.
  run_publicable hr-vers-primera; check "publicable: primera versión propia → publica" 0 $?
  run_publicable hr-vers-ok; check "publicable: release propio del mismo día → publica" 0 $?

  # La plantilla misma (sin .template-origin) publica lo suyo.
  run_publicable hr-plantilla; check "publicable: sin .template-origin → publica" 0 $?

  # Lo que de verdad cierra el fallo con retardo: cuando el proyecto llega a su
  # propia versión con el mismo número que la de la plantilla, PERO más tarde,
  # se publica. Si esto fallara, la guarda habría cambiado un fallo por otro.
  mkdir -p "$TMP/hr-pub-propia/docs/decisions"
  printf 'repo=x\ncommit=abc\nfecha=2026-08-07\nversiones=1.0.0,0.5.0\n' \
    >"$TMP/hr-pub-propia/.template-origin"
  printf '# Changelog\n\n## [Unreleased]\n\n## [1.0.0] - 2027-03-01\n\n- La v1 de verdad.\n' \
    >"$TMP/hr-pub-propia/CHANGELOG.md"
  run_publicable hr-pub-propia; check "publicable: v1.0.0 propia un año después → publica" 0 $?

  # Sin versiones= (instancias viejas) el criterio es el estricto: solo se
  # rechaza lo fechado ANTES de instalar. En la duda se publica, porque aquí el
  # falso positivo no es ruido: impide cortar la release.
  instancia hr-pub-vieja 2026-08-07
  printf '# Changelog\n\n## [Unreleased]\n\n## [0.9.0] - 2026-08-01\n\n- De la plantilla.\n' \
    >"$TMP/hr-pub-vieja/CHANGELOG.md"
  run_publicable hr-pub-vieja; check "publicable: sin versiones=, fecha anterior → NO publica" 1 $?

  instancia hr-pub-vieja-mismodia 2026-08-07
  printf '# Changelog\n\n## [Unreleased]\n\n## [0.1.0] - 2026-08-07\n\n- Propia.\n' \
    >"$TMP/hr-pub-vieja-mismodia/CHANGELOG.md"
  run_publicable hr-pub-vieja-mismodia; check "publicable: sin versiones=, mismo día → publica" 0 $?

  # Un CHANGELOG sin versión fechada no bloquea: de eso ya se ocupa release.yml.
  mkdir -p "$TMP/hr-pub-sinver"
  printf 'repo=x\nfecha=2026-08-07\n' >"$TMP/hr-pub-sinver/.template-origin"
  printf '# Changelog\n\n## [Unreleased]\n\n- Nada cortado.\n' >"$TMP/hr-pub-sinver/CHANGELOG.md"
  run_publicable hr-pub-sinver; check "publicable: sin versión fechada → no opina" 0 $?
fi

# ── check-project-tests.sh ────────────────────────────────────────────────────
CHECK_PROJECT_TESTS="$REPO_ROOT/.github/scripts/check-project-tests.sh"
if [ -f "$CHECK_PROJECT_TESTS" ]; then
  echo "check-project-tests.sh:"
  agents_md() { # $1 = dir, $2 = comando de pruebas (vacío = sin declarar)
    mkdir -p "$TMP/$1"
    {
      echo '# Proyecto'
      echo '## Uso'
      echo '```bash'
      [ -n "$2" ] && echo "$2   # suite de pruebas"
      echo '```'
    } >"$TMP/$1/README.md"
  }

  mkdir -p "$TMP/pt-sin"
  (bash "$CHECK_PROJECT_TESTS" "$TMP/pt-sin" >/dev/null); check "sin README.md → pasa avisando" 0 $?
  agents_md pt-hueco '[COMANDO_TEST]'
  (bash "$CHECK_PROJECT_TESTS" "$TMP/pt-hueco" >/dev/null); check "comando sin rellenar → pasa avisando" 0 $?
  agents_md pt-verde 'python3 -c "raise SystemExit(0)"'
  (bash "$CHECK_PROJECT_TESTS" "$TMP/pt-verde" >/dev/null 2>&1); check "suite en verde → pasa" 0 $?
  agents_md pt-rojo 'python3 -c "raise SystemExit(1)"'
  (bash "$CHECK_PROJECT_TESTS" "$TMP/pt-rojo" >/dev/null 2>&1); check "suite en rojo → falla" 1 $?

  # Allowlist: el comando viene de AGENTS.md y en CI corre sobre PRs de
  # terceros — uno fuera de la lista NO se ejecuta (aquí: crear un directorio).
  agents_md pt-raro 'mkdir dir-peligroso'
  (bash "$CHECK_PROJECT_TESTS" "$TMP/pt-raro" >/dev/null 2>&1); rc=$?
  [ "$rc" -eq 0 ] && [ ! -d "$TMP/pt-raro/dir-peligroso" ]
  check "comando fuera de la allowlist → no se ejecuta" 0 $?

  # Prefijos VAR=valor no cambian la clasificación (RAILS_ENV=test bin/rails
  # test es un comando de test normal) — antes caían en "no reconocido" y el
  # ✅ volvía a no probar nada.
  agents_md pt-env 'CI=1 python3 -c "raise SystemExit(1)"'
  (bash "$CHECK_PROJECT_TESTS" "$TMP/pt-env" >/dev/null 2>&1); check "prefijo VAR=valor: la suite corre (y falla) → falla" 1 $?

  # Un comando COMPUESTO no se clasifica por su prefijo: `npm test && <lo que
  # sea>` pasaba la allowlist entera hacia el eval.
  agents_md pt-compuesto 'python3 -c pass && mkdir dir-encadenado'
  (bash "$CHECK_PROJECT_TESTS" "$TMP/pt-compuesto" >/dev/null 2>&1); rc=$?
  [ "$rc" -eq 0 ] && [ ! -d "$TMP/pt-compuesto/dir-encadenado" ]
  check "comando compuesto → no se ejecuta" 0 $?

  # Entre el PR de documentación y el del andamiaje, AGENTS.md ya declara el comando
  # del stack elegido pero el proyecto no existe. Un gestor sin su manifiesto no es
  # una suite en rojo: no hay suite todavía.
  agents_md pt-sin-manifiesto 'pnpm test'
  (bash "$CHECK_PROJECT_TESTS" "$TMP/pt-sin-manifiesto" >/dev/null 2>&1)
  check "gestor sin manifiesto → pasa avisando" 0 $?
  # Pero con manifiesto sí corre: el atajo no puede tapar una suite real en rojo.
  agents_md pt-con-manifiesto 'npm test'
  echo '{"scripts":{"test":"exit 1"}}' >"$TMP/pt-con-manifiesto/package.json"
  (bash "$CHECK_PROJECT_TESTS" "$TMP/pt-con-manifiesto" >/dev/null 2>&1)
  check "gestor con manifiesto y suite en rojo → falla" 1 $?
fi

# ── check-instructions.sh ────────────────────────────────────────────────────
# La poda deja el README mandando ejecutar lo que ya no existe, y NINGÚN check lo
# reclamaba: `cp .env.example .env` no es un placeholder, es texto hardcodeado. Se
# lee como una instrucción correcta hasta que alguien la ejecuta.
if [ -f "$CHECK_INSTRUCCIONES" ]; then
  echo "check-instructions.sh:"
  instr() { mkdir -p "$TMP/$1"; }
  run_instr() { (bash "$CHECK_INSTRUCCIONES" "$TMP/$1" >/dev/null 2>&1); }

  # El caso del hallazgo: .env.example conservado a propósito pero SIN variables
  # —solo su explicación de por qué está vacío— y el README mandando copiarlo.
  instr in-vacio
  printf '# Variables de entorno\n# Ninguna: sin servidor, sin build, la clave vive en el navegador.\n' \
    >"$TMP/in-vacio/.env.example"
  printf '# P\n\n```bash\ngit clone x\ncp .env.example .env\n```\n' >"$TMP/in-vacio/README.md"
  run_instr in-vacio; check "instrucciones: .env.example sin variables + cp → falla" 1 $?

  # Con variables de verdad, el mismo README es correcto.
  instr in-vars
  printf 'APP_ENV=development\nPORT=3000\n' >"$TMP/in-vars/.env.example"
  printf '# P\n\n```bash\ncp .env.example .env\n```\n' >"$TMP/in-vars/README.md"
  run_instr in-vars; check "instrucciones: con variables → pasa" 0 $?

  # Los comentarios no son variables: un archivo lleno de `# FOO=bar` sigue vacío.
  instr in-comentado
  printf '# Ejemplo de lo que habrá algún día:\n#   DATABASE_URL=postgres://…\n' \
    >"$TMP/in-comentado/.env.example"
  printf '# P\n\n```bash\ncp .env.example .env\n```\n' >"$TMP/in-comentado/README.md"
  run_instr in-comentado; check "instrucciones: variables solo comentadas → falla" 1 $?

  # Sin la línea del README no hay nada que reprochar, aunque el archivo esté vacío:
  # conservar .env.example vacío CON su explicación es lo que manda /instanciar.
  instr in-podado
  printf '# Ninguna variable todavía.\n' >"$TMP/in-podado/.env.example"
  printf '# P\n\n```bash\ngit clone x\n```\n' >"$TMP/in-podado/README.md"
  run_instr in-podado; check "instrucciones: .env.example vacío pero README limpio → pasa" 0 $?

  # [COMANDO_MIGRACIONES] en un producto sin base de datos ni variables.
  instr in-migra
  printf '# Ninguna variable.\n' >"$TMP/in-migra/.env.example"
  printf '# P\n\n```bash\n[COMANDO_MIGRACIONES]\n```\n' >"$TMP/in-migra/README.md"
  run_instr in-migra; check "instrucciones: migraciones sin base de datos → falla" 1 $?

  # …pero con carpeta de migraciones el paso es legítimo.
  instr in-migra-ok
  mkdir -p "$TMP/in-migra-ok/db/migrate"
  printf '# Ninguna variable.\n' >"$TMP/in-migra-ok/.env.example"
  printf '# P\n\n```bash\n[COMANDO_MIGRACIONES]\n```\n' >"$TMP/in-migra-ok/README.md"
  run_instr in-migra-ok; check "instrucciones: migraciones con db/migrate → pasa" 0 $?

  # En modo PLANTILLA no impone nada: el README es todavía el esqueleto por podar,
  # y su .env.example trae los seis bloques.
  instr in-plantilla
  printf 'guía\n' >"$TMP/in-plantilla/TEMPLATE-USAGE.md"
  printf '# Ninguna variable.\n' >"$TMP/in-plantilla/.env.example"
  printf '# P\n\n```bash\ncp .env.example .env\n```\n' >"$TMP/in-plantilla/README.md"
  run_instr in-plantilla; check "instrucciones: modo plantilla → no opina" 0 $?

  # Sin README no hay nada que verificar.
  instr in-sin-readme
  run_instr in-sin-readme; check "instrucciones: sin README → permite" 0 $?
fi

# ── check-hooks-enabled.sh ────────────────────────────────────────────────────
# core.hooksPath no viaja en el repositorio: el estado por DEFECTO de todo clon es
# «sin verificación local». Y cuando GitHub no ofrece protección de ramas —repos
# privados de plan gratuito— esos hooks son la única defensa que queda.
if [ -f "$CHECK_HOOKS" ]; then
  echo "check-hooks-enabled.sh:"
  hooks_repo() { # $1 = nombre; repo con .githooks/ ejecutables
    mkdir -p "$TMP/$1/.githooks" && git -C "$TMP/$1" init -q -b main
    printf '#!/bin/sh\nexit 0\n' >"$TMP/$1/.githooks/pre-push"
    chmod +x "$TMP/$1/.githooks/pre-push"
  }
  run_hooks() { (bash "$CHECK_HOOKS" "$TMP/$1" >/dev/null 2>&1); }

  hooks_repo hk-sin
  run_hooks hk-sin; check "hooks: clon nuevo sin core.hooksPath → falla" 1 $?

  hooks_repo hk-con
  git -C "$TMP/hk-con" config core.hooksPath .githooks
  run_hooks hk-con; check "hooks: core.hooksPath puesto → pasa" 0 $?

  # Apuntar bien no basta: si no son ejecutables, git los ignora en silencio.
  hooks_repo hk-noexec
  git -C "$TMP/hk-noexec" config core.hooksPath .githooks
  chmod -x "$TMP/hk-noexec/.githooks/pre-push"
  run_hooks hk-noexec; check "hooks: apunta bien pero sin permiso de ejecución → falla" 1 $?

  # --arreglar los activa, y deja el repo pasando.
  hooks_repo hk-fix
  (bash "$CHECK_HOOKS" --arreglar "$TMP/hk-fix" >/dev/null 2>&1)
  check "hooks: --arreglar sale con 0" 0 $?
  run_hooks hk-fix; check "hooks: tras --arreglar, pasa" 0 $?
  [ "$(git -C "$TMP/hk-fix" config --get core.hooksPath)" = ".githooks" ]
  check "hooks: --arreglar deja core.hooksPath = .githooks" 0 $?

  # …y también repara el permiso, que es el otro modo de fallar en silencio.
  hooks_repo hk-fix-exec
  git -C "$TMP/hk-fix-exec" config core.hooksPath .githooks
  chmod -x "$TMP/hk-fix-exec/.githooks/pre-push"
  (bash "$CHECK_HOOKS" --arreglar "$TMP/hk-fix-exec" >/dev/null 2>&1)
  run_hooks hk-fix-exec; check "hooks: --arreglar repara el permiso" 0 $?

  # Un proyecto que borró .githooks/ no tiene nada que activar.
  mkdir -p "$TMP/hk-sin-carpeta" && git -C "$TMP/hk-sin-carpeta" init -q -b main
  run_hooks hk-sin-carpeta; check "hooks: sin carpeta .githooks → no opina" 0 $?

  # Fuera de un repo git tampoco opina.
  mkdir -p "$TMP/hk-no-git/.githooks"
  run_hooks hk-no-git; check "hooks: fuera de un repo git → no opina" 0 $?
fi

# ── La versión de Prettier vive en UN solo sitio ──────────────────────────────
# Va fija (no `prettier@3`) porque un formateador que cambia de minor cambia su
# salida: el mismo archivo pasa en una máquina y falla en el CI. Y va en un solo
# sitio porque dos versiones del mismo formateador en el mismo repo se pelean —
# pre-commit formatearía de una forma y el check del CI exigiría otra.
echo "versión de Prettier:"
FMT="$REPO_ROOT/.github/scripts/format.sh"
PRECOMMIT="$REPO_ROOT/.githooks/pre-commit"
if [ -f "$FMT" ]; then
  v_fmt="$(sed -n 's/^PRETTIER="\(.*\)"$/\1/p' "$FMT")"
  printf '%s' "$v_fmt" | grep -Eq '^prettier@[0-9]+\.[0-9]+\.[0-9]+$'
  check "format.sh fija una versión exacta de Prettier" 0 $?

  # Nadie INVOCA una versión literal: los dos scripts pasan la variable. Se busca
  # `npx … prettier@…` y no el string a secas, porque el respaldo de pre-commit
  # (`PRETTIER="prettier@3"`, que solo actúa si no puede leer format.sh) es una
  # asignación deliberada, no una invocación.
  sueltas="$(grep -rn 'npx.*prettier@' "$FMT" "$PRECOMMIT" 2>/dev/null || true)"
  [ -z "$sueltas" ]
  check "ningún script invoca una versión literal de Prettier" 0 $?
fi
if [ -f "$PRECOMMIT" ]; then
  # pre-commit no repite el número: lo lee de format.sh.
  grep -q 'sed -n .*PRETTIER=.*format\.sh' "$PRECOMMIT"
  check "pre-commit lee la versión de format.sh, no la repite" 0 $?
  # Y de hecho la lee bien: el valor que extrae es el que format.sh declara.
  v_pre="$(cd "$REPO_ROOT" && sed -n 's/^PRETTIER="\(.*\)"$/\1/p' .github/scripts/format.sh)"
  [ "$v_pre" = "$v_fmt" ]
  check "la versión que lee pre-commit coincide con la de format.sh" 0 $?
fi

# ── LABELS.md como fuente única de setup-labels.sh ────────────────────────────
SETUP_LABELS="$REPO_ROOT/.github/scripts/setup-labels.sh"
LABELS_MD_REAL="$REPO_ROOT/.github/LABELS.md"
if [ -f "$SETUP_LABELS" ] && [ -f "$LABELS_MD_REAL" ]; then
  echo "setup-labels.sh:"
  filas="$(grep -cE '^\| *`[^`]+` *\| *`#[0-9A-Fa-f]{6}` *\|' "$LABELS_MD_REAL" || true)"
  [ "$filas" -ge 10 ]; check "LABELS.md tiene filas parseables ($filas)" 0 $?
  # Ni un label hardcodeado en el script: eran dos copias y ya habían divergido
  # ("Cambios en documentación" vs "Cambios solo de documentación").
  ! grep -qE 'create_label "[a-z]' "$SETUP_LABELS"; check "setup-labels.sh sin labels hardcodeados" 0 $?
fi

# ── Estructura de .github/workflows/ ──────────────────────────────────────────
# GitHub ejecuta CUALQUIER .yml/.yaml de esa carpeta, sin mirar el resto del
# nombre: `ci.example.yml` se ejecutaba de verdad (workflow "CI" en verde sin
# probar nada). Lo que no deba ejecutarse no puede terminar en .yml/.yaml.
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
