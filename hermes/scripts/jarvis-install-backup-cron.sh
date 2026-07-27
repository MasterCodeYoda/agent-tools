#!/usr/bin/env bash
# Install host cron for nightly Jarvis adaptive-state backup (full-fidelity setup).
#
#   ./hermes/scripts/jarvis-install-backup-cron.sh
#   ./hermes/scripts/jarvis-install-backup-cron.sh --remove
#   ./hermes/scripts/jarvis-install-backup-cron.sh --schedule "15 3 * * *"
#
# Writes user crontab entry (or /etc/cron.d if root + --system).
# Requires jarvis-backup-state.sh on PATH or absolute path next to this script.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="${SCRIPT_DIR}/jarvis-backup-state.sh"
MARKER="# jarvis-backup-state (agent-tools)"
SCHEDULE="${JARVIS_BACKUP_CRON_SCHEDULE:-15 3 * * *}"  # 03:15 local daily
DO_REMOVE=0
SYSTEM=0

die() { echo "jarvis-install-backup-cron: error: $*" >&2; exit 1; }
info() { echo "jarvis-install-backup-cron: $*" >&2; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --remove) DO_REMOVE=1; shift ;;
    --schedule) SCHEDULE="${2:-}"; shift 2 ;;
    --system) SYSTEM=1; shift ;;
    -h|--help) sed -n '2,12p' "$0" | sed 's/^# \?//'; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done

[[ -x "$BACKUP" ]] || die "missing executable $BACKUP"

LOG_DIR="${HOME}/.jarvis/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="${LOG_DIR}/backup-state.log"
CRON_LINE="${SCHEDULE} ${BACKUP} >>${LOG_FILE} 2>&1 ${MARKER}"

if [[ "$SYSTEM" -eq 1 ]]; then
  [[ "$(id -u)" -eq 0 ]] || die "--system requires root"
  CRON_D="/etc/cron.d/jarvis-backup-state"
  if [[ "$DO_REMOVE" -eq 1 ]]; then
    rm -f "$CRON_D"
    info "removed $CRON_D"
    exit 0
  fi
  cat > "$CRON_D" <<EOF
# Managed by hermes/scripts/jarvis-install-backup-cron.sh
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
${SCHEDULE} root ${BACKUP} >>/var/log/jarvis-backup-state.log 2>&1
EOF
  chmod 644 "$CRON_D"
  info "installed $CRON_D"
  exit 0
fi

# User crontab
existing="$(crontab -l 2>/dev/null || true)"
filtered="$(printf '%s\n' "$existing" | grep -v 'jarvis-backup-state' || true)"

if [[ "$DO_REMOVE" -eq 1 ]]; then
  printf '%s\n' "$filtered" | crontab -
  info "removed jarvis-backup-state from user crontab"
  exit 0
fi

{
  printf '%s\n' "$filtered"
  echo "$CRON_LINE"
} | grep -v '^$' | crontab -

info "installed user crontab: $CRON_LINE"
info "log: $LOG_FILE"
info "verify: crontab -l | grep jarvis-backup"
