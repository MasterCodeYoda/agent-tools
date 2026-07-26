#!/usr/bin/env bash
#
# Install the product Workstation Kevin CLI onto PATH.
#
# Copies:
#   PREFIX/bin/kevin
#   PREFIX/share/kevin/profile/          (hermes/profile bundle)
#   PREFIX/share/kevin/install-kevin-skills.sh
#
# Usage:
#   tools/install-kevin-cli.sh [--prefix DIR]
#
# Default PREFIX: $HOME/.local
#
# Env:
#   PREFIX              install prefix (default ~/.local)
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PREFIX="${PREFIX:-${HOME}/.local}"

die() { echo "install-kevin-cli: error: $*" >&2; exit 1; }
info() { echo "install-kevin-cli: $*" >&2; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --prefix)
      [[ $# -ge 2 ]] || die "--prefix needs a path"
      PREFIX="$2"
      shift 2
      ;;
    -h|--help)
      sed -n '2,18p' "$0" | sed 's/^# \?//'
      exit 0
      ;;
    *) die "unknown argument: $1" ;;
  esac
done

CLI_SRC="${REPO_ROOT}/tools/kevin/kevin"
PROFILE_SRC="${REPO_ROOT}/hermes/profile"
SKILLS_INSTALLER="${REPO_ROOT}/tools/install-kevin-skills.sh"

[[ -f "$CLI_SRC" ]] || die "missing CLI source: ${CLI_SRC}"
[[ -f "${PROFILE_SRC}/distribution.yaml" ]] || die "missing profile: ${PROFILE_SRC}"
[[ -x "$SKILLS_INSTALLER" || -f "$SKILLS_INSTALLER" ]] || die "missing ${SKILLS_INSTALLER}"

BIN_DIR="${PREFIX}/bin"
SHARE_DIR="${PREFIX}/share/kevin"

mkdir -p "$BIN_DIR" "$SHARE_DIR"

install -m 0755 "$CLI_SRC" "${BIN_DIR}/kevin"

# Stage profile bundle
if command -v rsync >/dev/null 2>&1; then
  rsync -a --delete "${PROFILE_SRC}/" "${SHARE_DIR}/profile/"
else
  rm -rf "${SHARE_DIR}/profile"
  mkdir -p "${SHARE_DIR}/profile"
  cp -a "${PROFILE_SRC}/." "${SHARE_DIR}/profile/"
fi

install -m 0755 "$SKILLS_INSTALLER" "${SHARE_DIR}/install-kevin-skills.sh"

# Ensure ~/.kevin exists for later stage
mkdir -p "${HOME}/.kevin"

info "installed ${BIN_DIR}/kevin"
info "share:    ${SHARE_DIR}"
info "profile:  ${SHARE_DIR}/profile"
if ! echo "${PATH}" | tr ':' '\n' | grep -qx "${BIN_DIR}"; then
  info "note: ${BIN_DIR} is not on PATH — add it, e.g.:"
  info "  export PATH=\"${BIN_DIR}:\$PATH\""
fi
info "next: kevin setup   # or: kevin setup --from-file dist/kevin-skills/kevin-skills.tar.gz"
echo "${BIN_DIR}/kevin"
