---
name: workflow:execute
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

## Flag Extraction

Before interpreting input, extract the `--worktree` flag if present:

1. **Check for `--worktree`** in `$ARGUMENTS`
2. If found, set `WORKTREE_MODE=true` and strip `--worktree` from `$ARGUMENTS` before Input Interpretation
3. If not found, set `WORKTREE_MODE=false`

**Validation** (stop with error if any fail):

- **`--worktree continue` is invalid**: Creating a new worktree for an existing session is nonsensical. Error:
  ```
  ERROR: --worktree cannot be used with 'continue'.
  To resume work in an existing worktree, cd to the worktree directory and run:
    /workflow:execute continue
  ```
- **Already inside a worktree**: If `git rev-parse --show-toplevel` differs from the main repo root (CWD is already a worktree), error:
  ```
  ERROR: Already inside a git worktree. Cannot nest worktrees.
  Run /workflow:execute without --worktree from this worktree.
  ```
- **Worktree already recorded in session-state**: If `--worktree` is passed AND `session-state.md` already has a `worktree:` path, error:
  ```
  ERROR: A worktree is already recorded in session-state.md: <path>
  Run /workflow:execute without --worktree — it will detect and enter the existing worktree automatically.
  ```

## Input Interpretation

| Input Pattern | Interpretation |
|---------------|----------------|
| `./planning/<project>/` | Start/continue project from planning subdirectory |
| `./planning/` or empty | Auto-detect from `./planning/*.md` or `./planning/*/` |
| `*.md` file path | Execute specific plan file |
| `continue` | Resume last active session |
| `LIN-[0-9]+` or `[A-Z]+-[0-9]+` | Fetch via Issue Retrieval Strategy, then direct execution |
| Text summary | Steering input for next session |

## Direct Issue Execution (micro track)

For simple tasks that don't need full planning docs (clear bugs, small enhancements, issue-as-plan).
Also the process used when `/workflow:continue` classifies track **micro**.

- **When:** clear scope; issue description is enough; planning overhead not justified — or track=micro
- **Flow:** **load** `references/direct-issue-execution.md` (fetch issue, confirm, execute, quick review, integrate, compound disposition)
- **Escalation:** if complexity grows — reclassify feature; pause; `/workflow:plan` or refine; resume via continue

PM retrieval: @workflow (`planning/pm-integration.md`). Tracks: @workflow `references/tracks.md`.

## Session Initialization

### 1. Locate Planning Documents

Precedence:

```bash
ls ./planning/*/session-state.md 2>/dev/null
ls ./planning/*.md 2>/dev/null
```

Support project subdirs (`planning/<project>/`) and flat `planning/` files. Both modes use
`implementation-plan.md` + `session-state.md`; `requirements.md` is file mode only.
Optional `visual_plan:` in session-state is **approval metadata only** — execute always follows
the markdown `implementation-plan.md`, never a visual plan URL or MDX folder.

### 1.25–1.5 Worktree detect / enter

If `session-state.md` has `worktree:` or `WORKTREE_MODE=true`, **load and follow**
`references/worktree-enter.md` (detect existing, create via @git worktree-create, rename branch,
dependency restore via `dependency-establishment.md`, validate planning docs committed, record path).

Surface the ERROR strings defined there (including planning-docs-missing-in-worktree).

### 2. Load Session State

- **If session-state exists:** read, show progress, confirm continuation
- **If planning docs but no state:** read plan (+ requirements or PM issue); create session-state;
  `session_count: 1`
- **If multiple project dirs:** list and ask which to continue
- PM mode: do not warn about missing `requirements.md` when `work_item` / PM source is set

### 2.5. Ensure Working Branch

- Worktree just entered: branch already set — record and skip create
- Else: honor `branch:` in session-state; never start implementation on `main`/`master`
- Create/switch using Branch Naming Convention from @workflow (`<type>/<ISSUE-KEY>` or short description)

**IMPORTANT**: Never begin implementation work on main/master. Always create or switch to a working branch first.

### 3. Context Review

Show project, session #, progress, current focus, last session summary.

### 4. Task Selection

Next incomplete plan task; honor steering; parallelize with sub-agents when safe; confirm if unclear.

## Execution Loop

Quality detail: **load** `quality-checkpoints.md`. Layer order: @workflow
(`references/decomposition-modes.md`). Testing strategy: @test-strategy. Logging: `logging.md`.

### Task Execution Pattern

```
while (tasks remain):
  1. Mark task in_progress in TodoWrite
  2. Read relevant files from plan
  3. Look for existing patterns in codebase
  4. Write tests for next behavior — see @test-strategy
  5. Implement minimal code to pass (Green)
  6. Refactor if needed, run full tests
  7. Mark task completed in TodoWrite
  8. Update plan file ([ ] -> [x])
  9. Check for story/slice completion
  10. Check for session boundary
```

### Story / Slice / Sub-issue Completion Checkpoint

**CRITICAL**: Commit each decomposition unit independently (story/slice or sub-issue/deliverable).

For each unit:

1. Implement end-to-end (vertical-slice) or comprehensively against owned ACs (deliverable-partition)
2. Run full test suite
3. Mark TodoWrite complete
4. **Deliverable-partition only:** verify every **inherited verbatim parent AC** against test/CI evidence
5. Commit: `feat(scope): description (ISSUE-ID)`
6. Update PM story/sub-issue Done
7. Next unit

**Anti-patterns:** one big commit at the end; closing a sub-issue with a **paraphrased** AC instead of
the verbatim parent AC.

### Quality Gates (triggers)

Before marking a task complete:

- [ ] Matches plan requirements
- [ ] Tests pass for new functionality
- [ ] No new lint/type errors
- [ ] Follows existing patterns; changes focused/atomic
- [ ] Mutation testing on domain logic if tool available (changed files only)

Run project-appropriate checks (pytest/mypy/ruff, npm test/tsc/eslint, etc.). Full checklists:
`quality-checkpoints.md`.

### Progress Tracking

Update plan checkboxes and `session-state.md` after significant milestones.

## Completion Verification

Before stopping or generating a handoff:

### When to Run

- All tasks appear done / about to hand off / about to stop during active execution

### When NOT to Run

- User said stop; question-only; planning/review-only session

### Checklist

1. Re-read original requests vs delivered
2. TodoWrite all complete (none stuck in_progress)
3. Targeted plan checkboxes done
4. Last tests/lint/types clean
5. No loose TODOs / half-edited files from this session

### After

Finish remaining work if possible; else handoff; if blocked, document in session state then handoff.

## Session Boundaries

### Detecting Boundary Conditions

Slice complete; milestone; user ending; context stale.

### Session Handoff Protocol

0. **Completion Verification** (above) first  
1. **Update session state** — write `./planning/<project>/session-state.md` using
   **`templates/session-state.md`** (load and fill)  
2. **Git commit** progress with clear message (session #, tasks done)  
3. **Compound prompt** — load **`templates/session-learnings.md`**; on Yes run `/workflow:compound`  
4. **Handoff summary** — load **`templates/session-complete.md`** (includes worktree status/cleanup rules)

Do **not** remove worktrees during handoff — user-initiated after all parallel sessions finish
(see template + `references/worktree-enter.md` + @git worktree-delete).

## Error Recovery

### If Tests Fail

1. Distinguish crash site from root cause — trace back  
2. Trace to actual definitions — don't assume from names  
3. Check the opposite hypothesis before concluding  
4. Fix before next task; if out of scope, document evidence in session state  
5. Do not proceed with failing tests  

### If Approach Diverges

Stop; document; re-plan with `/workflow:plan`; resume from revised plan.

### If Blocked

Document; create resolution task; parallelize if possible; escalate if critical path.

### If Lost Context

Read session-state, git log, implementation-plan; ask user if needed.

## Key Principles

- **Ship complete work** — no 80% features  
- **Maintain continuity** — session state is SoT  
- **Build knowledge** — compound at boundaries  
- **Quality built in** — patterns, tests, continuous checks  

## Definition of Done (Per Task)

- [ ] Implementation complete  
- [ ] Tests written and passing  
- [ ] Plan checkbox updated  
- [ ] Session state reflects progress  
- [ ] No introduced regressions  
- [ ] Mutation survivors analyzed (domain logic only, if tool available)  
- [ ] Committed (if completing a story/slice)  
- [ ] Decision-reconciliation at close — governing decision + touched docs/ACs vs built code
      (see `quality-checkpoints.md` › Decision-Reconciliation at Close)  
- [ ] PM tool updated (story marked Done)  

## Definition of Done (Per Session)

- [ ] Completion Verification checklist passed  
- [ ] All targeted tasks complete or documented  
- [ ] All acceptance criteria verified against the plan before closing  
- [ ] Session state updated  
- [ ] Work committed  
- [ ] Compound prompt offered  
- [ ] Handoff summary provided  

## Integration Points

- **/workflow:plan** — loads plan + session-state; worktree coordinate (plan creates, execute enters)  
- **/workflow:compound** — offered at session boundaries  
- **@test-strategy** — per-task testing approach  
- **PM tools** — status updates from session-state issue keys  
- **Sibling docs** — `quality-checkpoints.md`, `dependency-establishment.md`, `logging.md`  
