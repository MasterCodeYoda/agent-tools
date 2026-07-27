#!/usr/bin/env bash
#
# Pack Kevin product skills artifact (dialect × product — ADR-005).
#
#   dialect: publish-skills --agents hermes → dist/hermes/skills  (Hermes loader shape)
#   product: this pack → dist/kevin-skills/ + revision publish-agent=kevin
#
# Usage:
#   tools/pack-kevin-skills.sh [--no-publish] [--out-dir DIR]
#
# Default: publish hermes dialect, then pack into dist/kevin-skills/.
# Outputs: kevin-skills.tar.gz, kevin-skills.sha256, manifest.json
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PUBLISH="${REPO_ROOT}/tools/publish-skills.sh"
DIST_HERMES="${AGENT_TOOLS_DIST_ROOT:-${REPO_ROOT}/dist}/hermes/skills"
OUT_DIR="${REPO_ROOT}/dist/kevin-skills"
DO_PUBLISH=1

die() { echo "pack-kevin-skills: error: $*" >&2; exit 1; }
info() { echo "pack-kevin-skills: $*" >&2; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-publish) DO_PUBLISH=0; shift ;;
    --out-dir)
      [[ $# -ge 2 ]] || die "--out-dir needs a path"
      OUT_DIR="$2"
      shift 2
      ;;
    -h|--help)
      sed -n '2,12p' "$0" | sed 's/^# \?//'
      exit 0
      ;;
    *) die "unknown argument: $1" ;;
  esac
done

[[ -x "$PUBLISH" ]] || die "publisher not executable: $PUBLISH"

if [[ "$DO_PUBLISH" -eq 1 ]]; then
  info "publishing render dialect hermes → dist/hermes/skills…"
  env -u AGENT_TOOLS_SRC_ROOT -u AGENT_TOOLS_DIST_ROOT \
    "$PUBLISH" --agents hermes --quiet \
    || die "publish-skills failed"
fi

[[ -d "$DIST_HERMES" ]] || die "missing hermes dialect tree: $DIST_HERMES"
skill_count="$(find "$DIST_HERMES" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')"
[[ "$skill_count" -gt 0 ]] || die "no skill directories under $DIST_HERMES"

git_sha="unknown"
if command -v git >/dev/null 2>&1; then
  git_sha="$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo unknown)"
fi
created_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

STAGE="$(mktemp -d "${TMPDIR:-/tmp}/kevin-skills-pack.XXXXXX")"
cleanup() { rm -rf "$STAGE"; }
trap cleanup EXIT

PKG="${STAGE}/kevin-skills"
mkdir -p "${PKG}/skills"
# Copy tree (no symlinks into package — portable install)
cp -a "${DIST_HERMES}/." "${PKG}/skills/"

{
  echo "agent-tools-rev=${git_sha}"
  echo "installed-at=${created_at}"
  echo "publish-agent=kevin"
  echo "render-dialect=hermes"
} > "${PKG}/.agent-tools-revision"
# Also inside skills tree for consumers that only mount skills/
cp "${PKG}/.agent-tools-revision" "${PKG}/skills/.agent-tools-revision"

manifest="${PKG}/manifest.json"
# Minimal JSON without jq dependency
cat > "$manifest" <<EOF
{
  "schema_version": 1,
  "name": "kevin-skills",
  "git_sha": "${git_sha}",
  "created_at": "${created_at}",
  "publish_agent": "kevin",
  "render_dialect": "hermes",
  "skill_count": ${skill_count}
}
EOF

mkdir -p "$OUT_DIR"
TAR="${OUT_DIR}/kevin-skills.tar.gz"
SHA="${OUT_DIR}/kevin-skills.sha256"
MANIFEST_OUT="${OUT_DIR}/manifest.json"

tar -C "$STAGE" -czf "$TAR" kevin-skills
cp "$manifest" "$MANIFEST_OUT"

# sha256sum on Linux; shasum on macOS
if command -v sha256sum >/dev/null 2>&1; then
  (cd "$OUT_DIR" && sha256sum kevin-skills.tar.gz > kevin-skills.sha256)
elif command -v shasum >/dev/null 2>&1; then
  (cd "$OUT_DIR" && shasum -a 256 kevin-skills.tar.gz > kevin-skills.sha256)
else
  die "need sha256sum or shasum"
fi

info "wrote ${TAR}"
info "wrote ${SHA}"
info "wrote ${MANIFEST_OUT}"
info "skill_count=${skill_count} git_sha=${git_sha}"
echo "$TAR"
