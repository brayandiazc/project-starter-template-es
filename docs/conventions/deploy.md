# Convenciones de despliegue

> Operaciones de producción de [NOMBRE_DEL_PROYECTO]. Fuente de verdad de cómo se
> despliega, se hace rollback y se opera el sistema.
> **Última actualización**: [FECHA]

## Stack de infraestructura

- **Hosting / cómputo**: [PROVEEDOR].
- **DNS / TLS**: [PROVEEDOR].
- **Contenedores / orquestación**: [HERRAMIENTA].
- **CI/CD**: [HERRAMIENTA].

## Ambientes

| Ambiente   | URL              | Rama      | Deploy     |
| ---------- | ---------------- | --------- | ---------- |
| Desarrollo | [URL_DEV]        | `develop` | Automático |
| Staging    | [URL_STAGING]    | `staging` | Automático |
| Producción | [URL_PRODUCCION] | `main`    | Manual     |

## Reglas

- Solo se despliega a producción desde `main`.
- Cada deploy debe ser reproducible y reversible.
- Las variables de entorno y secretos se gestionan según [`secrets.md`](secrets.md).
- Verificar health checks tras cada deploy.

## Procedimiento de deploy

```bash
# 1. Build
[COMANDO_BUILD]

# 2. Deploy al ambiente
[COMANDO_DEPLOY]

# 3. Verificar
curl [URL_HEALTHCHECK]
```

## Rollback

```bash
[COMANDO_ROLLBACK]
```

## Health checks y monitoreo

- Endpoint de salud: `[RUTA_HEALTHCHECK]`.
- Monitoreo de errores: [HERRAMIENTA].
- Alertas: [Dónde y ante qué se notifica].

## Referencias

- [Documentación de la herramienta de deploy].
