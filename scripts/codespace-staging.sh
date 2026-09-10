#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ "$(id -u)" -eq 0 ]]; then
  STATE_DIR="${STATE_DIR:-/tmp/armsphere-staging}"
else
  STATE_DIR="${STATE_DIR:-${HOME}/.local/share/armsphere-staging}"
fi
ENV_FILE="${STAGING_ENV_FILE:-${STATE_DIR}/api.env}"
PGDATA="${STATE_DIR}/postgres"
PGPORT="${PGPORT:-5432}"
API_PORT="${PORT:-4000}"

mkdir -p "${STATE_DIR}"
if [[ "$(id -u)" -eq 0 ]]; then
  chown -R postgres:postgres "${STATE_DIR}"
fi
chmod 700 "${STATE_DIR}"

if [[ ! -f "${ENV_FILE}" ]]; then
  # When running as root the state dir moves to /tmp, but an env file may
  # already exist under the user's HOME (e.g. /root/.local/share/...).
  # Fall back to the HOME-based location before failing.
  _HOME_ENV="${HOME}/.local/share/armsphere-staging/api.env"
  if [[ "${ENV_FILE}" != "${_HOME_ENV}" && -f "${_HOME_ENV}" ]]; then
    ENV_FILE="${_HOME_ENV}"
  else
    printf 'Missing staging secret file: %s\n' "${ENV_FILE}" >&2
    printf 'Set STAGING_ENV_FILE to an ignored env file containing the required values.\n' >&2
    exit 1
  fi
  unset _HOME_ENV
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

# Prefer the native Codespace PostgreSQL binaries if they exist outside PATH
# (Ubuntu keeps them in /usr/lib/postgresql/<ver>/bin, so initdb/pg_ctl
# appear "missing" unless we add the bindir first).
if command -v pg_config >/dev/null 2>&1; then
  export PATH="$(pg_config --bindir):${PATH}"
else
  for _pgbind in /usr/lib/postgresql/*/bin; do
    if [[ -d "${_pgbind}" ]]; then
      export PATH="${_pgbind}:${PATH}"
      break
    fi
  done
  unset _pgbind
fi

# Only install PostgreSQL when there is genuinely no usable server tooling.
# pg_ctlcluster (Debian/Ubuntu wrapper) is the preferred launcher for the
# pre-provisioned Codespace cluster; initdb/pg_ctl live outside default PATH.
if ! command -v psql >/dev/null 2>&1 || ! command -v pg_ctlcluster >/dev/null 2>&1; then
  sudo apt-get update
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y postgresql postgresql-client
  if command -v pg_config >/dev/null 2>&1; then
    export PATH="$(pg_config --bindir):${PATH}"
  fi
fi

command -v psql >/dev/null
command -v pg_ctlcluster >/dev/null
command -v pg_isready >/dev/null

if ! pg_isready -h 127.0.0.1 -p "${PGPORT}" >/dev/null 2>&1; then
  # Use whichever cluster actually exists (do not hardcode the major version).
  _PG_VERSION=""
  _PG_CLUSTER=""
  if command -v pg_lsclusters >/dev/null 2>&1; then
    # Last "Ver Cluster" pair wins; an empty result means no cluster exists.
    while read -r _ver _cluster _rest; do
      case "${_ver}" in
        ""|"Ver"|"#") continue ;;
      esac
      if [[ "${_ver}" =~ ^[0-9]+$ && -n "${_cluster}" ]]; then
        _PG_VERSION="${_ver}"
        _PG_CLUSTER="${_cluster}"
      fi
    done < <(pg_lsclusters 2>/dev/null || true)
  fi
  if [[ -n "${_PG_VERSION}" && -n "${_PG_CLUSTER}" ]]; then
    pg_ctlcluster "${_PG_VERSION}" "${_PG_CLUSTER}" start
  else
    pg_ctlcluster 16 main start >/dev/null
  fi
  unset _PG_VERSION _PG_CLUSTER _ver _cluster _rest
fi

pg_isready -h 127.0.0.1 -p "${PGPORT}" >/dev/null

unset PGPASSWORD PGHOST PGUSER

# Escape single quotes for safe SQL literal interpolation.
_ESCAPED_DB_PASSWORD="${DB_PASSWORD//\'/\'\'}"

sudo -u postgres env -u PGPASSWORD -u PGHOST -u PGUSER psql -d postgres -v ON_ERROR_STOP=1 <<-SQL >/dev/null
ALTER USER postgres WITH PASSWORD '${_ESCAPED_DB_PASSWORD}';
SQL

if ! sudo -u postgres env -u PGPASSWORD -u PGHOST -u PGUSER psql -d postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname = 'armsphere_staging'" | grep -q 1; then
  sudo -u postgres env -u PGPASSWORD -u PGHOST -u PGUSER psql -d postgres -v ON_ERROR_STOP=1 -c "CREATE ROLE armsphere_staging WITH LOGIN PASSWORD '${_ESCAPED_DB_PASSWORD}';" >/dev/null
else
  # Keep the existing staging role's password in sync with the secret file.
  sudo -u postgres env -u PGPASSWORD -u PGHOST -u PGUSER psql -d postgres -v ON_ERROR_STOP=1 <<-SQL >/dev/null
ALTER ROLE armsphere_staging WITH LOGIN PASSWORD '${_ESCAPED_DB_PASSWORD}';
SQL
fi

if ! sudo -u postgres env -u PGPASSWORD -u PGHOST -u PGUSER psql -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname = 'armsphere_staging'" | grep -q 1; then
  sudo -u postgres env -u PGPASSWORD -u PGHOST -u PGUSER createdb -O armsphere_staging armsphere_staging >/dev/null
fi

export PGPASSWORD="${DB_PASSWORD}"

export NODE_ENV="${NODE_ENV:-development}"
export IS_SERVERLESS="${IS_SERVERLESS:-false}"
export PORT="${API_PORT}"
export DATABASE_URL="${DATABASE_URL:-postgresql://armsphere_staging:${DB_PASSWORD}@127.0.0.1:${PGPORT}/armsphere_staging}"
export CORS_ORIGIN="${CORS_ORIGIN_VALUE}"

cd "${ROOT_DIR}"
npm run build
npm run db:migrate --workspace=@armsphere/api
exec npm run start --workspace=@armsphere/api