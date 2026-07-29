# shellcheck shell=bash
# Image update check / enact / poll. Requires common.sh.
# Ops artifacts live on the Docker volume (not host FS path units).

REQUEST_TTL_SEC="${JARVIS_HOST_REQUEST_TTL_SEC:-86400}"

_ops_rel() { echo "profiles/jarvis/state/ops"; }

_json_escape() {
  # minimal escape for embedding strings in JSON
  printf '%s' "$1" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read())[1:-1])' 2>/dev/null \
    || printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

_running_image_id() {
  docker inspect --format '{{.Image}}' "${JARVIS_CONTAINER_NAME}" 2>/dev/null || echo ""
}

_running_image_ref() {
  docker inspect --format '{{.Config.Image}}' "${JARVIS_CONTAINER_NAME}" 2>/dev/null || echo ""
}

_write_status() {
  local available="$1" current_id="$2" target_id="$3" current_ref="$4" target_ref="$5" message="$6"
  local checked_at
  checked_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  local body
  body=$(cat <<EOF
{
  "schema": "jarvis-host.update-status/v1",
  "checked_at": "${checked_at}",
  "available": ${available},
  "current_image_id": "$( _json_escape "$current_id" )",
  "target_image_id": "$( _json_escape "$target_id" )",
  "current_image_ref": "$( _json_escape "$current_ref" )",
  "target_image_ref": "$( _json_escape "$target_ref" )",
  "channel_image": "$( _json_escape "$JARVIS_HERMES_IMAGE" )",
  "kit_version": "$( _json_escape "$(kit_version)" )",
  "message": "$( _json_escape "$message" )"
}
EOF
)
  printf '%s\n' "$body" | volume_write "$(_ops_rel)/update-status.json"
  info "wrote update-status available=${available}"
}

_write_result() {
  local ok="$1" message="$2" before="$3" after="$4"
  local finished_at
  finished_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  local body
  body=$(cat <<EOF
{
  "schema": "jarvis-host.update-result/v1",
  "finished_at": "${finished_at}",
  "ok": ${ok},
  "before_image_id": "$( _json_escape "$before" )",
  "after_image_id": "$( _json_escape "$after" )",
  "message": "$( _json_escape "$message" )"
}
EOF
)
  printf '%s\n' "$body" | volume_write "$(_ops_rel)/update-result.json"
}

cmd_update_check() {
  require_docker
  local current_id current_ref target_id
  current_id="$(_running_image_id)"
  current_ref="$(_running_image_ref)"
  info "pulling metadata for ${JARVIS_HERMES_IMAGE}…"
  if ! docker pull "$JARVIS_HERMES_IMAGE"; then
    _write_status false "$current_id" "" "$current_ref" "$JARVIS_HERMES_IMAGE" "docker pull failed (login?)"
    die "docker pull failed for ${JARVIS_HERMES_IMAGE}"
  fi
  target_id="$(docker image inspect --format '{{.Id}}' "$JARVIS_HERMES_IMAGE" 2>/dev/null || echo "")"
  if [[ -z "$current_id" ]]; then
    _write_status true "" "$target_id" "" "$JARVIS_HERMES_IMAGE" "container not running; image present on host"
    return 0
  fi
  if [[ "$current_id" == "$target_id" ]]; then
    _write_status false "$current_id" "$target_id" "$current_ref" "$JARVIS_HERMES_IMAGE" "up to date"
  else
    _write_status true "$current_id" "$target_id" "$current_ref" "$JARVIS_HERMES_IMAGE" "update available"
  fi
}

cmd_update_enact() {
  require_docker
  local force="${1:-0}"
  local before after
  before="$(_running_image_id)"

  if [[ "$force" != "1" ]]; then
    # Require status.available unless --yes forced from operator CLI with explicit flag handling below
    local status
    status="$(volume_cat "$(_ops_rel)/update-status.json" 2>/dev/null || true)"
    if [[ -z "$status" ]] || ! printf '%s' "$status" | grep -q '"available": true'; then
      die "no update available (run: jarvis-host update --check). Refuse auto-apply."
    fi
  fi

  info "pulling ${JARVIS_HERMES_IMAGE}"
  docker pull "$JARVIS_HERMES_IMAGE" || die "pull failed"

  # Optional kit self-update: if JARVIS_HOST_RELEASE_URL set and newer, reinstall (best-effort)
  if [[ -n "${JARVIS_HOST_RELEASE_URL:-}" ]]; then
    info "kit self-update check skipped unless install.sh invoked with --self-update (see docs)"
  fi

  info "recreating container (volume preserved)"
  compose up -d --force-recreate
  local i
  for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
    if docker exec "${JARVIS_CONTAINER_NAME}" hermes -p jarvis profile show jarvis >/dev/null 2>&1; then
      break
    fi
    sleep 2
  done
  after="$(_running_image_id)"
  if docker exec "${JARVIS_CONTAINER_NAME}" hermes -p jarvis profile show jarvis >/dev/null 2>&1; then
    _write_result true "update complete" "$before" "$after"
    # clear request after success
    printf '%s\n' '{"schema":"jarvis-host.update-request/v1","cleared":true}' | volume_write "$(_ops_rel)/update-request.json" || true
    info "update OK"
  else
    _write_result false "container unhealthy after recreate" "$before" "$after"
    die "update finished but profile jarvis not healthy"
  fi
}

_clear_check_request() {
  printf '%s\n' '{"schema":"jarvis-host.update-check-request/v1","cleared":true}' \
    | volume_write "$(_ops_rel)/update-check-request.json" || true
}

cmd_update_poll() {
  require_docker

  # !update / CoS "check now" → immediate check (then clear the nudge)
  local check_req
  check_req="$(volume_cat "$(_ops_rel)/update-check-request.json" 2>/dev/null || true)"
  if [[ -n "$check_req" ]] && ! printf '%s' "$check_req" | grep -q '"cleared": true'; then
    if printf '%s' "$check_req" | grep -qE '"action"[[:space:]]*:[[:space:]]*"check"'; then
      info "update-check-request present — running check now"
      cmd_update_check || true
      _clear_check_request
    fi
  fi

  local req
  req="$(volume_cat "$(_ops_rel)/update-request.json" 2>/dev/null || true)"
  [[ -n "$req" ]] || { info "no update-request"; return 0; }
  if printf '%s' "$req" | grep -q '"cleared": true'; then
    info "request cleared; nothing to do"
    return 0
  fi
  if ! printf '%s' "$req" | grep -qE '"action"[[:space:]]*:[[:space:]]*"update-image"'; then
    info "request missing action update-image; ignore"
    return 0
  fi
  # TTL: if requested_at present and older than TTL, refuse
  local requested_at
  requested_at="$(printf '%s' "$req" | python3 -c 'import sys,json,re
try:
  d=json.load(sys.stdin); print(d.get("requested_at",""))
except Exception:
  print("")' 2>/dev/null || true)"
  if [[ -n "$requested_at" ]] && have_cmd python3; then
    local age
    age="$(python3 -c "import datetime as d; print(int((d.datetime.utcnow()-d.datetime.strptime('${requested_at}','%Y-%m-%dT%H:%M:%SZ')).total_seconds()))" 2>/dev/null || echo 0)"
    if [[ "$age" -gt "$REQUEST_TTL_SEC" ]]; then
      info "request stale (age=${age}s > ${REQUEST_TTL_SEC}); refuse"
      _write_result false "stale request" "" ""
      return 0
    fi
  fi
  local status
  status="$(volume_cat "$(_ops_rel)/update-status.json" 2>/dev/null || true)"
  if [[ -z "$status" ]] || ! printf '%s' "$status" | grep -q '"available": true'; then
    info "status not available; re-check then skip if still no"
    cmd_update_check || true
    status="$(volume_cat "$(_ops_rel)/update-status.json" 2>/dev/null || true)"
    if [[ -z "$status" ]] || ! printf '%s' "$status" | grep -q '"available": true'; then
      info "still no update available; not enacting"
      return 0
    fi
  fi
  info "valid request — enacting update"
  cmd_update_enact 1
}

jarvis_host_update() {
  local mode="enact" force=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --check) mode=check; shift ;;
      --poll) mode=poll; shift ;;
      --yes) force=1; shift ;;
      -h|--help)
        echo "usage: jarvis-host update [--check|--poll|--yes]"
        return 0
        ;;
      *) die "update: unknown option: $1" ;;
    esac
  done
  case "$mode" in
    check) cmd_update_check ;;
    poll) cmd_update_poll ;;
    enact)
      if [[ "$force" -eq 1 ]]; then
        cmd_update_enact 1
      else
        # Operator manual update without Slack: require --yes to skip approve gate
        die "refuse update without approval. Use: jarvis-host update --yes (operator) or approve via Jarvis (writes request; poll enacts). Or: jarvis-host update --check"
      fi
      ;;
  esac
}
