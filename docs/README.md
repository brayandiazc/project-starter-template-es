# Documentación de [NOMBRE_DEL_PROYECTO]

Mapa de la documentación del proyecto. Empieza por aquí para saber qué documento
responde cada pregunta.

| Documento                                                      | Pregunta que responde                | Cuándo leerlo                   |
| -------------------------------------------------------------- | ------------------------------------ | ------------------------------- |
| [`architecture/architecture.md`](architecture/architecture.md) | ¿Cómo está construido el sistema?    | Al entender el panorama general |
| [`architecture/stack.md`](architecture/stack.md)               | ¿Con qué tecnologías y versiones?    | Al configurar el entorno        |
| [`architecture/database.md`](architecture/database.md)         | ¿Qué entidades y relaciones hay?     | Al trabajar con datos           |
| [`architecture/auth.md`](architecture/auth.md)                 | ¿Cómo se entra y qué se permite?     | Al tocar autenticación/permisos |
| [`architecture/api.md`](architecture/api.md)                   | ¿Qué endpoints expone?               | Al integrar o consumir la API   |
| [`architecture/screens.md`](architecture/screens.md)           | ¿Qué pantallas hay y por dónde va?   | Al diseñar features o UI        |
| [`../design/README.md`](../design/README.md)                   | ¿Qué identidad visual y tokens?      | Al construir cualquier vista    |
| [`product/business-model.md`](product/business-model.md)       | ¿Por qué existe / cómo genera valor? | Para entender el negocio        |
| [`product/roadmap.md`](product/roadmap.md)                     | ¿Hacia dónde va?                     | Para conocer prioridades        |
| [`decisions/`](decisions/README.md)                            | ¿Por qué tomamos cada decisión?      | Antes de re-debatir algo        |
| [`conventions/`](conventions/README.md)                        | ¿Cómo trabajamos en este repo?       | Antes de escribir código        |

## Sobre la distinción `architecture/` vs `conventions/`

- **`architecture/`** responde **qué construye este proyecto** (su modelo de datos, su
  API, sus pantallas).
- **`conventions/`** responde **cómo se trabaja** (cómo se testea, cómo se despliega,
  cómo se manejan secretos) — transversal a cualquier feature.

Cuando un tema no da para las dos preguntas, vive en un solo documento: la auth entera
está en `architecture/auth.md`, reglas incluidas. Solo la base de datos conserva el par,
y cada regla vive en un único lado.

**Por qué `design/` no está aquí dentro**: `docs/` es lo que se **lee** para construir;
`design/` se **consume** — `design/tokens.css` lo importa el CSS de la aplicación.

## Cómo mantener esta documentación

- Actualiza la línea **"Última actualización"** al editar un documento.
- Registra las decisiones relevantes como [ADRs](decisions/README.md).
- Mantén este índice al día si agregas o quitas documentos.
