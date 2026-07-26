#!/usr/bin/env bash
# dev.sh — build kevin-hermes from *this* agent-tools checkout and run it locally.
#
# For developers changing profile / Dockerfile / entrypoint / process pack.
# Not a client install CLI and not a GHCR distribution tool.
#
# Cross-platform: macOS, Linux, WSL, Git Bash (requires Docker + bash).
#
# Usage:
#   ./hermes/dev.sh                          # build from source, then up
#   ./hermes/dev.sh -p ~/code/my-app         # mount product repo
#   ./hermes/dev.sh up --no-build            # reuse last local image (tight loop)
#   ./hermes/dev.sh down | logs | status | restart | build
#
# Env (optional):
#   KEVIN_PROJECT_ROOT   product git repo (default: cwd if .git)
#   KEVIN_HERMES_DATA    Hermes volume (default: ~/.kevin/hermes-data)
#   HERMES_UID / HERMES_GID  (default: current user)
#
set -euo pipefail

SCRIPT_PATH="${BASH_SOURCE[0]}"
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

die() { echo "dev.sh: error: $*" >&2; exit 1; }
info() { echo "dev.sh: $*" >&2; }

usage() {
  cat <<'EOF'
dev.sh — build kevin-hermes from this agent-tools checkout and run it on local Docker

Usage:
  ./hermes/dev.sh [command] [options]

Commands:
  up         Build from source (default), then start container (default command)
  down       Stop and remove the container
  restart    down + up
  build      Build local image only (kevin-hermes:local)
  logs       Follow container logs
  status     Show container status
  help       This message

Options (up / restart):
  --project, -p DIR   Product repo to mount as /workspace
                      (default: $KEVIN_PROJECT_ROOT, else cwd if git)
  --data DIR          Hermes data volume (default: ~/.kevin/hermes-data)
  --no-build          Skip docker build; reuse existing kevin-hermes:local

Examples:
  ./hermes/dev.sh -p ~/Source/my-app
  ./hermes/dev.sh up --no-build
  ./hermes/dev.sh logs
  ./hermes/dev.sh down

Distribution (pull GHCR / install a client `kevin` on PATH) is out of scope here.
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
    HERMES_UID="$(id -u 2>/dev/null || echo 1000)"
  fi
  if [[ -z "${HERMES_GID:-}" ]] && command -v id >/dev/null 2>&1; then
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
    KEVIN_HERMES_DATA="${KEVIN_HERMES_DATA/#\~/$HOME}"
  fi
  mkdir -p "$KEVIN_HERMES_DATA"
  export KEVIN_HERMES_DATA
}

compose() {
  [[ -f "$COMPOSE_FILE" ]] || die "missing $COMPOSE_FILE"
  export KEVIN_HERMES_IMAGE="$LOCAL_IMAGE"
  (
    cd "$REPO_ROOT"
    env \
      KEVIN_PROJECT_ROOT="$KEVIN_PROJECT_ROOT" \
      KEVIN_HERMES_DATA="$KEVIN_HERMES_DATA" \
      KEVIN_HERMES_IMAGE="$LOCAL_IMAGE" \
      HERMES_UID="$HERMES_UID" \
      HERMES_GID="$HERMES_GID" \
      "${COMPOSE[@]}" -f "$COMPOSE_FILE" "$@"
  )
}

cmd_build() {
  need_docker
  [[ -f "$DOCKERFILE" ]] || die "missing $DOCKERFILE"
  info "building ${LOCAL_IMAGE} from ${REPO_ROOT} …"
  (
    cd "$REPO_ROOT"
    docker build -f "$DOCKERFILE" -t "$LOCAL_IMAGE" .
  )
  info "built ${LOCAL_IMAGE}"
}

cmd_up() {
  need_docker
  default_uid_gid
  resolve_project_root
  resolve_data_dir

  if [[ "${NO_BUILD:-0}" == "1" ]]; then
    docker image inspect "$LOCAL_IMAGE" >/dev/null 2>&1 \
      || die "no ${LOCAL_IMAGE} — run without --no-build, or: $0 build"
    info "skipping build (--no-build)"
  else
    cmd_build
  fi

  info "project=${KEVIN_PROJECT_ROOT}"
  info "data=${KEVIN_HERMES_DATA}"
  info "image=${LOCAL_IMAGE}"
  compose up -d
  info "running — logs: $0 logs"
  compose ps
}

cmd_down() {
  need_docker
  export KEVIN_PROJECT_ROOT="${KEVIN_PROJECT_ROOT:-${PWD}}"
  export KEVIN_HERMES_DATA="${KEVIN_HERMES_DATA:-${HOME}/.kevin/hermes-data}"
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

CMD=""
PROJECT_ARG=""
DATA_ARG=""
NO_BUILD=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    up|down|restart|build|logs|status|help|-h|--help)
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
    --no-build) NO_BUILD=1; shift ;;
    --build|--pull|--local|--image)
      die "$1 is not supported (dev.sh always builds from this checkout; use --no-build to reuse local image only)"
      ;;
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
  logs) cmd_logs ;;
  status) cmd_status ;;
  *) die "unknown command: $CMD" ;;
esac
