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
#   ./hermes/scripts/jarvis-setup.sh --no-build
#   ./hermes/scripts/jarvis-setup.sh --skip-cron     # emergency only; prints residual
#   ./hermes/scripts/jarvis-setup.sh --check         # validate install without prompts
#
# Local packaging smoke (no backup): use jarvis-local-smoke.sh instead.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRING_UP="${SCRIPT_DIR}/jarvis-bring-up.sh"
SMOKE="${SCRIPT_DIR}/jarvis-local-smoke.sh"
WIZARD="${SCRIPT_DIR}/jarvis-secrets-wizard.sh"
BACKUP="${SCRIPT_DIR}/jarvis-backup-state.sh"
CRON_INSTALL="${SCRIPT_DIR}/jarvis-install-backup-cron.sh"

export JARVIS_HERMES_IMAGE="${JARVIS_HERMES_IMAGE:-jarvis-hermes:local}"
export JARVIS_VOLUME_SPEC="${JARVIS_VOLUME_SPEC:-jarvis-hermes-data}"

NO_BUILD=()
SKIP_CRON=0
CHECK_ONLY=0

die() { echo "jarvis-setup: error: $*" >&2; exit 1; }
info() { echo "jarvis-setup: $*" >&2; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-build) NO_BUILD=(--no-build); shift ;;
    --skip-cron) SKIP_CRON=1; shift ;;
    --check) CHECK_ONLY=1; shift ;;
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

info "=== 1/4 bring-up ==="
"$BRING_UP" "${NO_BUILD[@]}"

info "=== 2/4 secrets (backup write PAT + OMG GitHub read + Linear + Jira) ==="
# Prefer in-container wizard (baked in image); always refresh script from repo for latest prompts
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
