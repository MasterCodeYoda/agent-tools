#!/usr/bin/env bash
# kevin-pre-wake.sh — unattended pre-wake for Kevin (worktree required)
#
# Defaults REQUIRE_WORKTREE=1. Fail-closed before hermes -p kevin continue/cron.
# Exit: 0 ok · 1 fail closed
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export KEVIN_WAKE_ROOT="${KEVIN_WAKE_ROOT:-${FACTORY_WAKE_ROOT:-$(pwd)}}"
# Unattended default: must be a linked worktree unless operator explicitly opts out.
export KEVIN_WAKE_REQUIRE_WORKTREE="${KEVIN_WAKE_REQUIRE_WORKTREE:-${FACTORY_WAKE_REQUIRE_WORKTREE:-1}}"
export KEVIN_WAKE_PRIMARY_HINT="${KEVIN_WAKE_PRIMARY_HINT:-${FACTORY_WAKE_PRIMARY_HINT:-}}"

# Mirror to legacy names for the shared checker
export FACTORY_WAKE_ROOT="$KEVIN_WAKE_ROOT"
export FACTORY_WAKE_REQUIRE_WORKTREE="$KEVIN_WAKE_REQUIRE_WORKTREE"
export FACTORY_WAKE_PRIMARY_HINT="$KEVIN_WAKE_PRIMARY_HINT"

echo "KEVIN-PRE-WAKE: root=$KEVIN_WAKE_ROOT require_worktree=$KEVIN_WAKE_REQUIRE_WORKTREE"
exec "$SCRIPT_DIR/pre-wake-project-check.sh"
