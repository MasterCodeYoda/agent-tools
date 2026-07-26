#!/usr/bin/env bash
# kevin-controller.sh — project chrome + disk-gated judgment (KEVN-10)
#
# Read-only lens on the project. Does not claim work, invent NEXT, or write session-state.
# Profile reminder: hermes -p kevin. Process SoT remains agent-tools.
#
# Usage:
#   ./scripts/kevin-controller.sh status [--json] [--root PATH]
#   ./scripts/kevin-controller.sh decide [--json] [--chrome] [--root PATH]
#   ./scripts/kevin-controller.sh help
#
# decide exit codes:
#   0  continue  — claimable unit present; no human gate / thrash / theater soft-check
#  10  idle      — no claimable unit (do not invent NEXT)
#  20  escalate  — human/judgment gate required
#   2  error     — bad args / unreadable project root
#
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: kevin-controller.sh <status|decide|help> [options]

Project chrome and disk-gated judgment for Kevin (lean A). Read-only.

Commands:
  status   Standing chrome: phase, model map, capacity, yield/stuck
  decide   Print continue|escalate|idle + reason codes; set exit code
  help     This message

Options:
  --root PATH   Project root (default: cwd, or KEVIN_PROJECT_ROOT / FACTORY_WAKE_ROOT)
  --json        Machine-oriented key=value blocks (still plain text; stable keys)
  --chrome      With decide: also print status chrome before decision

Exit codes (decide only):
  0  continue
  10 idle
  20 escalate
  2  error

Docs: docs/runbooks/kevin-controller.md
EOF
}

ROOT="${KEVIN_PROJECT_ROOT:-${FACTORY_WAKE_ROOT:-}}"
JSON=0
CHROME=0
CMD=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help|help)
      usage
      exit 0
      ;;
    status|decide)
      CMD="$1"
      shift
      ;;
    --root)
      ROOT="$2"
      shift 2
      ;;
    --json)
      JSON=1
      shift
      ;;
    --chrome)
      CHROME=1
      shift
      ;;
    *)
      echo "kevin-controller: unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "${CMD}" ]]; then
  usage >&2
  exit 2
fi

if [[ -z "${ROOT}" ]]; then
  ROOT="$(pwd)"
fi
ROOT="$(cd "$ROOT" && pwd)"

PLANNING="$ROOT/.agent-tools/planning"
RUNS="$ROOT/.agent-tools/runs"
SWARM_ACTIVE="$ROOT/.agent-tools/parallel/active-run"
PROFILE_CFG="$ROOT/hermes/profile/config.yaml"
HIERARCHY="$ROOT/packs/kevin-model-hierarchy.md"

if [[ ! -d "$PLANNING" ]]; then
  echo "kevin-controller: planning root missing: $PLANNING" >&2
  exit 2
fi

# --- helpers ---------------------------------------------------------------

# Extract first YAML frontmatter block (between --- lines) from a file.
frontmatter() {
  local f="$1"
  [[ -f "$f" ]] || return 0
  awk '
    BEGIN { in_fm=0; n=0 }
    /^---[[:space:]]*$/ {
      n++
      if (n==1) { in_fm=1; next }
      if (n==2) { exit }
    }
    in_fm { print }
  ' "$f"
}

# Get scalar value for key from frontmatter text (simple "key: value" lines).
fm_get() {
  local key="$1"
  local text="$2"
  printf '%s\n' "$text" | awk -v k="$key" '
    $0 ~ "^" k ":[[:space:]]*" {
      sub("^" k ":[[:space:]]*", "")
      gsub(/^["'\'']|["'\'']$/, "")
      print
      exit
    }
  '
}

emit() {
  if [[ "$JSON" -eq 1 ]]; then
    printf '%s=%s\n' "$1" "$2"
  else
    printf '%s: %s\n' "$1" "$2"
  fi
}

# --- scan project ------------------------------------------------------------

NEXT_UNIT=""
TOP_STATUS=""
if [[ -f "$PLANNING/session-state.md" ]]; then
  TOP_FM="$(frontmatter "$PLANNING/session-state.md")"
  NEXT_UNIT="$(fm_get next_unit "$TOP_FM")"
  TOP_STATUS="$(fm_get status "$TOP_FM")"
fi

# Fallback: grep NEXT markdown for KEVN-#### if frontmatter empty
if [[ -z "$NEXT_UNIT" && -f "$PLANNING/session-state.md" ]]; then
  NEXT_UNIT="$(
    awk '
      /^\*\*KEVN-[0-9]+/ {
        if (match($0, /KEVN-[0-9]+/)) { print substr($0, RSTART, RLENGTH); exit }
      }
      /^## NEXT/ { next_sec=1; next }
      next_sec && /KEVN-[0-9]+/ {
        if (match($0, /KEVN-[0-9]+/)) { print substr($0, RSTART, RLENGTH); exit }
      }
    ' "$PLANNING/session-state.md" || true
  )"
fi

IN_PROGRESS_UNITS=()
PENDING_GATES=()
THEATER_UNITS=()
THRASH_UNITS=()

shopt -s nullglob
for ss in "$PLANNING"/*/session-state.md; do
  slug="$(basename "$(dirname "$ss")")"
  # skip non-unit noise if any
  fm="$(frontmatter "$ss")"
  st="$(fm_get status "$fm")"
  # normalize
  case "$st" in
    in_progress|implementing|executing|planned) ;;
    *)
      # also treat pending_gate without complete as interesting when status complete? no
      continue
      ;;
  esac
  # Some units use status: in_progress; others use complete/done — only live work
  if [[ "$st" == "in_progress" || "$st" == "implementing" || "$st" == "executing" ]]; then
    wi="$(fm_get work_item "$fm")"
    [[ -z "$wi" ]] && wi="$slug"
    IN_PROGRESS_UNITS+=("$wi")
    pg="$(fm_get pending_gate "$fm")"
    if [[ -n "$pg" && "$pg" != "none" && "$pg" != "null" ]]; then
      PENDING_GATES+=("$wi:$pg")
    fi
    rev="$(fm_get review "$fm")"
    if [[ -n "$rev" && "$rev" != "null" ]]; then
      if ! printf '%s' "$rev" | grep -q 'method='; then
        THEATER_UNITS+=("$wi")
      fi
    fi
    thrash="$(fm_get thrash_bound_hits "$fm")"
    # thrash may be nested under reentry_counts — also scan raw file
    if [[ -z "$thrash" ]]; then
      thrash="$(grep -E '^thrash_bound_hits:' "$ss" 2>/dev/null | head -1 | sed 's/.*:[[:space:]]*//' || true)"
    fi
    if [[ -n "$thrash" && "$thrash" != "0" && "$thrash" != "null" ]]; then
      THRASH_UNITS+=("$wi")
    fi
    # reentry sum > 2
    r1="$(grep -E 'refine_from_execute_or_review:' "$ss" 2>/dev/null | head -1 | sed 's/.*:[[:space:]]*//' || echo 0)"
    r2="$(grep -E 'plan_from_execute_or_review:' "$ss" 2>/dev/null | head -1 | sed 's/.*:[[:space:]]*//' || echo 0)"
    r1="${r1:-0}"
    r2="${r2:-0}"
    if [[ "$r1" =~ ^[0-9]+$ && "$r2" =~ ^[0-9]+$ ]]; then
      if (( r1 + r2 > 2 )); then
        THRASH_UNITS+=("$wi")
      fi
    fi
  fi
done
shopt -u nullglob

SWARM_RUN=""
if [[ -f "$SWARM_ACTIVE" ]]; then
  SWARM_RUN="$(tr -d '[:space:]' <"$SWARM_ACTIVE" || true)"
fi

MODEL_DEFAULT=""
MODEL_PROVIDER=""
if [[ -f "$PROFILE_CFG" ]]; then
  MODEL_DEFAULT="$(awk '/^model:/{m=1;next} m&&/^[^[:space:]#]/{exit} m&&/default:/{sub(/.*default:[[:space:]]*/,""); print; exit}' "$PROFILE_CFG" || true)"
  MODEL_PROVIDER="$(awk '/^model:/{m=1;next} m&&/^[^[:space:]#]/{exit} m&&/provider:/{sub(/.*provider:[[:space:]]*/,""); print; exit}' "$PROFILE_CFG" || true)"
fi

LAST_EVENT=""
if [[ -f "$RUNS/events.ndjson" ]]; then
  LAST_EVENT="$(tail -n 1 "$RUNS/events.ndjson" 2>/dev/null || true)"
fi

# --- status chrome ---------------------------------------------------------

print_status() {
  if [[ "$JSON" -eq 1 ]]; then
    emit project_root "$ROOT"
    emit profile "kevin"
    emit next_unit "${NEXT_UNIT:-}"
    emit top_status "${TOP_STATUS:-}"
    emit in_progress "$(IFS=,; echo "${IN_PROGRESS_UNITS[*]:-}")"
    emit pending_gates "$(IFS=,; echo "${PENDING_GATES[*]:-}")"
    emit swarm_active "${SWARM_RUN:-}"
    emit model_default "${MODEL_DEFAULT:-}"
    emit model_provider "${MODEL_PROVIDER:-}"
    emit model_hierarchy_doc "packs/kevin-model-hierarchy.md"
    emit capacity "best-available via control plane / hermes dashboard (see docs/runbooks/kevin-control-plane.md)"
    emit thrash_units "$(IFS=,; echo "${THRASH_UNITS[*]:-}")"
    emit theater_units "$(IFS=,; echo "${THEATER_UNITS[*]:-}")"
    emit last_run_event "${LAST_EVENT:-}"
    return
  fi

  cat <<EOF
=== Kevin project chrome ===
Project root:     $ROOT
Profile:        kevin (Hermes host; process SoT = agent-tools)

--- Phase ---
NEXT:           ${NEXT_UNIT:-"(none — do not invent)"}
Top status:     ${TOP_STATUS:-"(unknown)"}
In progress:    ${IN_PROGRESS_UNITS[*]:-(none)}
Pending gates:  ${PENDING_GATES[*]:-(none)}
Swarm active:   ${SWARM_RUN:-"(none)"}

--- Model map ---
Profile default: ${MODEL_DEFAULT:-"(missing hermes/profile/config.yaml)"}
Provider:        ${MODEL_PROVIDER:-"(unknown)"}
Hierarchy:       packs/kevin-model-hierarchy.md
Turn override:   hermes -p kevin -m … / dashboard (KEVN-4)

--- Capacity / windows ---
Best-available via operator control plane (Hermes dashboard):
  ./scripts/kevin-control-plane.sh
  docs/runbooks/kevin-control-plane.md
Project does not store subscription windows on disk.

--- Yield / stuck ---
Thrash flags:   ${THRASH_UNITS[*]:-(none)}
Review theater: ${THEATER_UNITS[*]:-(none)}
Last run event: ${LAST_EVENT:-"(none)"}

Lens only — does not write project state.
EOF
}

# --- decide ----------------------------------------------------------------

# Decision codes space-separated
CODES=()
DECISION=""
REASON=""
UNIT_HINT=""

run_decide() {
  if [[ -n "$SWARM_RUN" ]]; then
    DECISION="escalate"
    REASON="swarm run active; orchestrator owns in-flight items"
    CODES+=("E-SWARM")
    UNIT_HINT="$SWARM_RUN"
    return
  fi

  # Human gates on in-progress units
  if [[ ${#PENDING_GATES[@]} -gt 0 ]]; then
    DECISION="escalate"
    REASON="pending human gate on in-progress unit"
    CODES+=("E-GATE")
    UNIT_HINT="${PENDING_GATES[0]}"
    return
  fi

  if [[ ${#THEATER_UNITS[@]} -gt 0 ]]; then
    DECISION="escalate"
    REASON="review theater (review: missing method=)"
    CODES+=("E-REVIEW")
    UNIT_HINT="${THEATER_UNITS[0]}"
    return
  fi

  if [[ ${#THRASH_UNITS[@]} -gt 0 ]]; then
    DECISION="escalate"
    REASON="thrash bound signal"
    CODES+=("E-THRASH")
    UNIT_HINT="${THRASH_UNITS[0]}"
    return
  fi

  # Claimable?
  if [[ ${#IN_PROGRESS_UNITS[@]} -gt 0 ]]; then
    DECISION="continue"
    REASON="in_progress unit"
    UNIT_HINT="${IN_PROGRESS_UNITS[0]}"
    CODES+=("SAFE_BAND")
    return
  fi

  if [[ -n "$NEXT_UNIT" ]]; then
    DECISION="continue"
    REASON="named NEXT claimable"
    UNIT_HINT="$NEXT_UNIT"
    CODES+=("CLAIMABLE")
    return
  fi

  DECISION="idle"
  REASON="no claimable unit — do not invent NEXT"
  CODES+=("E-PATH")
  UNIT_HINT=""
}

print_decision() {
  local codes_joined
  codes_joined="$(IFS=,; echo "${CODES[*]}")"
  if [[ "$JSON" -eq 1 ]]; then
    emit decision "$DECISION"
    emit reason "$REASON"
    emit unit "${UNIT_HINT:-}"
    emit codes "${codes_joined}"
  else
    cat <<EOF
=== Kevin controller decide ===
decision: $DECISION
reason:   $REASON
unit:     ${UNIT_HINT:-(none)}
codes:    ${codes_joined:-(none)}
EOF
  fi
}

exit_for_decision() {
  case "$DECISION" in
    continue) exit 0 ;;
    idle) exit 10 ;;
    escalate) exit 20 ;;
    *) exit 2 ;;
  esac
}

# --- main ------------------------------------------------------------------

case "$CMD" in
  status)
    print_status
    exit 0
    ;;
  decide)
    if [[ "$CHROME" -eq 1 ]]; then
      print_status
      echo ""
    fi
    run_decide
    print_decision
    exit_for_decision
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
