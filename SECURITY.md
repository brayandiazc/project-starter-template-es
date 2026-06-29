# Política de Seguridad

Este documento describe cómo reportar vulnerabilidades en **[NOMBRE_DEL_PROYECTO]** y qué prácticas de seguridad seguimos en el repositorio.

## Tabla de Contenidos

- [Reporte de Vulnerabilidades](#reporte-de-vulnerabilidades)
  - [Información a incluir](#información-a-incluir)
  - [Qué esperar](#qué-esperar)
- [Versiones Soportadas](#versiones-soportadas)
- [Alcance](#alcance)
- [Fuera de Alcance](#fuera-de-alcance)
- [Manejo de Secretos](#manejo-de-secretos)
- [Dependencias](#dependencias)
- [Prácticas de Desarrollo Seguro](#prácticas-de-desarrollo-seguro)
- [Respuesta a Incidentes](#respuesta-a-incidentes)
- [Reconocimientos](#reconocimientos)
- [Contacto](#contacto)

## Reporte de Vulnerabilidades

Si descubres una vulnerabilidad de seguridad, **no abras un issue público**. Repórtala de forma privada a través de uno de estos canales:

- **Email**: <[EMAIL_SEGURIDAD]> (preferido — usa un asunto que empiece con `Security:` para priorizarlo).
- **GitHub Security Advisories**: pestaña _Security_ del repositorio → _Report a vulnerability_.

### Información a incluir

Para poder triagear y responder rápido, incluye:

1. Descripción clara de la vulnerabilidad.
2. Pasos para reproducirla (PoC si es posible).
3. Impacto estimado (qué se puede comprometer).
4. Versión / commit afectado.
5. Sugerencia de mitigación (opcional).
6. Si quieres crédito público en la corrección, indica nombre y handle.

### Qué esperar

| Etapa                              | Tiempo objetivo             |
| ---------------------------------- | --------------------------- |
| Acuse de recibo                    | 48 horas hábiles            |
| Triage inicial y severidad         | 5 días hábiles              |
| Corrección de severidad crítica    | 7 días                      |
| Corrección de severidad alta       | 30 días                     |
| Corrección de severidad media/baja | próxima release planificada |

Nos comprometemos a confirmar la recepción, mantenerte informado del progreso, no tomar represalias legales contra reportes de buena fe y acreditarte en el changelog/advisory una vez publicada la corrección (si lo deseas).

## Versiones Soportadas

| Versión                 | Soporte de seguridad          |
| ----------------------- | ----------------------------- |
| `main` (rama principal) | Sí                            |
| `develop` (integración) | Sí                            |
| Releases / tags         | [DEFINIR_POLÍTICA_DE_SOPORTE] |

## Alcance

Superficies **en alcance** para reportes de seguridad:

- Código fuente del repositorio.
- Aplicación desplegada en los dominios oficiales.
- Endpoints HTTP/API expuestos por el proyecto.
- Pipelines de CI/CD del repositorio (`.github/workflows/`).
- Artefactos publicados oficialmente.

Ejemplos de hallazgos de interés:

- Inyecciones (SQL, comandos, plantillas, deserialización).
- Cross-Site Scripting (XSS), CSRF, SSRF, clickjacking.
- Autenticación rota o bypass de autorización.
- Escalada de privilegios.
- Exposición de datos sensibles (PII, claves de API, secretos).
- Configuraciones inseguras (CORS, headers, cookies, TLS).
- Vulnerabilidades en dependencias con impacto demostrable.
- Race conditions con impacto en seguridad.
- Path traversal, RCE, LFI/RFI.

## Fuera de Alcance

Los siguientes hallazgos **no califican** como vulnerabilidades:

- Reportes de scanners automáticos sin impacto demostrado.
- Ausencia de headers de seguridad sin un vector de explotación.
- Self-XSS, ingeniería social, phishing.
- Denegación de servicio (DoS / DDoS) por volumen de tráfico.
- Vulnerabilidades en dependencias sin vector de explotación en este proyecto.
- Versiones beta/desarrollo de software de terceros.
- Divulgación de información ya pública.

## Manejo de Secretos

- **Nunca** commitear secretos en texto plano (claves de API, tokens, contraseñas, certificados privados, archivos `.env` con valores reales).
- Gestiona los secretos con el mecanismo de tu stack (gestor de secretos, variables de entorno cifradas, etc.). Ver [`docs/conventions/secrets.md`](docs/conventions/secrets.md).
- Comparte las credenciales fuera de banda con nuevos colaboradores (nunca por git, email en texto plano ni chat público).
- En CI/CD, los secretos viven como **secrets cifrados** del proveedor (p. ej. GitHub Actions Secrets).
- Rota credenciales periódicamente (sugerido cada **90 días**) y de inmediato ante sospecha de compromiso.
- Si un secreto se commitea por error: **rota el secreto antes de limpiar la historia**. Reescribir la historia no es suficiente — asume que ya está comprometido.

## Dependencias

- Fija las versiones de dependencias con un lockfile versionado.
- Ejecuta auditorías de vulnerabilidades automáticas en CI ([COMANDO_AUDIT_DEPENDENCIAS]).
- Las actualizaciones automáticas se gestionan con **Dependabot** (`.github/dependabot.yml`) — PRs revisados por humanos antes del merge.
- Las vulnerabilidades críticas en dependencias se atienden con la misma prioridad que las del propio código.

## Prácticas de Desarrollo Seguro

### Autenticación y Autorización

- Hashea contraseñas con un algoritmo robusto (bcrypt, argon2…).
- Rota los tokens de sesión en cada login.
- Valida la autorización **en el servidor** en cada request — nunca confíes en checks de cliente.
- Valida server-side los flujos de OAuth/SSO.

### Validación de Input

- Valida y normaliza el input en todos los bordes del sistema.
- Usa **queries parametrizadas** — nunca concatenes SQL.
- Codifica el output según el contexto (HTML, atributo, URL, JS, CSS).
- Prefiere listas blancas sobre listas negras.

### Comunicación

- HTTPS obligatorio en todos los entornos públicos (HSTS habilitado).
- Cookies sensibles con `Secure`, `HttpOnly` y `SameSite`.
- Verifica la firma de los webhooks entrantes sobre el cuerpo crudo.

### Logging y Monitoreo

- No loguees secretos, contraseñas, tokens ni PII innecesaria.
- Centraliza los logs con retención y acceso controlado.
- Monitorea errores y configura alertas para anomalías de autenticación y picos de error.

### Backups y Recuperación

- Backups automáticos y periódicos de los datos.
- Backups cifrados y almacenados en una ubicación separada de producción.
- Pruebas de restore periódicas — un backup sin restore probado no es un backup.

### Code Review

- Toda PR requiere aprobación antes del merge (ver [CONTRIBUTING.md](CONTRIBUTING.md)).
- Los cambios sensibles (auth, criptografía, manejo de secretos, infraestructura) requieren revisión específica de seguridad.
- El análisis estático y la auditoría de dependencias son checks bloqueantes.

## Respuesta a Incidentes

En caso de incidente de seguridad confirmado:

1. **Contener**: aislar el sistema afectado, revocar credenciales comprometidas.
2. **Comunicar internamente**: notificar al equipo responsable por el canal definido.
3. **Investigar**: identificar causa raíz, alcance y vectores de explotación.
4. **Remediar**: aplicar la corrección, redeploy, rotar todos los secretos potencialmente expuestos.
5. **Notificar a los afectados**: si hubo exposición de datos personales, según las obligaciones legales aplicables.
6. **Post-mortem**: documentar el incidente, lecciones aprendidas y acciones correctivas.

## Reconocimientos

Agradecemos a quienes reportan vulnerabilidades de forma responsable.

<!-- Orden cronológico inverso. Formato: - YYYY-MM-DD — Nombre/Handle — Resumen breve -->

- _Aún no hay reportes públicos._

## Contacto

- **Reportes de seguridad**: <[EMAIL_SEGURIDAD]> (asunto: `Security: …`)
- **Consultas generales**: <[EMAIL_SOPORTE]>

---

> Versión: 1.0 — Última actualización: [FECHA]
