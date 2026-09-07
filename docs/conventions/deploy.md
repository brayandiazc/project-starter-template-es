# Convenciones de despliegue

> Operaciones de producción de [NOMBRE_DEL_PROYECTO]. Fuente de verdad de cómo se
> despliega, se hace rollback y se opera el sistema.
> **Última actualización**: [FECHA]

> El stack concreto —motor, librería, herramientas— lo decide el proyecto y lo registra
> [`../architecture/stack.md`](../architecture/stack.md), con el porqué en
> [`../decisions/`](../decisions/README.md). Aquí van solo las **reglas**, que no cambian
> al cambiar de herramienta.

## Ambientes

| Ambiente   | URL              | Rama      | Deploy     |
| ---------- | ---------------- | --------- | ---------- |
| Desarrollo | [URL_DEV]        | `develop` | Automático |
| Producción | [URL_PRODUCCION] | `main`    | Manual     |

## Reglas

- Solo se despliega a producción desde `main`, y todo merge a `main` publica versión.
- **Cada deploy es reproducible y reversible.** Con Docker como contrato, volver atrás
  es redesplegar la imagen anterior, no revertir código a mano.
- No hay `staging`: `develop` es el entorno de integración. Un tercer entorno que nadie
  usa de verdad solo añade un sitio donde la configuración se desincroniza.
- Las variables de entorno y secretos se gestionan según [`secrets.md`](secrets.md).
- Verificar health checks tras cada deploy.

## Procedimiento de deploy

```bash
# 1. Build
[COMANDO_BUILD]

# 2. Deploy al ambiente
[COMANDO_DEPLOY]

# 3. Verificar
curl [URL_HEALTHCHECK]
```

## Rollback

```bash
[COMANDO_ROLLBACK]
```

## Respaldos: son DOS, y cubren fallos distintos

Confundirlos es descubrir en la urgencia que solo tenías la mitad.

| Fallo                                                                      | Qué te salva    | Qué NO te salva                                      |
| -------------------------------------------------------------------------- | --------------- | ---------------------------------------------------- |
| Borraste una tabla, una migración salió mal, datos corruptos               | **El dump**     | El snapshot: restaura datos viejos de todo           |
| Rompiste la máquina: upgrade de SO fallido, disco lleno, Docker inservible | **El snapshot** | El dump: tiene los datos, pero no hay dónde ponerlos |

Sin rodeos: **lo que la herramienta de deploy no cubre y queda a tu cargo son las
actualizaciones de SO y el espacio en disco.** Esas son exactamente las dos formas de
romper la máquina, y el dump a R2 no cubre ninguna.

### El dump de datos

Diario, automático, a un bucket de R2 aparte del de la aplicación. Script:
[`scripts/backup-db.sh`](../../scripts/backup-db.sh). Retención de 30 días.

### El snapshot de la máquina

Es una imagen del disco entero: SO, Docker, configuración, claves del host.
Restaurarlo devuelve el servidor a como estaba, no los datos a como estaban.

**Cuándo se toma** — no «cada semana», sino **antes de lo que puede romperlo**:

- Antes de cada actualización de SO o de kernel.
- Antes de tocar Docker, el firewall o el particionado.
- Y uno periódico de fondo, por si el daño llega sin que tú lo provoques.

Escribe aquí los tres comandos de **tu** proveedor, tal cual se ejecutan. No es
documentación de adorno: el día que hagan falta, nadie va a estar en condiciones de
buscarlos en un panel web.

```bash
# Crear (nombra con la fecha: en la urgencia se elige por nombre, no por id)
[COMANDO_SNAPSHOT_CREAR]   # → "[NOMBRE_DEL_PROYECTO]-$(date +%F)" sobre [SERVIDOR]

# Ver los que hay
[COMANDO_SNAPSHOT_LISTAR]

# Restaurar SOBRE el servidor existente — destructivo, pide confirmación
[COMANDO_SNAPSHOT_RESTAURAR]   # → [SERVIDOR] desde [ID_SNAPSHOT]
```

**Retención: los últimos [N], y se borran los viejos a mano.** Los snapshots se cobran
por GB almacenado, así que uno olvidado es un cargo que crece en silencio.

> **La restauración se prueba, no se supone.** Una vez al mes, y de los dos: levanta el
> dump en una base local y reconstruye un servidor de usar y tirar desde el último
> snapshot. **Un respaldo que nunca se restauró no es un respaldo, es una suposición**
> — y se descubre el día que importa.

## Health checks y monitoreo

- Endpoint de salud: `[RUTA_HEALTHCHECK]`.
- Monitoreo de errores: [HERRAMIENTA].
- Alertas: [Dónde y ante qué se notifica].

## Si el producto es una app móvil

**Todo lo de arriba supone que un despliegue se revierte con un comando. En móvil no.**
Una versión instalada en el teléfono de alguien no se recupera: puedes dejar de
distribuirla, no quitarla. Y una parte de tus usuarios se queda en versiones viejas de
forma permanente.

Eso no cambia una sección: cambia la premisa. Sustituye las de arriba por estas.

| Concepto        | Servidor         | Móvil                                                                                                                            |
| --------------- | ---------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| Ambientes       | dev / producción | Desarrollo · **TestFlight** y pista interna de Play · producción                                                                 |
| Procedimiento   | un comando       | `eas build` → subir → **revisión de la store** (horas o días) → publicación                                                      |
| Rollback        | un comando       | **No existe para el binario.** EAS Update revierte el JavaScript; lo demás es publicar una versión nueva y esperar otra revisión |
| Health check    | endpoint         | Tasa de fallos por versión y adopción de versiones (monitor de errores y consolas de las tiendas)                                |
| Lo irreversible | —                | **Habrá usuarios en versiones viejas para siempre.** Por eso la API solo agrega campos, nunca borra ni renombra                  |

La fila del rollback es la que hay que leer dos veces: **es la razón de que la regla de la
API no se negocie.** No es rigidez, es que no hay vuelta atrás.

### Antes de la primera subida

Tres requisitos que no son técnicos, se descubren tarde y **bloquean la publicación**:

- **Login**: si ofreces un login social de terceros para la cuenta principal, App Store
  exige una alternativa equivalente que limite los datos a nombre y correo, permita
  ocultar el correo y no rastree para publicidad (guía 4.8). Sign in with Apple la cumple.
- **Política de privacidad** accesible desde la ficha de la store y desde la app.
- **Borrado de cuenta desde dentro de la app**, no solo por correo o desde la web.
