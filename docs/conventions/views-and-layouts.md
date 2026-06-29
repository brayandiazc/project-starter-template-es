# Convenciones de vistas y layouts

> Cómo organizamos vistas, layouts y UI compartida en [NOMBRE_DEL_PROYECTO].
> **Última actualización**: [FECHA]

## Layouts

| Layout           | Uso                                         |
| ---------------- | ------------------------------------------- |
| [LAYOUT_PUBLICO] | Páginas públicas (landing, marketing)       |
| [LAYOUT_AUTH]    | Pantallas de autenticación (login/registro) |
| [LAYOUT_APP]     | Producto autenticado (dashboard)            |

## Elementos compartidos

- **Head compartido**: metadatos y SEO (ver [`seo.md`](seo.md)).
- **Mensajes flash**: patrón único para notificaciones de éxito/error.
- **Navegación**: header/menú reutilizable.

## Reglas

- Reutiliza parciales/componentes; no dupliques marcado.
- Cada vista contempla sus estados: carga, vacío, error y éxito.
- La UI sigue el [sistema de diseño](design-system.md).
- Separa estructura (layout) de contenido (vista) de comportamiento.

## Estructura

```text
[RUTA_VISTAS]/
├── layouts/
├── shared/        # parciales reutilizables
└── [recurso]/     # vistas por recurso
```

## Referencias

- [`design-system.md`](design-system.md)
- [`seo.md`](seo.md)
