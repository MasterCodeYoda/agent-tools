# shellcheck shell=bash
# Systemd system timer install for backup / update-check / update-poll.
# Requires common.sh. Durable path: system units only (headless).

UNIT_BACKUP="jarvis-backup-state"
UNIT_CHECK="jarvis-update-check"
UNIT_POLL="jarvis-update-poll"

_write_backup_units() {
  local run_as="$1" home="$2" cal="$3" group
  group="$(id -gn "$run_as" 2>/dev/null || echo "$run_as")"
  cat >"/etc/systemd/system/${UNIT_BACKUP}.service" <<EOF
# Managed by jarvis-host schedule
[Unit]
Description=Jarvis adaptive-state git backup
After=docker.service network-online.target
Wants=network-online.target
Requires=docker.service

[Service]
Type=oneshot
User=${run_as}
Group=${group}
WorkingDirectory=${KIT_ROOT}
Environment=HOME=${home}
Environment=JARVIS_VOLUME_NAME=${JARVIS_VOLUME_NAME}
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ExecStartPre=/bin/bash -c 'for i in 1 2 3 4 5 6 7 8; do getent hosts github.com >/dev/null 2>&1 && exit 0; sleep 3; done; exit 1'
ExecStart=${KIT_ROOT}/bin/jarvis-host backup
Nice=10
EOF
  cat >"/etc/systemd/system/${UNIT_BACKUP}.timer" <<EOF
# Managed by jarvis-host schedule
[Unit]
Description=Nightly Jarvis adaptive-state backup

[Timer]
OnCalendar=${cal}
Persistent=true
RandomizedDelaySec=5m
Unit=${UNIT_BACKUP}.service

[Install]
WantedBy=timers.target
EOF
}

_write_check_units() {
  local run_as="$1" home="$2" group
  group="$(id -gn "$run_as" 2>/dev/null || echo "$run_as")"
  cat >"/etc/systemd/system/${UNIT_CHECK}.service" <<EOF
# Managed by jarvis-host schedule
[Unit]
Description=Jarvis image update check (write status for CoS)
After=docker.service network-online.target
Wants=network-online.target

[Service]
Type=oneshot
User=${run_as}
Group=${group}
WorkingDirectory=${KIT_ROOT}
Environment=HOME=${home}
Environment=JARVIS_VOLUME_NAME=${JARVIS_VOLUME_NAME}
Environment=JARVIS_HERMES_IMAGE=${JARVIS_HERMES_IMAGE}
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ExecStart=${KIT_ROOT}/bin/jarvis-host update --check
Nice=10
EOF
  cat >"/etc/systemd/system/${UNIT_CHECK}.timer" <<EOF
# Managed by jarvis-host schedule
[Unit]
Description=Hourly Jarvis image update check

[Timer]
OnCalendar=hourly
Persistent=true
RandomizedDelaySec=10m
Unit=${UNIT_CHECK}.service

[Install]
WantedBy=timers.target
EOF
}

_write_poll_units() {
  local run_as="$1" home="$2" group
  group="$(id -gn "$run_as" 2>/dev/null || echo "$run_as")"
  cat >"/etc/systemd/system/${UNIT_POLL}.service" <<EOF
# Managed by jarvis-host schedule
[Unit]
Description=Jarvis update request poll (approve-only enact)
After=docker.service network-online.target
Wants=network-online.target

[Service]
Type=oneshot
User=${run_as}
Group=${group}
WorkingDirectory=${KIT_ROOT}
Environment=HOME=${home}
Environment=JARVIS_VOLUME_NAME=${JARVIS_VOLUME_NAME}
Environment=JARVIS_HERMES_IMAGE=${JARVIS_HERMES_IMAGE}
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ExecStart=${KIT_ROOT}/bin/jarvis-host update --poll
Nice=10
EOF
  cat >"/etc/systemd/system/${UNIT_POLL}.timer" <<EOF
# Managed by jarvis-host schedule
[Unit]
Description=Jarvis update request poll every 5 minutes

[Timer]
OnCalendar=*:0/5
Persistent=true
Unit=${UNIT_POLL}.service

[Install]
WantedBy=timers.target
EOF
}

_run_as_user() {
  if [[ "$(id -u)" -eq 0 && -n "${SUDO_USER:-}" && "${SUDO_USER}" != root ]]; then
    echo "$SUDO_USER"
  elif [[ -n "${JARVIS_BACKUP_RUN_AS:-}" ]]; then
    echo "$JARVIS_BACKUP_RUN_AS"
  else
    echo "${USER:-$(id -un)}"
  fi
}

_user_home() {
  local u="$1"
  getent passwd "$u" 2>/dev/null | cut -d: -f6 || eval echo "~$u"
}

jarvis_host_schedule() {
  local sub="${1:-}"
  shift || true
  case "$sub" in
    install)
      [[ "$(id -u)" -eq 0 ]] || die "schedule install requires root (sudo jarvis-host schedule install)"
      local u home cal
      u="$(_run_as_user)"
      [[ "$u" != root ]] || die "set JARVIS_BACKUP_RUN_AS or invoke via sudo as docker user"
      home="$(_user_home "$u")"
      cal="${JARVIS_BACKUP_ON_CALENDAR:-*-*-* 03:15:00}"
      _write_backup_units "$u" "$home" "$cal"
      _write_check_units "$u" "$home"
      _write_poll_units "$u" "$home"
      systemctl daemon-reload
      systemctl enable --now "${UNIT_BACKUP}.timer" "${UNIT_CHECK}.timer" "${UNIT_POLL}.timer"
      info "installed system timers: ${UNIT_BACKUP}, ${UNIT_CHECK}, ${UNIT_POLL} (run_as=${u})"
      systemctl list-timers --all | grep -E 'jarvis-|NEXT' || true
      ;;
    remove)
      [[ "$(id -u)" -eq 0 ]] || die "schedule remove requires root"
      systemctl disable --now "${UNIT_BACKUP}.timer" "${UNIT_CHECK}.timer" "${UNIT_POLL}.timer" 2>/dev/null || true
      rm -f \
        /etc/systemd/system/${UNIT_BACKUP}.{service,timer} \
        /etc/systemd/system/${UNIT_CHECK}.{service,timer} \
        /etc/systemd/system/${UNIT_POLL}.{service,timer}
      systemctl daemon-reload
      info "removed jarvis host timers"
      ;;
    status)
      systemctl list-timers --all 2>/dev/null | grep -E 'jarvis-|NEXT' || echo "no jarvis timers listed"
      for u in "${UNIT_BACKUP}" "${UNIT_CHECK}" "${UNIT_POLL}"; do
        echo -n "$u.timer: "
        systemctl is-enabled "${u}.timer" 2>/dev/null || echo "missing"
      done
      ;;
    *)
      die "usage: jarvis-host schedule install|status|remove"
      ;;
  esac
}
