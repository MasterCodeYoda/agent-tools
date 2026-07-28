#!/usr/bin/env bash
#
# Pack Jarvis product skills artifact (dialect × product — ADR-005).
#
#   src/ layout: product namespace under src/jarvis/<leaf>/ (no parent SKILL.md)
#   publish-skills (hermes dialect) → dist/hermes/skills/jarvis/<leaf>/
#   this pack lifts leaves flat into dist/jarvis-skills/skills/<leaf>/
#     (skill id = leaf name; no jarvis: frontmatter prefix)
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

# Product leaves under src/jarvis/<leaf>/ after dialect publish at
# dist/hermes/skills/jarvis/<leaf>/. Install id is the leaf name (flat).
# Expand as new Jarvis leaves land. Never include work / work-* process pack.
JARVIS_SKILL_LEAVES=(
  research-digest
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
for leaf in "${JARVIS_SKILL_LEAVES[@]}"; do
  # Nested under product namespace in dialect dist (src/jarvis/<leaf>/)
  src="${DIST_HERMES}/jarvis/${leaf}"
  if [[ ! -d "$src" ]]; then
    die "allowlisted leaf missing after publish: jarvis/${leaf} (expected ${src})"
  fi
  if [[ ! -f "${src}/SKILL.md" ]]; then
    die "missing SKILL.md for leaf: jarvis/${leaf}"
  fi
  # Frontmatter must not use jarvis: product prefix (product stamp is pack revision)
  declared="$(grep -m1 '^name:' "${src}/SKILL.md" | cut -d: -f2- | tr -d ' \t\r\n' || true)"
  if [[ "$declared" == jarvis:* ]]; then
    die "leaf ${leaf} still uses jarvis: name prefix (${declared}); use bare skill id"
  fi
  if [[ -n "$declared" && "$declared" != "$leaf" ]]; then
    die "leaf ${leaf} frontmatter name=${declared} must match install id ${leaf}"
  fi
  dest="${PKG}/skills/${leaf}"
  rm -rf "$dest"
  cp -a "${src}" "$dest"
  copied=$((copied + 1))
  info "packed leaf ${leaf} ← jarvis/${leaf}"
done

# Fail closed: no work/continue process skills; no accidental jarvis- prefix flats
while IFS= read -r -d '' d; do
  base="$(basename "$d")"
  case "$base" in
    work|work-*|git|git-*|jarvis|jarvis-*)
      die "refusing to pack process/product-prefix skill: ${base}"
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
