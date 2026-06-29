# Convenciones de calidad y tooling

> Linters, formato, análisis estático y git hooks de [NOMBRE_DEL_PROYECTO].
> **Última actualización**: [FECHA]

## Stack

- **Linter**: [LINTER].
- **Formateador**: [FORMATEADOR].
- **Análisis estático / seguridad**: [HERRAMIENTA].
- **Auditoría de dependencias**: [HERRAMIENTA].
- **Orquestador de git hooks**: [HERRAMIENTA] (opcional).

## Git hooks

Estrategia sugerida: hooks baratos y rápidos en `pre-commit`, los más costosos en
`pre-push`. CI ejecuta todo de nuevo en el servidor.

### pre-commit (en cada commit)

- Linter sobre archivos cambiados.
- Formato automático.
- Verificación de trailing whitespace, fin de archivo, conflictos sin resolver.

### pre-push (al subir)

- Linter completo.
- Tests (o un subconjunto rápido).
- Auditoría de dependencias.

## Reglas

- El código debe pasar linter y formato antes del merge.
- Los checks de calidad son **bloqueantes** en CI.

## Comandos útiles

```bash
[COMANDO_LINT]
[COMANDO_FORMAT]
[COMANDO_AUDIT_DEPENDENCIAS]
```

## Referencias

- [Documentación de las herramientas elegidas].
