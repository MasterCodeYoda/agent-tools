# Function: plan

**Kind:** phase packet (maps to `/work:plan`)

## Procedure

Run `/work:plan --worktree` against the item's requirements (dispatch gives issue key or
requirements path). The `--worktree` flag creates the per-item worktree and branch via
`/git:worktree-create` and commits planning docs inside it.

## Scope

- Produce `implementation-plan.md` (with dependency frontmatter) and `session-state.md` in
  the worktree; commit them there.
- Do **not** start implementing. Planning only.
- Capture/confirm the item's `blocks` / `blocked_by` / `parallelizable_with` in plan
  frontmatter when present in requirements.
- Report `artifacts.branch`, `artifacts.worktree`, and `artifacts.planning_docs` (orchestrator
  records them for the implement dispatch).

## Valid statuses

`DONE` · `NEEDS_CONTEXT` · `BLOCKED`
