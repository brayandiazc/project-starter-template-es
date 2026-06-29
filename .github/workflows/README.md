# Workflows de CI/CD

Esta carpeta contiene los workflows de [GitHub Actions](https://docs.github.com/actions)
del proyecto.

Como la plantilla es agnóstica del stack, **no incluye workflows listos para
ejecutar**: solo un esqueleto de ejemplo. Adáptalo (o créalo) según tu lenguaje
y herramientas.

## Esqueleto incluido

- [`ci.example.yml`](ci.example.yml) — pipeline de CI neutro (lint → test → build).
  Tiene la extensión `.example` **a propósito** para que GitHub no lo ejecute.
  Cuando lo adaptes a tu stack, renómbralo a `ci.yml`.

## Workflows recomendados

| Workflow                    | Propósito                                      |
| --------------------------- | ---------------------------------------------- |
| `ci.yml`                    | Lint, tests y build en cada push/PR.           |
| `labeler.yml`               | Auto-etiquetado de PRs (usa `../labeler.yml`). |
| `dependabot-auto-merge.yml` | Auto-merge de PRs de Dependabot (parches).     |
| `deploy.yml`                | Despliegue (depende de tu infraestructura).    |

## Secrets

Define en **Settings → Secrets and variables → Actions** los secretos que
necesiten tus workflows (claves de deploy, tokens, etc.). Ver
[`../../docs/conventions/secrets.md`](../../docs/conventions/secrets.md).
