# Reference: `state.yml` Schema (per-run)

Machine-managed per-run orchestrator state at
`.agent-tools/swarm/sessions/<run-id>/state.yml`. **Gitignored** by default. The orchestrator
writes it **atomically** (temp file + rename) after each wave and merge-sweep cycle.

`state.yml` is a **hint, not gospel** — disk (worktrees, branches, commits, session-state
files) and PM truth take precedence. `/swarm:continue` always reconciles against ground truth
before resuming.

## Schema

```yaml
schema_version: 1

run_id: 2026-05-28-k3p9a-aer-v03
goal: "Linear v0.3.0 milestone"
goal_source: linear         # linear | jira | github-issues | file | inline
started_at: 2026-05-28T10:42:00Z
last_updated: 2026-05-28T11:17:22Z
status: in_progress          # in_progress | goal_complete | terminal_pause
exit_state: null             # null | GOAL_COMPLETE | IN_FLIGHT_DECISION | TERMINAL_PAUSE
exit_reason: null

items:
  - key: AER-101
    title: "Add multi-tenant booking holds"
    stage: implementing
    # stages: unrefined | refined | planning | planned | implementing | implemented
    #         | reviewing | approved | merged | fix-requested
    branch: feat/AER-101
    worktree: /Users/.../.claude/worktrees/aer-101
    blocks: [AER-115]
    blocked_by: []
    priority: null            # null = use PM-derived; int = explicit override
    in_flight:                # set when a worker dispatch is active
      role: implementer
      dispatched_at: 2026-05-28T11:00:00Z
      log_file: .agent-tools/swarm/sessions/<run-id>/AER-101/implementer-1.md
    last_completed:           # set when most recent dispatch returned
      role: planner
      completed_at: 2026-05-28T10:58:33Z
      status: DONE
      log_file: .agent-tools/swarm/sessions/<run-id>/AER-101/planner-1.md
    fix_list: []              # populated when stage=fix-requested

merge_queue: []  # item keys in stage=approved, awaiting merge sweep

last_handoff: null
# When set on TERMINAL_PAUSE:
# last_handoff:
#   generated_at: 2026-05-28T12:14:00Z
#   reason: "Integration test failure on main after merging AER-115; one-shot fix-it failed."
#   user_actions_needed:
#     - "Inspect failed tests in worktree X"
#     - "Decide: revert AER-115 or fix forward"
#   diagnostic_files:
#     - .agent-tools/swarm/sessions/<run-id>/AER-115/integration-fixer-1.md
```

## Notes

- `in_flight` and `last_completed` are mutually informative; contents move from `in_flight`
  to `last_completed` on return.
- `blocks` / `blocked_by` are sourced from refinement/planning dependency metadata.
- `fix_list` persists across waves until consumed by the next implementer dispatch.
- **Wave history is NOT in state.yml** — it lives in `orchestrator.md`.

## Atomic writes

```
write state.yml.tmp
fsync state.yml.tmp
rename state.yml.tmp → state.yml   # atomic on POSIX
```

- Crash mid-write → incomplete `.tmp`; rename never happened; `state.yml` retains last good
  state. On resume, detect and remove an orphan `.tmp`.
- Crash mid-wave → `state.yml` reflects pre-dispatch state; reconciliation re-derives from
  disk + PM.

## Schema versioning

Read `schema_version` on load. Older than current → migrate in place (forward-only). Newer
than current → refuse to read; instruct the user to update agent-tools.
