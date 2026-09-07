# Convenciones de UI

> Cómo se organizan las vistas y dónde viven los assets de marca de
> [NOMBRE_DEL_PROYECTO]. **El sistema de diseño no se describe aquí**: vive en
> [`design/`](../../design/README.md), con los tokens al lado de su guía.
> **Última actualización**: 2026-08-10

## Qué manda sobre qué

| Pregunta                                      | Dónde                                                      |
| --------------------------------------------- | ---------------------------------------------------------- |
| Paleta, tipografía, iconos, motion, estados   | [`design/README.md`](../../design/README.md)               |
| Los valores concretos de los tokens           | [`design/tokens.css`](../../design/tokens.css)             |
| Qué pantallas tiene el producto               | [`../architecture/screens.md`](../architecture/screens.md) |
| Cómo se organizan esas pantallas en el código | Este documento                                             |
| Los assets de marca de este producto          | Este documento                                             |

Desviarse del design system es legítimo y cuesta un ADR — igual que desviarse del
marco técnico. Lo que no vale es desviarse sin querer.

## Layouts

| Layout           | Uso                                         |
| ---------------- | ------------------------------------------- |
| [LAYOUT_PUBLICO] | Páginas públicas (landing, marketing)       |
| [LAYOUT_AUTH]    | Pantallas de autenticación (login/registro) |
| [LAYOUT_APP]     | Producto autenticado (dashboard)            |

## Estructura

```text
[RUTA_VISTAS]/
├── layouts/
├── shared/        # parciales reutilizables
└── [recurso]/     # vistas por recurso
```

## Reglas

- **Reutiliza parciales y componentes**; no dupliques marcado. Un componente que se
  copia y se toca un poco es dos componentes que divergen.
- **Separa estructura (layout) de contenido (vista) de comportamiento** (Stimulus,
  React). Un layout no toma decisiones de negocio.
- **Primitivas nativas y los cuatro estados de datos**: las reglas viven en
  [`../../design/README.md`](../../design/README.md) — única copia, como promete la
  cabecera de este documento; aquí solo el recordatorio de que aplican a toda vista.
- **Head compartido** para metadatos y SEO — ver [`seo.md`](seo.md).
- **Mensajes flash**: un solo patrón para éxito y error en todo el producto.
- Nada de colores crudos: solo tokens semánticos. Lo verifica el job `Design system`
  del CI, no la memoria.

## Assets de marca

Lo que cambia por producto y `design/` deliberadamente no fija:

| Asset             | Archivo fuente     | Uso                     |
| ----------------- | ------------------ | ----------------------- |
| Isotipo (símbolo) | `[RUTA_LOGO_MARK]` | Favicon, icono de app   |
| Logotipo (texto)  | `[RUTA_LOGO]`      | Header, materiales      |
| Versión monocroma | `[RUTA_LOGO_MONO]` | Fondos de un solo color |
| Imagen social     | `[URL_IMAGEN_OG]`  | 1200×630 para compartir |

```text
[RUTA_ASSETS_MARCA]/
├── logo.svg
├── logo-mark.svg
└── og-image.png
```

- Los fuentes en **vectorial (SVG)**; los rasterizados se generan desde ahí, nunca al
  revés.
- Respeta el área de protección alrededor del logo. No lo deformes, recolorees ni le
  apliques efectos.
- Usa la variante que corresponda al fondo (claro, oscuro, color).
