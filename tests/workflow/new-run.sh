#!/usr/bin/env bash
#
# tests/workflow/new-run.sh — start a workflow process harness run.
#
# Generates a throwaway repo and prints the agent drive handoff.
# The agent session is not automated.
#
# Usage:
#   tests/workflow/new-run.sh [scenario]     # default: context-compact-soft
#   tests/workflow/new-run.sh --list
#   tests/workflow/new-run.sh --path <scn>   # print ONLY the run dir
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCENARIOS_DIR="$SCRIPT_DIR/scenarios"

list_scenarios() {
    for d in "$SCENARIOS_DIR"/*/; do
        [ -d "$d" ] && [ -f "$d/scenario.yml" ] && echo "  - $(basename "$d")"
    done
}

PATH_ONLY=false
case "${1:-}" in
    -h|--help)
        echo "usage: tests/workflow/new-run.sh [scenario]   (default: context-compact-soft)"
        echo "       tests/workflow/new-run.sh --list"
        echo "       tests/workflow/new-run.sh --path <scenario>"
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

scenario="${1:-context-compact-soft}"

if [[ ! -d "$SCENARIOS_DIR/$scenario" ]]; then
    echo "error: unknown scenario '$scenario'" >&2
    echo "available scenarios:" >&2
    list_scenarios >&2
    exit 1
fi

cd "$REPO_ROOT"

if [[ "$PATH_ONLY" == true ]]; then
    python3 -m tests.workflow.harness generate "$scenario" 1>&2
    ls -dt "$SCRIPT_DIR/runs/${scenario}-"* | head -1
else
    exec python3 -m tests.workflow.harness generate "$scenario"
fi
