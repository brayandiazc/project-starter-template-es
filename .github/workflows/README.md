# Workflows de CI/CD

Esta carpeta contiene los workflows de [GitHub Actions](https://docs.github.com/actions)
del proyecto.

## Workflows activos (agnósticos del stack)

Funcionan tal cual, sin importar el lenguaje del proyecto — no los borres al instanciar:

- [`quality.yml`](quality.yml) — calidad de la documentación: formato (Prettier sobre Markdown, HTML, CSS, JSON y YAML), enlaces internos, placeholders y la suite de pruebas de los scripts del
  repo (ver [`../scripts/`](../scripts)).
- [`secret-scan.yml`](secret-scan.yml) — escaneo de secretos con
  [gitleaks](https://github.com/gitleaks/gitleaks) sobre el historial.

## Exclusivo del repo-plantilla

- [`template-parity.yml`](template-parity.yml) — compara la estructura con la variante
  hermana en el otro idioma. Tiene un guard por nombre de repositorio para no ejecutarse
  en proyectos instanciados; aun así, bórralo al instanciar la plantilla.

## Esqueleto incluido

- [`ci.yml.example`](ci.yml.example) — pipeline de CI neutro (lint → test → build).
  La extensión `.example` va **al final a propósito**: GitHub ejecuta cualquier archivo
  `.yml`/`.yaml` que viva en esta carpeta, sin importar qué más lleve en el nombre.
  Cuando lo adaptes a tu stack, renómbralo a `ci.yml`.

> Regla para esta carpeta: si un archivo no debe ejecutarse, **no puede terminar en
> `.yml` ni `.yaml`**. La suite de pruebas lo verifica.

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
