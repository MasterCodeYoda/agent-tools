#!/usr/bin/env bash
# Promote Jarvis lab (Docker Desktop) → durable host (Portainer / remote Docker).
#
# Thin path: no interactive wizard on the server.
#   1) Export .env from local volume (values never printed)
#   2) scp to remote
#   3) Remote non-interactive finish: inject .env, restart, backup init+push, cron
#   4) Optional purge of local disposable instance
#
# Usage (agent- or human-driven):
#   # Lab first
#   ./hermes/scripts/jarvis-local-smoke.sh
#   ./hermes/scripts/jarvis-local-smoke.sh --secrets   # mint once on Desktop
#
#   # Full promote (I run this when SSH + image tag ready)
#   ./hermes/scripts/jarvis-promote.sh promote \
#     --ssh user@portainer-host \
#     --remote-repo /opt/agent-tools \
#     --image ghcr.io/OWNER/jarvis-hermes:sha-XXXXXXX
#
#   # Export only
#   ./hermes/scripts/jarvis-promote.sh export-env --out ~/secure/jarvis.env
#
#   # On durable host already (env file placed privately)
#   ./hermes/scripts/jarvis-promote.sh finish-remote --env-file /secure/jarvis.env --image <tag>
#
# Safety: never echoes secret values; temp files mode 600 + shredded; no lab sessions/DBs copied.
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
ENV_OUT=""
ENV_FILE=""
DRY_RUN=0
SKIP_LOCAL_SMOKE=0
SKIP_PURGE_LOCAL=0
SKIP_BACKUP=0
CMD=""

die() { echo "jarvis-promote: error: $*" >&2; exit 1; }
info() { echo "jarvis-promote: $*" >&2; }
usage() { sed -n '2,32p' "$0" | sed 's/^# \?//'; }

require_cmd() { command -v "$1" >/dev/null 2>&1 || die "need $1 on PATH"; }

export_env_from_local() {
  local dest="$1"
  mkdir -p "$(dirname "$dest")"
  umask 077
  if docker ps --format '{{.Names}}' | grep -qx "$CONTAINER"; then
    info "exporting .env from container $CONTAINER"
    docker exec "$CONTAINER" cat /opt/data/profiles/jarvis/.env >"$dest" \
      || die "export failed (run secrets wizard on lab first)"
  else
    info "exporting .env from volume $VOLUME_NAME"
    docker run --rm -v "${VOLUME_NAME}:/data:ro" alpine:3.20 \
      cat /data/profiles/jarvis/.env >"$dest" \
      || die "export failed — volume missing .env"
  fi
  chmod 600 "$dest"
  grep -qE '^[A-Za-z_][A-Za-z0-9_]*=' "$dest" || die "exported file does not look like .env"
  local n
  n="$(grep -cE '^[A-Za-z_][A-Za-z0-9_]*=' "$dest" || true)"
  info "exported $n key(s) → $dest (mode 600; values not shown)"
  for k in JARVIS_BACKUP_REPO JARVIS_BACKUP_GITHUB_TOKEN; do
    grep -qE "^${k}=.+" "$dest" || die "exported .env missing required $k — re-run lab secrets with backup"
  done
  for k in JARVIS_GITHUB_READ_TOKEN JARVIS_LINEAR_API_KEY JARVIS_JIRA_BASE_URL JARVIS_JIRA_EMAIL JARVIS_JIRA_API_TOKEN; do
    if ! grep -qE "^${k}=.+" "$dest"; then
      info "warning: $k not set in lab .env (integrations incomplete)"
    fi
  done
}

inject_env_into_volume() {
  local src="$1"
  [[ -f "$src" && -r "$src" ]] || die "env file missing/unreadable: $src"
  info "injecting .env into volume $VOLUME_NAME"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    info "dry-run: would inject $(wc -l <"$src" | tr -d ' ') lines"
    return 0
  fi
  local abs
  abs="$(cd "$(dirname "$src")" && pwd)/$(basename "$src")"
  docker run --rm \
    -v "${VOLUME_NAME}:/data" \
    -v "${abs}:/in.env:ro" \
    alpine:3.20 \
    sh -c 'mkdir -p /data/profiles/jarvis && cp /in.env /data/profiles/jarvis/.env && chmod 600 /data/profiles/jarvis/.env'
  info "inject complete"
}

shred_file() {
  local f="$1"
  [[ -f "$f" ]] || return 0
  if command -v shred >/dev/null 2>&1; then
    shred -u "$f" 2>/dev/null || rm -f "$f"
  else
    rm -f "$f"
  fi
  info "removed temp env file"
}

finish_remote_here() {
  local envf="$1"
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

  info "=== finish-remote: inject .env ==="
  inject_env_into_volume "$envf"

  if [[ "$DRY_RUN" -eq 0 ]]; then
    docker restart "$CONTAINER" 2>/dev/null || true
    sleep 4
  fi

  if [[ "$SKIP_BACKUP" -eq 1 ]]; then
    info "skip backup/cron"
  elif [[ "$DRY_RUN" -eq 1 ]]; then
    info "dry-run: would backup --init + backup + install cron"
  else
    info "=== finish-remote: backup + cron ==="
    "$BACKUP" --init
    "$BACKUP"
    "$CRON_INSTALL"
  fi

  info "=== finish-remote: validate ==="
  if [[ "$DRY_RUN" -eq 1 ]]; then
    info "dry-run: would smoke"
  else
    "$SMOKE" || die "smoke failed after promote"
    docker exec "$CONTAINER" /opt/jarvis/bin/jarvis-secrets-wizard.sh --in-container --check 2>/dev/null \
      || info "secrets --check skipped or incomplete"
  fi
  info "finish-remote COMPLETE"
}

# ── args ───────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    export-env|finish-remote|promote) CMD="$1"; shift ;;
    --ssh) SSH_TARGET="${2:-}"; shift 2 ;;
    --remote-repo) REMOTE_REPO="${2:-}"; shift 2 ;;
    --image) IMAGE="${2:-}"; shift 2 ;;
    --out) ENV_OUT="${2:-}"; shift 2 ;;
    --env-file) ENV_FILE="${2:-}"; shift 2 ;;
    --volume) VOLUME_NAME="${2:-}"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --skip-local-smoke) SKIP_LOCAL_SMOKE=1; shift ;;
    --skip-purge-local) SKIP_PURGE_LOCAL=1; shift ;;
    --skip-backup) SKIP_BACKUP=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done

[[ -n "$CMD" ]] || die "command required: export-env | finish-remote | promote"
require_cmd docker

case "$CMD" in
  export-env)
    [[ -n "$ENV_OUT" ]] || ENV_OUT="${HOME}/.jarvis/promote/jarvis.env"
    export_env_from_local "$ENV_OUT"
    info "Transfer privately (not chat). On remote:"
    info "  $0 finish-remote --env-file /path/to/jarvis.env --image <tag>"
    ;;

  finish-remote)
    [[ -n "$ENV_FILE" ]] || die "finish-remote requires --env-file"
    [[ -f "$ENV_FILE" ]] || die "missing $ENV_FILE"
    [[ -n "$IMAGE" ]] && export JARVIS_HERMES_IMAGE="$IMAGE"
    finish_remote_here "$ENV_FILE"
    ;;

  promote)
    require_cmd scp
    require_cmd ssh
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
      info "dry-run: would export .env (or use --env-file), scp to $SSH_TARGET,"
      info "  ssh finish-remote on $REMOTE_REPO with image=$IMAGE volume=$VOLUME_NAME,"
      info "  then purge local (unless --skip-purge-local)"
      info "PROMOTE dry-run OK"
      exit 0
    fi

    TMP_ENV="$(mktemp "${TMPDIR:-/tmp}/jarvis-promote.XXXXXX.env")"
    chmod 600 "$TMP_ENV"
    # shellcheck disable=SC2064
    trap "shred_file '$TMP_ENV'" EXIT

    if [[ -n "$ENV_FILE" ]]; then
      info "using provided --env-file"
      cp "$ENV_FILE" "$TMP_ENV"
      chmod 600 "$TMP_ENV"
      for k in JARVIS_BACKUP_REPO JARVIS_BACKUP_GITHUB_TOKEN; do
        grep -qE "^${k}=.+" "$TMP_ENV" || die "env file missing $k"
      done
    else
      export_env_from_local "$TMP_ENV"
    fi

    REMOTE_ENV="/tmp/jarvis-promote-$$.env"
    info "=== scp .env → ${SSH_TARGET} (path only; values not logged) ==="
    scp -o StrictHostKeyChecking=accept-new "$TMP_ENV" "${SSH_TARGET}:${REMOTE_ENV}"
    ssh "$SSH_TARGET" "chmod 600 '${REMOTE_ENV}'"
    info "=== remote finish-remote ==="
    # shellcheck disable=SC2029
    ssh "$SSH_TARGET" \
      "set -euo pipefail; cd '${REMOTE_REPO}'; \
       export JARVIS_HERMES_IMAGE='${IMAGE}'; \
       export JARVIS_VOLUME_NAME='${VOLUME_NAME}'; \
       export JARVIS_VOLUME_SPEC='${VOLUME_NAME}'; \
       ./hermes/scripts/jarvis-promote.sh finish-remote \
         --env-file '${REMOTE_ENV}' --image '${IMAGE}' --volume '${VOLUME_NAME}'; \
       if command -v shred >/dev/null 2>&1; then shred -u '${REMOTE_ENV}' 2>/dev/null || rm -f '${REMOTE_ENV}'; \
       else rm -f '${REMOTE_ENV}'; fi"

    shred_file "$TMP_ENV"
    trap - EXIT

    if [[ "$SKIP_PURGE_LOCAL" -eq 1 ]]; then
      info "skip local purge — purge lab when durable is confirmed: jarvis-local-smoke.sh --purge"
    else
      info "=== purge local disposable instance ==="
      "$SMOKE" --purge || info "local purge non-zero (ok if already down)"
    fi

    info "PROMOTE COMPLETE → ${SSH_TARGET}"
    info "  image=${IMAGE} volume=${VOLUME_NAME}"
    info "  next: durable Slack/email smokes; crontab -l | grep jarvis-backup"
    ;;
esac
