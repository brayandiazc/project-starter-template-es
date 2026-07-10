# Guardrails de git (opcional)

Hooks nativos de git que refuerzan el branching de
[`../CONTRIBUTING.md`](../CONTRIBUTING.md):

- `pre-commit` — bloquea commits directos en `main` / `master` / `develop`, y
  además rechaza archivos de secretos en stage: `.env` y sus variantes
  (`.env.local`, `.env.production`…) y claves privadas (`*.pem`, `*.key`,
  `id_rsa*`, `id_ed25519*`, `id_ecdsa*`). Los contratos de ejemplo
  (`.env.example`, `.env.sample`, `.env.template`) sí se permiten.
- `pre-push` — bloquea push directo a esas ramas.

No están activos por defecto. Para habilitarlos en tu clon:

```bash
git config core.hooksPath .githooks
```

Para desactivarlos: `git config --unset core.hooksPath`.

> Son una red de seguridad **local**; no sustituyen la protección de ramas del
> lado del servidor (GitHub).
