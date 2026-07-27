#!/usr/bin/env bash
# Restore Jarvis adaptive text state from the private backup repo into the Docker volume.
# Does **not** restore secrets or policy. Policy remains agent-tools dist + apply.
#
#   ./hermes/scripts/jarvis-restore-state.sh
#   ./hermes/scripts/jarvis-restore-state.sh --dry-run
#
set -euo pipefail

DRY_RUN=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) echo "Usage: $0 [--dry-run]"; exit 0 ;;
    *) echo "unknown: $1" >&2; exit 2 ;;
  esac
done

VOLUME_NAME="${JARVIS_VOLUME_NAME:-jarvis-hermes-data}"
WORKDIR="${JARVIS_BACKUP_WORKDIR:-${HOME}/.jarvis/backup-repo}"

die() { echo "jarvis-restore-state: error: $*" >&2; exit 1; }
info() { echo "jarvis-restore-state: $*" >&2; }

[[ -d "${WORKDIR}/state" ]] || die "missing ${WORKDIR}/state — clone/pull backup repo first (jarvis-backup-state.sh --init)"

if [[ "$DRY_RUN" -eq 1 ]]; then
  info "dry-run: would copy ${WORKDIR}/state → volume ${VOLUME_NAME}:/data/profiles/jarvis/state"
  find "${WORKDIR}/state" -type f | head -50
  exit 0
fi

# Safety: refuse if source looks like it contains secrets
if find "${WORKDIR}" \( -name '.env' -o -name 'auth.json' \) | grep -q .; then
  die "refusing: secret-like files in worktree"
fi

docker run --rm \
  -v "${VOLUME_NAME}:/data" \
  -v "${WORKDIR}/state:/in/state:ro" \
  alpine:3.20 \
  sh -c '
    set -e
    mkdir -p /data/profiles/jarvis/state
    cp -a /in/state/. /data/profiles/jarvis/state/
    # ownership for hermes user if present
    if id hermes >/dev/null 2>&1; then chown -R hermes:hermes /data/profiles/jarvis/state; fi
  '

info "restored adaptive state into volume ${VOLUME_NAME}"
info "restart jarvis if running: docker restart jarvis-hermes"
