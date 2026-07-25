# Parallel mode — resume

**Not a slash command.** Used when `/workflow:continue` selects **parallel_resume**
(active `.agent-tools/parallel/active-run`). Full loop: `orchestrator.md`.

Resumes a paused or interrupted parallel run. Resilient to clean `TERMINAL_PAUSE` and to
crashes/reboots/network loss that left `state.yml` at the last atomic write.

**Never trust `state.yml` as ground truth.** It is a hint. Truth is on disk (worktrees,
branches, commits, `session-state.md`) and in the PM tool. Always reconcile before resuming.

## Procedure

### 1. Locate the run

Read `.agent-tools/parallel/active-run`.

- **Absent** → no active parallel run; continue falls through to other portfolio modes (or
  hard_stop). Do not invent a wave.
- **Present** → load `.agent-tools/parallel/sessions/<run-id>/state.yml`.
  - Missing/unreadable `state.yml` → surface; offer to clear `active-run`. Stop.
  - Orphan `state.yml.tmp` (crash mid-write) → remove tmp; keep last good `state.yml`.

### 2. Announce recovery

> Recovering — last known state from `<state.yml.last_updated>`. Re-classifying from project
> state…

### 3. Reconcile against ground truth

Re-classify **every item not in stage `merged`** from disk + PM using
`references/classification-rules.md`. Do not assume `state.yml` stages are correct.

### 4. Surface drift

Compare reconciled classification against `state.yml` and present every difference.

Special cases:

- **Goal already complete** (everything merged manually) → report GOAL_COMPLETE, clear
  `active-run`, exit.
- **Goal no longer achievable** (issues closed externally without merge) → surface and ask.

### 5. Confirm

Display reconciliation summary; user confirms or corrects before resume. Do not silently
overwrite intent.

### 6. Persist & resume

Write reconciled classification to `state.yml` (atomic temp + rename). Clear stale
`last_handoff`.

**Explicit charter load:** read `.agent-tools/charter/{charter,project,engineering,workflow}.md`.

Re-enter the orchestrator main loop **at the between-wave merge sweep** (Phase 3(A) of
`orchestrator.md`) — the safe re-entry point.

## Safety

Same as `orchestrator.md`: never push to remote; never trust cached state alone.
