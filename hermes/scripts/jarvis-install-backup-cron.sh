#!/usr/bin/env bash
# Install host schedule for nightly Jarvis adaptive-state backup (full-fidelity setup).
#
# Prefer **systemd system timer** on durable/headless hosts (fires without login).
# Ubuntu 24+ minimal often has no crontab — do not require installing cron.
#
#   # Path of record (headless / Portainer host / skynet):
#   sudo ./hermes/scripts/jarvis-install-backup-cron.sh --system
#
#   ./hermes/scripts/jarvis-install-backup-cron.sh              # same: system scope (may re-exec sudo)
#   ./hermes/scripts/jarvis-install-backup-cron.sh --user       # workstation only (needs linger)
#   ./hermes/scripts/jarvis-install-backup-cron.sh --backend cron
#   ./hermes/scripts/jarvis-install-backup-cron.sh --on-calendar "*-*-* 03:15:00"
#   ./hermes/scripts/jarvis-install-backup-cron.sh --schedule "15 3 * * *"
#   ./hermes/scripts/jarvis-install-backup-cron.sh --remove
#   ./hermes/scripts/jarvis-install-backup-cron.sh --status
#
# Design (do not move schedule into jarvis-hermes):
#   - Backup write PAT stays on the host; script uses docker CLI + host git worktree
#   - Schedule must survive agent container restarts AND host reboots without login
#   - User systemd timers are NOT durable on headless hosts unless linger is set
#     (linger also needs root — so system units are the direct fix, not linger+user)
#   - See docs/agents/runbooks/jarvis-state-backup.md
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="${SCRIPT_DIR}/jarvis-backup-state.sh"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
UNIT_NAME="jarvis-backup-state"
MARKER="# jarvis-backup-state (agent-tools)"
SCHEDULE="${JARVIS_BACKUP_CRON_SCHEDULE:-15 3 * * *}"
ON_CALENDAR="${JARVIS_BACKUP_ON_CALENDAR:-}"
BACKEND="${JARVIS_BACKUP_SCHEDULE_BACKEND:-auto}"  # auto|systemd|cron
# system = path of record for durable/headless; user = explicit workstation opt-in
SCOPE="${JARVIS_BACKUP_SCHEDULE_SCOPE:-system}"  # system|user
DO_REMOVE=0
DO_STATUS=0

die() { echo "jarvis-install-backup-cron: error: $*" >&2; exit 1; }
info() { echo "jarvis-install-backup-cron: $*" >&2; }

usage() {
  sed -n '2,28p' "$0" | sed 's/^# \?//'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --remove) DO_REMOVE=1; shift ;;
    --status) DO_STATUS=1; shift ;;
    --schedule) SCHEDULE="${2:-}"; shift 2 ;;
    --on-calendar) ON_CALENDAR="${2:-}"; shift 2 ;;
    --backend) BACKEND="${2:-}"; shift 2 ;;
    --system) SCOPE=system; shift ;;
    --user) SCOPE=user; shift ;;
    --systemd) BACKEND=systemd; shift ;;
    --cron) BACKEND=cron; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done

[[ -x "$BACKUP" ]] || die "missing executable $BACKUP"

# ── helpers ──────────────────────────────────────────────────────────

cron_schedule_to_oncalendar() {
  # Convert simple daily "M H * * *" → "*-*-* HH:MM:00"
  # noglob: unquoted * would expand to cwd files
  local sched="$1" min hour dom mon dow
  set -f
  # shellcheck disable=SC2086
  set -- $sched
  set +f
  if [[ $# -ne 5 ]]; then
    return 1
  fi
  min="$1" hour="$2" dom="$3" mon="$4" dow="$5"
  if [[ "$dom" == "*" && "$mon" == "*" && "$dow" == "*" \
    && "$min" =~ ^[0-9]+$ && "$hour" =~ ^[0-9]+$ ]]; then
    printf '%s\n' "*-*-* $(printf '%02d:%02d:00' "$hour" "$min")"
    return 0
  fi
  return 1
}

resolve_on_calendar() {
  if [[ -n "$ON_CALENDAR" ]]; then
    printf '%s\n' "$ON_CALENDAR"
    return
  fi
  if cal="$(cron_schedule_to_oncalendar "$SCHEDULE")"; then
    printf '%s\n' "$cal"
    return
  fi
  die "cannot derive OnCalendar from --schedule '$SCHEDULE'; pass --on-calendar '*-*-* HH:MM:00'"
}

have_systemctl() {
  command -v systemctl >/dev/null 2>&1
}

have_crontab() {
  command -v crontab >/dev/null 2>&1
}

detect_backend() {
  case "$BACKEND" in
    auto)
      if have_systemctl && systemctl list-unit-files >/dev/null 2>&1; then
        echo systemd
      elif have_crontab; then
        echo cron
      else
        die "no scheduler backend: host needs systemd (preferred) or cron — see jarvis-state-backup.md"
      fi
      ;;
    systemd|cron) echo "$BACKEND" ;;
    *) die "unknown --backend '$BACKEND' (use auto|systemd|cron)" ;;
  esac
}

run_user() {
  if [[ "$(id -u)" -eq 0 && -n "${SUDO_USER:-}" && "${SUDO_USER}" != root ]]; then
    printf '%s\n' "$SUDO_USER"
  elif [[ "$(id -u)" -eq 0 && -n "${JARVIS_BACKUP_RUN_AS:-}" ]]; then
    printf '%s\n' "$JARVIS_BACKUP_RUN_AS"
  else
    printf '%s\n' "${USER:-$(id -un)}"
  fi
}

user_home() {
  local u="$1"
  if command -v getent >/dev/null 2>&1; then
    getent passwd "$u" | cut -d: -f6
  else
    eval echo "~$u"
  fi
}

user_group() {
  local u="$1"
  id -gn "$u" 2>/dev/null || printf '%s\n' "$u"
}

user_uid() {
  id -u "$1"
}

# Re-exec under sudo for system-scope install when not root.
ensure_root_for_system() {
  [[ "$(id -u)" -eq 0 ]] && return 0
  local self args=()
  self="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
  # Preserve flags we already parsed
  args=(--system --backend "${BACKEND_RESOLVED:-systemd}")
  [[ -n "$ON_CALENDAR" ]] && args+=(--on-calendar "$ON_CALENDAR")
  [[ -n "$SCHEDULE" ]] && args+=(--schedule "$SCHEDULE")
  [[ "$DO_REMOVE" -eq 1 ]] && args+=(--remove)
  export JARVIS_BACKUP_RUN_AS="${JARVIS_BACKUP_RUN_AS:-$(run_user)}"
  export JARVIS_VOLUME_NAME="${JARVIS_VOLUME_NAME:-jarvis-hermes-data}"
  if command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
    info "elevating with passwordless sudo for system units…"
    exec sudo --preserve-env=JARVIS_BACKUP_RUN_AS,JARVIS_VOLUME_NAME,JARVIS_BACKUP_ON_CALENDAR,JARVIS_BACKUP_CRON_SCHEDULE \
      "$self" "${args[@]}"
  fi
  cat >&2 <<EOF
jarvis-install-backup-cron: error: system timer install needs root (durable/headless path of record).

  User systemd timers do NOT fire after reboot on a headless host unless linger is enabled,
  and enabling linger also needs root — so install system units directly:

    sudo $self --system

  Optional: sudo $self --system --on-calendar '*-*-* 03:15:00'

  Do not use --user on skynet-class hosts.
EOF
  exit 1
}

remove_user_units_for() {
  local u="$1" home unit_dir uid runtime
  home="$(user_home "$u")"
  unit_dir="${home}/.config/systemd/user"
  [[ -d "$unit_dir" ]] || return 0
  rm -f "${unit_dir}/${UNIT_NAME}.service" "${unit_dir}/${UNIT_NAME}.timer"
  uid="$(user_uid "$u" 2>/dev/null || true)"
  runtime="/run/user/${uid}"
  if [[ -n "$uid" && -S "${runtime}/bus" ]]; then
    # Best-effort: drop enable symlink while user manager is up
    sudo -u "$u" XDG_RUNTIME_DIR="$runtime" systemctl --user disable --now "${UNIT_NAME}.timer" 2>/dev/null || true
    sudo -u "$u" XDG_RUNTIME_DIR="$runtime" systemctl --user daemon-reload 2>/dev/null || true
  fi
  info "removed any user-scope units for ${UNIT_NAME} (user=${u})"
}

# ── status ───────────────────────────────────────────────────────────

do_status() {
  info "backup script: $BACKUP"
  info "repo root: $REPO_ROOT"
  if have_systemctl; then
    info "--- systemd system timer (path of record for headless) ---"
    systemctl is-enabled "${UNIT_NAME}.timer" 2>/dev/null || echo "disabled/missing"
    systemctl list-timers --all 2>/dev/null | grep -E "${UNIT_NAME}|NEXT" || true
    info "--- systemd user timer (workstation opt-in only) ---"
    systemctl --user is-enabled "${UNIT_NAME}.timer" 2>/dev/null || echo "disabled/missing"
    systemctl --user list-timers --all 2>/dev/null | grep -E "${UNIT_NAME}|NEXT" || true
  else
    info "systemctl: not available"
  fi
  info "--- cron ---"
  if have_crontab && crontab -l 2>/dev/null | grep -q jarvis-backup-state; then
    echo "user crontab: present"
    crontab -l 2>/dev/null | grep jarvis-backup-state || true
  else
    echo "user crontab: missing (or crontab binary absent)"
  fi
  if [[ -f /etc/cron.d/jarvis-backup-state ]]; then
    echo "system cron.d: present"
  else
    echo "system cron.d: missing"
  fi
  if have_systemctl; then
    local u linger
    u="$(run_user)"
    linger="$(loginctl show-user "$u" -p Linger 2>/dev/null | cut -d= -f2 || echo unknown)"
    info "loginctl Linger for ${u}: ${linger} (irrelevant if system timer is installed)"
  fi
}

if [[ "$DO_STATUS" -eq 1 ]]; then
  do_status
  exit 0
fi

BACKEND_RESOLVED="$(detect_backend)"
info "backend: $BACKEND_RESOLVED  scope: $SCOPE"

# ── unit writers ─────────────────────────────────────────────────────

write_timer_unit() {
  local cal
  cal="$(resolve_on_calendar)"
  cat <<EOF
# Managed by hermes/scripts/jarvis-install-backup-cron.sh
[Unit]
Description=Nightly Jarvis adaptive-state backup timer

[Timer]
OnCalendar=${cal}
Persistent=true
RandomizedDelaySec=5m
Unit=${UNIT_NAME}.service

[Install]
WantedBy=timers.target
EOF
}

# mode=user|system
write_service_unit() {
  local mode="$1" run_as="$2" home="$3" workdir="$4" group after requires user_lines
  group="$(user_group "$run_as")"
  after="After=network-online.target"
  requires=""
  user_lines=""
  if [[ "$mode" == system ]]; then
    after="After=docker.service network-online.target"
    requires="Requires=docker.service"
    user_lines="User=${run_as}
Group=${group}"
  fi
  cat <<EOF
# Managed by hermes/scripts/jarvis-install-backup-cron.sh
[Unit]
Description=Jarvis adaptive-state git backup (allowlisted text → private repo)
Documentation=https://github.com/MasterCodeYoda/agent-tools/blob/main/docs/agents/runbooks/jarvis-state-backup.md
${after}
Wants=network-online.target
${requires}

[Service]
Type=oneshot
${user_lines}
WorkingDirectory=${workdir}
Environment=HOME=${home}
Environment=JARVIS_VOLUME_NAME=${JARVIS_VOLUME_NAME:-jarvis-hermes-data}
# Backup PAT is read from the volume .env by the script (not injected here).
# network-online ≠ DNS ready; fail fast if GitHub never resolves (script also retries push).
ExecStartPre=/bin/bash -c 'for i in 1 2 3 4 5 6 7 8; do getent hosts github.com >/dev/null 2>&1 && exit 0; sleep 3; done; echo "jarvis-backup: github.com DNS not ready" >&2; exit 1'
ExecStart=${BACKUP}
Nice=10
EOF
}

# ── systemd ──────────────────────────────────────────────────────────

install_systemd_user() {
  local u home unit_dir linger
  u="$(run_user)"
  home="$(user_home "$u")"
  [[ -n "$home" && -d "$home" ]] || die "cannot resolve home for $u"
  unit_dir="${home}/.config/systemd/user"
  mkdir -p "$unit_dir"

  if [[ "$DO_REMOVE" -eq 1 ]]; then
    systemctl --user disable --now "${UNIT_NAME}.timer" 2>/dev/null || true
    rm -f "${unit_dir}/${UNIT_NAME}.service" "${unit_dir}/${UNIT_NAME}.timer"
    systemctl --user daemon-reload 2>/dev/null || true
    info "removed user systemd units ${UNIT_NAME}.*"
    exit 0
  fi

  linger="$(loginctl show-user "$u" -p Linger 2>/dev/null | cut -d= -f2 || echo no)"
  if [[ "$linger" != "yes" ]]; then
    die "refusing --user install: Linger≠yes for ${u}. On headless hosts use system units instead:

  sudo $0 --system

User timers without linger do not fire after reboot until someone logs in.
(Linger itself needs root — prefer --system over enable-linger + --user.)"
  fi

  write_service_unit user "$u" "$home" "$REPO_ROOT" >"${unit_dir}/${UNIT_NAME}.service"
  write_timer_unit >"${unit_dir}/${UNIT_NAME}.timer"

  systemctl --user daemon-reload
  systemctl --user enable --now "${UNIT_NAME}.timer"
  info "installed user systemd timer: ${unit_dir}/${UNIT_NAME}.timer"
  info "OnCalendar=$(resolve_on_calendar)"
  info "verify: systemctl --user list-timers | grep ${UNIT_NAME}"
}

install_systemd_system() {
  local u home unit_dir
  ensure_root_for_system
  u="$(run_user)"
  [[ "$u" != root ]] || die "refusing system unit as root-owned run: set JARVIS_BACKUP_RUN_AS=docker-user or invoke via sudo so SUDO_USER is set"
  home="$(user_home "$u")"
  unit_dir=/etc/systemd/system

  if [[ "$DO_REMOVE" -eq 1 ]]; then
    systemctl disable --now "${UNIT_NAME}.timer" 2>/dev/null || true
    rm -f "${unit_dir}/${UNIT_NAME}.service" "${unit_dir}/${UNIT_NAME}.timer"
    systemctl daemon-reload
    info "removed system systemd units ${UNIT_NAME}.*"
    remove_user_units_for "$u"
    exit 0
  fi

  write_service_unit system "$u" "$home" "$REPO_ROOT" >"${unit_dir}/${UNIT_NAME}.service"
  write_timer_unit >"${unit_dir}/${UNIT_NAME}.timer"
  systemctl daemon-reload
  systemctl enable --now "${UNIT_NAME}.timer"
  # Avoid double-fire if a prior session installed a user timer
  remove_user_units_for "$u"
  info "installed system systemd timer: ${unit_dir}/${UNIT_NAME}.timer"
  info "OnCalendar=$(resolve_on_calendar) run_as=${u}"
  info "verify: systemctl list-timers | grep ${UNIT_NAME}"
  info "smoke:  systemctl start ${UNIT_NAME}.service && journalctl -u ${UNIT_NAME}.service -n 30 --no-pager"
}

# ── cron ─────────────────────────────────────────────────────────────

install_cron_system() {
  ensure_root_for_system
  local cron_d=/etc/cron.d/jarvis-backup-state
  if [[ "$DO_REMOVE" -eq 1 ]]; then
    rm -f "$cron_d"
    info "removed $cron_d"
    exit 0
  fi
  local u
  u="$(run_user)"
  cat >"$cron_d" <<EOF
# Managed by hermes/scripts/jarvis-install-backup-cron.sh
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
${SCHEDULE} ${u} ${BACKUP} >>/var/log/jarvis-backup-state.log 2>&1
EOF
  chmod 644 "$cron_d"
  info "installed $cron_d (user ${u})"
}

install_cron_user() {
  have_crontab || die "crontab not found (Ubuntu minimal often omits cron — use systemd system timer: sudo $0 --system)"

  local log_dir="${HOME}/.jarvis/logs"
  mkdir -p "$log_dir"
  local log_file="${log_dir}/backup-state.log"
  local cron_line="${SCHEDULE} ${BACKUP} >>${log_file} 2>&1 ${MARKER}"

  local existing filtered
  existing="$(crontab -l 2>/dev/null || true)"
  filtered="$(printf '%s\n' "$existing" | grep -v 'jarvis-backup-state' || true)"

  if [[ "$DO_REMOVE" -eq 1 ]]; then
    printf '%s\n' "$filtered" | crontab -
    info "removed jarvis-backup-state from user crontab"
    exit 0
  fi

  {
    printf '%s\n' "$filtered"
    echo "$cron_line"
  } | grep -v '^$' | crontab -

  info "installed user crontab: $cron_line"
  info "log: $log_file"
  info "verify: crontab -l | grep jarvis-backup"
}

# ── dispatch ─────────────────────────────────────────────────────────

case "$BACKEND_RESOLVED" in
  systemd)
    case "$SCOPE" in
      system) install_systemd_system ;;
      user) install_systemd_user ;;
      *) die "unknown scope '$SCOPE' (use --system or --user)" ;;
    esac
    ;;
  cron)
    case "$SCOPE" in
      system) install_cron_system ;;
      user) install_cron_user ;;
      *) die "unknown scope '$SCOPE'" ;;
    esac
    ;;
esac
