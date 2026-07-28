# shellcheck shell=bash
# Greenfield durable setup. Requires common.sh + schedule.sh + backup helpers.

jarvis_host_setup() {
  local secrets_dir="" image=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --from-secrets-dir) secrets_dir="${2:-}"; shift 2 ;;
      --image) image="${2:-}"; shift 2 ;;
      -h|--help)
        echo "usage: jarvis-host setup [--from-secrets-dir DIR] [--image IMAGE]"
        return 0
        ;;
      *) die "setup: unknown option: $1" ;;
    esac
  done
  [[ -n "$image" ]] && JARVIS_HERMES_IMAGE="$image"
  export JARVIS_HERMES_IMAGE

  require_docker
  info "prerequisites: docker + compose OK"
  info "image=${JARVIS_HERMES_IMAGE} volume=${JARVIS_VOLUME_NAME}"

  info "pulling image…"
  if ! docker pull "$JARVIS_HERMES_IMAGE"; then
    die "docker pull failed for ${JARVIS_HERMES_IMAGE} — if GHCR is private, run: docker login ghcr.io"
  fi

  info "compose up -d"
  compose up -d

  local i
  for i in 1 2 3 4 5 6 7 8 9 10 11 12; do
    if docker exec "${JARVIS_CONTAINER_NAME}" hermes -p jarvis profile show jarvis >/dev/null 2>&1; then
      break
    fi
    sleep 2
  done
  docker ps --format '{{.Names}}' | grep -qx "${JARVIS_CONTAINER_NAME}" \
    || die "container ${JARVIS_CONTAINER_NAME} not running — docker logs ${JARVIS_CONTAINER_NAME}"

  if [[ -n "$secrets_dir" ]]; then
    [[ -d "$secrets_dir" ]] || die "secrets dir missing: $secrets_dir"
    local envf authf
    envf="${secrets_dir}/.env"
    authf="${secrets_dir}/auth.json"
    [[ -f "$envf" ]] || die "missing ${envf}"
    info "injecting secrets from ${secrets_dir} (values not logged)"
    docker run --rm \
      -v "${JARVIS_VOLUME_NAME}:/data" \
      -v "${secrets_dir}:/in:ro" \
      alpine:3.20 \
      sh -c 'mkdir -p /data/profiles/jarvis && cp /in/.env /data/profiles/jarvis/.env && chmod 600 /data/profiles/jarvis/.env && if [ -f /in/auth.json ]; then cp /in/auth.json /data/profiles/jarvis/auth.json && chmod 600 /data/profiles/jarvis/auth.json; fi'
    docker restart "${JARVIS_CONTAINER_NAME}"
    sleep 4
  else
    info "no --from-secrets-dir: ensure secrets via wizard or inject later"
  fi

  if [[ "$(id -u)" -eq 0 ]]; then
    # shellcheck source=schedule.sh
    source "${KIT_ROOT}/lib/schedule.sh"
    jarvis_host_schedule install
  else
    info "not root: install timers with: sudo ${KIT_ROOT}/bin/jarvis-host schedule install"
  fi

  if docker exec "${JARVIS_CONTAINER_NAME}" hermes -p jarvis profile show jarvis >/dev/null 2>&1; then
    info "setup OK — profile jarvis resolvable"
  else
    die "setup incomplete — profile jarvis not available after start"
  fi
}
