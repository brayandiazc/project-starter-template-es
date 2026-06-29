# Convenciones de testing

> Cómo escribimos y ejecutamos tests en [NOMBRE_DEL_PROYECTO].
> **Última actualización**: [FECHA]

## Stack

- **Framework de tests**: [FRAMEWORK_TEST].
- **Cobertura**: [HERRAMIENTA_COBERTURA].
- **Tests de sistema/E2E**: [HERRAMIENTA_E2E] (si aplica).

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

```bash
[COMANDO_TEST]            # Ejecutar todos los tests
[COMANDO_TEST_COBERTURA]  # Con reporte de cobertura
[COMANDO_TEST_WATCH]      # Modo watch
```

## Referencias

- [Documentación del framework de tests].
