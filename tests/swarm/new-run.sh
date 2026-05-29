#!/usr/bin/env bash
#
# tests/swarm/new-run.sh — start a /swarm test-harness run.
#
# Convenience wrapper for step 1 of the harness loop: generate a throwaway repo
# for a scenario and print the exact next commands. The /swarm run itself is
# agent-driven (an agent session interprets the skill), so this script stops at
# the boundary — it generates the repo and hands you the ready-to-run commands.
#
# Usage:
#   tests/swarm/new-run.sh [scenario]     # default: cli-task-manager
#   tests/swarm/new-run.sh --list         # list available scenarios
#   tests/swarm/new-run.sh --path <scn>   # print ONLY the run dir (for: cd "$(... --path x)")
#
# Runs from anywhere (resolves the repo root from this script's location).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCENARIOS_DIR="$SCRIPT_DIR/scenarios"

list_scenarios() {
    for d in "$SCENARIOS_DIR"/*/; do
        [ -d "$d" ] && echo "  - $(basename "$d")"
    done
}

PATH_ONLY=false
case "${1:-}" in
    -h|--help)
        echo "usage: tests/swarm/new-run.sh [scenario]   (default: cli-task-manager)"
        echo "       tests/swarm/new-run.sh --list"
        echo "       tests/swarm/new-run.sh --path <scenario>"
        echo "scenarios:"
        list_scenarios
        exit 0
        ;;
    --list)
        echo "scenarios:"
        list_scenarios
        exit 0
        ;;
    --path)
        PATH_ONLY=true
        shift
        ;;
esac

scenario="${1:-cli-task-manager}"

if [[ ! -d "$SCENARIOS_DIR/$scenario" ]]; then
    echo "error: unknown scenario '$scenario'" >&2
    echo "available scenarios:" >&2
    list_scenarios >&2
    exit 1
fi

cd "$REPO_ROOT"

if [[ "$PATH_ONLY" == true ]]; then
    # Print only the run dir on stdout, so callers can:  cd "$(tests/swarm/new-run.sh --path cli-task-manager)"
    # Progress/instructions go to stderr.
    python3 -m tests.swarm.harness generate "$scenario" 1>&2
    ls -dt "$SCRIPT_DIR/runs/${scenario}-"* | head -1
else
    exec python3 -m tests.swarm.harness generate "$scenario"
fi
