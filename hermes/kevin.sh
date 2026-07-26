#!/usr/bin/env bash
# kevin.sh — run the Kevin primary instance (kevin-hermes Docker).
#
# Cross-platform: macOS, Linux, WSL, Git Bash (requires Docker + bash).
#
# Usage:
#   ./hermes/kevin.sh                  # up (local image if present, else GHCR main)
#   ./hermes/kevin.sh up --project ~/code/my-app
#   ./hermes/kevin.sh up --build       # build local image, then up
#   ./hermes/kevin.sh pull             # pull GHCR :main, then up
#   ./hermes/kevin.sh down | logs | status | restart | build
#
# Env (optional overrides):
#   KEVIN_PROJECT_ROOT   product git repo (default: current directory if .git)
#   KEVIN_HERMES_DATA    Hermes volume   (default: ~/.kevin/hermes-data)
#   KEVIN_HERMES_IMAGE   image ref       (default: local if built, else GHCR :main)
#   HERMES_UID / HERMES_GID              (default: current user)
#
set -euo pipefail

SCRIPT_PATH="${BASH_SOURCE[0]}"
# Resolve symlinks when possible (macOS/Linux)
while [[ -L "$SCRIPT_PATH" ]]; do
  _dir="$(cd -P "$(dirname "$SCRIPT_PATH")" && pwd)"
  SCRIPT_PATH="$(readlink "$SCRIPT_PATH" 2>/dev/null || ls -l "$SCRIPT_PATH" | sed 's/.* -> //')"
  [[ "$SCRIPT_PATH" != /* ]] && SCRIPT_PATH="$_dir/$SCRIPT_PATH"
done
HERMES_DIR="$(cd -P "$(dirname "$SCRIPT_PATH")" && pwd)"
REPO_ROOT="$(cd -P "${HERMES_DIR}/.." && pwd)"
COMPOSE_FILE="${HERMES_DIR}/docker/compose.yaml"
DOCKERFILE="${HERMES_DIR}/docker/Dockerfile"
LOCAL_IMAGE="kevin-hermes:local"
GHCR_IMAGE="ghcr.io/mastercodeyoda/kevin-hermes:main"

die() { echo "kevin: error: $*" >&2; exit 1; }
info() { echo "kevin: $*" >&2; }

usage() {
  cat <<'EOF'
kevin.sh — Kevin primary instance (Docker)

Usage:
  kevin.sh [command] [options]

Commands:
  up         Start Kevin (default if no command)
  down       Stop and remove the container
  restart    down + up
  build      Build local image only (kevin-hermes:local)
  pull       Pull GHCR :main image
  logs       Follow container logs
  status     Show container status
  help       This message

Options (up / restart):
  --project, -p DIR   Product repo to mount as /workspace
                      (default: $KEVIN_PROJECT_ROOT, else cwd if git)
  --data DIR          Hermes data volume (default: ~/.kevin/hermes-data)
  --build             Build local image before up
  --pull              Pull GHCR :main before up
  --local             Force image kevin-hermes:local
  --image REF         Force image ref

Examples:
  ./hermes/kevin.sh --build -p ~/Source/my-app
  ./hermes/kevin.sh pull
  ./hermes/kevin.sh logs
  ./hermes/kevin.sh down
EOF
}

need_docker() {
  command -v docker >/dev/null 2>&1 || die "docker not found — install Docker Desktop or engine"
  docker info >/dev/null 2>&1 || die "docker is not running (start Docker Desktop / daemon)"
  if docker compose version >/dev/null 2>&1; then
    COMPOSE=(docker compose)
  elif command -v docker-compose >/dev/null 2>&1; then
    COMPOSE=(docker-compose)
  else
    die "docker compose not found"
  fi
}

# Absolute path, portable-ish (macOS/Linux/WSL/Git Bash)
abspath() {
  local p="$1"
  if command -v realpath >/dev/null 2>&1; then
    realpath "$p"
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c 'import os,sys; print(os.path.abspath(sys.argv[1]))' "$p"
  else
    (cd "$p" 2>/dev/null && pwd) || {
      local d b
      d="$(dirname "$p")"
      b="$(basename "$p")"
      (cd "$d" && echo "$(pwd)/$b")
    }
  fi
}

default_uid_gid() {
  if [[ -z "${HERMES_UID:-}" ]] && command -v id >/dev/null 2>&1; then
    export HERMES_UID
    HERMES_UID="$(id -u 2>/dev/null || echo 1000)"
  fi
  if [[ -z "${HERMES_GID:-}" ]] && command -v id >/dev/null 2>&1; then
    export HERMES_GID
    HERMES_GID="$(id -g 2>/dev/null || echo 1000)"
  fi
  export HERMES_UID="${HERMES_UID:-1000}"
  export HERMES_GID="${HERMES_GID:-1000}"
}

resolve_project_root() {
  if [[ -n "${PROJECT_ARG:-}" ]]; then
    KEVIN_PROJECT_ROOT="$(abspath "$PROJECT_ARG")"
  elif [[ -n "${KEVIN_PROJECT_ROOT:-}" ]]; then
    KEVIN_PROJECT_ROOT="$(abspath "$KEVIN_PROJECT_ROOT")"
  elif [[ -d "${PWD}/.git" || -f "${PWD}/.git" ]]; then
    KEVIN_PROJECT_ROOT="$(abspath "$PWD")"
    info "using cwd as project: ${KEVIN_PROJECT_ROOT}"
  else
    die "set product repo with --project DIR or KEVIN_PROJECT_ROOT (cwd is not a git repo)"
  fi
  [[ -d "$KEVIN_PROJECT_ROOT" ]] || die "project path not a directory: $KEVIN_PROJECT_ROOT"
  export KEVIN_PROJECT_ROOT
}

resolve_data_dir() {
  if [[ -n "${DATA_ARG:-}" ]]; then
    KEVIN_HERMES_DATA="$(abspath "$DATA_ARG")"
  else
    KEVIN_HERMES_DATA="${KEVIN_HERMES_DATA:-${HOME}/.kevin/hermes-data}"
    # Expand leading ~
    KEVIN_HERMES_DATA="${KEVIN_HERMES_DATA/#\~/$HOME}"
  fi
  mkdir -p "$KEVIN_HERMES_DATA"
  export KEVIN_HERMES_DATA
}

resolve_image() {
  if [[ -n "${IMAGE_ARG:-}" ]]; then
    KEVIN_HERMES_IMAGE="$IMAGE_ARG"
  elif [[ -n "${KEVIN_HERMES_IMAGE:-}" ]]; then
    :
  elif [[ "${FORCE_LOCAL:-0}" == "1" ]]; then
    KEVIN_HERMES_IMAGE="$LOCAL_IMAGE"
  elif docker image inspect "$LOCAL_IMAGE" >/dev/null 2>&1; then
    KEVIN_HERMES_IMAGE="$LOCAL_IMAGE"
    info "using local image ${LOCAL_IMAGE}"
  else
    KEVIN_HERMES_IMAGE="$GHCR_IMAGE"
    info "using ${GHCR_IMAGE} (no local image; pass --build to build)"
  fi
  export KEVIN_HERMES_IMAGE
}

compose() {
  [[ -f "$COMPOSE_FILE" ]] || die "missing $COMPOSE_FILE"
  (
    cd "$REPO_ROOT"
    env \
      KEVIN_PROJECT_ROOT="$KEVIN_PROJECT_ROOT" \
      KEVIN_HERMES_DATA="$KEVIN_HERMES_DATA" \
      KEVIN_HERMES_IMAGE="$KEVIN_HERMES_IMAGE" \
      HERMES_UID="$HERMES_UID" \
      HERMES_GID="$HERMES_GID" \
      "${COMPOSE[@]}" -f "$COMPOSE_FILE" "$@"
  )
}

cmd_build() {
  need_docker
  [[ -f "$DOCKERFILE" ]] || die "missing $DOCKERFILE"
  info "building ${LOCAL_IMAGE} …"
  (
    cd "$REPO_ROOT"
    docker build -f "$DOCKERFILE" -t "$LOCAL_IMAGE" .
  )
  info "built ${LOCAL_IMAGE}"
}

cmd_pull() {
  need_docker
  resolve_image
  # Prefer GHCR for pull unless --local
  if [[ "${FORCE_LOCAL:-0}" != "1" && -z "${IMAGE_ARG:-}" ]]; then
    KEVIN_HERMES_IMAGE="$GHCR_IMAGE"
    export KEVIN_HERMES_IMAGE
  fi
  info "pulling ${KEVIN_HERMES_IMAGE} …"
  docker pull "$KEVIN_HERMES_IMAGE"
}

cmd_up() {
  need_docker
  default_uid_gid
  resolve_project_root
  resolve_data_dir

  if [[ "${DO_BUILD:-0}" == "1" ]]; then
    cmd_build
    KEVIN_HERMES_IMAGE="$LOCAL_IMAGE"
    export KEVIN_HERMES_IMAGE
  elif [[ "${DO_PULL:-0}" == "1" ]]; then
    FORCE_LOCAL=0
    cmd_pull
  else
    resolve_image
  fi

  info "project=${KEVIN_PROJECT_ROOT}"
  info "data=${KEVIN_HERMES_DATA}"
  info "image=${KEVIN_HERMES_IMAGE}"
  compose up -d
  info "running — logs: $0 logs"
  compose ps
}

cmd_down() {
  need_docker
  # Compose still needs env vars even for down if file references them
  export KEVIN_PROJECT_ROOT="${KEVIN_PROJECT_ROOT:-${PWD}}"
  export KEVIN_HERMES_DATA="${KEVIN_HERMES_DATA:-${HOME}/.kevin/hermes-data}"
  export KEVIN_HERMES_IMAGE="${KEVIN_HERMES_IMAGE:-$LOCAL_IMAGE}"
  default_uid_gid
  compose down
}

cmd_logs() {
  need_docker
  docker logs -f kevin-hermes
}

cmd_status() {
  need_docker
  docker ps -a --filter name=^kevin-hermes$ --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}'
}

# ── parse ───────────────────────────────────────────────────────────
CMD=""
PROJECT_ARG=""
DATA_ARG=""
IMAGE_ARG=""
DO_BUILD=0
DO_PULL=0
FORCE_LOCAL=0

# Allow: kevin.sh --build  (implies up)  and  kevin.sh up --build
while [[ $# -gt 0 ]]; do
  case "$1" in
    up|down|restart|build|pull|logs|status|help|-h|--help)
      if [[ -z "$CMD" ]]; then
        case "$1" in
          help|-h|--help) usage; exit 0 ;;
          *) CMD="$1" ;;
        esac
      else
        die "unexpected argument: $1"
      fi
      shift
      ;;
    --project|-p)
      [[ $# -ge 2 ]] || die "$1 needs a directory"
      PROJECT_ARG="$2"
      shift 2
      ;;
    --data)
      [[ $# -ge 2 ]] || die "--data needs a directory"
      DATA_ARG="$2"
      shift 2
      ;;
    --image)
      [[ $# -ge 2 ]] || die "--image needs a ref"
      IMAGE_ARG="$2"
      shift 2
      ;;
    --build) DO_BUILD=1; shift ;;
    --pull) DO_PULL=1; shift ;;
    --local) FORCE_LOCAL=1; shift ;;
    *)
      die "unknown argument: $1 (try: $0 help)"
      ;;
  esac
done

CMD="${CMD:-up}"

case "$CMD" in
  up) cmd_up ;;
  down) cmd_down ;;
  restart) cmd_down; cmd_up ;;
  build) cmd_build ;;
  pull) need_docker; default_uid_gid; cmd_pull; DO_PULL=0; cmd_up ;;
  logs) cmd_logs ;;
  status) cmd_status ;;
  *) die "unknown command: $CMD" ;;
esac
