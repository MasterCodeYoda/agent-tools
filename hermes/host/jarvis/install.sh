#!/usr/bin/env bash
# Install jarvis-host kit to /opt/jarvis-host (or JARVIS_HOST_PREFIX).
# Usage (from unpacked kit or monorepo source tree):
#   sudo ./install.sh
#   sudo ./install.sh --prefix /opt/jarvis-host
# Online (after release):
#   curl -fsSL https://github.com/MasterCodeYoda/agent-tools/releases/download/jarvis-host/install.sh | sudo bash
set -euo pipefail

PREFIX="${JARVIS_HOST_PREFIX:-/opt/jarvis-host}"
STATE_DIR="${JARVIS_HOST_STATE_DIR:-/var/lib/jarvis-host}"
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# If this install.sh is the online bootstrap, it may download the tarball first.
BOOTSTRAP_URL="${JARVIS_HOST_TARBALL_URL:-https://github.com/MasterCodeYoda/agent-tools/releases/download/jarvis-host/jarvis-host.tar.gz}"

die() { echo "jarvis-host-install: error: $*" >&2; exit 1; }
info() { echo "jarvis-host-install: $*" >&2; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --prefix) PREFIX="${2:-}"; shift 2 ;;
    --from-url) BOOTSTRAP_URL="${2:-}"; shift 2 ;;
    -h|--help)
      echo "usage: sudo ./install.sh [--prefix DIR]"
      exit 0
      ;;
    *) die "unknown option: $1" ;;
  esac
done

[[ "$(id -u)" -eq 0 ]] || die "run as root (sudo ./install.sh)"

SRC="$SELF_DIR"
# If invoked as standalone bootstrap without kit files, download tarball
if [[ ! -x "${SRC}/bin/jarvis-host" ]]; then
  info "bin/jarvis-host missing next to install.sh — downloading ${BOOTSTRAP_URL}"
  STAGE="$(mktemp -d)"
  trap 'rm -rf "$STAGE"' EXIT
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$BOOTSTRAP_URL" -o "${STAGE}/jarvis-host.tar.gz"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "${STAGE}/jarvis-host.tar.gz" "$BOOTSTRAP_URL"
  else
    die "need curl or wget to download kit"
  fi
  tar -xzf "${STAGE}/jarvis-host.tar.gz" -C "$STAGE"
  # tarball may contain top-level jarvis-host/ or files at root
  if [[ -x "${STAGE}/jarvis-host/bin/jarvis-host" ]]; then
    SRC="${STAGE}/jarvis-host"
  elif [[ -x "${STAGE}/bin/jarvis-host" ]]; then
    SRC="$STAGE"
  else
    die "unpacked tarball missing bin/jarvis-host"
  fi
fi

info "installing kit → ${PREFIX}"
mkdir -p "$PREFIX" "$STATE_DIR"
# Replace tree atomically-ish
rsync -a --delete \
  --exclude '.git' \
  "${SRC}/" "${PREFIX}/" \
  || {
    # rsync optional fallback
    rm -rf "${PREFIX}.new"
    mkdir -p "${PREFIX}.new"
    cp -a "${SRC}/." "${PREFIX}.new/"
    rm -rf "${PREFIX}.bak"
    [[ -d "$PREFIX" ]] && mv "$PREFIX" "${PREFIX}.bak" || true
    mv "${PREFIX}.new" "$PREFIX"
  }

chmod 755 "${PREFIX}/bin/jarvis-host" "${PREFIX}/install.sh" 2>/dev/null || true
find "${PREFIX}/lib" -name '*.sh' -exec chmod 644 {} \; 2>/dev/null || true

# Symlink convenience
ln -sfn "${PREFIX}/bin/jarvis-host" /usr/local/bin/jarvis-host 2>/dev/null || true

if [[ ! -f "${STATE_DIR}/config.env" ]]; then
  cat >"${STATE_DIR}/config.env" <<EOF
# Non-secret host prefs for jarvis-host (not the container .env)
JARVIS_HERMES_IMAGE=ghcr.io/mastercodeyoda/jarvis-hermes:main
JARVIS_VOLUME_NAME=jarvis-hermes-data
EOF
  chmod 644 "${STATE_DIR}/config.env"
fi

info "installed jarvis-host $(cat "${PREFIX}/VERSION" 2>/dev/null || echo unknown)"
info "next: jarvis-host setup   # or migrate-from-legacy.sh on existing hosts"
info "      sudo jarvis-host schedule install  # if setup was non-root"
