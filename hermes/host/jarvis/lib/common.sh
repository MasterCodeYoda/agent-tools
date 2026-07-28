# shellcheck shell=bash
# Shared helpers for jarvis-host kit (sourced by bin/jarvis-host and lib/*).
# KIT_ROOT is set by the caller (absolute path to kit install or source tree).

: "${KIT_ROOT:?KIT_ROOT must be set before sourcing common.sh}"

JARVIS_HOST_PREFIX="${JARVIS_HOST_PREFIX:-/opt/jarvis-host}"
JARVIS_HOST_STATE_DIR="${JARVIS_HOST_STATE_DIR:-/var/lib/jarvis-host}"
JARVIS_VOLUME_NAME="${JARVIS_VOLUME_NAME:-jarvis-hermes-data}"
JARVIS_CONTAINER_NAME="${JARVIS_CONTAINER_NAME:-jarvis-hermes}"
JARVIS_HERMES_IMAGE="${JARVIS_HERMES_IMAGE:-ghcr.io/mastercodeyoda/jarvis-hermes:main}"
JARVIS_BACKUP_WORKDIR="${JARVIS_BACKUP_WORKDIR:-${HOME}/.jarvis/backup-repo}"

die() { echo "jarvis-host: error: $*" >&2; exit 1; }
info() { echo "jarvis-host: $*" >&2; }

kit_version() {
  if [[ -f "${KIT_ROOT}/VERSION" ]]; then
    tr -d '[:space:]' <"${KIT_ROOT}/VERSION"
  else
    echo "unknown"
  fi
}

have_cmd() { command -v "$1" >/dev/null 2>&1; }

# Prefer Compose V2 plugin; fall back to standalone docker-compose (skynet-class hosts).
compose() {
  local f="${KIT_ROOT}/compose/jarvis.yaml"
  [[ -f "$f" ]] || die "missing compose file: $f"
  export JARVIS_HERMES_IMAGE JARVIS_VOLUME_SPEC="${JARVIS_VOLUME_SPEC:-$JARVIS_VOLUME_NAME}"
  if docker compose version >/dev/null 2>&1; then
    docker compose -f "$f" "$@"
  elif have_cmd docker-compose; then
    docker-compose -f "$f" "$@"
  else
    die "need Docker Compose: install 'docker compose' plugin or docker-compose binary"
  fi
}

require_docker() {
  have_cmd docker || die "docker not on PATH"
  docker info >/dev/null 2>&1 || die "docker not usable (daemon/permissions)"
}

# Read a file from the Jarvis data volume (named volume or absolute bind path).
volume_cat() {
  local relpath="$1"
  require_docker
  docker run --rm \
    -v "${JARVIS_VOLUME_NAME}:/data:ro" \
    alpine:3.20 \
    cat "/data/${relpath}" 2>/dev/null
}

# Write stdin to a path on the Jarvis data volume (creates parent dirs).
volume_write() {
  local relpath="$1"
  local parent
  parent="$(dirname "$relpath")"
  require_docker
  docker run --rm -i \
    -v "${JARVIS_VOLUME_NAME}:/data" \
    alpine:3.20 \
    sh -c "mkdir -p /data/${parent} && cat > /data/${relpath}"
}

ops_dir_rel() { echo "profiles/jarvis/state/ops"; }
