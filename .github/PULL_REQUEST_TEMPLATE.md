# Descripción

Qué cambia y qué problema resuelve. Si implementa una spec, enlázala.

## Tipo de cambio

- [ ] Bug fix
- [ ] Nueva funcionalidad
- [ ] Breaking change
- [ ] Refactorización (sin cambio de comportamiento)
- [ ] Documentación
- [ ] Configuración / tooling

## Cómo comprobar que funciona

Pasos concretos para verificar el resultado, no el código:

1.
2.

## Lo que ninguna máquina comprueba

> El CI ya verifica formato, enlaces, entrada en el CHANGELOG y la suite de tests: no
> hay casillas para eso. Aquí van solo las cosas que **fallan en silencio** — pasan los
> tests y no generan un error en el monitor (`docs/conventions/ai-agents.md`).

- [ ] **Esquema de datos revisado a mano** — obligatorio si hay migración. Es lo más
      caro de cambiar después y lo único que ni los tests ni el monitoreo detectan.
- [ ] Si toca **autorización**: probada con un rol distinto al propio.
- [ ] Si toca **colas o móvil**: las operaciones de creación son idempotentes.
- [ ] Si toca **UI**: los cuatro estados (loading, empty, error, éxito) y ambos temas.
- [ ] Si hay **componente custom**: focus trap, Escape, ARIA y navegación por teclado.
- [ ] Documentación afectada actualizada e ítem del roadmap marcado si la spec lo completa.

## Impacto

- **Breaking change**: Sí / No — si sí, qué rompe y qué hay que hacer
- **Requiere migración**: Sí / No
- **Crece sin límite algo** (storage, cómputo, llamadas a un modelo): Sí / No — si sí,
  ¿está en el precio?

## Evidencia

Capturas o vídeo si hay UI — **en los dos temas**.

## Issues

Closes #
