# Drive prompt — context-compact mid-item (soft-named scenario dir)

Copy everything below the line into a **new** agent session whose **cwd is this run
directory** (the generated harness repo), not the agent-tools monorepo root.

---

You are validating the **workflow context-compact protocol** for a **mid-item** breakpoint.

## Requirement (read carefully)

This is **not** end-of-item handoff.

- **Mid-item** (this scenario): unit still has work remaining → WRITE IC → **RECLAIM the
  conversation window** → **RESUME the same workstream** (`/workflow:continue` or execute
  continue on `smoke-unit`). IC-only “prepared and stopped” is a **FAIL**.
- **End-of-item** (out of scope here): unit done → session handoff only, **no** compact.

## Setup

1. Load `@workflow:execute` / continue and `@workflow` `references/context-compact.md`.
2. Unit artifacts already exist under `.agent-tools/planning/smoke-unit/`.
3. Toy app under `src/` — you may **state** NEXT = Task 2 clamp after resume; do **not** fully
   implement Tasks 2–4 in this validation run (prove resume steering only).

## Forced condition

Treat as **dumb-zone / heavy context**, **mid-phase execute**, **tasks remain**.

## Required actions

1. **FREEZE** — no product feature work yet.
2. **WRITE** — full Intentional Compaction on
   `.agent-tools/planning/smoke-unit/session-state.md` with `compact_focus` + `resume_loads`.
3. **RECLAIM**
   - **Claude Code / Grok Build:** after WRITE, run host compact with focus, **or** output the
     **exact** command for the user to run immediately:
     `/compact <paste compact_focus here>`
     Then, on the next turn after compact (or after user confirms compact), go to RESUME.
   - **OpenCode / no focus-compact:** emit the protocol **Continue card**, then in a **new**
     session in this cwd run `/workflow:continue` (or execute continue) on smoke-unit.
4. **RESUME** — read `resume_loads` in order; restate NEXT from latest IC; do **not** re-explore.
   Prove you are mid-stream by naming Task 2 only (no full implement required for harness).

## Done when

- IC on disk with `compact_focus` + `resume_loads`
- Window reclaim attempted (host `/compact` with focus, or clean session after Continue card)
- Post-reclaim: resume_loads read + NEXT restated (same unit workstream)
- Operator: `python -m tests.workflow.harness analyze <this-run-dir>`

## Constraints

- Project-agnostic; relative paths only; no skill named `compact`.
