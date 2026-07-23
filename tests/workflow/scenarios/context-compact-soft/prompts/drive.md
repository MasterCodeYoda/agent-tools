# Drive prompt — context-compact-soft

Copy everything below the line into a **new** agent session whose **cwd is this run
directory** (the generated harness repo), not the agent-tools monorepo root.

---

You are validating the **workflow context-compact protocol** (skill corpus process IP).

## Setup

1. Load `@workflow:execute` (or `/workflow:execute continue` if your host uses slash skills).
2. Also load / follow `@workflow` `references/context-compact.md` when compacting.
3. Unit planning root is already present:

   - `.agent-tools/planning/smoke-unit/session-state.md`
   - `.agent-tools/planning/smoke-unit/implementation-plan.md`
   - `.agent-tools/planning/smoke-unit/codebase-research.md`

4. Toy app code is under `src/` — do **not** implement the remaining plan tasks in this run.
   This scenario only validates **context compact**, not product delivery.

## Forced condition

Treat the session as **dumb-zone / heavy context** even if the window feels light:

- Mid-phase execute on `smoke-unit`
- More plan tasks remain
- You must **not** push through with more exploration or feature edits

## Required actions (protocol)

Run the context-compact protocol **end-to-end**:

1. **FREEZE** — no new product edits, no broad search.
2. **WRITE** — update `.agent-tools/planning/smoke-unit/session-state.md` with a full
   **Intentional Compaction** snapshot (timestamped heading), including at least:
   - Goal / approach / done so far / current failure or next step / key files / do not re-open
   - **`compact_focus`** (3–8 lines for a summarizer)
   - **`resume_loads`** (ordered relative paths under this repo)
3. Optionally tick nothing on the plan (or leave checkboxes unchanged).
4. **EMIT** compact_focus + resume_loads clearly in the IC.
5. **RECLAIM**
   - Prefer **soft_compact**: print the Resume card from the protocol and **stop the turn**.
   - Only if this host documents an invocable conversation compact with focus text, you may
     offer a one-gate harness compact — still only **after** WRITE.
   - Do **not** invent slash commands or tools that do not exist on this host.
6. Do **not** implement remaining plan tasks after reclaim in this scenario.

## Constraints

- Stay **project-agnostic**: no references to external product codebases or ticket schemes.
- Paths in `resume_loads` must be **relative** to this run repo.
- Do not create a skill named `compact`.

## Done when

- Unit `session-state.md` has a real IC with `compact_focus` and `resume_loads`
- You have either stopped on a soft Resume card or completed harness compact after WRITE
- Operator will run: `python -m tests.workflow.harness analyze <this-run-dir>`
