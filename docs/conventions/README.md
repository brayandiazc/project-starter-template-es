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
| [authentication.md](authentication.md)             | Autenticación y autorización       |
| [branding.md](branding.md)                         | Identidad de marca y assets        |
| [database.md](database.md)                         | Modelado de datos y migraciones    |
| [deploy.md](deploy.md)                             | Despliegue y operaciones           |
| [design-system.md](design-system.md)               | Sistema de diseño y componentes    |
| [i18n.md](i18n.md)                                 | Internacionalización               |
| [quality-tooling.md](quality-tooling.md)           | Linters, formato y git hooks       |
| [secrets.md](secrets.md)                           | Manejo de secretos y credenciales  |
| [seo.md](seo.md)                                   | SEO y metadatos                    |
| [testing.md](testing.md)                           | Estrategia y estándares de testing |
| [transactional-emails.md](transactional-emails.md) | Correos transaccionales            |
| [views-and-layouts.md](views-and-layouts.md)       | Vistas, layouts y UI compartida    |

## Agregar una convención

Copia [`_template.md`](_template.md), renómbralo en `kebab-case` y documenta el
nuevo tema. Añádelo a la tabla de arriba.

> **Convenciones adicionales opcionales** (no incluidas por defecto, créalas si tu
> proyecto las necesita): pagos, webhooks, multi-tenancy, PWA, administración,
> aceptación legal, observabilidad, etc.
