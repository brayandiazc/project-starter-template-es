# Convenciones de calidad y tooling

> Linters, formato, análisis estático y git hooks de [NOMBRE_DEL_PROYECTO].
> **Última actualización**: [FECHA]

> El stack concreto —motor, librería, herramientas— lo decide el proyecto y lo registra
> [`../architecture/stack.md`](../architecture/stack.md), con el porqué en
> [`../decisions/`](../decisions/README.md). Aquí van solo las **reglas**, que no cambian
> al cambiar de herramienta.

## Git hooks

Estrategia: **`pre-commit` corrige, `pre-push` verifica.** El primero formatea y
nunca bloquea —un hook que bloquea por formato solo enseña a usar `--no-verify`—;
el segundo corre los mismos checks que el CI y sí bloquea, porque un enlace roto o
un test en rojo no es ruido.

El CI vuelve a ejecutarlo todo en el servidor, pero como **red de seguridad, no como
bucle de verificación**: en un repositorio privado los minutos de Actions son finitos
y descubrir allí un fallo que tardaba 15 segundos en local cuesta un run entero.

Los hooks viven versionados en [`.githooks/`](../../.githooks). Git no los usa hasta
que se lo dices, **una vez por clon** (no viaja en el repositorio):

```bash
git config core.hooksPath .githooks
```

Hazlo al clonar. Para saltárselos puntualmente: `git commit --no-verify` o
`git push --no-verify`.

### pre-push (incluido y activo)

Corre los mismos checks del job `Calidad`, en el mismo orden que
[`quality.yml`](../../.github/workflows/quality.yml): formato, enlaces internos,
placeholders, herencia, design system, instrucciones del README, la suite de pruebas
de la plantilla y las pruebas del proyecto. Tarda ~15 segundos. (La lista canónica es la del propio
[`pre-push`](../../.githooks/pre-push) — si esto se queda atrás, manda el hook.)

**Bloquea el push si algo falla**, y no corta en el primer fallo: los ejecuta todos y
los lista juntos, igual que el `!cancelled()` del workflow. Si un script no existe
—porque el proyecto lo podó al instanciar— se salta, no falla.

Según el stack, añádele: linter completo, un subconjunto rápido de tests, auditoría
de dependencias.

### pre-commit (incluido y activo)

- **Formatea lo que está en stage** con Prettier (`md`, `html`, `css`, `json`, `yml`)
  y lo vuelve a agregar al commit. **Nunca bloquea**: el formato no es una decisión,
  es ruido.
- Salta los archivos que tienen cambios sin agregar al stage: reformatearlos metería
  en el commit trabajo que decidiste dejar fuera.
- El código de la aplicación no lo toca — ese es del linter del stack. Cuando el
  stack esté elegido, añade aquí su linter sobre archivos cambiados y la verificación
  de trailing whitespace y conflictos sin resolver.

## Reglas

- El código debe pasar linter y formato antes del merge.
- Los checks de calidad son **bloqueantes** en CI.

## Comandos útiles

Los comandos de test y lint viven en el bloque «Uso» del
[`README.md`](../../README.md) — única copia. Aquí solo los que no están allí:

```bash
[COMANDO_FORMAT]
[COMANDO_AUDIT_DEPENDENCIAS]
```
