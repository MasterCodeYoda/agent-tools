#!/usr/bin/env bash
# Promote Jarvis lab (Docker Desktop) → durable host (Portainer / remote Docker).
#
# Thin path: no interactive wizard on the server.
#   1) Export secrets bundle: .env + auth.json (Grok OAuth lives in auth.json)
#   2) scp bundle to remote
#   3) Inject both into volume, restart, backup init+push, cron
#   4) Optional purge of local disposable instance
#
# Usage:
#   ./hermes/scripts/jarvis-promote.sh export-secrets --out ~/secure/jarvis-secrets
#   ./hermes/scripts/jarvis-promote.sh promote \
#     --ssh user@host --remote-repo /opt/agent-tools --image ghcr.io/…/jarvis-hermes:tag
#   ./hermes/scripts/jarvis-promote.sh finish-remote \
#     --secrets-dir /secure/jarvis-secrets --image <tag>
#
# Bundle layout (mode 600 files; never log contents):
#   <dir>/.env
#   <dir>/auth.json    # required for SuperGrok OAuth; fail if missing unless --allow-missing-auth
#
# Safety: never echoes secret values; temp files shredded; no sessions/DBs copied.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SMOKE="${SCRIPT_DIR}/jarvis-local-smoke.sh"
BRING_UP="${SCRIPT_DIR}/jarvis-bring-up.sh"
BACKUP="${SCRIPT_DIR}/jarvis-backup-state.sh"
CRON_INSTALL="${SCRIPT_DIR}/jarvis-install-backup-cron.sh"

VOLUME_NAME="${JARVIS_VOLUME_NAME:-jarvis-hermes-data}"
CONTAINER="${JARVIS_CONTAINER_NAME:-jarvis-hermes}"
IMAGE="${JARVIS_HERMES_IMAGE:-}"
SSH_TARGET=""
REMOTE_REPO=""
SECRETS_OUT=""
SECRETS_DIR=""
ENV_FILE=""   # legacy alias: treat as secrets dir parent or single .env
DRY_RUN=0
SKIP_LOCAL_SMOKE=0
SKIP_PURGE_LOCAL=0
SKIP_BACKUP=0
ALLOW_MISSING_AUTH=0
CMD=""

die() { echo "jarvis-promote: error: $*" >&2; exit 1; }
info() { echo "jarvis-promote: $*" >&2; }
usage() { sed -n '2,28p' "$0" | sed 's/^# \?//'; }

require_cmd() { command -v "$1" >/dev/null 2>&1 || die "need $1 on PATH"; }

# Export .env + auth.json into a directory (never print contents)
export_secrets_from_local() {
  local dest_dir="$1"
  mkdir -p "$dest_dir"
  chmod 700 "$dest_dir"
  umask 077

  local copy_from_container=0
  if docker ps --format '{{.Names}}' | grep -qx "$CONTAINER"; then
    copy_from_container=1
    info "exporting secrets from container $CONTAINER (/opt/data/profiles/jarvis/)"
  else
    info "exporting secrets from volume $VOLUME_NAME"
  fi

  if [[ "$copy_from_container" -eq 1 ]]; then
    docker exec "$CONTAINER" test -f /opt/data/profiles/jarvis/.env \
      || die "lab .env missing — run secrets wizard first"
    docker exec "$CONTAINER" cat /opt/data/profiles/jarvis/.env >"${dest_dir}/.env"
    if docker exec "$CONTAINER" test -f /opt/data/profiles/jarvis/auth.json; then
      docker exec "$CONTAINER" cat /opt/data/profiles/jarvis/auth.json >"${dest_dir}/auth.json"
    fi
  else
    docker run --rm -v "${VOLUME_NAME}:/data:ro" alpine:3.20 \
      test -f /data/profiles/jarvis/.env \
      || die "volume missing .env"
    docker run --rm -v "${VOLUME_NAME}:/data:ro" alpine:3.20 \
      cat /data/profiles/jarvis/.env >"${dest_dir}/.env"
    if docker run --rm -v "${VOLUME_NAME}:/data:ro" alpine:3.20 \
         test -f /data/profiles/jarvis/auth.json 2>/dev/null; then
      docker run --rm -v "${VOLUME_NAME}:/data:ro" alpine:3.20 \
        cat /data/profiles/jarvis/auth.json >"${dest_dir}/auth.json"
    fi
  fi

  chmod 600 "${dest_dir}/.env"
  [[ -f "${dest_dir}/auth.json" ]] && chmod 600 "${dest_dir}/auth.json"

  # Hermes may ship a comment-only .env until the secrets wizard writes keys
  local n
  n="$(grep -cE '^[A-Za-z_][A-Za-z0-9_]*=' "${dest_dir}/.env" || true)"
  info "exported .env ($n key line(s)) → ${dest_dir}/.env (values not shown)"

  if [[ -f "${dest_dir}/auth.json" ]]; then
    # structure check only — no token dump
    grep -q 'xai-oauth\|providers\|access_token\|refresh' "${dest_dir}/auth.json" 2>/dev/null \
      && info "exported auth.json (OAuth/provider store present; contents not shown)" \
      || info "exported auth.json (present; shape unknown)"
  else
    if [[ "$ALLOW_MISSING_AUTH" -eq 1 ]]; then
      info "warning: auth.json missing (Grok OAuth will not promote)"
    else
      die "auth.json missing — complete Grok OAuth (hermes auth add xai-oauth) or pass --allow-missing-auth"
    fi
  fi

  for k in JARVIS_BACKUP_REPO JARVIS_BACKUP_GITHUB_TOKEN; do
    grep -qE "^${k}=.+" "${dest_dir}/.env" || die "exported .env missing required $k"
  done
  for k in JARVIS_GITHUB_READ_TOKEN JARVIS_LINEAR_API_KEY; do
    if ! grep -qE "^${k}=.+" "${dest_dir}/.env"; then
      info "warning: $k not set in lab .env"
    fi
  done
  # Jira is optional (multi-account deferred)
}

# Inject .env + auth.json from a secrets directory into the Docker volume
inject_secrets_into_volume() {
  local src_dir="$1"
  [[ -d "$src_dir" ]] || die "secrets dir missing: $src_dir"
  [[ -f "${src_dir}/.env" ]] || die "secrets dir missing .env: $src_dir"
  info "injecting secrets into volume $VOLUME_NAME (.env + auth.json if present)"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    info "dry-run: would inject from $src_dir"
    return 0
  fi
  local abs
  abs="$(cd "$src_dir" && pwd)"
  docker run --rm \
    -v "${VOLUME_NAME}:/data" \
    -v "${abs}:/in:ro" \
    alpine:3.20 \
    sh -c '
      set -e
      mkdir -p /data/profiles/jarvis
      cp /in/.env /data/profiles/jarvis/.env
      chmod 600 /data/profiles/jarvis/.env
      if [ -f /in/auth.json ]; then
        cp /in/auth.json /data/profiles/jarvis/auth.json
        chmod 600 /data/profiles/jarvis/auth.json
      fi
    '
  info "inject complete (.env$([ -f "${src_dir}/auth.json" ] && echo ' + auth.json' || true))"
}

shred_path() {
  local p="$1"
  [[ -e "$p" ]] || return 0
  if [[ -d "$p" ]]; then
    find "$p" -type f -exec sh -c 'if command -v shred >/dev/null 2>&1; then shred -u "$1" 2>/dev/null || rm -f "$1"; else rm -f "$1"; fi' _ {} \;
    rm -rf "$p"
  elif command -v shred >/dev/null 2>&1; then
    shred -u "$p" 2>/dev/null || rm -f "$p"
  else
    rm -f "$p"
  fi
  info "removed temp secrets path"
}

pack_secrets_tar() {
  local src_dir="$1" tar_path="$2"
  tar -C "$src_dir" -czf "$tar_path" .env $( [[ -f "${src_dir}/auth.json" ]] && echo auth.json )
  chmod 600 "$tar_path"
}

unpack_secrets_tar() {
  local tar_path="$1" dest_dir="$2"
  mkdir -p "$dest_dir"
  chmod 700 "$dest_dir"
  tar -C "$dest_dir" -xzf "$tar_path"
  chmod 600 "${dest_dir}/.env" 2>/dev/null || true
  [[ -f "${dest_dir}/auth.json" ]] && chmod 600 "${dest_dir}/auth.json"
}

finish_remote_here() {
  local secrets_dir="$1"
  export JARVIS_HERMES_IMAGE="${IMAGE:-${JARVIS_HERMES_IMAGE:-jarvis-hermes:local}}"
  export JARVIS_VOLUME_SPEC="${JARVIS_VOLUME_SPEC:-${VOLUME_NAME}}"
  export JARVIS_VOLUME_NAME="${VOLUME_NAME}"

  info "=== finish-remote: image/bring-up ==="
  if [[ "$DRY_RUN" -eq 1 ]]; then
    info "dry-run: would pull/up image=$JARVIS_HERMES_IMAGE"
  else
    if [[ "$JARVIS_HERMES_IMAGE" == *'/'* ]]; then
      info "pulling $JARVIS_HERMES_IMAGE"
      docker pull "$JARVIS_HERMES_IMAGE" || info "pull failed — will try existing local tag"
    fi
    "$BRING_UP" --no-build 2>/dev/null || "$BRING_UP"
  fi

  info "=== finish-remote: inject secrets (.env + auth.json) ==="
  inject_secrets_into_volume "$secrets_dir"

  if [[ "$DRY_RUN" -eq 0 ]]; then
    docker restart "$CONTAINER" 2>/dev/null || true
    sleep 4
  fi

  if [[ "$SKIP_BACKUP" -eq 1 ]]; then
    info "skip backup/cron"
  elif [[ "$DRY_RUN" -eq 1 ]]; then
    info "dry-run: would backup --init + backup + install cron"
  else
    info "=== finish-remote: backup + host schedule ==="
    "$BACKUP" --init
    "$BACKUP"
    "$CRON_INSTALL"
  fi

  info "=== finish-remote: validate ==="
  if [[ "$DRY_RUN" -eq 1 ]]; then
    info "dry-run: would smoke + oauth presence check"
  else
    "$SMOKE" || die "smoke failed after promote"
    docker exec "$CONTAINER" /opt/jarvis/bin/jarvis-secrets-wizard.sh --in-container --check 2>/dev/null \
      || info "secrets --check skipped or incomplete"
    if docker exec "$CONTAINER" test -f /opt/data/profiles/jarvis/auth.json; then
      info "auth.json present on durable volume (OAuth store)"
    else
      info "warning: auth.json still missing on durable volume"
    fi
  fi
  info "finish-remote COMPLETE"
}

# Resolve --secrets-dir / --env-file / --secrets-bundle into a directory path
resolve_secrets_dir() {
  if [[ -n "$SECRETS_DIR" ]]; then
    [[ -d "$SECRETS_DIR" ]] || die "secrets dir missing: $SECRETS_DIR"
    echo "$SECRETS_DIR"
    return
  fi
  if [[ -n "$ENV_FILE" ]]; then
    # legacy: path to .env → use parent if auth.json beside it, else dir of file as bundle
    if [[ -d "$ENV_FILE" ]]; then
      echo "$ENV_FILE"
      return
    fi
    if [[ -f "$ENV_FILE" ]]; then
      local parent
      parent="$(cd "$(dirname "$ENV_FILE")" && pwd)"
      # if they passed foo/jarvis.env, prefer parent if it has both; else create temp dir with just .env
      if [[ -f "${parent}/auth.json" ]] || [[ "$(basename "$ENV_FILE")" == ".env" ]]; then
        if [[ "$(basename "$ENV_FILE")" != ".env" ]]; then
          # copy to temp layout
          local tmp
          tmp="$(mktemp -d "${TMPDIR:-/tmp}/jarvis-sec.XXXXXX")"
          cp "$ENV_FILE" "${tmp}/.env"
          [[ -f "${parent}/auth.json" ]] && cp "${parent}/auth.json" "${tmp}/auth.json"
          echo "$tmp"
          return
        fi
        echo "$parent"
        return
      fi
      local tmp
      tmp="$(mktemp -d "${TMPDIR:-/tmp}/jarvis-sec.XXXXXX")"
      cp "$ENV_FILE" "${tmp}/.env"
      echo "$tmp"
      return
    fi
  fi
  die "need --secrets-dir DIR (preferred) or --env-file PATH"
}

# ── args ───────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    export-env|export-secrets|finish-remote|promote) CMD="$1"; shift ;;
    --ssh) SSH_TARGET="${2:-}"; shift 2 ;;
    --remote-repo) REMOTE_REPO="${2:-}"; shift 2 ;;
    --image) IMAGE="${2:-}"; shift 2 ;;
    --out) SECRETS_OUT="${2:-}"; shift 2 ;;
    --secrets-dir) SECRETS_DIR="${2:-}"; shift 2 ;;
    --env-file) ENV_FILE="${2:-}"; shift 2 ;;  # legacy
    --volume) VOLUME_NAME="${2:-}"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --skip-local-smoke) SKIP_LOCAL_SMOKE=1; shift ;;
    --skip-purge-local) SKIP_PURGE_LOCAL=1; shift ;;
    --skip-backup) SKIP_BACKUP=1; shift ;;
    --allow-missing-auth) ALLOW_MISSING_AUTH=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done

# normalize alias
[[ "$CMD" == "export-env" ]] && CMD=export-secrets

[[ -n "$CMD" ]] || die "command required: export-secrets | finish-remote | promote"
require_cmd docker

case "$CMD" in
  export-secrets)
    [[ -n "$SECRETS_OUT" ]] || SECRETS_OUT="${HOME}/.jarvis/promote/secrets"
    export_secrets_from_local "$SECRETS_OUT"
    info "Transfer directory privately (scp -r). Do not paste into chat."
    info "On remote: $0 finish-remote --secrets-dir $SECRETS_OUT --image <tag>"
    ;;

  finish-remote)
    [[ -n "$IMAGE" ]] && export JARVIS_HERMES_IMAGE="$IMAGE"
    sdir="$(resolve_secrets_dir)"
    finish_remote_here "$sdir"
    ;;

  promote)
    require_cmd scp
    require_cmd ssh
    require_cmd tar
    [[ -n "$SSH_TARGET" ]] || die "promote requires --ssh user@host"
    [[ -n "$REMOTE_REPO" ]] || die "promote requires --remote-repo /path/to/agent-tools on host"
    [[ -n "$IMAGE" ]] || die "promote requires --image ghcr.io/…/jarvis-hermes:tag"

    if [[ "$SKIP_LOCAL_SMOKE" -eq 0 ]]; then
      info "=== local smoke ==="
      if [[ "$DRY_RUN" -eq 1 ]]; then
        info "dry-run: would run jarvis-local-smoke.sh"
      else
        "$SMOKE" || die "local smoke failed — fix lab before promote"
      fi
    fi

    if [[ "$DRY_RUN" -eq 1 ]]; then
      info "dry-run: would export .env+auth.json, scp to $SSH_TARGET,"
      info "  ssh finish-remote on $REMOTE_REPO with image=$IMAGE volume=$VOLUME_NAME,"
      info "  then purge local (unless --skip-purge-local)"
      info "PROMOTE dry-run OK"
      exit 0
    fi

    TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/jarvis-promote.XXXXXX")"
    TMP_TAR="${TMP_DIR}.tgz"
    # shellcheck disable=SC2064
    trap "shred_path '$TMP_DIR'; shred_path '$TMP_TAR'" EXIT

    if [[ -n "$SECRETS_DIR" || -n "$ENV_FILE" ]]; then
      sdir="$(resolve_secrets_dir)"
      info "using provided secrets from $sdir"
      mkdir -p "$TMP_DIR"
      cp "${sdir}/.env" "${TMP_DIR}/.env"
      [[ -f "${sdir}/auth.json" ]] && cp "${sdir}/auth.json" "${TMP_DIR}/auth.json"
      chmod 600 "${TMP_DIR}/.env"
      [[ -f "${TMP_DIR}/auth.json" ]] || {
        [[ "$ALLOW_MISSING_AUTH" -eq 1 ]] || die "auth.json missing in provided secrets"
      }
    else
      export_secrets_from_local "$TMP_DIR"
    fi

    pack_secrets_tar "$TMP_DIR" "$TMP_TAR"
    REMOTE_TAR="/tmp/jarvis-promote-$$.tgz"
    REMOTE_DIR="/tmp/jarvis-promote-$$-secrets"
    info "=== scp secrets bundle (.env + auth.json) → ${SSH_TARGET} (values not logged) ==="
    scp -o StrictHostKeyChecking=accept-new "$TMP_TAR" "${SSH_TARGET}:${REMOTE_TAR}"
    ssh "$SSH_TARGET" "chmod 600 '${REMOTE_TAR}'"
    info "=== remote finish-remote ==="
    # shellcheck disable=SC2029
    ssh "$SSH_TARGET" \
      "set -euo pipefail; cd '${REMOTE_REPO}'; \
       mkdir -p '${REMOTE_DIR}' && tar -C '${REMOTE_DIR}' -xzf '${REMOTE_TAR}' && chmod 600 '${REMOTE_DIR}/.env' && \
       ( [ -f '${REMOTE_DIR}/auth.json' ] && chmod 600 '${REMOTE_DIR}/auth.json' || true ); \
       export JARVIS_HERMES_IMAGE='${IMAGE}'; \
       export JARVIS_VOLUME_NAME='${VOLUME_NAME}'; \
       export JARVIS_VOLUME_SPEC='${VOLUME_NAME}'; \
       ./hermes/scripts/jarvis-promote.sh finish-remote \
         --secrets-dir '${REMOTE_DIR}' --image '${IMAGE}' --volume '${VOLUME_NAME}'; \
       rm -rf '${REMOTE_DIR}' '${REMOTE_TAR}'"

    shred_path "$TMP_DIR"
    shred_path "$TMP_TAR"
    trap - EXIT

    if [[ "$SKIP_PURGE_LOCAL" -eq 1 ]]; then
      info "skip local purge — purge lab when durable is confirmed: jarvis-local-smoke.sh --purge"
    else
      info "=== purge local disposable instance ==="
      "$SMOKE" --purge || info "local purge non-zero (ok if already down)"
    fi

    info "PROMOTE COMPLETE → ${SSH_TARGET}"
    info "  image=${IMAGE} volume=${VOLUME_NAME}"
    info "  secrets: .env + auth.json (OAuth) injected"
    info "  next: durable Slack/email smokes; ./hermes/scripts/jarvis-install-backup-cron.sh --status"
    ;;
esac
