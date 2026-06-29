# Convenciones de secretos y credenciales

> Cómo gestionamos secretos en [NOMBRE_DEL_PROYECTO].
> **Última actualización**: [FECHA]

## Filosofía

- Los secretos **nunca** se commitean en texto plano.
- Separación clara entre **configuración** (no sensible) y **secretos** (sensible).

## Dónde vive cada cosa

| Tipo                         | Dónde                                         |
| ---------------------------- | --------------------------------------------- |
| Secretos de aplicación       | [GESTOR_DE_SECRETOS / .env local]             |
| Variables de infraestructura | Variables de entorno del entorno              |
| Secretos de CI/CD            | Secrets del proveedor (p. ej. GitHub Actions) |

## Reglas

- El archivo `.env` está en `.gitignore`; solo se versiona `.env.example` (sin valores).
- Comparte secretos con nuevos colaboradores **fuera de banda** (nunca por git, email plano ni chat público).
- Rota credenciales periódicamente (sugerido cada 90 días) y de inmediato ante sospecha de fuga.
- Si un secreto se commitea por error: **rota el secreto primero**, luego limpia la historia.

## Ejemplos

```bash
# Copiar la plantilla de variables
cp .env.example .env
# Completar valores reales (que nunca se suben)
```

## Comandos útiles

```bash
[COMANDO_GESTION_SECRETOS]
```

## Referencias

- [SECURITY.md](../../SECURITY.md) — política de seguridad.
- [Documentación del gestor de secretos elegido].
