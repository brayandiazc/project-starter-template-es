# Convenciones del sistema de diseño

> Tokens, componentes y reglas de UI de [NOMBRE_DEL_PROYECTO].
> Para el diseño técnico/UX del producto ver
> [`../architecture/design.md`](../architecture/design.md).
> **Última actualización**: [FECHA]

## Stack

- **Librería de componentes**: [LIBRERÍA].
- **Solución de estilos**: [SOLUCIÓN].
- **Página de referencia viva** (si aplica): `[URL_DESIGN_SYSTEM]`.

## Tokens

| Token          | Uso                             |
| -------------- | ------------------------------- |
| Colores        | [primario, secundario, estados] |
| Tipografía     | [familias, escalas]             |
| Espaciado      | [escala de espaciado]           |
| Bordes/sombras | [radios, elevaciones]           |

> Usa **tokens semánticos** (p. ej. `color-primario`), no valores crudos, en los componentes.

## Componentes permitidos

- Usa los componentes de la librería; evita crear variantes ad-hoc.
- Cada componente debe contemplar sus **estados**: normal, hover, foco, deshabilitado, carga, error.

## Accesibilidad (baseline)

- Contraste mínimo objetivo: WCAG [AA/AAA].
- Foco visible y navegación por teclado.
- Roles/atributos ARIA donde corresponda.

## Anti-patrones

- Valores de color/espaciado hardcodeados fuera de los tokens.
- Componentes duplicados que reimplementan algo existente.

## Referencias

- [Documentación de la librería de componentes].
