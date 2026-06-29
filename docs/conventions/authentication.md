# Convenciones de autenticación y autorización

> Reglas transversales de autenticación y autorización en [NOMBRE_DEL_PROYECTO].
> Para cómo funciona la auth en este proyecto ver
> [`../architecture/auth.md`](../architecture/auth.md).
> **Última actualización**: [FECHA]

## Stack

- **Autenticación**: [MECANISMO / LIBRERÍA].
- **Autorización**: [MECANISMO / LIBRERÍA].
- **Hashing de contraseñas**: [bcrypt / argon2 / …].

## Reglas

- La autorización se valida **siempre en el servidor**, en cada request.
- Nunca confiar en checks de cliente para decisiones de seguridad.
- Las contraseñas se almacenan hasheadas con un algoritmo robusto y salt.
- Los tokens/sesiones se rotan en cada login y tienen expiración.
- Los flujos OAuth/SSO se validan server-side (email y UID).

## Modelo

- **Usuario**: [campos clave de identidad].
- **Sesión / token**: [cómo se representa].
- **Roles / permisos**: [esquema RBAC/ABAC].

## Ejemplos

```text
# Pseudocódigo de verificación de autorización
if not current_user.can?(:accion, recurso)
  rechazar(403)
```

## Comandos útiles

```bash
[COMANDO_RELEVANTE]
```

## Referencias

- [`../architecture/auth.md`](../architecture/auth.md)
- [SECURITY.md](../../SECURITY.md)
