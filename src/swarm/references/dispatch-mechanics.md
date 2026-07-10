# Reference: Dispatch Mechanics, Wave Scheduling & Merge Orchestration

## Wave scheduling

```
candidates = items NOT in [merged, awaiting-user-input]

filter to items whose next stage has no upstream blocker:
  refined         → planner can dispatch
  planned         → implementer can dispatch
  implemented     → reviewer can dispatch
  fix-requested   → implementer can re-dispatch
  planning/implementing/reviewing → in flight, do not dispatch again

respect explicit dependencies: drop any item whose blocked_by set has unmerged members.

sort by: user-declared priority (state.yml) → PM priority field → FIFO

pick first N  (N = config.concurrency_cap, default 5)  → the wave
```

**File-collision avoidance (MVP):** not pre-checked. Two parallel implementers may touch
overlapping files; conflicts surface at merge time and are handled by the conflict-resolver
dispatch.

**Backlog quality:** scheduling produces good parallelism only when items carry
`blocks`/`blocked_by`/`parallelizable_with` (from `/workflow:refine`). Missing metadata → fall
back to treating all items as independent in FIFO order (functional, higher conflict risk).

## Dispatch assembly

Each wave is a **single message** containing N parallel native `Agent`-tool dispatches (one
per item-stage transition). Each dispatch prompt is assembled by the orchestrator as:

```
prompt = worker-contract.md content                      (prepended mechanically)
       + roles/<role>.md content
       + charter load instruction (same-CLI or cross: "Read the project charter files under
         .agent-tools/charter/ at the start of your work: charter.md, then the relevant
         sections of project.md / engineering.md / workflow.md for your role. Do not assume
         they are pre-loaded from AGENTS.md.")
       + item context (issue key, title, refined ACs, planning-doc path, worktree, branch)
       + resume context (if re-dispatch — e.g. fix_list)
```

Pass the per-role **model** (from `config.models`, mapped to a concrete ID). Workers operate
in the item's worktree; entering an existing worktree is done via `cd <worktree-path>` in the
worker prompt.

This ensures charter content is loaded only inside active swarm worker sessions (when needed),
never as an unconditional cost for other sessions.

**Worktree handling — strict deferral to git skills:**

| Operation | Implementation |
|-----------|----------------|
| Create per-item worktree | Planner runs `/workflow:plan --worktree` → `/git:worktree-create`. Orchestrator never calls `git worktree add`. |
| Enter existing worktree | Worker prompt: `cd <worktree-path>`. |
| Remove worktree post-merge | Orchestrator dispatches `/git:worktree-delete` (merge-safety + agent-aware path resolution). |
| conflict-resolver / integration-fixer | Operate on `main`; no worktree. |

Do **not** use the host `Agent` tool's `isolation: "worktree"` option — it conflicts with the
explicit worktree-per-item model.

## Wave completion

1. Collect all N returns; parse each (malformed → `BLOCKED`, see structured-return-schema.md).
2. Update `state.yml` atomically (temp + rename).
3. Advance each item's stage per classification-rules.md.
4. Run exit-state triage.

## Merge orchestration

Runs **between** waves (sequential; affects shared `main`). For each item in stage=approved:

```
git checkout main
git merge --no-ff <branch>

if conflict:
  capture diagnostics (git status, file list, conflict markers)
  dispatch ONE conflict-resolver (workspace = main, merge in progress)
    DONE   → proceed to test gate
    FAILED → git merge --abort → TERMINAL_PAUSE

run full test suite (config test_command / discovery cascade)
if tests fail:
  capture diagnostics
  dispatch ONE integration-fixer (workspace = main, post-merge)
    re-run tests: pass → proceed
                  fail → TERMINAL_PAUSE (main left as-is, diagnostics in handoff)

on success:
  dispatch /git:worktree-delete for the item's worktree (safe branch cleanup)
  mark item stage=merged
```

Each ad-hoc fix-it role is **one-shot**: a second failure → `TERMINAL_PAUSE`. Ad-hoc roles
have no `BLOCKED`/`NEEDS_CONTEXT` — only `DONE`/`FAILED`.

## Session logs

Per-dispatch files at `.agent-tools/swarm/sessions/<run-id>/<item>/<role>-<n>.md` (orchestrator
captures the dispatch prompt + the returned YAML; worker appends a best-effort decision log).
The orchestrator's own log is `orchestrator.md` (goal, classification, waves, decisions).
Run-id format: `<YYYY-MM-DD>-<5-char-nonce>-<goal-slug>`.
