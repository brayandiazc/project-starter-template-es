# Convenciones de base de datos

> Reglas y estándares de modelado de datos en [NOMBRE_DEL_PROYECTO].
> Para el modelo de datos concreto del proyecto ver
> [`../architecture/database.md`](../architecture/database.md).
> **Última actualización**: [FECHA]

## Stack

- **Motor**: [BASE_DE_DATOS].
- **Capa de acceso / ORM**: [ORM].
- **Migraciones**: [HERRAMIENTA_MIGRACIONES].

## Reglas de modelado

- **Primary keys**: [estrategia — p. ej. UUID o autoincremental] de forma consistente.
- **Nombres**: tablas y columnas en [convención — snake_case], en [idioma].
- **Timestamps**: toda tabla tiene `created_at` y `updated_at`.
- **Foreign keys**: siempre con índice; `NOT NULL` salvo justificación explícita.
- **Tipos preferidos**:

| Caso              | Tipo               |
| ----------------- | ------------------ |
| Email             | [TIPO]             |
| Texto corto       | [TIPO]             |
| Texto largo       | [TIPO]             |
| JSON estructurado | [TIPO]             |
| Dinero            | [TIPO decimal]     |
| Booleano          | [TIPO] con default |

## Migraciones

- Reversibles y no destructivas siempre que sea posible.
- Una migración por cambio lógico; nunca editar una migración ya aplicada en `main`.
- Revisar el impacto en datos existentes antes de aplicar en producción.

## Ejemplos

```text
crear tabla [recurso]
  id           [pk]
  [referencia] [fk, not null, indexado]
  nombre       [texto, not null]
  timestamps
```

## Comandos útiles

```bash
[COMANDO_CREAR_MIGRACION]
[COMANDO_MIGRAR]
[COMANDO_ROLLBACK]
```

## Referencias

- [Documentación del ORM / motor de base de datos].
