---
name: work:execute
description: Session-based work execution with progress tracking and knowledge capture
argument-hint: "[--worktree] [planning directory, plan file, 'continue', or session summary text]"
user-invocable: true
---

# Session-Based Work Execution

Execute work plans while maintaining session continuity and capturing knowledge.

## User Input

```text
$ARGUMENTS
```

## Flags & input

Extract `--worktree` → `WORKTREE_MODE=true` and strip from `$ARGUMENTS`; else false.

**Hard refuse / surface exact ERROR strings:**

| Condition | Error gist |
|-----------|------------|
| `--worktree continue` | Cannot create worktree for existing session — cd to worktree, run execute continue |
| Nested worktree (CWD already worktree) | Cannot nest — run without `--worktree` |
| `--worktree` but `session-state` already has `worktree:` | Omit flag; enter existing path |
| Production-class ops without explicit user request | Do not run production/prod secret resolution, deploys, or destructive live-prod mutations unless the **current** user message names that environment. Prefer non-production secret sets; when ambiguous, ask. Project tools that take a "target" often select *which secrets to resolve*, not which host you call — check the tool's meaning before choosing production. |

| Input | Meaning |
|-------|---------|
| `./planning/<project>/` | Start/continue that unit |
| `./planning/` or empty | Auto-detect from session-state / plan files |
| `*.md` plan path | Execute that plan |
| `continue` | Resume last active session |
| Issue key | Micro/direct issue → `references/direct-issue-execution.md` |
| Text | Steering for next session |

## Micro / direct issue

**When:** clear scope; issue-as-plan; or continue track **micro**.  
**Flow:** load `references/direct-issue-execution.md`.  
**Escalation:** complexity grows → reclassify feature; pause; plan/refine; resume via continue.  
PM: @work `planning/pm-integration.md`. Tracks: @work `references/tracks.md`.

## Session initialization

1. **Locate docs** — prefer `planning/*/session-state.md`; support flat `planning/`. Both modes
   use `implementation-plan.md` + `session-state.md` (`requirements.md` file mode only).
   `visual_plan:` is approval metadata only — execute follows markdown plan SoT only.  
2. **Worktree** — if `worktree:` or `WORKTREE_MODE`: load `references/worktree-enter.md` end-to-end.  
3. **Session state** — read/show progress; create if missing (`session_count: 1`); multi-dir → ask;
   PM mode: no warn for missing requirements.  
4. **Branch** — never implement on `main`/`master` (**hard refuse**). Honor `branch:`; create/switch
   via @work `references/family-contracts.md`. Worktree enter may already set branch.  
5. **Context review** — project, session #, progress, focus, last summary.  
6. **Task select** — next incomplete plan task; honor steering; parallelize when safe.

## Execution loop

**Mandatory loads:** `quality-checkpoints.md` · @work `decomposition-modes.md` · @test-strategy ·
`logging.md` · @work `context-engineering.md` · @work `context-compact.md`.

### Pre-loop

1. Prefer **plan + codebase-research + latest IC** (+ `resume_loads`) over full chat replay.  
2. Missing research (non-trivial, no skip reason) → light/full on-demand research (dose in
   context-engineering). Micro → direct-issue ref.  
3. Stale research vs tip mid-complex work → re-run affected sections (`RESEARCH_STALE`).

### Task pattern

```
while tasks remain:
  in_progress → read plan/research sites → patterns (sub-agent search if heavy) →
  tests (@test-strategy) → minimal green → refactor + full tests →
  complete + plan checkbox → slice done? → compact if more work →
  dumb-zone/trajectory? → compact → session boundary?
```

### Mid-item reclaim (work remains)

Breakpoints: slice done with more tasks, dumb-zone, 2+ failed attempts, trajectory correction
(context-engineering). **Load and run** `context-compact.md` end-to-end (FREEZE → IC →
`workflow_reclaim` + clean-session host command → RESUME). Success = IC **and** reclaim **and**
`resume_loads` — not IC-only. Wrong approach → reclassify; no push in polluted window.

**End-of-item / user end:** Session Handoff below — **not** mid-item reclaim.  
Optional hooks: @work `hooks/reclaim-hooks.md`.

### Slice complete

**Load** `references/slice-checkpoint.md` — independent commit per unit; verbatim parent ACs in
deliverable-partition.

### Quality triggers (before task complete)

Matches plan · tests pass · no new lint/type errors · focused patterns · **domain verification**
when domain/pure logic changed: incremental mutation **or** sabotage 3–5 paths **or** skip
with reason (see `quality-checkpoints.md` › Domain verification path). **Property deliverable**
when strategy-fit (parsers/transforms/mappers): ship a property **or** exhaustive
table/reflection theory **or** skip reason — not example-only when an invariant is real
(`quality-checkpoints.md` › Property-fit). Full checklists: `quality-checkpoints.md`. Update plan
+ session-state at milestones.

## Completion verification

**Run when:** tasks appear done / about to hand off / stop mid-execution.  
**Skip when:** user stop; question-only; plan/review-only.

Checklist: request vs delivered · TodoWrite clean · plan checkboxes · tests/lint/types green ·
no half-edited files · domain verification evidence when applicable (mutation summary **or**
sabotage notes **or** skip reason). Finish remaining if possible; else handoff or document block.

## Session handoff (end-of-item)

Not for mid-item dumb-zone (use compact → continue).

0. Completion verification  
1. Session state via **`templates/session-state.md`**  
2. Git commit (session #, tasks)  
3. Compound offer via **`templates/session-learnings.md`**  
4. Handoff via **`templates/session-complete.md`**  

Do **not** remove worktrees on handoff — user after parallel sessions finish
(`worktree-enter.md` + @git worktree-delete).

## Error recovery

**Load** `references/error-recovery.md` on test failure, approach diverge / code pushback,
blocked, or lost context. Provisional plans: emit `PROBLEM_REFRAMED` / `DESIGN_FALSIFIED` /
`HUMAN_STEER` / `EXECUTE_GAP` rather than forcing the approved plan.

## Definition of Done

**Per task:** implemented + tests green + plan checkbox + session-state + focused changes +
domain verification evidence when applicable (mutation summary **or** sabotage notes **or**
skip reason) + slice commit + decision-reconciliation (`quality-checkpoints.md`) + PM when
applicable.

**Per session:** verification · tasks done/documented · ACs checked · state updated · committed ·
compound offered · handoff summary.

## Integration

`/work:plan` · `/work:compound` · @test-strategy · PM via session-state ·
`quality-checkpoints.md` · `dependency-establishment.md` · `logging.md` ·
@work `references/family-contracts.md`
