#!/usr/bin/env bash
# check-inheritance.sh — un proyecto instanciado no arrastra la vida de la plantilla.
#
# Todo lo de producto (roadmap, modelo de negocio) llega vacío al usuario, pero el
# CHANGELOG y los ADRs se colaban llenos del historial del repositorio origen. Este
# check lo impide, y usa un criterio determinista en vez de heurísticas de texto:
#
#   `.template-origin` guarda la FECHA de instanciación. Un proyecto creado el día X
#   no puede tener versiones publicadas ni decisiones tomadas antes del día X. Lo que
#   esté fechado antes, es herencia y sobra.
#
# Verifica tres cosas:
#   1. CHANGELOG.md sin versiones anteriores a la instanciación.
#   2. docs/decisions/ sin ADRs anteriores a la instanciación (salvo el 0001, que es
#      el ADR canónico sobre por qué se registran las decisiones: ese sí se hereda).
#   3. Sin los archivos exclusivos del repo-plantilla.
#
# Uso:
#   bash .github/scripts/check-inheritance.sh [raíz-del-repo]
#   bash .github/scripts/check-inheritance.sh --version-publicable [raíz-del-repo]
#
# En la plantilla misma no hay `.template-origin`, así que no impone nada: solo
# actúa en proyectos ya instanciados. Sale con 1 si encuentra herencia.
set -euo pipefail

PUBLICABLE=0
# --version-publicable: ¿la versión de arriba del CHANGELOG es de ESTE proyecto?
# Sale con 1 si es de la plantilla. Lo consultan release.yml (antes de crear el
# tag) y check-release.sh (antes de fusionar a main).
#
# Existe porque publicar `main` antes de resetear el CHANGELOG publica la release
# DE LA PLANTILLA, y nada lo atrapaba: se publica `main` apuntando al commit
# inicial —con el CHANGELOG heredado— y el push dispara
# release.yml, que ve la versión de arriba, comprueba que no tiene tag y la
# publica con las notas de otro repositorio. La poda manda `git tag -d`, pero el
# tag todavía no existe cuando eso corre: lo crea el push, dos pasos después.
#
# Y la parte cara es la de después: el día que el proyecto llegue a su propia
# 1.0.0, release.yml dirá "ya tiene tag" y se saltará esa release EN SILENCIO.
# Un fallo plantado hoy que se cobra dentro de un año.
if [ "${1:-}" = "--version-publicable" ]; then
  PUBLICABLE=1
  shift
fi

ROOT="${1:-.}"
cd "$ROOT"

ORIGEN=".template-origin"

if [ ! -f "$ORIGEN" ]; then
  [ "$PUBLICABLE" -eq 1 ] && exit 0   # la plantilla misma: publica lo suyo
  echo "ℹ️  Sin $ORIGEN: esto no es un proyecto instanciado. Nada que verificar."
  exit 0
fi

fecha="$(grep -m1 '^fecha=' "$ORIGEN" | cut -d= -f2- | tr -d '[:space:]' || true)"

if ! printf '%s' "$fecha" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'; then
  [ "$PUBLICABLE" -eq 1 ] && exit 0
  echo "ℹ️  $ORIGEN no trae una fecha válida ('${fecha:-vacía}'); se omite la verificación."
  exit 0
fi

# ── Modo --version-publicable ────────────────────────────────────────────────
# Mismo criterio que el bloque 1, aplicado a UNA versión: la de arriba del
# CHANGELOG, que es la que release.yml publicaría.
#
#   Con `versiones=` (lo normal, se escribe al instanciar): es herencia si el
#   número está en la lista y la fecha no es posterior a la instanciación —
#   salvo la excepción de la primera versión propia, idéntica a la del bloque 1:
#   toda instancia corta su 0.1.0 el mismo día de instalar, y la plantilla
#   también tuvo una 0.1.0. Se exime si está fechada ese día Y su número NO es
#   el de la versión más nueva de la plantilla, porque esa es justo la que queda
#   arriba cuando alguien se salta el reseteo.
#
#   Sin `versiones=` (instancias viejas): solo se rechaza lo fechado ESTRICTAMENTE
#   antes de instalar. Aquí el falso positivo no es ruido — impide publicar—, así
#   que en la duda se publica.
if [ "$PUBLICABLE" -eq 1 ]; then
  [ -f CHANGELOG.md ] || exit 0
  linea="$(grep -m1 -E '^## \[[0-9]+\.[0-9]+\.[0-9]+\] - [0-9]{4}-[0-9]{2}-[0-9]{2}' CHANGELOG.md || true)"
  [ -z "$linea" ] && exit 0
  v="$(sed -E 's/^## \[([0-9]+\.[0-9]+\.[0-9]+)\].*/\1/' <<<"$linea")"
  d="$(grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' <<<"$linea" | tail -1)"
  versiones="$(grep -m1 '^versiones=' "$ORIGEN" | cut -d= -f2- | tr -d '[:space:]' || true)"
  vs_nueva="${versiones%%,*}"

  heredada=0
  if [ -n "$versiones" ]; then
    case ",$versiones," in
      *",$v,"*)
        if [ "$d" \> "$fecha" ]; then heredada=0
        elif [ "$d" = "$fecha" ] && [ "$v" != "$vs_nueva" ]; then heredada=0
        else heredada=1
        fi
        ;;
    esac
  elif [ "$d" \< "$fecha" ]; then
    heredada=1
  fi

  if [ "$heredada" -eq 1 ]; then
    echo "⛔ v$v ($d) es una versión DE LA PLANTILLA, no de este proyecto."
    echo "   Instanciado el $fecha${versiones:+; versiones heredadas: $versiones}."
    echo "→ Publicarla crearía un tag y un release con las notas de otro repositorio."
    echo "  Peor: el día que este proyecto llegue a su propia v$v, release.yml diría"
    echo "  'ya tiene tag' y se saltaría esa release en silencio."
    echo "  Resetea el CHANGELOG al instanciar y corta tu propia versión."
    exit 1
  fi
  exit 0
fi

fail=0

# ── 1. Versiones heredadas en el CHANGELOG ───────────────────────────────────
# Criterio principal: `.template-origin` puede traer `versiones=` con la lista
# exacta de versiones que la plantilla tenía al instanciar (las escribe
# al instanciar). Una entrada del CHANGELOG con una de esas versiones Y fecha no
# posterior a la instanciación es herencia, sin ambigüedad.
# Fallback (instancias viejas sin `versiones=`): por fecha, con `<=` — el `<`
# estricto dejaba pasar la herencia cuando plantilla e instancia compartían
# día, que es el caso normal de "instalo la plantilla recién publicada". El
# coste del `<=` es señalar un release propio cortado el mismo día de la
# instanciación: raro, y el mensaje lo explica.
if [ -f CHANGELOG.md ]; then
  versiones="$(grep -m1 '^versiones=' "$ORIGEN" | cut -d= -f2- | tr -d '[:space:]' || true)"
  # La fecha se extrae por patrón, no con $NF: un encabezado con texto tras la
  # fecha ("## [1.0.0] - 2026-01-01 (nombre en clave)") dejaba en $NF otra cosa
  # y la comparación de cadenas daba falso positivo.
  # Exención de la primera versión propia: todo proyecto nuevo corta su `0.1.0` el mismo
  # día de instanciar, y la plantilla también tuvo una `0.1.0` — así que `versiones=` la
  # daba por heredada aunque el reseteo se hubiera hecho bien, y ningún arranque podía
  # cortar su release. Se exime la entrada de arriba del todo si está fechada ese día Y
  # su número NO es el de la versión más nueva de la plantilla (el primer elemento de
  # `versiones=`), porque **esa es justo la que queda arriba cuando alguien se salta el
  # reseteo**. Y es una sola entrada: lo que quede debajo se sigue señalando.
  vs_nueva="${versiones%%,*}"
  heredadas="$(grep -E '^## \[[0-9]+\.[0-9]+\.[0-9]+\] - [0-9]{4}-[0-9]{2}-[0-9]{2}' CHANGELOG.md \
    | awk -v f="$fecha" -v vs=",$versiones," -v vn="$vs_nueva" '{
        v = $2; gsub(/[][]/, "", v)
        if (!match($0, /[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/)) next
        d = substr($0, RSTART, RLENGTH)
        n++
        if (vs != ",,") {
          if (n == 1 && d == f && v != vn) next
          if (index(vs, "," v ",") && d <= f) print "   · " $0
        }
        else if (d <= f) print "   · " $0
      }' || true)"
  if [ -n "$heredadas" ]; then
    echo "❌ El CHANGELOG arrastra versiones anteriores a la instanciación ($fecha):"
    printf '%s\n' "$heredadas"
    echo "→ Son de la plantilla, no de tu proyecto. Deja el CHANGELOG con tu propia"
    echo "  primera versión; la historia de la plantilla vive en su repositorio."
    echo "  (¿Es un release TUYO cortado el mismo día de instanciar? Añade"
    echo "  'versiones=' con las versiones de la plantilla a .template-origin para"
    echo "  que el criterio sea exacto.)"
    fail=1
  fi
fi

# ── 2. ADRs heredados ────────────────────────────────────────────────────────
# Se exceptúa el 0001: es el ADR canónico sobre por qué se registran decisiones,
# y su sitio es cualquier proyecto que use ADRs.
if [ -d docs/decisions ]; then
  adrs=""
  for f in docs/decisions/*.md; do
    [ -f "$f" ] || continue
    case "$(basename "$f")" in
      0000-template.md | 0001-record-architecture-decisions.md | README.md) continue ;;
    esac
    d="$(grep -m1 -oE '\*\*Fecha\*\*:[[:space:]]*[0-9]{4}-[0-9]{2}-[0-9]{2}' "$f" \
      | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' || true)"
    [ -z "$d" ] && continue
    # Aquí el `<` estricto es DELIBERADO, al revés que en el CHANGELOG: el ADR
    # de instanciación del propio proyecto (el 0002) se fecha el mismo día de
    # instanciar, así que `<=` pondría en rojo a todo proyecto sano. El residuo
    # (un ADR de la plantilla fechado justo ese día que la poda no borró) queda
    # aceptado y documentado.
    if [ "$d" \< "$fecha" ]; then
      adrs="$adrs   · $f (fecha: $d)"$'\n'
    fi
  done
  if [ -n "$adrs" ]; then
    echo "❌ Hay ADRs anteriores a la instanciación ($fecha):"
    printf '%s' "$adrs"
    echo "→ Son decisiones de la plantilla, no tuyas. Retíralos: el ADR de"
    echo "  instanciación ya documenta qué se heredó y enlaza al repositorio origen."
    fail=1
  fi
fi

# ── 3. Archivos exclusivos del repo-plantilla ────────────────────────────────
declare -a sobrantes=()
for ruta in \
  "TEMPLATE-USAGE.md"; do
  [ -e "$ruta" ] && sobrantes+=("$ruta")
done

if [ "${#sobrantes[@]}" -gt 0 ]; then
  echo "❌ Quedan archivos que solo tienen sentido en el repo-plantilla:"
  printf '   · %s\n' "${sobrantes[@]}"
  echo "→ Bórralo (regla de poda de TEMPLATE-USAGE.md §7): es la guía de"
  echo "  arranque de la plantilla, ya cumplidos. Además, mientras TEMPLATE-USAGE.md"
  echo "  exista, check-placeholders.sh cree que este repo sigue siendo la plantilla."
  fail=1
fi

if [ "$fail" -ne 0 ]; then
  exit 1
fi

echo "✅ Herencia: el proyecto no arrastra historial ni archivos de la plantilla."
