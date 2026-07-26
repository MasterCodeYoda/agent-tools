#!/usr/bin/env bash
# Launch the Kevin operator control plane (Hermes web dashboard, kevin-scoped).
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: kevin-control-plane.sh [options] [-- hermes-dashboard-args...]

Launch Hermes web dashboard scoped to profile "kevin" (no personal default bleed).

Options:
  --status     Show dashboard process status and exit
  --stop       Stop running Hermes web servers and exit
  --no-open    Do not open a browser
  --port N     Dashboard port (default: Hermes default 9119)
  -h, --help   Show this help

Environment:
  Requires: hermes on PATH; profile kevin installed
    (./scripts/apply-kevin-profile.sh)

Docs: docs/runbooks/kevin-control-plane.md
EOF
}

STATUS=0
STOP=0
NO_OPEN=0
PORT=""
EXTRA=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --status) STATUS=1; shift ;;
    --stop) STOP=1; shift ;;
    --no-open) NO_OPEN=1; shift ;;
    --port) PORT="$2"; shift 2 ;;
    --) shift; EXTRA+=("$@"); break ;;
    *) EXTRA+=("$1"); shift ;;
  esac
done

if ! command -v hermes >/dev/null 2>&1; then
  echo "error: hermes CLI not found on PATH" >&2
  exit 1
fi

if ! hermes profile show kevin >/dev/null 2>&1; then
  echo "error: Hermes profile 'kevin' not found." >&2
  echo "  Apply config-as-code: ./scripts/apply-kevin-profile.sh" >&2
  exit 1
fi

if [[ "$STOP" -eq 1 ]]; then
  exec hermes -p kevin dashboard --stop
fi
if [[ "$STATUS" -eq 1 ]]; then
  exec hermes -p kevin dashboard --status
fi

ARGS=(dashboard --isolated)
if [[ -n "$PORT" ]]; then
  ARGS+=(--port "$PORT")
fi
if [[ "$NO_OPEN" -eq 1 ]]; then
  ARGS+=(--no-open)
fi
ARGS+=("${EXTRA[@]+"${EXTRA[@]}"}")

echo "→ hermes -p kevin ${ARGS[*]}"
echo "  Isolated kevin-scoped dashboard (not personal default profile)."
echo "  Policy SoT: hermes/profile/ in software-factory (re-apply after intentional policy changes)."
exec hermes -p kevin "${ARGS[@]}"
