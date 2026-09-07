# Convenciones de testing

> Cómo escribimos y ejecutamos tests en [NOMBRE_DEL_PROYECTO].
> **Última actualización**: [FECHA]

> El stack concreto —motor, librería, herramientas— lo decide el proyecto y lo registra
> [`../architecture/stack.md`](../architecture/stack.md), con el porqué en
> [`../decisions/`](../decisions/README.md). Aquí van solo las **reglas**, que no cambian
> al cambiar de herramienta.

## Tipos de test

| Tipo          | Qué cubre                     | Carpeta              |
| ------------- | ----------------------------- | -------------------- |
| Unitarios     | Funciones/clases aisladas     | `[RUTA_UNIT]`        |
| Integración   | Interacción entre componentes | `[RUTA_INTEGRACION]` |
| E2E / sistema | Flujos completos de usuario   | `[RUTA_E2E]`         |

## Reglas

- Todo cambio funcional se acompaña de tests.
- Estructura **Arrange-Act-Assert** (AAA): preparar, ejecutar, verificar.
- Un test verifica **una** cosa; nombres descriptivos del comportamiento esperado.
- Los tests deben ser deterministas (sin dependencia de red, reloj o orden).
- Cobertura mínima esperada: [PORCENTAJE]%.

## Ejemplos

```text
describe "[Unidad bajo prueba]"
  it "[comportamiento esperado] cuando [condición]"
    # Arrange
    # Act
    # Assert
```

## Comandos útiles

El comando para ejecutar la suite completa vive en el bloque «Configuración y
«Uso» del [`README.md`](../../README.md) — única copia (de ahí lo lee también
`check-project-tests.sh`). Aquí solo los que no están allí:

```bash
[COMANDO_TEST_COBERTURA]  # Con reporte de cobertura
[COMANDO_TEST_WATCH]      # Modo watch
```
