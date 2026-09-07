<!--
  ┌─────────────────────────────────────────────────────────────────────────┐
  │  Esto es una PLANTILLA. Antes de publicar tu proyecto:                     │
  │  1. Lee TEMPLATE-USAGE.md para saber cómo instanciarla.                    │
  │  2. Reemplaza todos los [PLACEHOLDERS] (búscalos con grep, ver guía).      │
  │  3. Elimina este comentario.                                               │
  └─────────────────────────────────────────────────────────────────────────┘
-->

# [NOMBRE_DEL_PROYECTO]

Descripción breve y concisa del proyecto (1-2 líneas).

![Calidad](https://github.com/[USUARIO_GITHUB]/[SLUG_REPOSITORIO]/actions/workflows/quality.yml/badge.svg)
![License](https://img.shields.io/badge/license-MIT-blue)

## Descripción

Qué problema resuelve, para quién y qué cambia para esa persona. El alcance de la
versión actual está en
[`docs/product/roadmap.md`](docs/product/roadmap.md).

## Requisitos previos

- **[RUNTIME]** v[VERSION] o superior
- **[GESTOR_DE_PAQUETES]** v[VERSION] o superior
- **[BASE_DE_DATOS]** v[VERSION] o superior

## Instalación

```bash
git clone [URL_REPOSITORIO]
cd [SLUG_REPOSITORIO]
git config core.hooksPath .githooks   # ← una vez por clon, no viaja en el repo
[COMANDO_INSTALAR_DEPENDENCIAS]
cp .env.example .env                  # completa los valores; nunca lo commitees
[COMANDO_MIGRACIONES]
```

> La primera línea no es opcional. Sin ella no corren los hooks: `pre-commit` no
> formatea y `pre-push` no verifica antes de publicar, así que los fallos se
> descubren en el CI —más lento y, en un repositorio privado, con minutos contados.

Las variables están documentadas en [`.env.example`](.env.example). Los valores reales
salen del gestor de credenciales, no del repositorio — ver
[`docs/conventions/secrets.md`](docs/conventions/secrets.md).

## Uso

```bash
[COMANDO_INICIAR_DESARROLLO]   # http://localhost:[PUERTO]
[COMANDO_TEST]                 # suite de pruebas
[COMANDO_LINT]                 # lint / formato
[COMANDO_BUILD]                # build de producción
```

## Stack

**[ELEGIDA]**. Lo elegido en este producto está en
[`docs/architecture/stack.md`](docs/architecture/stack.md); el porqué de cada decisión,
en [`docs/decisions/`](docs/decisions/README.md).

## Deployment

| Ambiente   | URL              | Rama      | Deploy     |
| ---------- | ---------------- | --------- | ---------- |
| Desarrollo | [URL_DEV]        | `develop` | Automático |
| Producción | [URL_PRODUCCION] | `main`    | Manual     |

Procedimiento en [`docs/conventions/deploy.md`](docs/conventions/deploy.md).

## Documentación

El mapa completo —qué documento responde a cada pregunta— está en
**[`docs/README.md`](docs/README.md)**. Los atajos más usados:

- [`docs/architecture/stack.md`](docs/architecture/stack.md) — con qué se construye
- [`docs/product/roadmap.md`](docs/product/roadmap.md) — qué está hecho y qué viene
- [`docs/conventions/`](docs/conventions/README.md) — cómo se trabaja aquí
- [`docs/decisions/`](docs/decisions/README.md) — por qué se decidió cada cosa

## Contribución

Flujo de trabajo, branching y formato de commits en
[`CONTRIBUTING.md`](CONTRIBUTING.md). Reporte de vulnerabilidades en
[`SECURITY.md`](SECURITY.md).

## Versionado y licencia

[Semantic Versioning](https://semver.org/) y [Keep a Changelog](CHANGELOG.md).
Licencia [MIT](LICENSE).

---

⌨️ con ❤️ por [@[USUARIO_GITHUB]](https://github.com/[USUARIO_GITHUB])
