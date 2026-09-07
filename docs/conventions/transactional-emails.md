# Convenciones de correos transaccionales

> Cómo enviamos correos transaccionales en [NOMBRE_DEL_PROYECTO].
> **Última actualización**: [FECHA]

> El stack concreto —motor, librería, herramientas— lo decide el proyecto y lo registra
> [`../architecture/stack.md`](../architecture/stack.md), con el porqué en
> [`../decisions/`](../decisions/README.md). Aquí van solo las **reglas**, que no cambian
> al cambiar de herramienta.

## Configuración por entorno

| Entorno    | Mecanismo de envío       |
| ---------- | ------------------------ |
| Desarrollo | [Previsualización local] |
| Test       | [Captura en memoria]     |
| Producción | [PROVEEDOR real]         |

## Reglas

- Todo correo se envía en **HTML y texto plano** (multipart).
- Operaciones idempotentes: registrar `*_enviado_at` para no reenviar.
- No incluir secretos ni PII innecesaria en el cuerpo.
- Asuntos y contenido localizados (ver [`i18n.md`](i18n.md)).
- Enlaces con URLs absolutas y firmadas/expirables cuando corresponda.

## Tipos de correo

| Correo           | Disparador          |
| ---------------- | ------------------- |
| Bienvenida       | Registro de usuario |
| Recuperar acceso | Solicitud de reset  |
| [OTRO]           | [Evento]            |

## Ejemplos

```text
Asunto: Bienvenido a [NOMBRE_DEL_PROYECTO]
Cuerpo: HTML + texto plano, con CTA y enlace de verificación
```
