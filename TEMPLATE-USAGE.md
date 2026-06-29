# Cómo usar esta plantilla

Esta guía explica cómo convertir esta plantilla en la documentación real de tu proyecto. Una vez instanciada, **puedes borrar este archivo** (`TEMPLATE-USAGE.md`).

## 1. Qué es y qué no es

- **Es** una base de documentación lista para iniciar cualquier proyecto: estructura de carpetas, archivos de gobernanza y esqueletos de documentos con placeholders.
- **No es** un boilerplate de código ni está atado a un stack concreto. No incluye dependencias ni configuración de un lenguaje específico — eso lo aporta tu proyecto.
- La integración con agentes de IA llegará en una fase posterior (ver §8).

## 2. Instanciar la plantilla

**Opción A — GitHub (recomendada):** pulsa **"Use this template" → Create a new repository**. GitHub copia el contenido sin el historial de commits.

**Opción B — Clonar y reiniciar el historial:**

```bash
git clone [URL_DE_ESTA_PLANTILLA] mi-proyecto
cd mi-proyecto
rm -rf .git
git init
```

## 3. Reemplazar los placeholders

Todos los placeholders usan el formato `[CORCHETES_EN_MAYÚSCULAS]`. Encuéntralos con:

```bash
grep -rno '\[[A-ZÁÉÍÓÚÑ0-9_/]\+\]' --include='*.md' --include='.env.example' .
```

### Catálogo de placeholders

| Placeholder                                        | Significado                                            |
| -------------------------------------------------- | ------------------------------------------------------ |
| `[NOMBRE_DEL_PROYECTO]`                            | Nombre del proyecto                                    |
| `[NOMBRE_EMPRESA]`                                 | Nombre de la empresa u organización                    |
| `[AUTOR]`                                          | Nombre del autor o mantenedor principal                |
| `[USUARIO_GITHUB]`                                 | Usuario u organización de GitHub                       |
| `[URL_REPOSITORIO]`                                | URL del repositorio                                    |
| `[AÑO]`                                            | Año del copyright en la licencia                       |
| `[VERSION]`                                        | Versión (de una dependencia o del proyecto)            |
| `[FECHA]`                                          | Fecha (formato `YYYY-MM-DD`)                           |
| `[EMAIL_SOPORTE]`                                  | Correo de contacto/soporte                             |
| `[EMAIL_SEGURIDAD]`                                | Correo para reportar vulnerabilidades                  |
| `[RUNTIME]`                                        | Lenguaje/runtime (Node.js, Python, Ruby…)              |
| `[GESTOR_DE_PAQUETES]`                             | npm, pnpm, bundler, pip…                               |
| `[BASE_DE_DATOS]`                                  | PostgreSQL, MySQL, MongoDB…                            |
| `[PUERTO]`                                         | Puerto local de desarrollo                             |
| `[COMANDO_*]`                                      | Comandos del proyecto (instalar, test, build, deploy…) |
| `[URL_DEV]` / `[URL_STAGING]` / `[URL_PRODUCCION]` | URLs por ambiente                                      |
| `[SERVICIO/API]`, `[LINK_*]`, `[OTROS_*]`          | Recursos específicos de tu proyecto                    |

> Mantén este catálogo actualizado: cualquier `[PLACEHOLDER]` nuevo que introduzcas debería aparecer aquí.

## 4. Orden recomendado de llenado

1. `README.md` — la portada del proyecto.
2. `docs/architecture/stack.md` — define el stack.
3. `docs/architecture/architecture.md` — vista de alto nivel.
4. `docs/architecture/database.md` — modelo de datos.
5. `docs/architecture/auth.md` — autenticación y autorización.
6. `docs/architecture/api.md` — contrato de API.
7. `docs/architecture/design.md` — diseño técnico / UI-UX.
8. `docs/product/business-model.md` — modelo de negocio.
9. `docs/product/roadmap.md` — roadmap.
10. `docs/decisions/` — crea un ADR cada vez que tomes una decisión relevante.

## 5. Inventario de archivos

| Archivo                       | Propósito                                 | ¿Obligatorio?        |
| ----------------------------- | ----------------------------------------- | -------------------- |
| `README.md`                   | Portada del proyecto                      | Sí                   |
| `CONTRIBUTING.md`             | Cómo contribuir y flujo Git               | Recomendado          |
| `CODE_OF_CONDUCT.md`          | Código de conducta                        | Recomendado          |
| `SECURITY.md`                 | Política de seguridad                     | Recomendado          |
| `CHANGELOG.md`                | Historial de cambios                      | Recomendado          |
| `LICENSE`                     | Licencia                                  | Sí                   |
| `.env.example`                | Contrato de variables de entorno          | Si hay configuración |
| `.gitignore`, `.editorconfig` | Higiene del repo                          | Recomendado          |
| `.github/`                    | Plantillas de issues/PR, automatizaciones | Opcional             |
| `docs/architecture/*`         | Documentación técnica                     | Según necesidad      |
| `docs/product/*`              | Negocio y roadmap                         | Según necesidad      |
| `docs/decisions/*`            | Registro de decisiones (ADR)              | Recomendado          |
| `docs/conventions/*`          | Convenciones de trabajo                   | Según necesidad      |

### Qué borrar si no aplica

- Convenciones de `docs/conventions/` que no uses (p. ej. `i18n.md` si no internacionalizas).
- Secciones del `README.md` que no apliquen (p. ej. la tabla de Deployment).
- Documentos de `docs/architecture/` que no correspondan (p. ej. `api.md` si no expones API).
- Los workflows de ejemplo en `.github/workflows/` si no usas GitHub Actions.

## 6. `architecture/X.md` vs `conventions/X.md`

Hay dos documentos sobre "base de datos" y dos sobre "autenticación", **a propósito**:

- `docs/architecture/database.md` describe **el modelo de datos de tu proyecto** (entidades, relaciones, ERD). Cambia con cada proyecto.
- `docs/conventions/database.md` describe **las reglas reusables** de cómo modelas datos (nomenclatura, índices, tipos). Es transversal.

La misma distinción aplica a `architecture/auth.md` (cómo funciona aquí) vs `conventions/authentication.md` (reglas de autenticación).

## 7. Mantener la documentación viva

- Actualiza la línea **"Última actualización: [FECHA]"** al editar un documento.
- Cada decisión arquitectónica relevante se registra como un **ADR** en `docs/decisions/` (ver su [README](docs/decisions/README.md)).
- Mantén `CHANGELOG.md` al día siguiendo [Keep a Changelog](https://keepachangelog.com/es-ES/).
- Convenciones adicionales (pagos, webhooks, multi-tenancy, PWA, etc.) pueden añadirse usando [`docs/conventions/_template.md`](docs/conventions/_template.md).

## 8. Próximamente: integración de IA / agentes

Una fase posterior añadirá estructura y archivos para flujos de trabajo con agentes de IA (especificaciones, instrucciones para agentes, etc.). Hasta entonces, esta plantilla se centra en documentación tangible.
