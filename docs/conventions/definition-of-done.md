# Definition of Done

> Qué significa "terminado" en [NOMBRE_DEL_PROYECTO]. Si una línea no se puede
> marcar, el cambio no está terminado — está _declarado_ terminado.
> **Última actualización**: [FECHA]

## Comportamiento

- [ ] El flujo completo se ejercitó de punta a punta (a mano o con una prueba
      automatizada de alto nivel), no solo con pruebas unitarias.
- [ ] El camino feliz **y al menos dos caminos de error** (entrada inválida, fallo
      de una dependencia) responden de forma sensata.
- [ ] Los estados de carga, vacío, error y éxito se muestran correctamente (si hay UI).

## Pruebas

- [ ] Existe al menos una prueba que fallaría si el cambio se revirtiera.
- [ ] Ninguna prueba existente se debilitó, saltó o borró para poner el CI en verde.
- [ ] La cobertura de las líneas cambiadas es significativa
      (ver [`testing.md`](testing.md)).

## Interfaces y datos

- [ ] Los cambios de API pública están documentados en
      [`../architecture/api.md`](../architecture/api.md); los cambios incompatibles
      tienen nota de migración en el `CHANGELOG.md`.
- [ ] Los mensajes de error son accionables, no "algo salió mal".
- [ ] Las migraciones son reversibles y seguras en caliente
      (ver [`database.md`](database.md)).
- [ ] No hay secretos en el código ni en los logs (ver [`secrets.md`](secrets.md)).

## Entrega

- [ ] Commits atómicos y legibles según [`../../CONTRIBUTING.md`](../../CONTRIBUTING.md).
- [ ] La descripción del PR responde el **por qué**, no solo el qué.
- [ ] Existe un plan de reversa (commit de revert, feature flag apagado, etc.).
- [ ] La documentación afectada en `docs/` y el `CHANGELOG.md` quedaron al día; las
      decisiones notables tienen su ADR en [`../decisions/`](../decisions/README.md).
