# Reference: Item Classification Rules

How the orchestrator determines each backlog item's current **stage**. Used at run start
(full classification) and on `/swarm:continue` (reconciliation). After each wave,
classification is **incremental** — only re-classify items whose workers returned, plus
unrefined items that might gate the next wave.

## Stages

```
unrefined | refined | planning | planned | implementing | implemented
          | reviewing | approved | merged | fix-requested
```

Stage names are lowercase. They are a separate namespace from worker **status codes**
(`DONE`, `APPROVED`, etc.). A reviewer's `APPROVED` status advances the item's stage to
`approved`.

## Classification sources

| Source | Reveals |
|--------|---------|
| PM issue (Linear/Jira via MCP) | refinement state; status |
| `./planning/<item>/requirements.md` (file mode) | refinement state |
| `./planning/<item>/implementation-plan.md` | planned? |
| `git worktree list` | worktree exists for this item? |
| `<worktree>/planning/<item>/session-state.md` (frontmatter only) | execution progress, branch, status |
| `git log main` for the item's branch | merged? |

Read only the **YAML frontmatter** of `session-state.md` — keeps orchestrator context bounded
as concurrency scales.

## Status → stage advancement

| Returned status | Stage transition |
|-----------------|------------------|
| planner `DONE` | planning → planned |
| implementer `DONE` / `DONE_WITH_CONCERNS` | implementing → implemented |
| reviewer `APPROVED` | reviewing → approved (enters `merge_queue`) |
| reviewer `FIX_REQUESTED` | reviewing → fix-requested (store `fix_list`) |
| (merge sweep success) | approved → merged |
| `NEEDS_CONTEXT` | stage unchanged; raise IN_FLIGHT_DECISION |
| `BLOCKED` | stage unchanged; TERMINAL_PAUSE |

## Reconciliation (`/swarm:continue`)

Never trust `state.yml`. Re-classify every non-`merged` item from the sources above, compare
to `state.yml`, and surface drifts to the user, e.g.:

- "AER-101: state.yml had `implementing`; re-classified as `implemented` (commits past plan,
  no review yet)."
- "AER-110: state.yml had `reviewing`; worktree missing → re-classified `planned` (possible
  manual cleanup)."

If reconciliation shows the goal already complete (user merged everything manually) → report
GOAL_COMPLETE. If no longer achievable (issues closed externally) → surface and ask.
