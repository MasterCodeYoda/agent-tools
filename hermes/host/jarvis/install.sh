#!/usr/bin/env bash
# Install jarvis-host kit to /opt/jarvis-host (or JARVIS_HOST_PREFIX).
#
#   sudo ./install.sh
#   sudo ./install.sh --prefix /opt/jarvis-host
#   curl -fsSL …/jarvis-host/install.sh | sudo bash
#
set -euo pipefail

PREFIX="${JARVIS_HOST_PREFIX:-/opt/jarvis-host}"
STATE_DIR="${JARVIS_HOST_STATE_DIR:-/var/lib/jarvis-host}"
BOOTSTRAP_URL="${JARVIS_HOST_TARBALL_URL:-https://github.com/MasterCodeYoda/agent-tools/releases/download/jarvis-host/jarvis-host.tar.gz}"

die() { echo "jarvis-host-install: error: $*" >&2; exit 1; }
info() { echo "jarvis-host-install: $*" >&2; }

# BASH_SOURCE is empty/unusable when run as `curl | bash` — do not require it.
SELF_DIR=""
if [[ -n "${BASH_SOURCE[0]:-}" && "${BASH_SOURCE[0]}" != "bash" && "${BASH_SOURCE[0]}" != "-" ]]; then
  SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd 2>/dev/null)" || SELF_DIR=""
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --prefix) PREFIX="${2:-}"; shift 2 ;;
    --from-url) BOOTSTRAP_URL="${2:-}"; shift 2 ;;
    -h|--help)
      echo "usage: sudo ./install.sh [--prefix DIR]"
      echo "   or: curl -fsSL …/install.sh | sudo bash"
      exit 0
      ;;
    *) die "unknown option: $1" ;;
  esac
done

[[ "$(id -u)" -eq 0 ]] || die "run as root (sudo ./install.sh)"

SRC=""
if [[ -n "$SELF_DIR" && -x "${SELF_DIR}/bin/jarvis-host" ]]; then
  SRC="$SELF_DIR"
fi

STAGE=""
if [[ -z "$SRC" ]]; then
  info "bootstrapping from ${BOOTSTRAP_URL}"
  STAGE="$(mktemp -d "${TMPDIR:-/tmp}/jarvis-host-install.XXXXXX")"
  # shellcheck disable=SC2064
  trap 'rm -rf "$STAGE"' EXIT
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$BOOTSTRAP_URL" -o "${STAGE}/jarvis-host.tar.gz"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "${STAGE}/jarvis-host.tar.gz" "$BOOTSTRAP_URL"
  else
    die "need curl or wget to download kit"
  fi
  tar -xzf "${STAGE}/jarvis-host.tar.gz" -C "$STAGE"
  if [[ -x "${STAGE}/jarvis-host/bin/jarvis-host" ]]; then
    SRC="${STAGE}/jarvis-host"
  elif [[ -x "${STAGE}/bin/jarvis-host" ]]; then
    SRC="$STAGE"
  else
    die "unpacked tarball missing bin/jarvis-host"
  fi
fi

[[ -x "${SRC}/bin/jarvis-host" ]] || die "no kit source at ${SRC}"

info "installing kit → ${PREFIX}"
mkdir -p "$PREFIX" "$STATE_DIR"

# Prefer rsync when present; otherwise atomic-ish cp (skynet has no rsync).
if command -v rsync >/dev/null 2>&1; then
  rsync -a --delete --exclude '.git' "${SRC}/" "${PREFIX}/"
else
  TMP_NEW="${PREFIX}.new.$$"
  rm -rf "$TMP_NEW"
  mkdir -p "$TMP_NEW"
  cp -a "${SRC}/." "$TMP_NEW/"
  rm -rf "${PREFIX}.bak"
  if [[ -d "$PREFIX" ]]; then
    mv "$PREFIX" "${PREFIX}.bak"
  fi
  mv "$TMP_NEW" "$PREFIX"
  rm -rf "${PREFIX}.bak"
fi

chmod 755 "${PREFIX}/bin/jarvis-host" "${PREFIX}/install.sh" "${PREFIX}/migrate-from-legacy.sh" 2>/dev/null || true
find "${PREFIX}/lib" -name '*.sh' -exec chmod 644 {} \; 2>/dev/null || true

# Wrapper on PATH (not a raw symlink): resolves kit root correctly.
mkdir -p /usr/local/bin
cat >/usr/local/bin/jarvis-host <<EOF
#!/usr/bin/env bash
exec "${PREFIX}/bin/jarvis-host" "\$@"
EOF
chmod 755 /usr/local/bin/jarvis-host

if [[ ! -f "${STATE_DIR}/config.env" ]]; then
  cat >"${STATE_DIR}/config.env" <<EOF
# Non-secret host prefs for jarvis-host (not the container .env)
JARVIS_HERMES_IMAGE=ghcr.io/mastercodeyoda/jarvis-hermes:main
JARVIS_VOLUME_NAME=jarvis-hermes-data
EOF
  chmod 644 "${STATE_DIR}/config.env"
fi

info "installed jarvis-host $(cat "${PREFIX}/VERSION" 2>/dev/null || echo unknown)"
info "verify: jarvis-host version && jarvis-host status"
info "timers: sudo env JARVIS_BACKUP_RUN_AS=\${SUDO_USER:-moverlund} jarvis-host schedule install"
