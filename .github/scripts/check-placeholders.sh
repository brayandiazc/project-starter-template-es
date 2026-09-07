#!/usr/bin/env bash
# check-placeholders.sh — verifica los placeholders `[ASÍ]` de la plantilla.
#
# Dos modos, autodetectados:
#   - Modo PLANTILLA (existe TEMPLATE-USAGE.md): todo placeholder usado en el
#     repo debe estar documentado en el catálogo de TEMPLATE-USAGE.md (§3),
#     de forma literal o cubierto por un comodín como `[COMANDO_*]`.
#   - Modo INSTANCIA (TEMPLATE-USAGE.md ya fue borrado): no debe quedar ningún
#     placeholder sin rellenar, salvo en los esqueletos intencionales y salvo los
#     marcados como PENDIENTE (ver abajo).
#
# Placeholders pendientes: al instanciar hay datos que legítimamente no se pueden
# inferir (un email de seguridad, una URL que aún no existe). La regla de
# al instanciar es "no inventes datos", así que esos se dejan — pero marcados:
#
#     - **Email de seguridad**: [EMAIL_SEGURIDAD] <!-- pendiente: aún sin buzón -->
#
# Un placeholder con marca de pendiente en su línea —o en la inmediatamente siguiente,
# porque Prettier parte líneas dentro de los bloques de código— no falla; los demás sí.
# La marca se acepta en las tres sintaxis de comentario que aparecen en el repo, porque
# los placeholders viven también dentro de bloques ```bash y en .env.example, donde un
# comentario HTML saldría literal:
#
#     [EMAIL_SEGURIDAD] <!-- pendiente: sin buzón -->     markdown
#     [COMANDO_TEST]     # pendiente: falta scaffolding   bash, .env
#     [RUTA_VISTAS]      // pendiente                     js/ts
# Así se distingue lo que decidiste dejar de lo que se te olvidó, que era la
# contradicción entre "no inventes datos" y "no debe quedar ninguno".
#
# Uso:
#   bash .github/scripts/check-placeholders.sh [raíz-del-repo]
#   bash .github/scripts/check-placeholders.sh --rutas-sustituibles [raíz]
#
# Requiere: git, perl. Sale con 1 si encuentra problemas.
set -euo pipefail

MARCAR=0
RUTAS=0
case "${1:-}" in
  --marcar) MARCAR=1; shift ;;
  # --rutas-sustituibles: imprime, una por línea, las rutas donde un placeholder
  # ES un valor por sustituir. Acota la pasada de relleno del arranque en vez de
  # recorrer el repositorio entero.
  #
  # Existe porque el alcance de esa pasada ya estaba definido aquí —en SKIP— y
  # nadie lo leía: la pasada global corrompió los fixtures de este mismo banco de
  # pruebas y rellenó las plantillas internas de docs/, que existen justamente
  # para conservar sus placeholders.
  #
  # La información no faltaba; faltaba una sola definición que ambos lados
  # usaran. Esta es esa definición: si cambia SKIP, cambia la lista.
  --rutas-sustituibles) RUTAS=1; shift ;;
esac

ROOT="${1:-.}"
cd "$ROOT"

CATALOG="TEMPLATE-USAGE.md"

# Rutas que se saltan en ambos modos:
#   - esqueletos que conservan placeholders a propósito (plantillas de docs);
#   - .github/scripts/ y .github/workflows/ (código, no documentación);
#   - CHANGELOG.md: es un registro histórico, no un formulario. Una entrada que
#     *menciona* un placeholder ("se elimina el bloque con [BASE_DE_DATOS]") no es
#     un hueco por rellenar, y reescribir el pasado para acallar un check sería
#     justo lo contrario de para qué sirve un changelog.
# El resto de .github/ SÍ se revisa: saltarlo entero dejaba el [URL_REPOSITORIO]
# de ISSUE_TEMPLATE/config.yml sin rellenar para siempre — enlaces rotos en la
# propia UI de GitHub de cada instancia.
SKIP='^(\.github/scripts/|\.github/workflows/|CHANGELOG\.md$|docs/conventions/_template\.md|docs/decisions/0000-template\.md)'

# Menciones "meta" sobre el propio sistema de placeholders (no son placeholders
# que haya que rellenar), y los prefijos de título de las plantillas de issue
# ("[BUG] …"), que sobreviven a la instanciación por diseño. Una sola lista
# (META_ALT) alimenta los tres filtros que la usan — tenerla copiada ya produjo
# un conteo falso de "pendientes" en el resumen.
META_ALT='PLACEHOLDER|PLACEHOLDERS|CORCHETES_EN_MAYÚSCULAS|BUG|FEATURE|TASK'
META="^(${META_ALT})\$"

# Extrae placeholders [MAYÚSCULAS] de un archivo, ignorando los enlaces
# markdown `[TEXTO](destino)` gracias al lookahead negativo.
extract() {
  perl -CSD -ne 'while (/\[([A-ZÁÉÍÓÚÑ0-9_\/]{2,})\](?!\()/g) { print "$ARGV:$.: [$1]\n" }' "$1"
}

# Huecos EN PROSA: `[Un párrafo describiendo…]`, `[NOMBRE / OBJETIVO]`, `[Qué representa]`.
# No siguen la convención [MAYÚSCULAS_SIN_ESPACIOS] y por eso el patrón de arriba no los
# veía: un roadmap íntegramente sin rellenar pasaba en verde, y en un repositorio recién
# instanciado había 160 de estos sin contar por nadie.
#
# Solo se revisan en modo INSTANCIA: en modo plantilla son legítimos —el esqueleto está
# hecho de ellos— y catalogarlos uno a uno no tendría sentido.
#
# Se excluye lo que lleva corchetes con todo derecho:
#   [texto](enlace)   enlaces markdown        → lookahead (?!\()
#   - [ ] / - [x]     casillas de tarea       → se exige que no abra la línea como tal
#   [!NOTE]           admoniciones de GitHub  → empiezan por !
#   ```…```           bloques de código       → lo de dentro es código citado, no prosa
# Lo último no es un detalle: la sintaxis normal de Mermaid usa corchetes para sus
# nodos —`A["Anfitrión"]`, `Inicio([Entrada])`— y la plantilla recomienda diagramas
# Mermaid en architecture.md, database.md y screens.md, así que sin esta exclusión
# el choque era seguro en toda instancia y empujaba a deformar los diagramas (nodos
# redondeados solo para contentar al check). Los placeholders [MAYÚSCULAS] NO quedan
# eximidos: extract_sin_pendientes() sigue mirando dentro de las vallas, porque un
# [COMANDO_TEST] en un bloque ```bash sí es un valor por sustituir.
extract_prosa() {
  perl -CSD -e '
    my $f = shift;
    open my $fh, "<:encoding(UTF-8)", $f or exit 0;
    my @l = <$fh>;
    close $fh;
    my $valla = 0;
    for my $i (0 .. $#l) {
      my $linea = $l[$i];
      if ($linea =~ /^\s*(?:```|~~~)/) { $valla = !$valla; next; }
      next if $valla;
      next if $linea =~ m{(?:<!--|\#|//)\s*pendiente}i;
      next if defined $l[$i + 1] && $l[$i + 1] =~ m{^\s*(?:<!--|\#|//)\s*pendiente}i;
      # Fuera las casillas de tarea antes de mirar nada más.
      $linea =~ s/^(\s*[-*]\s*)\[[ xX]\]/$1/;
      # Y fuera el código en línea: `[data-theme="dark"]` es un ejemplo citado, no un
      # hueco por rellenar. Lo mismo cualquier selector o fragmento entre acentos graves.
      $linea =~ s/`[^`]*`//g;
      while ($linea =~ /\[([^\]\[]{3,})\](?!\()/g) {
        my $t = $1;
        next if $t =~ /^!/;                      # [!NOTE], [!WARNING]
        next if $t !~ /[a-záéíóúñ]/;             # solo MAYÚSCULAS: ya lo ve extract()
        next if $t =~ /^(Unreleased|\d+\.\d+\.\d+)$/;  # sintaxis de Keep a Changelog
        next if $t =~ /=/;                       # selectores tipo [data-theme="dark"]
        printf "%s:%d: [%s]\n", $f, $i + 1, $t;
      }
    }
  ' "$1"
}

# Igual, pero saltándose los placeholders marcados como pendientes a propósito.
#
# La marca vale en la MISMA línea o en la INMEDIATAMENTE SIGUIENTE. Lo segundo no
# es laxitud: `pre-commit` formatea con Prettier, que dentro de una valla ```html
# parte la línea y deja el comentario debajo —
#
#     <meta content="[URL_IMAGEN_OG]" /> <!-- pendiente: falta la imagen -->
#   se convierte en
#     <meta content="[URL_IMAGEN_OG]" />
#     <!-- pendiente: falta la imagen -->
#
# — así que exigir la misma línea hacía que marcar bien y commitear rompiera el
# check, aconsejando hacer justo lo que ya habías hecho. La línea siguiente se
# acepta solo si el comentario la ABRE (nada más que espacios antes): así un
# marcador puesto para otro placeholder no excusa a este por vecindad.
extract_sin_pendientes() {
  perl -CSD -e '
    my $f = shift;
    open my $fh, "<:encoding(UTF-8)", $f or exit 0;
    my @l = <$fh>;
    close $fh;
    for my $i (0 .. $#l) {
      next if $l[$i] =~ m{(?:<!--|\#|//)\s*pendiente}i;
      next if defined $l[$i + 1] && $l[$i + 1] =~ m{^\s*(?:<!--|\#|//)\s*pendiente}i;
      while ($l[$i] =~ /\[([A-ZÁÉÍÓÚÑ0-9_\/]{2,})\](?!\()/g) {
        printf "%s:%d: [%s]\n", $f, $i + 1, $1;
      }
    }
  ' "$1"
}

# `git ls-files` lista lo que git TRAZA, no lo que hay en disco: durante una poda,
# un archivo borrado con `rm` (y no con `git rm`) sigue saliendo aquí y perl fallaba
# al abrirlo, escupiendo su error crudo mientras el resumen daba todo por revisado.
files() {
  # --others --exclude-standard añade lo que EXISTE pero git aún no traza, respetando
  # .gitignore: al adoptar la plantilla en un proyecto existente se copian decenas de
  # documentos sin commitear, y sin esto el check los ignoraba y respondía "no queda
  # ninguno" justo cuando la pregunta era "¿qué me falta rellenar?".
  # config.yml entra explícito: no es .md, pero lleva [URL_REPOSITORIO] y es lo
  # que GitHub muestra como enlaces de contacto en "New issue".
  git ls-files --cached --others --exclude-standard '*.md' '.env.example' '.github/ISSUE_TEMPLATE/config.yml' \
    | sort -u | grep -Ev "$SKIP" | while IFS= read -r f; do
      [ -f "$f" ] && printf '%s\n' "$f"
    done || true
}

# ── --rutas-sustituibles: el alcance de la pasada de relleno, y nada más ──────
# Se sirve de files(), así que sale de la MISMA lista SKIP que usan los dos modos
# del check. No imprime nada más —ni cabecera ni resumen— para que se pueda
# canalizar directo: `... --rutas-sustituibles | xargs perl -pi -e '...'`.
if [ "$RUTAS" -eq 1 ]; then
  files
  exit 0
fi

if [ -f "$CATALOG" ]; then
  # ── Modo PLANTILLA: consistencia del catálogo ──────────────────────────────
  # Prefijos comodín documentados en el catálogo, p. ej. `[COMANDO_*]` → COMANDO_.
  wildcards="$(perl -CSD -ne 'while (/\[([A-ZÁÉÍÓÚÑ0-9_\/]+_)\*\]/g) { print "$1\n" }' "$CATALOG" | sort -u)"

  missing=0
  placeholders="$(
    files | grep -v "^$CATALOG$" | while IFS= read -r f; do extract "$f"; done \
      | sed -E 's/^.*\[([^]]+)\]$/\1/' | sort -u
  )"

  while IFS= read -r p; do
    [ -z "$p" ] && continue
    printf '%s' "$p" | grep -Eq "$META" && continue
    grep -qF "[$p]" "$CATALOG" && continue
    covered=0
    while IFS= read -r w; do
      [ -n "$w" ] && case "$p" in "$w"*) covered=1 ;; esac
    done <<<"$wildcards"
    [ "$covered" -eq 1 ] && continue
    echo "❌ [$p] se usa en el repo pero no está en el catálogo de $CATALOG (§3)."
    missing=1
  done <<<"$placeholders"

  if [ "$missing" -ne 0 ]; then
    echo "→ Añade los placeholders faltantes al catálogo de $CATALOG."
    exit 1
  fi
  echo "✅ Placeholders: todos los usados están documentados en el catálogo."
else
  # ── Modo INSTANCIA: no deben quedar placeholders sin rellenar ──────────────
  # Pendientes DE PROYECTO: un dato que falta en todas partes a la vez (el buzón del
  # cliente, el dominio sin contratar) no se marca línea por línea — son decenas de
  # comentarios para una sola pregunta sin responder, y en `legal/`, que se publica
  # como páginas del producto, meterían comentarios HTML en los términos. Se declaran
  # una vez en `.pendientes`, en la raíz:
  #
  #     EMAIL_SOPORTE=el cliente aún no da el buzón
  #
  # Se listan aparte en el resumen, que es donde sirven: en un solo sitio para
  # reclamárselos a quien los debe.
  globales=""
  if [ -f .pendientes ]; then
    globales="$(sed -n 's/^\([A-ZÁÉÍÓÚÑ0-9_]\{2,\}\)=.*/\1/p' .pendientes | sort -u)"
  fi

  leftovers="$(files | while IFS= read -r f; do extract_sin_pendientes "$f"; done || true)"
  # Las plantillas de issue/PR son formularios cuyos huecos en prosa ("[Ej.
  # iPhone 13]") son para quien reporta, no para quien instancia: fuera del
  # check de prosa (el de [MAYÚSCULAS] sí les aplica — ahí vive URL_REPOSITORIO).
  prosa="$(files | grep -Ev '^\.github/(ISSUE_TEMPLATE|PULL_REQUEST_TEMPLATE)' \
    | while IFS= read -r f; do extract_prosa "$f"; done || true)"
  # Se filtra por la entrada extraída (`archivo:línea: [NOMBRE]`), no por la línea del
  # documento: si una línea tuviera dos placeholders y solo uno fuera global, el otro
  # tiene que seguir fallando.
  while IFS= read -r g; do
    [ -z "$g" ] && continue
    leftovers="$(printf '%s' "$leftovers" | grep -v "\[$g\]\$" || true)"
  done <<<"$globales"
  # También aquí las menciones meta no cuentan como pendientes.
  leftovers="$(printf '%s' "$leftovers" | grep -Ev "\[(${META_ALT})\]" || true)"

  # --marcar: adoptar este check en un proyecto que ya existe pone en rojo, de golpe,
  # todos los huecos que hasta ahora nadie exigía —160 en un repositorio real—. Marcarlos
  # a mano uno a uno no lo hace nadie; dejar el CI en rojo tampoco es opción, porque un
  # rojo permanente deja de mirarse.
  #
  # Esto los marca en una sola pasada, DICIENDO que están sin revisar. No los rellena ni
  # los esconde: siguen listados en cada ejecución, que es exactamente lo que hace que
  # molesten hasta que alguien los escriba.
  #
  # Solo toca los huecos EN PROSA. Los placeholders [MAYÚSCULAS] son valores que hay que
  # sustituir, y marcarlos en bloque sí sería esconderlos.
  if [ "$MARCAR" -eq 1 ]; then
    if [ -z "$prosa" ]; then
      echo "✅ No hay huecos en prosa que marcar."
      exit 0
    fi
    printf '%s\n' "$prosa" | perl -ne '
      next unless /^(.+?):(\d+): /;
      push @{$sitios{$1}}, $2;
      END {
        for my $f (sort keys %sitios) {
          open my $in, "<:encoding(UTF-8)", $f or next;
          my @l = <$in>;
          close $in;
          my %n = map { $_ => 1 } @{$sitios{$f}};
          for my $i (keys %n) {
            next unless defined $l[$i - 1];
            chomp(my $t = $l[$i - 1]);
            $l[$i - 1] = "$t <!-- pendiente: heredado al adoptar el check, sin revisar -->\n";
          }
          open my $out, ">:encoding(UTF-8)", $f or next;
          print $out @l;
          close $out;
          printf "   · %s (%d)\n", $f, scalar keys %n;
        }
      }
    '
    n_m="$(printf '%s' "$prosa" | grep -c . || true)"
    echo "✅ Marcados $n_m hueco(s) como heredados y sin revisar."
    echo "→ Commitea esto APARTE, antes de adoptar el check. Siguen listándose en cada"
    echo "  ejecución hasta que alguien los escriba: esa es la idea."
    exit 0
  fi

  # Los huecos en prosa se listan aparte: son de otra naturaleza —párrafos por escribir,
  # no valores por sustituir— y mezclarlos haría la salida ilegible.
  if [ -n "$prosa" ]; then
    n_prosa="$(printf '%s' "$prosa" | grep -c . || true)"
    echo "❌ Quedan $n_prosa hueco(s) de documentación sin escribir:"
    printf '%s\n' "$prosa" | head -20 | sed 's/^/   · /'
    [ "${n_prosa:-0}" -gt 20 ] && echo "   … y $((n_prosa - 20)) más."
    echo "→ Escríbelos, o márcalos con '<!-- pendiente: por qué -->' en su línea o la"
    echo "  siguiente, o borra la sección si no aplica a este producto."
  fi

  if [ -n "$leftovers" ]; then
    echo "❌ Quedan placeholders sin rellenar:"
    printf '%s\n' "$leftovers"
    echo "→ Rellénalos, o márcalos como decisión consciente con un comentario"
    echo "  '<!-- pendiente: por qué -->' en su misma línea o en la siguiente,"
    echo "  o borra el documento si no aplica."
    echo "  (En .env.example y en bloques de código la marca va con '#' o '//'.)"
    exit 1
  fi

  [ -n "$prosa" ] && exit 1

  # Los marcados sí se listan, para que no se conviertan en permanentes por inercia.
  # El filtro usa $META entera: sin BUG|FEATURE|TASK aquí, toda instancia limpia
  # reportaba "Quedan 3 marcado(s)" para siempre — un conteo falso permanente.
  pendientes="$(files | while IFS= read -r f; do extract "$f"; done || true)"
  pendientes="$(printf '%s' "$pendientes" | grep -Ev "\[(${META_ALT})\]" || true)"
  n="$(printf '%s' "$pendientes" | grep -c . || true)"

  if [ "${n:-0}" -gt 0 ]; then
    echo "✅ Placeholders: ninguno olvidado. Quedan $n marcado(s) como pendiente:"
    printf '%s\n' "$pendientes" | sed 's/^/   · /'
  else
    echo "✅ Placeholders: no queda ninguno sin rellenar."
  fi

  if [ -n "$globales" ]; then
    echo "   Pendientes de proyecto declarados en .pendientes:"
    sed -n 's/^\([A-ZÁÉÍÓÚÑ0-9_]\{2,\}\)=\(.*\)/   · \1 — \2/p' .pendientes
  fi
fi
