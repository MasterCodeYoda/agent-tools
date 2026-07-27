#!/usr/bin/env bash
# Full-fidelity Jarvis host setup (production path of record).
#
# Installs as one flow (not optional add-ons):
#   1. Image + container + named volume (bring-up)
#   2. Secrets wizard (model + required backup write token + required read integrations
#      GitHub OMG / Linear / Jira + optional email/slack)
#   3. Backup repo init + first backup
#   4. Nightly host cron for adaptive-state git push
#
# Usage:
#   ./hermes/scripts/jarvis-setup.sh                 # full setup (interactive secrets)
#   ./hermes/scripts/jarvis-setup.sh --from-env-file PATH       # legacy .env only
#   ./hermes/scripts/jarvis-setup.sh --from-secrets-dir DIR     # .env + auth.json (preferred)
#   ./hermes/scripts/jarvis-setup.sh --no-build
#   ./hermes/scripts/jarvis-setup.sh --skip-cron     # emergency only
#   ./hermes/scripts/jarvis-setup.sh --check
#
# Prefer lab→durable promote: ./hermes/scripts/jarvis-promote.sh --ssh … --image …
# Local packaging smoke: jarvis-local-smoke.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRING_UP="${SCRIPT_DIR}/jarvis-bring-up.sh"
SMOKE="${SCRIPT_DIR}/jarvis-local-smoke.sh"
WIZARD="${SCRIPT_DIR}/jarvis-secrets-wizard.sh"
BACKUP="${SCRIPT_DIR}/jarvis-backup-state.sh"
CRON_INSTALL="${SCRIPT_DIR}/jarvis-install-backup-cron.sh"
PROMOTE="${SCRIPT_DIR}/jarvis-promote.sh"

export JARVIS_HERMES_IMAGE="${JARVIS_HERMES_IMAGE:-jarvis-hermes:local}"
export JARVIS_VOLUME_SPEC="${JARVIS_VOLUME_SPEC:-jarvis-hermes-data}"

NO_BUILD=()
SKIP_CRON=0
CHECK_ONLY=0
FROM_ENV=""
FROM_SECRETS=""

die() { echo "jarvis-setup: error: $*" >&2; exit 1; }
info() { echo "jarvis-setup: $*" >&2; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-build) NO_BUILD=(--no-build); shift ;;
    --skip-cron) SKIP_CRON=1; shift ;;
    --check) CHECK_ONLY=1; shift ;;
    --from-env-file) FROM_ENV="${2:-}"; shift 2 ;;
    --from-secrets-dir) FROM_SECRETS="${2:-}"; shift 2 ;;
    -h|--help) sed -n '2,18p' "$0" | sed 's/^# \?//'; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done

[[ -x "$BRING_UP" && -x "$WIZARD" && -x "$BACKUP" && -x "$CRON_INSTALL" ]] || die "missing scripts in $SCRIPT_DIR"

if [[ "$CHECK_ONLY" -eq 1 ]]; then
  "$SMOKE" || true
  info "backup worktree: ${JARVIS_BACKUP_WORKDIR:-$HOME/.jarvis/backup-repo}"
  if crontab -l 2>/dev/null | grep -q jarvis-backup-state; then
    info "cron: installed"
  else
    info "cron: MISSING"
  fi
  docker exec jarvis-hermes /opt/jarvis/bin/jarvis-secrets-wizard.sh --in-container --check 2>/dev/null \
    || info "secrets check: run wizard if container has no wizard yet"
  exit 0
fi

# Non-interactive promote path (blind secrets inject)
if [[ -n "$FROM_SECRETS" || -n "$FROM_ENV" ]]; then
  [[ -x "$PROMOTE" ]] || die "missing $PROMOTE"
  export JARVIS_HERMES_IMAGE
  if [[ "$SKIP_CRON" -eq 1 ]]; then
    info "WARNING: --skip-cron: still injects secrets; run jarvis-install-backup-cron.sh later"
  fi
  if [[ -n "$FROM_SECRETS" ]]; then
    [[ -d "$FROM_SECRETS" ]] || die "missing --from-secrets-dir $FROM_SECRETS"
    "$PROMOTE" finish-remote --secrets-dir "$FROM_SECRETS" --image "$JARVIS_HERMES_IMAGE" \
      $([[ "$SKIP_CRON" -eq 1 ]] && echo --skip-backup || true)
  else
    [[ -f "$FROM_ENV" ]] || die "missing --from-env-file $FROM_ENV"
    info "warning: --from-env-file is .env only — Grok OAuth needs auth.json; prefer --from-secrets-dir"
    "$PROMOTE" finish-remote --env-file "$FROM_ENV" --image "$JARVIS_HERMES_IMAGE" --allow-missing-auth \
      $([[ "$SKIP_CRON" -eq 1 ]] && echo --skip-backup || true)
  fi
  exit 0
fi

info "=== 1/4 bring-up ==="
"$BRING_UP" "${NO_BUILD[@]}"

info "=== 2/4 secrets (backup write PAT + OMG GitHub read + Linear + Jira) ==="
docker cp "$WIZARD" jarvis-hermes:/opt/jarvis/bin/jarvis-secrets-wizard.sh
docker exec jarvis-hermes chmod 755 /opt/jarvis/bin/jarvis-secrets-wizard.sh
docker exec -it jarvis-hermes /opt/jarvis/bin/jarvis-secrets-wizard.sh \
  --in-container --require-backup --require-integrations
docker restart jarvis-hermes
sleep 4

info "=== 3/4 backup repo init + first push ==="
"$BACKUP" --init
"$BACKUP"

info "=== 4/4 nightly cron ==="
if [[ "$SKIP_CRON" -eq 1 ]]; then
  info "WARNING: --skip-cron used — full fidelity incomplete until:"
  info "  $CRON_INSTALL"
else
  "$CRON_INSTALL"
fi

info "=== validate ==="
"$SMOKE" || die "smoke failed after setup"
info "FULL SETUP COMPLETE"
info "  container: jarvis-hermes"
info "  volume: ${JARVIS_VOLUME_SPEC}"
info "  backup: nightly via host cron → private git (adaptive state only)"
info "  agent-tools: backup text is evolution signal (digests/state), not skill SoT"
info "  promote lab→server: hermes/scripts/jarvis-promote.sh --ssh user@host --remote-repo … --image …"
