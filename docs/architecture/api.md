# Referencia de API

> Endpoints, autenticación y convenciones de la API de **[NOMBRE_DEL_PROYECTO]**.
> Documentación interactiva: [LINK_OPENAPI/SWAGGER/POSTMAN]
>
> **Última actualización**: [FECHA]

## Convenciones generales

- **URL base**: `[URL_BASE_API]`
- **Versionado**: prefijo de versión en la ruta (p. ej. `/v1`).
- **Formato**: JSON (`Content-Type: application/json`).
- **Fechas**: ISO 8601 (`YYYY-MM-DDTHH:mm:ssZ`).

## Autenticación de la API

- Esquema: [Bearer token / API key / OAuth].
- Header: `Authorization: Bearer <token>`.
- Ver [`auth.md`](auth.md) para el detalle.

## Manejo de errores

Formato de error estándar:

```json
{
  "error": {
    "code": "[CÓDIGO]",
    "message": "[Mensaje legible]",
    "details": []
  }
}
```

| Código HTTP | Significado             |
| ----------- | ----------------------- |
| 200 / 201   | Éxito                   |
| 400         | Solicitud inválida      |
| 401         | No autenticado          |
| 403         | No autorizado           |
| 404         | No encontrado           |
| 422         | Validación fallida      |
| 429         | Límite de tasa excedido |
| 500         | Error interno           |

## Paginación, filtrado y ordenamiento

- **Paginación**: `?page=1&per_page=20` (o cursor: `?cursor=...`).
- **Filtrado**: `?filtro[campo]=valor`.
- **Ordenamiento**: `?sort=-created_at`.

## Endpoints

### [RECURSO]

```http
GET    /v1/[recursos]          # Listar
GET    /v1/[recursos]/:id      # Obtener uno
POST   /v1/[recursos]          # Crear
PUT    /v1/[recursos]/:id      # Actualizar
DELETE /v1/[recursos]/:id      # Eliminar
```

**Ejemplo — crear:**

```http
POST /v1/[recursos]
Content-Type: application/json
Authorization: Bearer <token>

{
  "[campo]": "[valor]"
}
```

**Respuesta:**

```json
{
  "id": "[uuid]",
  "[campo]": "[valor]"
}
```

## Rate limiting

- Límite: [N] solicitudes por [ventana] por [usuario/IP].
- Headers de respuesta: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `Retry-After`.

## Webhooks (si aplica)

- Endpoint de recepción, verificación de firma y eventos soportados.

## Changelog de la API

- [Cambios relevantes del contrato de la API, por versión].
