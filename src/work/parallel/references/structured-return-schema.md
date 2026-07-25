# Structured return schema (orchestrator parse)

Authority for the YAML block workers must return. Keep in lockstep with
`functions/worker-contract.md`.

## Required shape

```yaml
status: DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED | APPROVED | FIX_REQUESTED | FAILED
item: <issue-key>
function: plan | implement | review | resolve-conflict | fix-integration
summary: |
  <2-4 sentences>

artifacts:
  branch: <name or null>
  worktree: <path or null>
  commits: [<sha>, ...]
  files_changed: [<path>, ...]
  planning_docs: [<path>, ...]
  test_status: pass | fail | not-run | not-applicable
  test_command: <command or null>

concerns: []
needs: []
blocker: null
fix_list: []          # FIX_REQUESTED: items for the next implement dispatch
next_action_recommended: <phrase>
run_id: <optional>
track: feature | micro | research | null
```

## Parse rules

- Entire assistant return must be one ```yaml fence (or the first yaml fence is taken).
- Unknown `function` or `status` → treat as `BLOCKED` with parse note.
- Missing required keys for the status → `BLOCKED`.
- No legacy `role:` field — clean cut; reject or ignore only if you must recover a mid-flight
  pre-migration log (prefer re-dispatch).

Schema changes here and in `functions/worker-contract.md` stay in lockstep.
