# Stack de [NOMBRE_DEL_PROYECTO]

> **Qué es**: lo que se eligió en **este** producto y por qué. Es la **única** fuente
> del stack: si una convención repite uno de estos datos, se desincroniza sin que nadie
> lo note. El porqué largo de cada elección va como ADR en
> [`../decisions/`](../decisions/README.md).
> **Última actualización**: [FECHA]

## Stack elegido

**[ELEGIDA]**, y de dónde sale: [decisión propia de este proyecto · estándar del equipo
· requisito del cliente · desviación de un estándar, con ADR].

> Escribe de dónde viene la decisión, no solo cuál fue. Es lo que hace auditable, meses
> después, si alguien eligió o simplemente heredó.

> Las filas son **categorías**, no elecciones: rellena cada una con lo que use este
> producto y **borra las que no apliquen** (una CLI no tiene base de datos, un sitio
> estático no tiene framework de servidor).

| Pieza                  | Versión   | Nota |
| ---------------------- | --------- | ---- |
| Framework principal    | [VERSION] |      |
| Runtime / lenguaje     | [VERSION] |      |
| Base de datos          | [VERSION] |      |
| Gestor de dependencias | [VERSION] |      |

Todo lo demás es lo que dicta el marco. **Si no aparece abajo como desviación, es el
default.**

## Desviaciones de lo estándar del equipo

Cada fila necesita su ADR en [`../decisions/`](../decisions/README.md). Si la tabla está
vacía, mejor: el producto va por el camino trillado.

| Se desvió en | Se usa en su lugar | Por qué | ADR |
| ------------ | ------------------ | ------- | --- |
| [DESCARTADA] | [ELEGIDA]          |         |     |

## Servicios activos

Solo los que este producto tiene **contratados y conectados**. El catálogo completo está
donde el equipo lo tenga escrito; un servicio que aquí no esté listado, no está
funcionando todavía.

| Servicio       | Para qué   | Variable de entorno |
| -------------- | ---------- | ------------------- |
| [SERVICIO/API] | [PARA_QUE] | `[NOMBRES]`         |
|                |            |                     |

## APIs de terceros que consumimos

> **Bórrala si el producto no llama a ninguna.** Una fila por API, con su adaptador: la
> lógica de negocio no conoce al proveedor.

| API         | Para qué       | Adaptador        | ¿Clave? | Respaldo si falla                    |
| ----------- | -------------- | ---------------- | ------- | ------------------------------------ |
| [Proveedor] | [Qué resuelve] | [Clase o módulo] | [Sí/No] | [Otro proveedor · degradar · fallar] |

Y por cada una, decidido **antes** de implementar — si no está escrito, cada llamada lo
decide por su cuenta:

- **Qué forma tiene el objeto en NUESTRO dominio**, frente a lo que devuelve el proveedor.
  Es lo que el adaptador traduce; sin esto acaba siendo el JSON del proveedor con otro
  nombre, y entonces no hay adaptador.
- **Qué pasa cuando no encuentra nada.** Si la respuesta obliga a un flujo alternativo,
  dilo aquí: una limitación de la API que define una pantalla no es un detalle técnico.
- **Caché**: qué se guarda, cuánto vive y por qué. Cuando muchos usuarios piden lo mismo
  suele ser casi gratis y cambiar el coste entero.
- **Límites de uso** y qué ocurre al alcanzarlos.
- **Licencia de los datos** y atribución exigida al mostrarlos.

## Proveedor de IA

**Esta plantilla no fija ninguno**, y conviene que tú tampoco lo des por supuesto:
se elige aquí, por producto.

|                                                                               |                         |
| ----------------------------------------------------------------------------- | ----------------------- |
| Proveedor principal                                                           | `AI_PROVIDER=`          |
| Modelo por tarea                                                              |                         |
| **Segundo proveedor** (configurado desde el día 1, tests corriendo contra él) |                         |
| ¿Usa alguna capacidad exclusiva (caso B)?                                     | No / Sí → **exige ADR** |

Si la respuesta a la última fila es "Sí", las mitigaciones de una capacidad exclusiva
—puerto propio en el dominio, dos implementaciones, guardar el insumo y no solo el
resultado, y un ADR que nombre el riesgo de cierre— son
obligatorias — sobre todo **guardar el insumo, no solo el resultado**.

## Decisiones del arranque

Respondidas antes de escribir código:

- **Entidad central del producto**: — _(se diseña en papel antes que nada)_
- **¿Qué crece sin límite?**: — _ese es el costo recurrente_
- **¿Hay costo de infraestructura por usuario?**: — _si sí, va al precio desde el día uno_
- **¿Hay pantalla con interactividad continua?**: — _si sí, ahí es donde un framework
  de cliente se gana su sitio_
- **¿Necesita algo que la web no da?**: — _si sí, nativo; si no, PWA_
