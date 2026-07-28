#!/usr/bin/env bash
# Nightly (or on-demand) backup of Jarvis **adaptive text state** to a private git repo.
#
# - Allowlist only (never secrets, sessions, DBs, policy SoT)
# - Runs on the **Docker host** (cron), not as chat-driven git from the model
# - Token: JARVIS_BACKUP_GITHUB_TOKEN — fine-grained PAT scoped to the backup repo only
#
# Usage:
#   ./hermes/scripts/jarvis-backup-state.sh              # commit+push if dirty
#   ./hermes/scripts/jarvis-backup-state.sh --dry-run    # show what would copy/commit
#   ./hermes/scripts/jarvis-backup-state.sh --init       # clone/init worktree once
#
# Env (from live jarvis .env on volume, or export before run):
#   JARVIS_BACKUP_GITHUB_TOKEN   required for push
#   JARVIS_BACKUP_REPO           e.g. https://github.com/org/jarvis-state.git  or git@…
#   JARVIS_BACKUP_WORKDIR        default: $HOME/.jarvis/backup-repo
#   JARVIS_VOLUME_NAME           default: jarvis-hermes-data
#   JARVIS_BACKUP_BRANCH         default: main
#   JARVIS_BACKUP_GIT_NAME       default: jarvis-backup
#   JARVIS_BACKUP_GIT_EMAIL      default: jarvis-backup@localhost
#
# Agent-tools note: this text state is intentional input for skill evolution / process IP
# (what the CoS is tracking, digests, adaptive notes) — not a substitute for src/ skills SoT.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=0
DO_INIT=0

die() { echo "jarvis-backup-state: error: $*" >&2; exit 1; }
info() { echo "jarvis-backup-state: $*" >&2; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --init) DO_INIT=1; shift ;;
    -h|--help) sed -n '2,28p' "$0" | sed 's/^# \?//'; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done

VOLUME_NAME="${JARVIS_VOLUME_NAME:-jarvis-hermes-data}"
WORKDIR="${JARVIS_BACKUP_WORKDIR:-${HOME}/.jarvis/backup-repo}"
BRANCH="${JARVIS_BACKUP_BRANCH:-main}"
GIT_NAME="${JARVIS_BACKUP_GIT_NAME:-jarvis-backup}"
GIT_EMAIL="${JARVIS_BACKUP_GIT_EMAIL:-jarvis-backup@localhost}"

command -v docker >/dev/null 2>&1 || die "docker required"
command -v git >/dev/null 2>&1 || die "git required"

# ── Load secrets from jarvis volume .env (never print values) ───────
# Do NOT `source` the file: passwords often contain shell metacharacters
# ($ ` " ' spaces) and break with cryptic errors (e.g. "zwin: not found").
load_env_from_volume() {
  local tmp line key val
  tmp="$(mktemp)"
  # shellcheck disable=SC2064
  trap "rm -f '$tmp'" RETURN
  if ! docker run --rm -v "${VOLUME_NAME}:/data:ro" alpine:3.20 \
      cat /data/profiles/jarvis/.env >"$tmp" 2>/dev/null; then
    die "cannot read /data/profiles/jarvis/.env from volume ${VOLUME_NAME} (is jarvis set up?)"
  fi
  while IFS= read -r line || [[ -n "$line" ]]; do
    # skip blank / comments
    [[ -z "${line//[[:space:]]/}" || "$line" =~ ^[[:space:]]*# ]] && continue
    [[ "$line" == *=* ]] || continue
    key="${line%%=*}"
    val="${line#*=}"
    # trim key whitespace; strip optional surrounding quotes on value
    key="${key%"${key##*[![:space:]]}"}"
    key="${key#"${key%%[![:space:]]*}"}"
    [[ "$key" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || continue
    if [[ "$val" =~ ^\"(.*)\"$ ]]; then
      val="${BASH_REMATCH[1]}"
    elif [[ "$val" =~ ^\'(.*)\'$ ]]; then
      val="${BASH_REMATCH[1]}"
    fi
    # Only export keys we need for backup (avoid polluting env with SMTP etc.)
    case "$key" in
      JARVIS_BACKUP_GITHUB_TOKEN|JARVIS_BACKUP_REPO|JARVIS_BACKUP_WORKDIR|JARVIS_BACKUP_BRANCH|JARVIS_BACKUP_GIT_NAME|JARVIS_BACKUP_GIT_EMAIL|JARVIS_VOLUME_NAME)
        export "$key=$val"
        ;;
    esac
  done <"$tmp"
}

if [[ -z "${JARVIS_BACKUP_GITHUB_TOKEN:-}" || -z "${JARVIS_BACKUP_REPO:-}" ]]; then
  load_env_from_volume
fi

[[ -n "${JARVIS_BACKUP_REPO:-}" ]] || die "JARVIS_BACKUP_REPO not set (secrets wizard / .env)"
[[ -n "${JARVIS_BACKUP_GITHUB_TOKEN:-}" ]] || die "JARVIS_BACKUP_GITHUB_TOKEN not set (fine-grained PAT to backup repo only)"

# Build authenticated HTTPS URL if repo is github https without userinfo
remote_url="$JARVIS_BACKUP_REPO"
if [[ "$remote_url" =~ ^https://github.com/ ]]; then
  remote_url="https://x-access-token:${JARVIS_BACKUP_GITHUB_TOKEN}@${remote_url#https://}"
elif [[ "$remote_url" =~ ^https:// ]]; then
  # generic https: inject token as user
  remote_url="https://x-access-token:${JARVIS_BACKUP_GITHUB_TOKEN}@${remote_url#https://}"
fi

# ── Init worktree ──────────────────────────────────────────────────
if [[ "$DO_INIT" -eq 1 ]] || [[ ! -d "${WORKDIR}/.git" ]]; then
  info "init backup worktree at $WORKDIR"
  mkdir -p "$(dirname "$WORKDIR")"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    info "dry-run: would git clone $JARVIS_BACKUP_REPO → $WORKDIR"
  else
    rm -rf "$WORKDIR"
    # Clone without embedding token in disk config long-term: use once then set remote without token for fetch; push uses token via env URL
    GIT_TERMINAL_PROMPT=0 git clone --branch "$BRANCH" "$remote_url" "$WORKDIR" 2>/dev/null \
      || GIT_TERMINAL_PROMPT=0 git clone "$remote_url" "$WORKDIR"
    # Rewrite remote to non-token URL for local config safety
    git -C "$WORKDIR" remote set-url origin "$JARVIS_BACKUP_REPO"
    git -C "$WORKDIR" config user.name "$GIT_NAME"
    git -C "$WORKDIR" config user.email "$GIT_EMAIL"
    # README for empty repos
    if [[ ! -f "$WORKDIR/README.md" ]]; then
      cat > "$WORKDIR/README.md" <<'EOF'
# Jarvis adaptive state backup

Private mirror of **non-secret** CoS adaptive text from the single Jarvis Docker volume.

- **Allowlist:** `state/**` under the jarvis profile
- **Never:** `.env`, `auth.json`, sessions, SQLite, logs
- **Policy SoT:** agent-tools `hermes/jarvis-profile/` (not this repo)
- **Consumers:** disaster restore; agent-tools skill evolution signals (digests / tracking notes)

Produced by `hermes/scripts/jarvis-backup-state.sh` on the Jarvis host.
EOF
      git -C "$WORKDIR" add README.md
      git -C "$WORKDIR" commit -m "docs: jarvis state backup scaffold" || true
    fi
  fi
fi

[[ -d "${WORKDIR}/.git" ]] || die "backup worktree missing; run with --init first"

# ── Export allowlisted paths from volume ───────────────────────────
EXPORT_ROOT="${WORKDIR}/state"
STAGE="$(mktemp -d "${TMPDIR:-/tmp}/jarvis-backup.XXXXXX")"
cleanup() { rm -rf "$STAGE"; }
trap cleanup EXIT

info "exporting allowlisted adaptive text from volume ${VOLUME_NAME}"
# Copy only state/ tree
docker run --rm \
  -v "${VOLUME_NAME}:/data:ro" \
  -v "${STAGE}:/out" \
  alpine:3.20 \
  sh -c '
    set -e
    mkdir -p /out/state
    if [ -d /data/profiles/jarvis/state ]; then
      # text-ish files only; skip odd binaries if any
      cd /data/profiles/jarvis/state
      find . -type f \( \
        -name "*.md" -o -name "*.txt" -o -name "*.json" -o -name "*.yml" -o -name "*.yaml" -o -name "*.csv" \
      \) -print0 | while IFS= read -r -d "" f; do
        mkdir -p "/out/state/$(dirname "$f")"
        cp "$f" "/out/state/$f"
      done
    fi
    # Fail closed: ensure we never staged secrets
    if find /out -name ".env" -o -name "auth.json" | grep -q .; then
      echo "refusing: secret-like path in export" >&2
      exit 2
    fi
  '

# Denylist sweep on stage
if find "$STAGE" \( -name '.env' -o -name 'auth.json' -o -name '*.db' -o -name '*.db-*' \) 2>/dev/null | grep -q .; then
  die "denylist hit in export stage"
fi

file_count="$(find "$STAGE/state" -type f 2>/dev/null | wc -l | tr -d ' ')"
info "exported ${file_count} file(s) under state/"

if [[ "$DRY_RUN" -eq 1 ]]; then
  info "dry-run: would sync to $EXPORT_ROOT and commit+push if dirty"
  find "$STAGE/state" -type f 2>/dev/null | head -50
  exit 0
fi

mkdir -p "$EXPORT_ROOT"
# Replace export tree (keep git history)
rm -rf "${EXPORT_ROOT:?}/"*
mkdir -p "$EXPORT_ROOT"
if [[ -d "$STAGE/state" ]]; then
  cp -a "$STAGE/state/." "$EXPORT_ROOT/" 2>/dev/null || true
fi

# Manifest for consumers (skill evolution, restore)
cat > "${WORKDIR}/BACKUP_MANIFEST.md" <<EOF
# Backup manifest

- **utc:** $(date -u +%Y-%m-%dT%H:%M:%SZ)
- **host:** $(hostname 2>/dev/null || echo unknown)
- **volume:** ${VOLUME_NAME}
- **file_count:** ${file_count}
- **allowlist:** profiles/jarvis/state/** (text extensions only)
- **denylist:** .env, auth.json, sessions, *.db*, logs, caches
- **agent-tools:** adaptive CoS state for evolution signals; policy remains hermes/jarvis-profile
EOF

git -C "$WORKDIR" add -A
if git -C "$WORKDIR" diff --cached --quiet; then
  info "no changes — skip commit"
  exit 0
fi

git -C "$WORKDIR" commit -m "chore(jarvis-state): backup $(date -u +%Y-%m-%dT%H%MZ) (${file_count} files)"

# Push with token only in process env (not stored in remote URL on disk)
git -C "$WORKDIR" -c "http.extraHeader=Authorization: Bearer ${JARVIS_BACKUP_GITHUB_TOKEN}" \
  push "$remote_url" "HEAD:${BRANCH}" 2>/dev/null \
  || git -C "$WORKDIR" push "$remote_url" "HEAD:${BRANCH}"

info "pushed to backup repo (branch ${BRANCH})"
