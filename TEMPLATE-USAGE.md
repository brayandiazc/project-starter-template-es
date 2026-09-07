# Cómo usar esta plantilla

Esta guía explica cómo convertir esta plantilla en la documentación real de tu proyecto. Una vez instanciada, **puedes borrar este archivo** (`TEMPLATE-USAGE.md`).

## 1. Qué es y qué no es

- **Es** una base de documentación lista para iniciar cualquier proyecto: estructura de carpetas, archivos de gobernanza y esqueletos de documentos con placeholders.
- **No es** un boilerplate de código ni está atado a un stack concreto. No incluye dependencias ni configuración de un lenguaje específico — eso lo aporta tu proyecto.

## 2. Instanciar la plantilla

**Opción A — GitHub (recomendada):** pulsa **"Use this template" → Create a new repository**. GitHub copia el contenido sin el historial de commits.

**Opción B — Clonar y reiniciar el historial:**

```bash
git clone [URL_DE_ESTA_PLANTILLA] mi-proyecto
cd mi-proyecto
rm -rf .git
git init
```

### Adoptarla en un proyecto existente

"Use this template" solo funciona para repositorios nuevos. Para llevar esta estructura a
un proyecto que ya iniciaste hay **una sola regla, y no es negociable**:

> **Nunca se sobrescribe nada.** Se trae solo lo que no existe.

No es prudencia excesiva. La receta anterior hacía `cp -R .tpl/docs .`, y probada contra
un proyecto real —que ya había adoptado una versión anterior de esta plantilla— sustituyó
**1.532 líneas de documentación escrita por esqueletos vacíos**: su `api.md` pasó de 182
líneas de contrato real a 96 con cinco placeholders. Se recupera con git, sí, pero solo si
alguien lo nota, y el diff eran 57 archivos nuevos mezclados con 22 machacados.

```bash
# Desde la raíz de tu proyecto, en una rama nueva
git checkout -b chore/adopt-doc-template

# Descargar la plantilla sin su historial
npx degit brayandiazc/project-starter-template-es-ai .tpl

# Traer SOLO lo que te falta. Lo tuyo no se toca.
(cd .tpl && find docs .githooks .github/scripts design -type f 2>/dev/null) \
  | while IFS= read -r f; do
      [ -e "$f" ] || { mkdir -p "$(dirname "$f")"; cp ".tpl/$f" "$f"; }
    done

# Los de la raíz, uno a uno y solo si no existen
for f in .editorconfig; do
  [ -e "$f" ] || cp ".tpl/$f" "$f"
done

# Y ver qué existe en AMBOS, para decidirlo tú archivo por archivo
(cd .tpl && find docs -type f) | while IFS= read -r f; do [ -e "$f" ] && echo "AMBOS: $f"; done

rm -rf .tpl
```

Esa última lista es el trabajo de verdad: son los documentos donde la plantilla y tu
proyecto dicen cosas sobre lo mismo. Nadie puede fusionarlos por ti — pero al menos ahora
sabes cuáles son en vez de descubrirlo cuando ya se perdieron.

**Después**:

- **Compara los nombres de archivo contra el `CHANGELOG.md` de la plantilla**: si
  adoptaste una versión anterior, algún documento tuyo puede llamarse ahora de otra
  forma. Traer el nuevo sin borrar el viejo **deja los dos**, con contenido distinto y
  sin que ningún check lo note.
- Activa los git hooks: `git config core.hooksPath .githooks`.
- Escribe `.template-origin` (repo, commit, fecha y `versiones=` con las versiones
  del CHANGELOG de la plantilla — sin ellas, `check-inheritance.sh` cae a un criterio
  por fecha que puede acusar un release tuyo del mismo día) para que
  `/actualizar-plantilla` y el workflow de avisos funcionen de aquí en adelante.
- Rellena los `docs/` nuevos con lo que ya sabes del proyecto en vez de dejar placeholders.
- Commitea en la rama, abre un PR y luego borra `TEMPLATE-USAGE.md`.

> Si tu proyecto **ya tenía** una versión de esta plantilla, el camino corto es
> `/actualizar-plantilla`, que hace todo esto y además calcula el diff del tooling.

## 3. Reemplazar los placeholders

Todos los placeholders usan el formato `[CORCHETES_EN_MAYÚSCULAS]`. **Pero no se
sustituyen en todo el repositorio**: pide primero las rutas donde un placeholder es un
valor por rellenar.

```bash
bash .github/scripts/check-placeholders.sh --rutas-sustituibles   # dónde se toca
bash .github/scripts/check-placeholders.sh                        # qué falta
```

Fuera quedan `.github/scripts/`, `.github/workflows/`, `CHANGELOG.md` y las dos
plantillas internas (`docs/decisions/0000-template.md`,
`docs/conventions/_template.md`). Ahí un placeholder es **dato de prueba, texto
explicativo o lo único que hace útil a la plantilla**, y sustituirlo lo destruye: pasó,
y rompió el banco de pruebas de este mismo repositorio.

Para inspeccionar a ojo, sin sustituir:

```bash
bash .github/scripts/check-placeholders.sh --rutas-sustituibles \
  | xargs grep -no '\[[A-ZÁÉÍÓÚÑ0-9_/]\+\]'
```

### Catálogo de placeholders

| Placeholder                                                                                       | Significado                                                    |
| ------------------------------------------------------------------------------------------------- | -------------------------------------------------------------- |
| `[NOMBRE_DEL_PROYECTO]`                                                                           | Nombre del producto, tal como se lee                           |
| `[SLUG_REPOSITORIO]`                                                                              | Nombre del repositorio en GitHub (`mi-proyecto`)               |
| `[AUTOR]`                                                                                         | Nombre del autor o mantenedor principal                        |
| `[USUARIO_GITHUB]`                                                                                | Usuario u organización de GitHub                               |
| `[URL_REPOSITORIO]`                                                                               | URL del repositorio                                            |
| `[AÑO]`                                                                                           | Año del copyright en la licencia                               |
| `[VERSION]`                                                                                       | Versión (de una dependencia o del proyecto)                    |
| `[FECHA]`                                                                                         | Fecha (formato `YYYY-MM-DD`)                                   |
| `[EMAIL_SOPORTE]`                                                                                 | Correo de contacto/soporte                                     |
| `[EMAIL_SEGURIDAD]`                                                                               | Correo para reportar vulnerabilidades                          |
| `[RUNTIME]`                                                                                       | Lenguaje/runtime (Node.js, Python, Ruby…)                      |
| `[GESTOR_DE_PAQUETES]`                                                                            | npm, pnpm, bundler, pip…                                       |
| `[BASE_DE_DATOS]`                                                                                 | PostgreSQL, MySQL, MongoDB…                                    |
| `[PUERTO]`                                                                                        | Puerto local de desarrollo                                     |
| `[COMANDO_*]`                                                                                     | Comandos del proyecto (instalar, test, build, deploy…)         |
| `[URL_*]` (`[URL_DEV]`, `[URL_BASE_API]`…)                                                        | URLs por ambiente y recursos web                               |
| `[SERVICIO/API]`, `[LINK_*]`, `[OTROS_*]`                                                         | Recursos específicos de tu proyecto                            |
| `[HERRAMIENTA]`, `[HERRAMIENTA_*]`, `[OTRA_HERRAMIENTA]`                                          | Herramientas del stack (build, test, e2e, migraciones…)        |
| `[FRAMEWORK_*]`, `[ORM]`, `[LINTER]`, `[FORMATEADOR]`                                             | Piezas del stack por rol                                       |
| `[CACHE]`, `[COLA]`, `[CONTENEDORES]`, `[CI_CD]`, `[MONITOREO]`, `[TTL]`                          | Infraestructura y operaciones                                  |
| `[URL]`                                                                                           | Una URL de fuente, en las tablas de discovery                  |
| `[SERVIDOR]`, `[ID_SNAPSHOT]`                                                                     | Nombre del host y de un snapshot, en los comandos de respaldo  |
| `[RUTA_*]`                                                                                        | Rutas de carpetas/archivos del proyecto                        |
| `[LAYOUT_*]`, `[LOCALE_*]`, `[AA/AAA]`                                                            | UI, i18n y nivel de accesibilidad objetivo                     |
| `[ENTIDAD_*]`, `[COMPONENTE_*]`, `[SERVICIO_*]`, `[ROL_*]`, `[ACTOR_*]`                           | Modelo de dominio y arquitectura                               |
| `[SEGMENTO_*]`, `[PLAN_*]`, `[PRECIO]`, `[PORCENTAJE]`                                            | Modelo de negocio                                              |
| `[ELEGIDA]`, `[DESCARTADA]`, `[ALTERNATIVA]`                                                      | Comparativas en decisiones (stack, diseño)                     |
| `[HERRAMIENTA_IA]`, `[EMAIL_HERRAMIENTA_IA]`                                                      | Herramienta de IA y su email (trailer de coautoría)            |
| `[TIPO]`, `[OTRO]`, `[EJEMPLO]`, `[COMANDO]`, `[NOMBRES]`, `[PROVEEDOR]`, `[RECURSO]`, `[RIESGO]` | Descriptivos locales de cada documento                         |
| `[RAZON]`, `[NOTA]`, `[PARA_QUE]`                                                                 | Ídem: la celda que explica el porqué o el para qué de una fila |
| `[COMANDO_SNAPSHOT_*]`                                                                            | Comandos de respaldo del proveedor que uses                    |

> Mantén este catálogo actualizado: cualquier `[PLACEHOLDER]` nuevo que introduzcas debería
> aparecer aquí — el CI lo verifica con `.github/scripts/check-placeholders.sh`.

**Globales y posicionales.** Un placeholder es **global** si tiene una sola respuesta para
todo el repositorio (`NOMBRE_DEL_PROYECTO`, `USUARIO_GITHUB`, los `COMANDO_*`): se puede
sustituir en bloque. Es **posicional** si significa algo distinto en cada aparición —las
cuatro últimas filas de la tabla lo son casi enteras: `VERSION` es la versión de una pieza
distinta cada vez, y `ELEGIDA`/`DESCARTADA` son los dos lados de una comparación por
tabla—. Los posicionales **se rellenan uno a uno, leyendo su contexto**; sustituirlos en
bloque deja documentos ordenados y falsos, que es peor que dejarlos vacíos. Si el mismo
placeholder aparece dos veces en un mismo archivo, es posicional.

**El nombre y el slug no son lo mismo.** `NOMBRE_DEL_PROYECTO` es el nombre del producto
tal como se lee («Registro de Turnos»); `SLUG_REPOSITORIO` es el nombre del repositorio
(`turnos-app`). Coinciden solo cuando el repositorio se llama igual que el producto, y
en cuanto se usa un nombre-clave divergen. Los dos son globales, así que la regla de
arriba no los separa: lo que los separa es **dónde van**.

> Un nombre de producto **nunca** aparece en una URL, una ruta ni un comando. Ahí va
> siempre el slug: badges, `cd`, `git clone`, `gh api`, `URL_REPOSITORIO`.

No es cosmético. Un badge roto se ve; `cd Registro de Turnos` y
`gh api repos/mi-usuario/Registro de Turnos/...` se leen como instrucciones correctas
hasta que alguien las ejecuta.

### Pendientes: lo que aún no se puede rellenar

Al instanciar hay datos que legítimamente no se pueden inferir. La regla es «no
inventes datos», así que se dejan — pero marcados:

- **Un dato que falta en una línea** se marca en su misma línea:
  `[EMAIL_SEGURIDAD] <!-- pendiente: aún sin buzón -->`. En prosa sin placeholder,
  una frase corta y la misma marca (no te inventes placeholders fuera del catálogo).
- **Un dato que falta en todo el repositorio** (el buzón del cliente, el dominio sin
  contratar) se declara UNA vez en un archivo `.pendientes` en la raíz:
  `EMAIL_SOPORTE=el cliente aún no da el buzón`.
- Los marcados no fallan el check, pero **se listan en cada ejecución** — resolverlos
  debe molestar un poco, no olvidarse.

> **Al citar un placeholder en prosa, escribe su nombre sin corchetes** — `NOMBRE_DEL_PROYECTO`,
> no entre `[` `]`. Un documento que habla _sobre_ los placeholders (una bitácora, una
> spec, este mismo archivo) los tiene igual de literales que uno sin rellenar, y el check
> no distingue intención. Los archivos que existen para explicarlos van en la lista `SKIP`
> de `check-placeholders.sh`; el resto, sin corchetes.

## 4. Orden recomendado de llenado

1. `README.md` — la portada del proyecto.
2. `docs/architecture/stack.md` — registra el stack que elegiste y de dónde sale.
3. `docs/architecture/architecture.md` — vista de alto nivel.
4. `docs/architecture/database.md` — modelo de datos.
5. `docs/architecture/auth.md` — autenticación y autorización.
6. `docs/architecture/api.md` — contrato de API.
7. `docs/architecture/screens.md` — mapa de pantallas y recorrido crítico.
8. `docs/product/business-model.md` — por qué existe el producto y cómo se paga.
9. `docs/product/roadmap.md` — roadmap.
10. `docs/decisions/` — crea un ADR cada vez que tomes una decisión relevante.

### Qué arranca vacío (historial de la plantilla)

Un proyecto nuevo hereda las **herramientas** de la plantilla, no su **vida**. Al
instanciar quedan a cero:

| Archivo           | Cómo queda                                                                                                                                                       |
| ----------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `CHANGELOG.md`    | Cabecera + `## [Unreleased]` **con una viñeta del arranque** — nunca vacío: `check-changelog.sh` bloquearía tu primer PR. Esa viñeta se convierte en tu `v0.1.0` |
| `docs/decisions/` | Solo `0000-template.md` y `0001-record-architecture-decisions.md`                                                                                                |
| `docs/product/*`  | Esqueletos con placeholders, que rellena el sprint de definición                                                                                                 |

Los ADRs `0002` en adelante son decisiones que tomó la plantilla, no tu proyecto: lo
heredado se resume en el ADR de instanciación, con enlace al repositorio origen.

El job `herencia` de `quality.yml` lo verifica de forma determinista: `.template-origin`
guarda la fecha de instanciación y las versiones de la plantilla (`versiones=`), y nada
puede venir de antes de esa fecha ni repetir esas versiones.

### Qué borrar si no aplica

Cada capacidad que el producto **no** tenga se lleva su convención por delante: sin
i18n → `docs/conventions/i18n.md`; sin base de datos → `conventions/database.md` y
`architecture/database.md`; sin SEO/web pública → `conventions/seo.md`; sin interfaz →
`conventions/ui.md`, `architecture/screens.md` y la carpeta `design/`. Y además:

- Los workflows de ejemplo en `.github/workflows/` si no usas GitHub Actions. Los
  workflows **activos** (`quality.yml`, `secret-scan.yml`) funcionan en cualquier stack —
  consérvalos si usas GitHub Actions.
- **Siempre** borra lo exclusivo del repo-plantilla: este mismo archivo, el workflow
  `.github/workflows/template-parity.yml` y el script `.github/scripts/check-parity.sh`
  (solo sirven para mantener la familia de variantes).

## 5. Mantener la documentación viva

- Actualiza la línea **"Última actualización: [FECHA]"** al editar un documento.
- Cada decisión arquitectónica relevante se registra como un **ADR** en `docs/decisions/` (ver su [README](docs/decisions/README.md)).
- Mantén `CHANGELOG.md` al día siguiendo [Keep a Changelog](https://keepachangelog.com/es-ES/).
- Convenciones adicionales (pagos, webhooks, multi-tenancy, PWA, etc.) pueden añadirse usando [`docs/conventions/_template.md`](docs/conventions/_template.md).
- El CI vigila la salud de los docs (workflow [`quality.yml`](.github/workflows/quality.yml)):
  formato Markdown, enlaces internos y placeholders pendientes.

### Recibir mejoras de la plantilla

La plantilla sigue evolucionando después de que la instancias. Para poder traer esas
mejoras (nuevos scripts, hooks o workflows) a tu proyecto:

- Al instanciar, queda un archivo `.template-origin` en la raíz con el repo y el commit
  de la plantilla de origen.
- Cuando quieras sincronizar, calcula el diff del tooling entre tu commit de origen y
  el HEAD actual de la plantilla (`.github/`, `.githooks/`,
  `docs/conventions/_template.md`) y aplícalo — sin tocar tu documentación ya
  rellenada.
- Sigue los releases/tags del repositorio de la plantilla para saber qué cambió.
