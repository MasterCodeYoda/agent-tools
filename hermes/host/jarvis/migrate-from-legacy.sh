#!/usr/bin/env bash
# ONE-SHOT throwaway: move an existing durable Jarvis host onto jarvis-host kit paths
# without re-provisioning secrets or adaptive state.
#
#   sudo ./migrate-from-legacy.sh
#   sudo /opt/jarvis-host/migrate-from-legacy.sh   # after kit install
#
# Delete this script from the product path of record after all hosts are migrated.
set -euo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREFIX="${JARVIS_HOST_PREFIX:-/opt/jarvis-host}"
CONTAINER="${JARVIS_CONTAINER_NAME:-jarvis-hermes}"
VOLUME="${JARVIS_VOLUME_NAME:-jarvis-hermes-data}"

die() { echo "migrate-from-legacy: error: $*" >&2; exit 1; }
info() { echo "migrate-from-legacy: $*" >&2; }

[[ "$(id -u)" -eq 0 ]] || die "run as root (sudo)"

command -v docker >/dev/null 2>&1 || die "docker required"

docker ps -a --format '{{.Names}}' | grep -qx "$CONTAINER" \
  || die "container ${CONTAINER} not found — refuse to invent a second brain"

docker volume inspect "$VOLUME" >/dev/null 2>&1 \
  || die "volume ${VOLUME} not found — refuse to invent a second brain"

info "detected container=${CONTAINER} volume=${VOLUME}"

# Ensure kit installed
if [[ ! -x "${PREFIX}/bin/jarvis-host" ]]; then
  if [[ -x "${SELF_DIR}/bin/jarvis-host" ]]; then
    info "installing kit from ${SELF_DIR}"
    "${SELF_DIR}/install.sh" --prefix "$PREFIX"
  else
    die "kit not at ${PREFIX}; run install.sh first"
  fi
fi

# Capture baseline image
BASELINE="$(docker inspect --format '{{.Image}}' "$CONTAINER" 2>/dev/null || echo unknown)"
info "baseline image id=${BASELINE}"

# Install/replace system timers to kit paths (does not touch volume data or secrets)
export JARVIS_VOLUME_NAME="$VOLUME"
export JARVIS_BACKUP_RUN_AS="${JARVIS_BACKUP_RUN_AS:-${SUDO_USER:-moverlund}}"
"${PREFIX}/bin/jarvis-host" schedule install

# Write baseline status (not available) so Jarvis has a file to read
if command -v "${PREFIX}/bin/jarvis-host" >/dev/null; then
  sudo -u "${JARVIS_BACKUP_RUN_AS}" \
    env JARVIS_VOLUME_NAME="$VOLUME" \
    "${PREFIX}/bin/jarvis-host" update --check 2>/dev/null \
    || info "update --check deferred (network/login); timers will retry"
fi

info "migrate complete — secrets/state untouched"
info "verify: jarvis-host status && systemctl list-timers | grep jarvis"
info "THIS SCRIPT IS THROW AWAY after durable hosts are on the kit"
