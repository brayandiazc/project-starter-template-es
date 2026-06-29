# Convenciones de marca (branding)

> Identidad visual y gestión de assets de marca de [NOMBRE_DEL_PROYECTO].
> Para tokens y componentes de UI ver [`design-system.md`](design-system.md).
> **Última actualización**: [FECHA]

## Logos

| Asset             | Archivo fuente     | Uso                     |
| ----------------- | ------------------ | ----------------------- |
| Isotipo (símbolo) | `[RUTA_LOGO_MARK]` | Favicon, app icon       |
| Logotipo (texto)  | `[RUTA_LOGO]`      | Header, materiales      |
| Versión monocroma | `[RUTA_LOGO_MONO]` | Fondos de un solo color |

- Mantén los fuentes en formato vectorial (SVG) y genera los rasterizados desde ahí.

## Paleta y tipografía

- Definidas como tokens en el [sistema de diseño](design-system.md).
- **Colores de marca**: [primario], [secundario], [acento].
- **Tipografías**: [familia titulares], [familia cuerpo].

## Reglas de uso

- Respeta el área de protección (espacio libre) alrededor del logo.
- No deformes, recolores ni apliques efectos no autorizados al logo.
- Usa la variante adecuada según el fondo (claro/oscuro/color).

## Assets

```text
[RUTA_ASSETS_MARCA]/
├── logo.svg
├── logo-mark.svg
└── og-image.png   # 1200×630 para compartir en redes
```

## Referencias

- [`design-system.md`](design-system.md)
- [Guía de marca completa, si existe].
