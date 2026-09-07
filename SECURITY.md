# Política de Seguridad

Cómo reportar vulnerabilidades en **[NOMBRE_DEL_PROYECTO]** y qué prácticas de seguridad
se siguen en el repositorio.

## Reportar una vulnerabilidad

**No abras un issue público.** Repórtala en privado por uno de estos canales:

- **GitHub Security Advisories** — pestaña _Security_ del repositorio → _Report a
  vulnerability_ (preferido: queda trazado y permite publicar el advisory).
- **Email** — <[EMAIL_SEGURIDAD]>, con el asunto empezando por `Security:`.

Incluye: descripción, pasos para reproducirla (PoC si puedes), impacto estimado, versión
o commit afectado y, si quieres crédito en la corrección, tu nombre o handle.

Esto lo mantiene una sola persona: **no hay SLA de respuesta**. Lo que sí hay es el
compromiso de acusar recibo, priorizar por impacto real, no tomar represalias contra
reportes de buena fe y acreditarte en el changelog si lo deseas. Las vulnerabilidades
críticas se atienden antes que cualquier feature.

### Qué cuenta y qué no

En alcance: el código del repositorio, la aplicación desplegada en sus dominios
oficiales, los endpoints que expone y los workflows de `.github/workflows/`.

**No** cuentan: salidas de scanners automáticos sin impacto demostrado, ausencia de
headers sin vector de explotación, self-XSS, ingeniería social, DoS por volumen, ni
vulnerabilidades de dependencias que este proyecto no puede alcanzar.

## Manejo de secretos

- **Nunca** commitear secretos en texto plano: claves, tokens, contraseñas,
  certificados privados o un `.env` con valores reales. El workflow `secret-scan.yml`
  escanea el historial con gitleaks.
- El lugar canónico es **el gestor de credenciales del equipo**; `.env` se genera
  desde ahí y `.env.example`
  documenta el contrato sin valores. Ver
  [`docs/conventions/secrets.md`](docs/conventions/secrets.md).
- En CI, secretos cifrados del proveedor (GitHub Actions Secrets) — nunca en el YAML.
- **Si un secreto se filtra: rota primero, limpia la historia después.** Reescribir la
  historia no basta; asume que ya está comprometido desde el primer push.

## Dependencias

- Lockfile versionado siempre; nada de rangos abiertos en producción.
- **Dependabot** (`.github/dependabot.yml`) abre los PRs de actualización.
- Una vulnerabilidad crítica en una dependencia tiene la misma prioridad que una del
  código propio.

## Dónde se revisa la seguridad a mano

Estas cuatro áreas se miran explícitamente porque **fallan en silencio**: pasan los
tests y no generan un solo error en el monitor.

| Área             | Qué se comprueba                                                                        |
| ---------------- | --------------------------------------------------------------------------------------- |
| **Autorización** | Cada endpoint, con roles distintos al propio. Validación siempre en servidor            |
| **Input**        | Queries parametrizadas (nunca concatenar SQL), validación en cada borde                 |
| **Sesiones**     | Hash con argon2/bcrypt, rotación de token en cada login, `Secure`+`HttpOnly`+`SameSite` |
| **Webhooks**     | Firma verificada sobre el **cuerpo crudo**, antes de parsear                            |

Lo demás es línea base y no se negocia: HTTPS con HSTS en todo entorno público, sin
secretos ni PII en logs, y backups cifrados **con restore probado** — un backup sin
restore probado no es un backup.

Antes de fusionar cualquier cosa que toque autenticación, autorización, pagos o datos de
usuario, recorre esa tabla explícitamente en el PR.

## Respuesta a un incidente

1. **Contener** — aislar lo afectado y revocar credenciales comprometidas.
2. **Investigar** — causa raíz, alcance y vector.
3. **Remediar** — corregir, redesplegar y rotar todos los secretos que hayan podido
   quedar expuestos.
4. **Notificar** — a las personas afectadas si hubo exposición de datos personales,
   según la normativa de protección de datos que le aplique al producto.
5. **Post-mortem** — qué falló y qué cambia para que no se repita, como ADR si toca
   estructura.

## Contacto

- Seguridad: <[EMAIL_SEGURIDAD]> (asunto `Security: …`)
- General: <[EMAIL_SOPORTE]>
