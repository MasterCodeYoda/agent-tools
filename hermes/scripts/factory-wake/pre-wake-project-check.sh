#!/usr/bin/env bash
#
# pre-wake-project-check.sh — fail-closed checks before unattended /work:continue
# Portable contract: process pack workflow/references/pre-wake-checklist.md
#
# Exit: 0 ok · 1 fail closed (do not claim / escalate)
#
set -euo pipefail

# Env: prefer KEVIN_WAKE_* (Kevin product); accept legacy FACTORY_WAKE_* as synonyms.
ROOT="${KEVIN_WAKE_ROOT:-${FACTORY_WAKE_ROOT:-$(pwd)}}"
REQUIRE_WORKTREE="${KEVIN_WAKE_REQUIRE_WORKTREE:-${FACTORY_WAKE_REQUIRE_WORKTREE:-0}}"
PRIMARY_HINT="${KEVIN_WAKE_PRIMARY_HINT:-${FACTORY_WAKE_PRIMARY_HINT:-}}"

fail() {
  echo "PRE-WAKE FAIL: $*" >&2
  exit 1
}

ok() {
  echo "PRE-WAKE OK: $*"
}

cd "$ROOT" || fail "cannot cd to ROOT=$ROOT"

# 1 — git repo
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || fail "not a git work tree: $ROOT"

GIT_COMMON="$(git rev-parse --git-common-dir 2>/dev/null || true)"
GIT_DIR="$(git rev-parse --git-dir 2>/dev/null || true)"
IN_WORKTREE=0
if [[ -f "${GIT_DIR}/gitdir" ]] || [[ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" == "true" && "$GIT_COMMON" != "$GIT_DIR" && "$GIT_COMMON" != .git ]]; then
  # worktree: .git is a file, or git-dir differs from common-dir
  if [[ -f "$(git rev-parse --git-dir)/../.." ]] 2>/dev/null; then
    :
  fi
  if [[ -f "$ROOT/.git" ]]; then
    IN_WORKTREE=1
  fi
fi
# More reliable: git worktree list
if git rev-parse --path-format=absolute --git-dir >/dev/null 2>&1; then
  if [[ -f "$ROOT/.git" ]]; then
    IN_WORKTREE=1
  fi
fi

# 2 — isolation policy
if [[ "$REQUIRE_WORKTREE" == "1" && "$IN_WORKTREE" != "1" ]]; then
  fail "REQUIRE_WORKTREE=1 but $ROOT is not a linked worktree (.git file)"
fi

if [[ -n "$PRIMARY_HINT" ]]; then
  # Resolve both to physical paths when possible
  root_phys="$(cd "$ROOT" && pwd -P 2>/dev/null || pwd)"
  primary_phys="$(cd "$PRIMARY_HINT" 2>/dev/null && pwd -P || echo "$PRIMARY_HINT")"
  if [[ "$root_phys" == "$primary_phys" ]]; then
    dirty="$(git status --porcelain 2>/dev/null | head -5 || true)"
    if [[ -n "$dirty" ]]; then
      fail "ROOT is primary checkout ($PRIMARY_HINT) and dirty — refuse unattended wake"
    fi
    echo "PRE-WAKE WARN: ROOT equals primary hint; prefer disposable worktree for automation" >&2
  fi
fi

# 3 — planning root
if [[ -d "$ROOT/.agent-tools/planning" ]]; then
  PLAN_ROOT="$ROOT/.agent-tools/planning"
elif [[ -d "$ROOT/planning" ]]; then
  PLAN_ROOT="$ROOT/planning"
else
  fail "no planning root (.agent-tools/planning or ./planning) — run /work:setup"
fi
ok "planning root: $PLAN_ROOT"

# 4 — claimable signal (heuristic; continue still owns invent rules)
claimable=0
if [[ -f "$PLAN_ROOT/session-state.md" ]]; then
  if grep -Eiq 'next_unit:\s*[^n]|NEXT|in_progress|claimable' "$PLAN_ROOT/session-state.md" 2>/dev/null; then
    # still may be none_forced — check explicit none
    if grep -Eiq 'next_unit:\s*none|none_forced|No forced' "$PLAN_ROOT/session-state.md" 2>/dev/null; then
      :
    else
      claimable=1
    fi
  fi
fi
if [[ -f "$PLAN_ROOT/roadmap.md" ]] && grep -Eiq '^\*\*NEXT\*\*|NEXT:|claimable' "$PLAN_ROOT/roadmap.md" 2>/dev/null; then
  if ! grep -Eiq 'No forced factory unit|none_forced|None forced' "$PLAN_ROOT/roadmap.md" 2>/dev/null; then
    claimable=1
  fi
fi
# Named unit dirs with in_progress
if find "$PLAN_ROOT" -mindepth 2 -maxdepth 2 -name session-state.md 2>/dev/null | head -20 | while read -r f; do
  grep -Eiq 'status:\s*in_progress' "$f" 2>/dev/null && exit 0
  exit 1
done; then
  claimable=1
fi

if [[ "$claimable" != "1" ]]; then
  fail "no claimable unit signal (do not invent NEXT) — hard_stop / idle"
fi
ok "claimable signal present (continue must still refuse invent)"

# 5 — runs scaffold advisory
if [[ ! -d "$ROOT/.agent-tools/runs" ]]; then
  echo "PRE-WAKE WARN: .agent-tools/runs missing — setup recommended" >&2
fi

ok "root=$ROOT worktree=$IN_WORKTREE"
exit 0
