# Parallel Execution with Worktrees

How multiple sessions execute independent slices of one epic simultaneously in isolated git worktrees — when to use it, prerequisites, the session workflow, merge strategy, and the safety rules. Summarized in the parent @workflow skill; agent-specific mechanics live in @git (worktree-create) and @git (worktree-delete).

## When to Use

- An epic has 2+ independent stories/slices that don't modify the same files
- You want multiple Claude sessions to execute different slices simultaneously
- The planning phase has identified parallel execution groups (see @workflow (`planning/templates.md`) › Implementation Plan Document Template)

## When NOT to Use

- Stories have sequential dependencies (Story 2 builds on Story 1's code)
- Stories modify the same files (merge conflicts are likely)
- The project is small enough that serial execution is fast enough
- You're working on a single story or bug fix

## Prerequisites

1. **Planning docs must be in the worktree** — either use `/workflow:plan --worktree` (which commits docs into the worktree automatically) or manually commit `./planning/` before running `/workflow:execute --worktree`
2. **Parallel groups identified** — the implementation plan should indicate which stories can run concurrently
3. **No shared file modifications** — stories in the same parallel group must touch different files

## Parallel Execution Workflow

```
1. Plan the epic:  /workflow:plan --worktree <epic>
                   (or /workflow:plan <epic>, then commit docs manually)
2. Start parallel sessions (each in its own terminal):
   Session A: /workflow:execute ./planning/<project>/   (detects existing worktree from plan)
   Session B: /workflow:execute --worktree ./planning/<project>/   (creates new worktree)
3. Each session works in its own worktree with its own branch
4. Sessions complete — each handoff documents its worktree path and branch
5. USER merges one branch at a time (after ALL sessions complete):
   cd <main-repo-root>
   git checkout main
   git merge feat/<slice-a-key>    # Run full test suite
   git merge feat/<slice-b-key>    # Run full test suite again
6. USER cleans up worktrees (only after all merges succeed) via **@git worktree-delete**
   (never raw `git worktree remove` — the skill enforces merge-safety and agent path resolution):
   git worktree list               # Verify no sessions are still active
   /git:worktree-delete <worktree-path-a>
   /git:worktree-delete <worktree-path-b>
```

## Branch Naming for Parallel Work

Each worktree gets its own branch following the standard naming convention:
- `<type>/<issue-key>` (e.g., `feat/LIN-101`, `feat/LIN-102`)
- The `--worktree` flag auto-creates and renames the branch to match

## Merge Strategy

Merge branches **one at a time**, running the full test suite after each merge. This isolates merge conflicts to a single branch and makes failures easy to attribute.

## Worktree Safety Rules

Use the dedicated git worktree skills (`git:worktree-create` and `git:worktree-delete`) for creating, entering, and safely removing worktrees. These skills contain the concrete, agent-aware implementation details.

General safety principles (apply across agents):

1. **Sessions never remove worktrees** — Handoff documents the worktree path but does NOT delete it. Cleanup is always a separate, user-initiated action.
2. **Only remove worktrees you created** — Never clean up another session's worktree.
3. **Check `git worktree list` before removal** — Verify no other worktrees are still active.
4. **Never remove a worktree while CWD is inside it** — The shell will break irrecoverably.
5. **Session-state tracks ownership** — The `worktree:` field in `session-state.md` records which worktree belongs to each session.

See @git (worktree-create) and @git (worktree-delete) for agent-specific behavior, directory conventions, and commands.
