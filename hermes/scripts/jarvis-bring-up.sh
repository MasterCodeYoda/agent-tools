#!/usr/bin/env bash
# Idempotent Jarvis bring-up: image + compose + named Docker volume.
# Default data home is Docker volume `jarvis-hermes-data` (inside the container at /opt/data).
# You do not need a host project directory — Jarvis is not Kevin.
#
# Usage:
#   ./hermes/scripts/jarvis-bring-up.sh
#   ./hermes/scripts/jarvis-bring-up.sh --no-build
#   ./hermes/scripts/jarvis-bring-up.sh --status
#   ./hermes/scripts/jarvis-bring-up.sh --down
#   ./hermes/scripts/jarvis-bring-up.sh --purge   # down + delete named volume (disposable test)
#
# Env:
#   JARVIS_HERMES_IMAGE   default jarvis-hermes:local
#   JARVIS_VOLUME_SPEC    default jarvis-hermes-data (named vol); set absolute path to bind-mount
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HERMES_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${HERMES_DIR}/.." && pwd)"
COMPOSE_FILE="${HERMES_DIR}/docker/compose.jarvis.yaml"
DOCKERFILE="${HERMES_DIR}/docker/Dockerfile.jarvis"

IMAGE="${JARVIS_HERMES_IMAGE:-jarvis-hermes:local}"
VOLUME_SPEC="${JARVIS_VOLUME_SPEC:-jarvis-hermes-data}"
NO_BUILD=0
DO_DOWN=0
DO_STATUS=0
DO_PURGE=0

die() { echo "jarvis-bring-up: error: $*" >&2; exit 1; }
info() { echo "jarvis-bring-up: $*" >&2; }

usage() { sed -n '2,18p' "$0" | sed 's/^# \?//'; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-build) NO_BUILD=1; shift ;;
    --down) DO_DOWN=1; shift ;;
    --purge) DO_PURGE=1; shift ;;
    --status) DO_STATUS=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done

command -v docker >/dev/null 2>&1 || die "docker not on PATH"
[[ -f "$COMPOSE_FILE" ]] || die "missing compose: $COMPOSE_FILE"

export JARVIS_HERMES_IMAGE="$IMAGE"
export JARVIS_VOLUME_SPEC="$VOLUME_SPEC"

# Prefer Compose V2 plugin (`docker compose`); fall back to standalone `docker-compose`
# (common on hosts where the plugin is not installed, e.g. some Portainer/Docker CE boxes).
if docker compose version >/dev/null 2>&1; then
  compose() { docker compose -f "$COMPOSE_FILE" "$@"; }
elif command -v docker-compose >/dev/null 2>&1; then
  compose() { docker-compose -f "$COMPOSE_FILE" "$@"; }
else
  die "need Docker Compose: install the compose plugin (docker compose) or docker-compose binary"
fi

if [[ "$DO_STATUS" -eq 1 ]]; then
  info "image=$IMAGE"
  info "volume_spec=$VOLUME_SPEC  (container path always /opt/data)"
  compose ps 2>/dev/null || true
  if docker ps --format '{{.Names}}' | grep -qx jarvis-hermes; then
    docker exec jarvis-hermes hermes -p jarvis profile show jarvis 2>&1 | head -20 || true
    if docker exec jarvis-hermes test -f /opt/data/profiles/jarvis/.env 2>/dev/null; then
      info ".env: present inside container (values not shown)"
    else
      info ".env: missing inside container — run: ./hermes/scripts/jarvis-local-smoke.sh --secrets"
    fi
  fi
  exit 0
fi

if [[ "$DO_PURGE" -eq 1 ]]; then
  info "purge: compose down -v (removes named volume data)"
  compose down -v 2>/dev/null || true
  docker rm -f jarvis-hermes 2>/dev/null || true
  # Named volume may remain if not attached
  docker volume rm jarvis-hermes-data 2>/dev/null || true
  info "purge complete — disposable local data gone"
  exit 0
fi

if [[ "$DO_DOWN" -eq 1 ]]; then
  info "stopping container (volume preserved)"
  compose down
  exit 0
fi

if [[ "$NO_BUILD" -eq 0 ]]; then
  if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
    info "building $IMAGE"
    docker build -f "$DOCKERFILE" -t "$IMAGE" "$REPO_ROOT"
  else
    info "image $IMAGE present"
  fi
else
  docker image inspect "$IMAGE" >/dev/null 2>&1 || die "image $IMAGE missing"
fi

info "compose up -d (data at volume_spec=$VOLUME_SPEC → /opt/data)"
compose up -d

# Wait for profile + gateway (entrypoint may retry once)
for i in 1 2 3 4 5 6 7 8 9 10; do
  if docker exec jarvis-hermes hermes -p jarvis profile show jarvis >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

if docker ps --format '{{.Names}}' | grep -qx jarvis-hermes; then
  info "container jarvis-hermes is up"
else
  die "container not running — docker logs jarvis-hermes"
fi

info "done. Validate: ./hermes/scripts/jarvis-local-smoke.sh"
info "Secrets (interactive in container): ./hermes/scripts/jarvis-local-smoke.sh --secrets"
