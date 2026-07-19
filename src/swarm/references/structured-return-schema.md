# Reference: Structured Return Schema

Every worker returns a single YAML document in one fenced ```yaml block — nothing outside it.
The orchestrator parses it with a YAML library. This file is the **orchestrator-side**
authority for the schema and parse rules; the same schema is embedded in
`roles/worker-contract.md` for the worker side.

## Schema

```yaml
status: DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED | APPROVED | FIX_REQUESTED | FAILED
item: <issue-key>
role: planner | implementer | reviewer | conflict-resolver | integration-fixer
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

concerns: []          # DONE_WITH_CONCERNS: bullets tagged [info|warn|important]
needs: []             # NEEDS_CONTEXT: questions for the user
blocker:              # BLOCKED: { what, why_offband_needed, suggested_action }
fix_list: []          # FIX_REQUESTED: items for the next implementer dispatch
next_action_recommended: <one phrase>
run_id: <r-YYYYMMDD-N or null>   # optional; shared with /workflow runs ledger
track: feature | micro | research | null
```

Unit continue maps these statuses to phase-return events via `@workflow`
`references/handoff-package.md`. Schema changes here and in `roles/worker-contract.md` stay
in lockstep — do not fork a second return dialect for sequential workflow.

## Parse rules

1. Extract the first fenced ```yaml block from the worker's output. Ignore any prose outside
   it (workers are instructed not to emit any, but be tolerant on extraction).
2. Parse with a YAML parser.
3. **If extraction or parse fails, or `status` is missing/invalid → treat as `BLOCKED`** with
   a synthetic `blocker` describing the parse error. Never guess the worker's intent.
4. Validate `status` is in the role's allowed set (see role files). An out-of-set status is a
   parse failure → `BLOCKED`.

## Why YAML-in-a-fenced-block (not a tool call)

Portable across CLIs — a Phase 3 shell-out worker on a non-host CLI produces the identical
format. Parsing a fenced block with a YAML library is robust against models embellishing
around tool calls.

## Status → orchestrator action

See `classification-rules.md` for how each status advances the item's stage, and
`dispatch-mechanics.md` for merge-time handling of `APPROVED`.
