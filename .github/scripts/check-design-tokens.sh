#!/usr/bin/env bash
# check-design-tokens.sh — el design system se cumple, no se recuerda.
#
# Las vistas del producto NO usan color crudo: ni hex, ni rgb()/hsl()/oklch()
# inline, ni utilidades o variables cuyo nombre diga el COLOR en vez del ROL
# (bg-blue-500, $gray-700, --ui-red), ni valores arbitrarios (bg-[#0A7A9D]).
# Solo tokens semánticos — es lo que permite que un producto cambie su marca
# tocando un solo bloque de design/tokens.css.
#
# ES AGNÓSTICO DEL FRAMEWORK: la regla que verifica es de los tokens, no de
# ninguna librería. Busca en las carpetas de vistas y estilos habituales. Si el
# repositorio todavía no tiene vistas —una plantilla recién instanciada, o un
# proyecto sin UI— no impone nada.
#
# Uso:
#   bash .github/scripts/check-design-tokens.sh [raíz-del-repo]
#
# Requiere: python3. Sale con 1 si encuentra problemas.
set -euo pipefail

ROOT="${1:-.}"
cd "$ROOT"

# Carpetas de vistas habituales, cubriendo las convenciones más comunes:
# app/views y app/components, templates, src, components, pages, layouts.
DIRS="app/views app/components templates src components pages layouts"
# `css`, `js` y `ts` no estaban, y ese era el agujero grande: **el CSS es donde viven
# los colores crudos en CUALQUIER stack**. Un proyecto con
# app/assets/stylesheets/*.css tampoco se revisaba, y uno sin framework —vistas como
# plantillas de texto en .js, estilos en .css— pasaba el check en verde sin que se
# abriera un solo archivo. La regla de oro del sistema («nunca un hex, solo tokens»)
# no se verificaba justo en el archivo donde se rompe.
EXT='html erb astro jsx tsx vue j2 jinja css scss sass less js ts mjs'

# El archivo que DEFINE los tokens es la excepción obvia: ahí los colores crudos son
# el contenido, no la infracción. Se exime por nombre, no por carpeta, porque al
# migrar design/ dentro de la aplicación acaba en sitios distintos según el stack.
EXENTOS='tokens.css'

buscar() { # $1 = carpeta, $2 = profundidad ('' = recursivo)
  for e in $EXT; do
    find "$1" ${2:+-maxdepth "$2"} -type f -name "*.$e" \
      -not -path '*/node_modules/*' -not -path '*/vendor/*' \
      -not -path '*/dist/*' -not -path '*/build/*' 2>/dev/null || true
  done
}

archivos=""
for d in $DIRS; do
  [ -d "$d" ] || continue
  encontrados="$(buscar "$d" '')"
  [ -n "$encontrados" ] && archivos="$archivos$encontrados"$'\n'
done

# La raíz, a un solo nivel: en un proyecto sin framework la página vive en ./index.html
# y los estilos en ./styles.css, y ninguna carpeta de DIRS los cubre.
raiz="$(buscar . 1)"
[ -n "$raiz" ] && archivos="$archivos$raiz"$'\n'

# Fuera los archivos exentos (por basename) y las líneas en blanco.
for x in $EXENTOS; do
  archivos="$(printf '%s\n' "$archivos" | grep -v "/$x\$" | grep -v "^$x\$" || true)"
done
archivos="$(printf '%s\n' "$archivos" | sed '/^[[:space:]]*$/d' || true)"

if [ -z "$archivos" ]; then
  # "Nada que verificar" era indistinguible de un ✅ real: se leía como "no aplica"
  # en vez de "no sé mirar esto". Ahora dice DÓNDE y QUÉ buscó, para que sea una
  # afirmación revisable y no un silencio.
  echo "ℹ️  Design system: no encontré vistas ni estilos que revisar."
  echo "   Carpetas: $DIRS (y la raíz, un nivel)."
  echo "   Extensiones: $EXT."
  echo "   Si tu proyecto tiene UI en otro sitio, añádelo a DIRS en este script."
  exit 0
fi

fail=0

# ── 1. Colores crudos en las vistas ──────────────────────────────────────────
# Nombres de color, en las tres notaciones en que se escriben (utilidad con
# guiones, variable de preprocesador, custom property). Se detecta la NOTACIÓN, no
# un framework concreto: la infracción es que el nombre diga el COLOR y no el ROL.
# `bg-neutral` es válido; `bg-neutral-500`, `$gray-700` y `--ui-red` no.
PALETA='slate|gray|zinc|neutral|stone|red|orange|amber|yellow|lime|green|emerald|teal|cyan|sky|blue|indigo|violet|purple|fuchsia|pink|rose'

crudos=""
while IFS= read -r f; do
  [ -n "$f" ] && [ -f "$f" ] || continue
  hallazgos="$(PALETA="$PALETA" python3 - "$f" <<'PY' || true
import os, re, sys

ruta = sys.argv[1]
src = open(ruta).read()

# Los comentarios no se envían al navegador, así que no infringen nada — y sin esta
# exclusión, DOCUMENTAR la regla la infringe: la cabecera de una hoja de estilos que
# deletrea los patrones prohibidos («nunca #hex, nunca rgb()») salía como hallazgo.
# Eso desincentiva justo el comentario que explica el sistema.
def sin_comentarios(texto, ruta):
    ext = ruta.rsplit(".", 1)[-1].lower()
    patrones = [r"/\*.*?\*/", r"<!--.*?-->"]
    # `//` solo en lenguajes que lo usan, y nunca tras `:` — si no, `https://…` se
    # comería el resto de la línea.
    if ext in ("js", "ts", "mjs", "jsx", "tsx", "vue", "astro", "css", "scss", "sass", "less"):
        patrones.append(r"(?<!:)//[^\n]*")
    for p in patrones:
        texto = re.sub(p, blanquear, texto, flags=re.S)
    return texto

# Excepción: logos de terceros. Un logo de marca lleva SUS colores —Google, GitHub,
# Stripe— y retiñirlo con nuestros tokens infringe sus brand guidelines
# (design/README.md → "Logos de marcas de terceros"). Se marca el elemento con
# `data-brand="<marca>"` y su contenido queda fuera del análisis. Es la única vía:
# un hex suelto en cualquier otro sitio sigue fallando.
def blanquear(m):
    # Conserva los saltos de línea para no descuadrar los números de línea.
    return re.sub(r"[^\n]", " ", m.group(0))


def sin_marcas(texto):
    return re.sub(r"<svg\b[^>]*\bdata-brand=[^>]*>.*?</svg>", blanquear, texto, flags=re.S)

paleta = os.environ["PALETA"]
patrones = [
    (rf"(?:bg|text|border|from|via|to|ring|fill|stroke|decoration|outline|shadow|accent)-(?:{paleta})-\d{{2,3}}\b",
     "utilidad de paleta cruda"),
    (rf"\$(?:{paleta})-\d{{2,3}}\b", "variable de paleta cruda"),
    # Dos formas, y ninguna puede tragarse los tokens del sistema: `--neutral` es
    # un ROL válido aquí. Por eso se exige o un prefijo (`--ui-red`) o un número
    # (`--gray-700`) — que es justo lo que convierte el nombre en un color.
    (rf"--[a-z]{{1,8}}-(?:{paleta})\b", "variable de paleta cruda"),
    (rf"--(?:{paleta})-\d{{2,3}}\b", "variable de paleta cruda"),
    (r"(?:bg|text|border|fill|stroke)-\[[^\]]+\]", "valor arbitrario"),
    (r"#[0-9a-fA-F]{3}(?![0-9a-zA-Z_-])|#[0-9a-fA-F]{6}(?![0-9a-zA-Z_-])", "color hex"),
    (r"\b(?:rgba?|hsla?|oklch)\(", "color inline"),
]

for n, linea in enumerate(sin_comentarios(sin_marcas(src), ruta).split("\n"), 1):
    for patron, etiqueta in patrones:
        for m in re.finditer(patron, linea):
            print(f"{ruta}:{n}: {etiqueta}: {m.group(0)}")
PY
)"
  [ -n "$hallazgos" ] && crudos="$crudos$hallazgos"$'\n'
done <<< "$archivos"

if [ -n "${crudos// /}" ]; then
  echo "❌ Colores crudos en las vistas (solo tokens semánticos):"
  printf '%s' "$crudos" | sed '/^$/d' | sed 's/^/   · /'
  echo "→ Usa los tokens del sistema (primary, base-100, base-content…). Ver design/README.md"
  echo "  → 'Regla de oro'. Si de verdad hace falta un color nuevo, va a tokens.css."
  fail=1
fi

if [ "$fail" -ne 0 ]; then
  exit 1
fi

echo "✅ Design system: las vistas usan solo tokens semánticos."
