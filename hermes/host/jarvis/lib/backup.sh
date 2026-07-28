# shellcheck shell=bash
# Adaptive-state backup (allowlisted text → private git). Port of hermes/scripts/jarvis-backup-state.sh
# for kit install under KIT_ROOT. Requires common.sh.

jarvis_host_backup() {
  local DRY_RUN=0 DO_INIT=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run) DRY_RUN=1; shift ;;
      --init) DO_INIT=1; shift ;;
      -h|--help)
        echo "usage: jarvis-host backup [--init|--dry-run]"
        return 0
        ;;
      *) die "backup: unknown option: $1" ;;
    esac
  done

  require_docker
  have_cmd git || die "git required for backup"

  local VOLUME_NAME WORKDIR BRANCH GIT_NAME GIT_EMAIL
  VOLUME_NAME="${JARVIS_VOLUME_NAME}"
  WORKDIR="${JARVIS_BACKUP_WORKDIR}"
  BRANCH="${JARVIS_BACKUP_BRANCH:-main}"
  GIT_NAME="${JARVIS_BACKUP_GIT_NAME:-jarvis-backup}"
  GIT_EMAIL="${JARVIS_BACKUP_GIT_EMAIL:-jarvis-backup@localhost}"

  # Load secrets from volume .env without sourcing (shell-safe).
  load_backup_env_from_volume() {
    local tmp line key val
    tmp="$(mktemp)"
    # shellcheck disable=SC2064
    trap "rm -f '$tmp'" RETURN
    if ! docker run --rm -v "${VOLUME_NAME}:/data:ro" alpine:3.20 \
        cat /data/profiles/jarvis/.env >"$tmp" 2>/dev/null; then
      die "cannot read /data/profiles/jarvis/.env from volume ${VOLUME_NAME}"
    fi
    while IFS= read -r line || [[ -n "$line" ]]; do
      [[ -z "${line//[[:space:]]/}" || "$line" =~ ^[[:space:]]*# ]] && continue
      [[ "$line" == *=* ]] || continue
      key="${line%%=*}"; val="${line#*=}"
      key="${key%"${key##*[![:space:]]}"}"
      key="${key#"${key%%[![:space:]]*}"}"
      [[ "$key" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || continue
      if [[ "$val" =~ ^\"(.*)\"$ ]]; then val="${BASH_REMATCH[1]}"
      elif [[ "$val" =~ ^\'(.*)\'$ ]]; then val="${BASH_REMATCH[1]}"
      fi
      case "$key" in
        JARVIS_BACKUP_GITHUB_TOKEN|JARVIS_BACKUP_REPO|JARVIS_BACKUP_WORKDIR|JARVIS_BACKUP_BRANCH|JARVIS_BACKUP_GIT_NAME|JARVIS_BACKUP_GIT_EMAIL|JARVIS_VOLUME_NAME)
          export "$key=$val"
          ;;
      esac
    done <"$tmp"
  }

  if [[ -z "${JARVIS_BACKUP_GITHUB_TOKEN:-}" || -z "${JARVIS_BACKUP_REPO:-}" ]]; then
    load_backup_env_from_volume
  fi
  WORKDIR="${JARVIS_BACKUP_WORKDIR:-$WORKDIR}"
  BRANCH="${JARVIS_BACKUP_BRANCH:-$BRANCH}"
  VOLUME_NAME="${JARVIS_VOLUME_NAME:-$VOLUME_NAME}"

  [[ -n "${JARVIS_BACKUP_REPO:-}" ]] || die "JARVIS_BACKUP_REPO not set"
  [[ -n "${JARVIS_BACKUP_GITHUB_TOKEN:-}" ]] || die "JARVIS_BACKUP_GITHUB_TOKEN not set"

  local remote_url="$JARVIS_BACKUP_REPO"
  if [[ "$remote_url" =~ ^https://github.com/ ]]; then
    remote_url="https://x-access-token:${JARVIS_BACKUP_GITHUB_TOKEN}@${remote_url#https://}"
  elif [[ "$remote_url" =~ ^https:// ]]; then
    remote_url="https://x-access-token:${JARVIS_BACKUP_GITHUB_TOKEN}@${remote_url#https://}"
  fi

  if [[ "$DO_INIT" -eq 1 ]]; then
    if [[ ! -d "${WORKDIR}/.git" ]]; then
      info "init backup worktree at $WORKDIR"
      mkdir -p "$(dirname "$WORKDIR")"
      if git ls-remote "$remote_url" HEAD &>/dev/null; then
        git clone "$remote_url" "$WORKDIR"
      else
        mkdir -p "$WORKDIR"
        git -C "$WORKDIR" init
        git -C "$WORKDIR" checkout -b "$BRANCH" 2>/dev/null || true
        git -C "$WORKDIR" config user.name "$GIT_NAME"
        git -C "$WORKDIR" config user.email "$GIT_EMAIL"
        printf '# Jarvis adaptive state backup\n' >"${WORKDIR}/README.md"
        git -C "$WORKDIR" add README.md
        git -C "$WORKDIR" commit -m "docs: jarvis state backup scaffold" || true
      fi
    fi
  fi

  [[ -d "${WORKDIR}/.git" ]] || die "backup worktree missing; run: jarvis-host backup --init"
  git -C "$WORKDIR" config user.name "$GIT_NAME"
  git -C "$WORKDIR" config user.email "$GIT_EMAIL"

  local EXPORT_ROOT STAGE
  EXPORT_ROOT="${WORKDIR}/state"
  STAGE="$(mktemp -d "${TMPDIR:-/tmp}/jarvis-backup.XXXXXX")"
  cleanup() {
    rm -rf "$STAGE" 2>/dev/null \
      || docker run --rm -v "$(dirname "$STAGE"):/p" alpine:3.20 \
           rm -rf "/p/$(basename "$STAGE")" 2>/dev/null \
      || true
  }
  trap cleanup EXIT

  info "exporting allowlisted adaptive text from volume ${VOLUME_NAME}"
  docker run --rm \
    -u "$(id -u):$(id -g)" \
    -v "${VOLUME_NAME}:/data:ro" \
    -v "${STAGE}:/out" \
    alpine:3.20 \
    sh -c '
      set -e
      mkdir -p /out/state
      if [ -d /data/profiles/jarvis/state ]; then
        cd /data/profiles/jarvis/state
        find . -type f \( \
          -name "*.md" -o -name "*.txt" -o -name "*.json" -o -name "*.yml" -o -name "*.yaml" -o -name "*.csv" \
        \) -print0 | while IFS= read -r -d "" f; do
          mkdir -p "/out/state/$(dirname "$f")"
          cp "$f" "/out/state/$f"
        done
      fi
      if find /out -name ".env" -o -name "auth.json" | grep -q .; then
        echo "refusing: secret-like path in export" >&2
        exit 2
      fi
    '

  if find "$STAGE" \( -name '.env' -o -name 'auth.json' -o -name '*.db' -o -name '*.db-*' \) 2>/dev/null | grep -q .; then
    die "denylist hit in export stage"
  fi

  local file_count
  file_count="$(find "$STAGE/state" -type f 2>/dev/null | wc -l | tr -d ' ')"
  info "exported ${file_count} file(s) under state/"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    info "dry-run: would sync to $EXPORT_ROOT and commit+push if dirty"
    find "$STAGE/state" -type f 2>/dev/null | head -50
    return 0
  fi

  mkdir -p "$EXPORT_ROOT"
  rm -rf "${EXPORT_ROOT:?}/"*
  mkdir -p "$EXPORT_ROOT"
  if [[ -d "$STAGE/state" ]]; then
    cp -a "$STAGE/state/." "$EXPORT_ROOT/" 2>/dev/null || true
  fi

  cat > "${WORKDIR}/BACKUP_MANIFEST.md" <<EOF
# Backup manifest

- **utc:** $(date -u +%Y-%m-%dT%H:%M:%SZ)
- **host:** $(hostname 2>/dev/null || echo unknown)
- **volume:** ${VOLUME_NAME}
- **file_count:** ${file_count}
- **kit:** jarvis-host $(kit_version)
- **allowlist:** profiles/jarvis/state/** (text extensions only)
- **denylist:** .env, auth.json, sessions, *.db*, logs, caches
EOF

  git -C "$WORKDIR" add -A
  if git -C "$WORKDIR" diff --cached --quiet; then
    info "no changes — skip commit"
    return 0
  fi

  git -C "$WORKDIR" commit -m "chore(jarvis-state): backup $(date -u +%Y-%m-%dT%H%MZ) (${file_count} files)"

  push_backup() {
    git -C "$WORKDIR" -c "http.extraHeader=Authorization: Bearer ${JARVIS_BACKUP_GITHUB_TOKEN}" \
      push "$remote_url" "HEAD:${BRANCH}" 2>/dev/null \
      || git -C "$WORKDIR" push "$remote_url" "HEAD:${BRANCH}"
  }
  local attempt=1 max_attempts="${JARVIS_BACKUP_PUSH_RETRIES:-5}"
  until push_backup; do
    if [[ "$attempt" -ge "$max_attempts" ]]; then
      die "git push failed after ${max_attempts} attempts"
    fi
    info "git push failed (attempt ${attempt}/${max_attempts}); retrying…"
    sleep $((attempt * 3))
    attempt=$((attempt + 1))
  done
  info "pushed to backup repo (branch ${BRANCH})"
}
