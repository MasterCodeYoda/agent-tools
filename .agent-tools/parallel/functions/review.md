# Function: review

**Kind:** phase packet (maps to `/work:review`)

## Procedure

Review the item's implementation (branch/worktree in the dispatch). Prefer
`/work:review` against the branch or worktree range. Produce a real review with method,
verdict, and P1–P3 counts — no theater.

## Scope

- Approve only if merge-ready under project gates.
- If changes are needed, return `FIX_REQUESTED` with a concrete, actionable `fix_list`
  (handed to the next implement dispatch verbatim).
- Do not implement fixes yourself unless the fix is trivial and still within review
  procedure; default is return + orchestrator re-dispatch implement.

## Valid statuses

`APPROVED` · `FIX_REQUESTED` · `NEEDS_CONTEXT` · `BLOCKED` · `DONE_WITH_CONCERNS`
(use `DONE_WITH_CONCERNS` only when approved-with-notes is the honest verdict and
`APPROVED` alone would hide material caveats — prefer `APPROVED` + concerns when clean
enough to merge)
