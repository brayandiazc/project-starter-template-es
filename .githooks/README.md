# Guardrails de git (opcional)

Hooks nativos de git que refuerzan el branching de
[`../CONTRIBUTING.md`](../CONTRIBUTING.md):

- `pre-commit` — bloquea commits directos en `main` / `master` / `develop`.
- `pre-push` — bloquea push directo a esas ramas.

No están activos por defecto. Para habilitarlos en tu clon:

```bash
git config core.hooksPath .githooks
```

Para desactivarlos: `git config --unset core.hooksPath`.

> Son una red de seguridad **local**; no sustituyen la protección de ramas del
> lado del servidor (GitHub). No requieren ninguna herramienta de IA.
