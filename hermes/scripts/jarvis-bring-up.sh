#!/usr/bin/env bash
# Idempotent Jarvis single-remote bring-up (volume + image + compose).
# Secrets: optional guided wizard (no LLM) — see jarvis-secrets-wizard.sh
#
# Usage (from agent-tools repo root or any cwd):
#   ./hermes/scripts/jarvis-bring-up.sh              # ensure volume, build if needed, up
#   ./hermes/scripts/jarvis-bring-up.sh --no-build   # reuse existing image
#   ./hermes/scripts/jarvis-bring-up.sh --secrets     # bring-up then secrets wizard
#   ./hermes/scripts/jarvis-bring-up.sh --status      # print paths + container status
#   ./hermes/scripts/jarvis-bring-up.sh --down
#
# Env:
#   JARVIS_HERMES_DATA   default: $HOME/.jarvis/hermes-data  (production volume)
#   JARVIS_HERMES_IMAGE  default: jarvis-hermes:local
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HERMES_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${HERMES_DIR}/.." && pwd)"
COMPOSE_FILE="${HERMES_DIR}/docker/compose.jarvis.yaml"
DOCKERFILE="${HERMES_DIR}/docker/Dockerfile.jarvis"
WIZARD="${SCRIPT_DIR}/jarvis-secrets-wizard.sh"

DATA_DIR="${JARVIS_HERMES_DATA:-${HOME}/.jarvis/hermes-data}"
IMAGE="${JARVIS_HERMES_IMAGE:-jarvis-hermes:local}"
NO_BUILD=0
RUN_SECRETS=0
DO_DOWN=0
DO_STATUS=0

die() { echo "jarvis-bring-up: error: $*" >&2; exit 1; }
info() { echo "jarvis-bring-up: $*" >&2; }

usage() {
  sed -n '2,20p' "$0" | sed 's/^# \?//'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-build) NO_BUILD=1; shift ;;
    --secrets) RUN_SECRETS=1; shift ;;
    --down) DO_DOWN=1; shift ;;
    --status) DO_STATUS=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done

command -v docker >/dev/null 2>&1 || die "docker not on PATH"
[[ -f "$COMPOSE_FILE" ]] || die "missing compose: $COMPOSE_FILE"

export JARVIS_HERMES_DATA="$DATA_DIR"
export JARVIS_HERMES_IMAGE="$IMAGE"

compose() {
  docker compose -f "$COMPOSE_FILE" "$@"
}

profile_env_path() {
  # Hermes may nest under profiles/jarvis or similar after first start.
  local candidates=(
    "${DATA_DIR}/profiles/jarvis/.env"
    "${DATA_DIR}/hermes/profiles/jarvis/.env"
  )
  local c
  for c in "${candidates[@]}"; do
    if [[ -f "$c" ]] || [[ -d "$(dirname "$c")" ]]; then
      echo "$c"
      return 0
    fi
  done
  # Default path we will create after first up if missing
  echo "${DATA_DIR}/profiles/jarvis/.env"
}

if [[ "$DO_STATUS" -eq 1 ]]; then
  info "JARVIS_HERMES_DATA=$DATA_DIR"
  info "JARVIS_HERMES_IMAGE=$IMAGE"
  info "compose=$COMPOSE_FILE"
  if [[ -d "$DATA_DIR" ]]; then
    info "volume: present ($(du -sh "$DATA_DIR" 2>/dev/null | awk '{print $1}'))"
  else
    info "volume: missing (will create on bring-up)"
  fi
  compose ps 2>/dev/null || true
  envf="$(profile_env_path)"
  if [[ -f "$envf" ]]; then
    info "live .env: $envf (exists; contents not shown)"
  else
    info "live .env: not yet at $envf"
  fi
  exit 0
fi

if [[ "$DO_DOWN" -eq 1 ]]; then
  info "stopping compose (volume preserved at $DATA_DIR)"
  compose down
  exit 0
fi

# ── Idempotent volume ──────────────────────────────────────────────
if [[ ! -d "$DATA_DIR" ]]; then
  mkdir -p "$DATA_DIR"
  info "created volume directory: $DATA_DIR"
else
  info "volume directory exists: $DATA_DIR"
fi
# Pre-seed adaptive state on host so it is visible even before entrypoint (optional)
STATE_SEED="${DATA_DIR}/profiles/jarvis/state"
if [[ ! -f "${STATE_SEED}/projects.md" ]]; then
  mkdir -p "${STATE_SEED}/digests"
  cat > "${STATE_SEED}/projects.md" <<'EOF'
# In-flight projects

<!-- Seed projects here. Survives profile re-apply (adaptive state lane). -->
EOF
  info "seeded ${STATE_SEED}/projects.md"
fi

# ── Image ──────────────────────────────────────────────────────────
if [[ "$NO_BUILD" -eq 0 ]]; then
  if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
    info "image $IMAGE missing — building from $DOCKERFILE"
    docker build -f "$DOCKERFILE" -t "$IMAGE" "$REPO_ROOT"
  else
    info "image $IMAGE present (use rebuild: docker build -f hermes/docker/Dockerfile.jarvis -t $IMAGE .)"
  fi
else
  docker image inspect "$IMAGE" >/dev/null 2>&1 || die "image $IMAGE missing; omit --no-build to build"
fi

# ── Up ─────────────────────────────────────────────────────────────
info "compose up -d"
compose up -d

# Brief wait for entrypoint
sleep 2
if compose ps | grep -q jarvis; then
  info "container running"
else
  info "warning: container not listed as running — check: docker compose -f $COMPOSE_FILE logs"
fi

info "volume SoT: $DATA_DIR"
info "ops: docker exec jarvis-hermes hermes -p jarvis doctor"
info "talk: Slack (see docs/agents/runbooks/jarvis-slack.md) — not terminal"

if [[ "$RUN_SECRETS" -eq 1 ]]; then
  [[ -x "$WIZARD" ]] || die "secrets wizard missing or not executable: $WIZARD"
  exec "$WIZARD" --data-dir "$DATA_DIR"
fi

info "secrets: run ./hermes/scripts/jarvis-secrets-wizard.sh  (or re-run bring-up with --secrets)"
