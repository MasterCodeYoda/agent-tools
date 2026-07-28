#!/usr/bin/env bash
# Pack jarvis-host ops kit for rolling GitHub Release tag `jarvis-host`.
#
#   tools/pack-jarvis-host.sh
#   tools/pack-jarvis-host.sh --out-dir dist/jarvis-host
#
# Outputs: jarvis-host.tar.gz, jarvis-host.sha256, manifest.json, install.sh (copy)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SRC="${REPO_ROOT}/hermes/host/jarvis"
OUT_DIR="${REPO_ROOT}/dist/jarvis-host"
DEFAULT_IMAGE="ghcr.io/mastercodeyoda/jarvis-hermes:main"

die() { echo "pack-jarvis-host: error: $*" >&2; exit 1; }
info() { echo "pack-jarvis-host: $*" >&2; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --out-dir) OUT_DIR="${2:-}"; shift 2 ;;
    -h|--help) sed -n '2,12p' "$0" | sed 's/^# \?//'; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done

[[ -d "$SRC" ]] || die "missing kit source: $SRC"
[[ -x "${SRC}/bin/jarvis-host" ]] || chmod +x "${SRC}/bin/jarvis-host" "${SRC}/install.sh" "${SRC}/migrate-from-legacy.sh" 2>/dev/null || true

git_sha="unknown"
if command -v git >/dev/null 2>&1; then
  git_sha="$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo unknown)"
fi
kit_version="$(tr -d '[:space:]' <"${SRC}/VERSION" 2>/dev/null || echo 0.0.0)"
created_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

STAGE="$(mktemp -d "${TMPDIR:-/tmp}/jarvis-host-pack.XXXXXX")"
cleanup() { rm -rf "$STAGE"; }
trap cleanup EXIT

PKG="${STAGE}/jarvis-host"
mkdir -p "$PKG"
cp -a "${SRC}/." "$PKG/"
# Ensure executables
chmod 755 "${PKG}/bin/jarvis-host" "${PKG}/install.sh" "${PKG}/migrate-from-legacy.sh"

cat >"${PKG}/manifest.json" <<EOF
{
  "schema": "jarvis-host.manifest/v1",
  "product": "jarvis-host",
  "kit_version": "${kit_version}",
  "git_sha": "${git_sha}",
  "created_at": "${created_at}",
  "default_image": "${DEFAULT_IMAGE}",
  "install_prefix": "/opt/jarvis-host"
}
EOF
cp "${PKG}/manifest.json" "${PKG}/manifest.json" 2>/dev/null || true

mkdir -p "$OUT_DIR"
TAR="${OUT_DIR}/jarvis-host.tar.gz"
# Pack with top-level jarvis-host/ directory
tar -czf "$TAR" -C "$STAGE" jarvis-host

if command -v shasum >/dev/null 2>&1; then
  (cd "$OUT_DIR" && shasum -a 256 jarvis-host.tar.gz > jarvis-host.sha256)
elif command -v sha256sum >/dev/null 2>&1; then
  (cd "$OUT_DIR" && sha256sum jarvis-host.tar.gz > jarvis-host.sha256)
else
  info "warning: no shasum/sha256sum — skip checksum"
fi

cp "${PKG}/manifest.json" "${OUT_DIR}/manifest.json"
cp "${PKG}/install.sh" "${OUT_DIR}/install.sh"

info "wrote ${TAR}"
info "manifest: kit_version=${kit_version} git_sha=${git_sha}"
cat "${OUT_DIR}/manifest.json"
