# Convenciones

Esta carpeta documenta **cómo trabajamos** en [NOMBRE_DEL_PROYECTO]: reglas y
estándares transversales que aplican al día a día, independientes de cualquier
feature concreta.

> Diferencia con `docs/architecture/`: aquí van las **reglas** ("cómo modelamos
> datos"); en `architecture/` va **este** proyecto en concreto ("cuál es nuestro
> modelo de datos").

## Convenciones incluidas

| Convención                                         | Tema                               |
| -------------------------------------------------- | ---------------------------------- |
| [database.md](database.md)                         | Modelado de datos y migraciones    |
| [definition-of-done.md](definition-of-done.md)     | Qué significa "terminado"          |
| [deploy.md](deploy.md)                             | Despliegue y operaciones           |
| [i18n.md](i18n.md)                                 | Internacionalización               |
| [quality-tooling.md](quality-tooling.md)           | Linters, formato y git hooks       |
| [secrets.md](secrets.md)                           | Manejo de secretos y credenciales  |
| [seo.md](seo.md)                                   | SEO y metadatos                    |
| [testing.md](testing.md)                           | Estrategia y estándares de testing |
| [ui.md](ui.md)                                     | Vistas, layouts y assets de marca  |
| [transactional-emails.md](transactional-emails.md) | Correos transaccionales            |

## Agregar una convención

Copia [`_template.md`](_template.md), renómbralo en `kebab-case` y documenta el
nuevo tema. Añádelo a la tabla de arriba.

## Convenciones adicionales opcionales

No se incluyen por defecto; créalas con `_template.md` si tu proyecto las necesita.

- **Genéricas / SaaS**: pagos, webhooks, multi-tenancy, PWA, administración,
  aceptación legal, observabilidad.
- **Móvil**: release a stores (versionado, firma/code-signing, capturas y ASO),
  permisos del dispositivo, notificaciones push, modo offline.
- **Escritorio**: empaquetado e instaladores por SO, code signing y notarización,
  auto-update, telemetría / reporte de crashes.

> **Lo que no va aquí**: el stack concreto (lo registra
> [`../architecture/stack.md`](../architecture/stack.md)) y el sistema de
> diseño (vive en [`design/`](../../design/README.md), con los tokens al lado de su guía).
> Una convención que repite un dato de esos se desincroniza sin que nadie lo note.
