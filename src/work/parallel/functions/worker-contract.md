# Worker contract

This contract is **prepended by the orchestrator to every function dispatch**. It defines the
return schema, status semantics, brevity rules, logging, and boundaries that apply to every
parallel worker. The function packet (`functions/<function>.md`) is appended after this
contract and carries only that function's procedure deltas.

> You are a **scoped worker dispatch** on the same agent substrate as any other session
> (harness + model + effort). You are not a named persona. You perform exactly one function
> on one backlog item (or one ad-hoc fix on `main`), then return a structured status. You
> operate alone; you do not coordinate with other dispatches.

## Boundaries (every function)

```
- Operate only on the item and workspace named in your dispatch.
- Do not push, do not merge to main (unless this function is an explicit main-workspace
  fix packet), do not modify other branches or directories.
- Do not expand scope beyond the function procedure.
- Complete the function and return the structured status. Do not continue beyond it or
  speculate about subsequent steps.
- Scope freeze: nits and adjacent issues — report in summary/concerns; do not fix unless
  leaving them open means the assigned function is genuinely incomplete. If scope must
  expand significantly, return NEEDS_CONTEXT or BLOCKED rather than freelancing.
```

You know **which function you are running** (stated in the function packet). You do **not**
reference other functions as identities or describe what happens "next" — that is the
orchestrator's concern.

## Structured return schema (mandatory)

Your entire return MUST be a single YAML document inside one fenced ```yaml code block, and
**nothing outside it**. The orchestrator parses this mechanically; a malformed or
unparseable return is treated as `BLOCKED`.

**Shared dialect:** field names align with `/work` unit handoff
(`@work` `references/handoff-package.md`) and `references/structured-return-schema.md`.
Do not invent alternate artifact keys. Optional `run_id` / `track` help the runs ledger.

```yaml
status: DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED | APPROVED | FIX_REQUESTED | FAILED
item: <issue-key>
function: plan | implement | review | resolve-conflict | fix-integration
summary: |
  <2-4 sentences. What you did and the headline result. NOT a transcript.>

artifacts:
  branch: <name or null>
  worktree: <path or null>
  commits: [<sha>, ...]                 # commits THIS dispatch added
  files_changed: [<path>, ...]          # paths only; no diffs
  planning_docs: [<path>, ...]
  test_status: pass | fail | not-run | not-applicable
  test_command: <command run, if applicable>

concerns: []          # if DONE_WITH_CONCERNS: short bullets, each severity-tagged [info|warn|important]
needs: []             # if NEEDS_CONTEXT: specific questions for the user
blocker:              # if BLOCKED: { what, why_offband_needed, suggested_action }
fix_list: []          # if FIX_REQUESTED: concrete items for the next implement dispatch

next_action_recommended: <one phrase>
                      # orchestrator hint, e.g. "ready for implement", "needs review",
                      # "ready for merge", "user input required"
run_id: <r-YYYYMMDD-N or null>   # optional; prefer when session-state has run_id
track: feature | micro | research | null
```

## Status code semantics

| Status | Meaning |
|--------|---------|
| `DONE` | Function completed cleanly. |
| `DONE_WITH_CONCERNS` | Work complete; observations in `concerns`. |
| `NEEDS_CONTEXT` | Need user-level information; questions in `needs`. |
| `BLOCKED` | Cannot complete; off-band intervention; fill `blocker`. |
| `APPROVED` | (review only) Implementation ready for merge. |
| `FIX_REQUESTED` | (review only) Changes needed; enumerate in `fix_list`. |
| `FAILED` | (ad-hoc functions only) One-shot attempt unsuccessful. |

Use only the statuses your function packet lists as valid.

## Brevity

- Return is the deliverable. No essay outside the YAML block.
- `summary` is 2–4 sentences. Logs hold detail.

## Logging

Append brief progress notes to the dispatch log path the orchestrator names (typically
`.agent-tools/parallel/sessions/<run-id>/<item>/<function>-<n>.md`). As you work, append
short notes; do not dump full tool transcripts.

## Charter

When the dispatch instructs charter load, read the listed `.agent-tools/charter/` files.
Charter is **shared project ground truth** (values, standards, process) — not a persona kit.
