#!/usr/bin/env bash
#
# Install Kevin process skills from a packed artifact into the Kevin skills root.
#
# Product path (ADR-004): copy into KEVIN_SKILLS_ROOT (default ~/.kevin/skills).
# Not multi-agent setup.sh → ~/.hermes/skills.
#
# Usage:
#   tools/install-kevin-skills.sh --from-file path/to/kevin-skills.tar.gz
#   tools/install-kevin-skills.sh --from-url URL
#   tools/install-kevin-skills.sh --from-url   # default stable release URL
#
# Env:
#   KEVIN_SKILLS_ROOT   install target (default: $HOME/.kevin/skills)
#   KEVIN_SKILLS_URL    override default download URL
#
set -euo pipefail

DEFAULT_URL="${KEVIN_SKILLS_URL:-https://github.com/MasterCodeYoda/agent-tools/releases/download/kevin-skills/kevin-skills.tar.gz}"
ROOT="${KEVIN_SKILLS_ROOT:-${HOME}/.kevin/skills}"
FROM_FILE=""
FROM_URL=""

die() { echo "install-kevin-skills: error: $*" >&2; exit 1; }
info() { echo "install-kevin-skills: $*" >&2; }

usage() {
  sed -n '2,18p' "$0" | sed 's/^# \?//'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --from-file)
      [[ $# -ge 2 ]] || die "--from-file needs a path"
      FROM_FILE="$2"
      shift 2
      ;;
    --from-url)
      if [[ $# -ge 2 && "$2" != --* ]]; then
        FROM_URL="$2"
        shift 2
      else
        FROM_URL="$DEFAULT_URL"
        shift
      fi
      ;;
    --root)
      [[ $# -ge 2 ]] || die "--root needs a path"
      ROOT="$2"
      shift 2
      ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown argument: $1 (try --help)" ;;
  esac
done

if [[ -n "$FROM_FILE" && -n "$FROM_URL" ]]; then
  die "use only one of --from-file or --from-url"
fi
if [[ -z "$FROM_FILE" && -z "$FROM_URL" ]]; then
  FROM_URL="$DEFAULT_URL"
  info "no source flag; using default URL"
fi

STAGE="$(mktemp -d "${TMPDIR:-/tmp}/kevin-skills-install.XXXXXX")"
cleanup() { rm -rf "$STAGE"; }
trap cleanup EXIT

TAR="${STAGE}/kevin-skills.tar.gz"
if [[ -n "$FROM_FILE" ]]; then
  [[ -f "$FROM_FILE" ]] || die "file not found: $FROM_FILE"
  cp "$FROM_FILE" "$TAR"
  info "from file: $FROM_FILE"
else
  command -v curl >/dev/null 2>&1 || die "curl required for --from-url"
  info "downloading: $FROM_URL"
  curl -fsSL "$FROM_URL" -o "$TAR" || die "download failed"
fi

tar -tzf "$TAR" >/dev/null 2>&1 || die "not a valid tar.gz: $TAR"
tar -xzf "$TAR" -C "$STAGE"

PKG=""
if [[ -d "${STAGE}/kevin-skills" ]]; then
  PKG="${STAGE}/kevin-skills"
elif [[ -d "${STAGE}/skills" ]]; then
  PKG="$STAGE"
else
  die "archive missing kevin-skills/ or skills/ root"
fi

SKILLS_SRC=""
if [[ -d "${PKG}/skills" ]]; then
  SKILLS_SRC="${PKG}/skills"
else
  die "package missing skills/ directory"
fi

REV_SRC=""
if [[ -f "${PKG}/.agent-tools-revision" ]]; then
  REV_SRC="${PKG}/.agent-tools-revision"
elif [[ -f "${SKILLS_SRC}/.agent-tools-revision" ]]; then
  REV_SRC="${SKILLS_SRC}/.agent-tools-revision"
else
  die "package missing .agent-tools-revision"
fi

mkdir -p "$ROOT"
# Replace skills content carefully: keep root, wipe previous skill dirs that we own
# Simple model: rsync if available, else rm children + cp
if command -v rsync >/dev/null 2>&1; then
  rsync -a --delete "${SKILLS_SRC}/" "${ROOT}/"
else
  find "$ROOT" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
  cp -a "${SKILLS_SRC}/." "${ROOT}/"
fi
cp "$REV_SRC" "${ROOT}/.agent-tools-revision"

[[ -f "${ROOT}/.agent-tools-revision" ]] || die "revision missing after install"
[[ -n "$(ls -A "$ROOT" 2>/dev/null || true)" ]] || die "skills root empty after install"

info "installed → ${ROOT}"
info "revision:"
sed 's/^/  /' "${ROOT}/.agent-tools-revision" >&2
echo "$ROOT"
