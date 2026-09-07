#!/usr/bin/env bash
# ==============================================================================
# backup-db.sh — Dump de PostgreSQL → almacenamiento S3-compatible
# ==============================================================================
# EJEMPLO FUNCIONAL, no un mandato de stack. Implementa el default de backups que
# declares en docs/architecture/stack.md: dump comprimido diario a un bucket con
# retención configurable. Habla S3, así que sirve tal cual con cualquier
# almacenamiento compatible; si tu base de datos no es PostgreSQL, este archivo es
# el punto de partida — cambia `pg_dump`/`pg_restore` por su equivalente y el resto
# se queda igual. Si el producto no tiene base de datos, bórralo.
#
# Requisitos en el host: pg_dump (postgresql-client) y AWS CLI v2.
#
# Variables de entorno (los valores reales viven en tu gestor de credenciales y
# llegan vía .env; ver docs/conventions/secrets.md):
#   DATABASE_URL             postgres://usuario:clave@host:5432/basedatos (obligatoria)
#   BACKUP_S3_ENDPOINT       endpoint del servicio S3-compatible          (obligatoria)
#   BACKUP_S3_ACCESS_KEY_ID  credencial del token de acceso               (obligatoria)
#   BACKUP_S3_SECRET_KEY     credencial del token de acceso               (obligatoria)
#   BACKUP_S3_BUCKET         bucket destino, p. ej. miapp-backups         (obligatoria;
#                            distinto del bucket de archivos de la app)
#   BACKUP_PREFIX            prefijo dentro del bucket (default: db)
#   BACKUP_RETENTION_DAYS    días que se conservan los dumps (default: 30)
#
# Uso:
#   ./scripts/backup-db.sh                       # manual
#   cron (VPS): 0 3 * * * cd /ruta/app && ./scripts/backup-db.sh >> /var/log/backup-db.log 2>&1
#   Con orquestador: ejecútalo con cron en el host, o como comando programado del contenedor.
#
# Restore — PRUÉBALO CADA MES. Un respaldo que nunca se restauró es una suposición:
#   export AWS_ACCESS_KEY_ID=$BACKUP_S3_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY=$BACKUP_S3_SECRET_KEY
#   aws s3 cp "s3://$BACKUP_S3_BUCKET/db/<archivo>.dump" . \
#     --endpoint-url "$BACKUP_S3_ENDPOINT"
#   pg_restore --clean --no-owner --dbname "$DATABASE_URL" <archivo>.dump
# ==============================================================================
set -euo pipefail

: "${DATABASE_URL:?Falta DATABASE_URL}"
: "${BACKUP_S3_ENDPOINT:?Falta BACKUP_S3_ENDPOINT}"
: "${BACKUP_S3_ACCESS_KEY_ID:?Falta BACKUP_S3_ACCESS_KEY_ID}"
: "${BACKUP_S3_SECRET_KEY:?Falta BACKUP_S3_SECRET_KEY}"
: "${BACKUP_S3_BUCKET:?Falta BACKUP_S3_BUCKET}"

BACKUP_PREFIX="${BACKUP_PREFIX:-db}"
BACKUP_RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-30}"
export AWS_ACCESS_KEY_ID="$BACKUP_S3_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="$BACKUP_S3_SECRET_KEY"

# Nombre del archivo: <basedatos>_<timestamp UTC>.dump
db_name="$(basename "${DATABASE_URL%%\?*}")"
timestamp="$(date -u +%Y-%m-%dT%H-%M-%SZ)"
dump_file="${db_name}_${timestamp}.dump"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

echo "→ pg_dump de ${db_name}…"
pg_dump --format=custom --no-owner --file "${tmp_dir}/${dump_file}" "$DATABASE_URL"

echo "→ subiendo a s3://${BACKUP_S3_BUCKET}/${BACKUP_PREFIX}/${dump_file}…"
aws s3 cp "${tmp_dir}/${dump_file}" \
  "s3://${BACKUP_S3_BUCKET}/${BACKUP_PREFIX}/${dump_file}" \
  --endpoint-url "$BACKUP_S3_ENDPOINT" --only-show-errors

echo "→ aplicando retención de ${BACKUP_RETENTION_DAYS} días…"
# date -d es GNU (Linux); date -v es BSD (macOS) — se intenta la primera y se cae a la segunda
cutoff_date="$(date -u -d "-${BACKUP_RETENTION_DAYS} days" +%Y-%m-%d 2>/dev/null \
  || date -u -v "-${BACKUP_RETENTION_DAYS}d" +%Y-%m-%d)"
aws s3 ls "s3://${BACKUP_S3_BUCKET}/${BACKUP_PREFIX}/" --endpoint-url "$BACKUP_S3_ENDPOINT" \
  | while read -r obj_date _obj_time _obj_size obj_name; do
      [ -n "$obj_name" ] || continue
      if [[ "$obj_date" < "$cutoff_date" ]]; then
        echo "   borrando ${obj_name} (${obj_date})"
        aws s3 rm "s3://${BACKUP_S3_BUCKET}/${BACKUP_PREFIX}/${obj_name}" \
          --endpoint-url "$BACKUP_S3_ENDPOINT" --only-show-errors
      fi
    done

echo "✓ backup ${dump_file} completado"
