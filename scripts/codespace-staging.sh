#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_DIR="${HOME}/.local/share/armsphere-staging"
ENV_FILE="${STAGING_ENV_FILE:-${STATE_DIR}/api.env}"
PGDATA="${STATE_DIR}/postgres"
PGPORT="${PGPORT:-5432}"
API_PORT="${PORT:-4000}"

mkdir -p "${STATE_DIR}"
chmod 700 "${STATE_DIR}"

if [[ ! -f "${ENV_FILE}" ]]; then
  printf 'Missing staging secret file: %s\n' "${ENV_FILE}" >&2
  printf 'Set STAGING_ENV_FILE to an ignored env file containing the required values.\n' >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "${ENV_FILE}"
set +a

: "${DB_PASSWORD:?DB_PASSWORD must be set in the staging secret file}"
: "${JWT_ACCESS_SECRET:?JWT_ACCESS_SECRET must be set in the staging secret file}"
: "${JWT_REFRESH_SECRET:?JWT_REFRESH_SECRET must be set in the staging secret file}"
: "${CRON_SECRET:?CRON_SECRET must be set in the staging secret file}"
: "${STRIPE_SECRET_KEY:?STRIPE_SECRET_KEY must be set in the staging secret file}"
: "${STRIPE_WEBHOOK_SECRET:?STRIPE_WEBHOOK_SECRET must be set in the staging secret file}"
CORS_ORIGIN_VALUE="${CORS_ORIGIN:-http://localhost:3000}"

if ! command -v psql >/dev/null 2>&1 || ! command -v initdb >/dev/null 2>&1 || ! command -v pg_ctl >/dev/null 2>&1; then
  sudo apt-get update
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y postgresql postgresql-client
fi

if command -v pg_config >/dev/null 2>&1; then
  export PATH="$(pg_config --bindir):${PATH}"
fi

command -v psql >/dev/null
command -v initdb >/dev/null
command -v pg_ctl >/dev/null
command -v pg_isready >/dev/null

if [[ ! -d "${PGDATA}" ]]; then
  initdb -D "${PGDATA}" -U armsphere_staging --pwfile=<(printf '%s' "${DB_PASSWORD}") --auth=scram-sha-256 >/dev/null
fi

export PGPASSWORD="${DB_PASSWORD}"

if ! pg_isready -h 127.0.0.1 -p "${PGPORT}" >/dev/null 2>&1; then
  pg_ctl -D "${PGDATA}" -o "-p ${PGPORT}" -l "${STATE_DIR}/postgres.log" start >/dev/null
fi

pg_isready -h 127.0.0.1 -p "${PGPORT}" >/dev/null

if ! psql "postgresql://armsphere_staging@127.0.0.1:${PGPORT}/postgres" -tAc "SELECT 1 FROM pg_database WHERE datname = 'armsphere_staging'" | grep -q 1; then
  createdb "postgresql://armsphere_staging@127.0.0.1:${PGPORT}/postgres" armsphere_staging
fi

export NODE_ENV="${NODE_ENV:-development}"
export IS_SERVERLESS="${IS_SERVERLESS:-false}"
export PORT="${API_PORT}"
export DATABASE_URL="${DATABASE_URL:-postgresql://armsphere_staging:${DB_PASSWORD}@127.0.0.1:${PGPORT}/armsphere_staging}"
export CORS_ORIGIN="${CORS_ORIGIN_VALUE}"

cd "${ROOT_DIR}"
npm run build
npm run db:migrate --workspace=@armsphere/api
exec npm run start --workspace=@armsphere/api