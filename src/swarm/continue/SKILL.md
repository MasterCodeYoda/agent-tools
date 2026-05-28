---
name: swarm:continue
description: Resume the most recent paused swarm run. Reconciles the saved state.yml against disk + PM ground truth, surfaces any drift for confirmation, then re-enters the orchestration loop. Resilient to clean TERMINAL_PAUSE and to crashes/reboots/network loss.
user-invocable: true
argument-hint: "[no args — resumes the run named by .agent-tools/swarm/active-run]"
---

# Resume Swarm (`/swarm:continue`)

`/swarm:continue` resumes a paused or interrupted `/swarm <goal>` run. It is resilient to all
exit reasons — not just a clean TERMINAL_PAUSE, but also machine reboot, network loss,
terminal crash, or power outage, all of which leave `state.yml` at whatever was last
atomically written.

The governing principle: **never trust `state.yml` as ground truth.** It is a hint about
intended state at last write. Actual truth is on disk (worktrees, branches, commits,
`session-state.md` files) and in the PM tool. `/swarm:continue` always reconciles before
resuming.

## User Input

```text
$ARGUMENTS
```

`/swarm:continue` takes no arguments; it resumes the run named by `active-run`.

## Procedure (§6.9)

### 1. Locate the run

Read `.agent-tools/swarm/active-run`.

- **Absent** → inform the user there is no active run; suggest `/swarm <goal>`. Exit.
- **Present** → load `.agent-tools/swarm/sessions/<run-id>/state.yml`.
  - If `state.yml` is missing or unreadable → surface it; offer to clear the `active-run`
    pointer. Exit.
  - If an orphan `state.yml.tmp` exists (crash mid-write) → remove it; `state.yml` retains the
    last good state.

### 2. Announce recovery

> Recovering — last known state from `<state.yml.last_updated>`. Re-classifying from project
> state…

### 3. Reconcile against ground truth

Re-classify **every item not in stage `merged`** from disk + PM, using
`references/classification-rules.md` (the same classification logic the orchestrator uses).
Do not assume `state.yml` stages are correct.

### 4. Surface drift

Compare the reconciled classification against `state.yml` and present every difference, e.g.:

- "AER-101: state.yml had `implementing`; re-classified as `implemented` (commits past plan
  present, no review yet)."
- "AER-110: state.yml had `reviewing`; worktree missing → re-classified as `planned` (possible
  manual cleanup)."

Special cases:

- **Goal already complete** (user merged everything manually) → report GOAL_COMPLETE, clear
  `active-run`, exit.
- **Goal no longer achievable** (issues closed externally without merge) → surface and ask the
  user how to proceed.

### 5. Confirm

Display the reconciliation summary and ask the user to confirm or correct before resuming. Do
not silently overwrite their intent.

### 6. Persist & resume

Write the reconciled classification to `state.yml` (atomically — temp + rename). Clear any
stale `last_handoff`. Then re-enter the orchestrator main loop **at the between-wave merge
sweep** (Phase 3(A) of `/swarm`), which is the safe re-entry point.

## Notes

- `/swarm:continue` shares all orchestration mechanics with `/swarm <goal>` — see the `swarm`
  SKILL.md and `references/dispatch-mechanics.md`. It differs only in the reconciliation
  preamble above.
- It never pushes to remote and never trusts cached state. Same safety constraints as the
  orchestrator.
