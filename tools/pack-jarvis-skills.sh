#!/usr/bin/env bash
#
# Pack Jarvis product skills artifact (dialect × product — ADR-005).
#
#   src/ layout stays nested family trees (e.g. src/jarvis/research-digest/)
#   publish-skills (hermes dialect) emits colon-named leaves as flat dirs
#     (jarvis:research-digest → dist/hermes/skills/jarvis-research-digest/)
#   this pack copies only those product flat dirs into dist/jarvis-skills/
#
# Install/image never reads src/ — only this pack / baked /opt/jarvis/skills.
#
# Usage:
#   tools/pack-jarvis-skills.sh [--no-publish] [--out-dir DIR]
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PUBLISH="${REPO_ROOT}/tools/publish-skills.sh"
DIST_HERMES="${AGENT_TOOLS_DIST_ROOT:-${REPO_ROOT}/dist}/hermes/skills"
OUT_DIR="${REPO_ROOT}/dist/jarvis-skills"
DO_PUBLISH=1

# Allowlist: flat skill ids under dist/hermes/skills after publish (not src paths).
# Colon names in src SKILL.md frontmatter are required for publish flatten.
# Expand as new Jarvis leaves land. Never include work / work-* process pack.
JARVIS_SKILL_ALLOWLIST=(
  jarvis-research-digest
)

die() { echo "pack-jarvis-skills: error: $*" >&2; exit 1; }
info() { echo "pack-jarvis-skills: $*" >&2; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-publish) DO_PUBLISH=0; shift ;;
    --out-dir)
      [[ $# -ge 2 ]] || die "--out-dir needs a path"
      OUT_DIR="$2"
      shift 2
      ;;
    -h|--help)
      sed -n '2,14p' "$0" | sed 's/^# \?//'
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

git_sha="unknown"
if command -v git >/dev/null 2>&1; then
  git_sha="$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo unknown)"
fi
created_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

STAGE="$(mktemp -d "${TMPDIR:-/tmp}/jarvis-skills-pack.XXXXXX")"
cleanup() { rm -rf "$STAGE"; }
trap cleanup EXIT

PKG="${STAGE}/jarvis-skills"
mkdir -p "${PKG}/skills"

copied=0
for name in "${JARVIS_SKILL_ALLOWLIST[@]}"; do
  src="${DIST_HERMES}/${name}"
  if [[ ! -d "$src" ]]; then
    die "allowlisted skill missing after publish: ${name} (expected ${src})"
  fi
  cp -a "${src}" "${PKG}/skills/"
  copied=$((copied + 1))
done

# Fail closed: no work/continue process skills
while IFS= read -r -d '' d; do
  base="$(basename "$d")"
  case "$base" in
    work|work-*|git|git-*)
      die "refusing to pack process skill: ${base}"
      ;;
  esac
done < <(find "${PKG}/skills" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null || true)

[[ "$copied" -gt 0 ]] || die "no skills copied"

{
  echo "agent-tools-rev=${git_sha}"
  echo "installed-at=${created_at}"
  echo "publish-agent=jarvis"
  echo "render-dialect=hermes"
} > "${PKG}/.agent-tools-revision"
cp "${PKG}/.agent-tools-revision" "${PKG}/skills/.agent-tools-revision"

manifest="${PKG}/manifest.json"
cat > "$manifest" <<EOF
{
  "schema_version": 1,
  "name": "jarvis-skills",
  "git_sha": "${git_sha}",
  "created_at": "${created_at}",
  "publish_agent": "jarvis",
  "render_dialect": "hermes",
  "skill_count": ${copied}
}
EOF

mkdir -p "$OUT_DIR"
TAR="${OUT_DIR}/jarvis-skills.tar.gz"
SHA="${OUT_DIR}/jarvis-skills.sha256"
MANIFEST_OUT="${OUT_DIR}/manifest.json"

tar -C "$STAGE" -czf "$TAR" jarvis-skills
cp "$manifest" "$MANIFEST_OUT"

if command -v sha256sum >/dev/null 2>&1; then
  (cd "$OUT_DIR" && sha256sum jarvis-skills.tar.gz > jarvis-skills.sha256)
elif command -v shasum >/dev/null 2>&1; then
  (cd "$OUT_DIR" && shasum -a 256 jarvis-skills.tar.gz > jarvis-skills.sha256)
else
  die "need sha256sum or shasum"
fi

info "wrote ${TAR}"
info "wrote ${SHA}"
info "wrote ${MANIFEST_OUT}"
info "skill_count=${copied} git_sha=${git_sha}"
echo "$TAR"
