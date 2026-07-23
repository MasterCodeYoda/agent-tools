# Drive prompt — mid-item reclaim (clean-session default)

Copy everything below the line into a **new** agent session whose **cwd is this run
directory**.

---

Validate the **workflow context-compact protocol** for a **mid-item** breakpoint.

## Requirement

| Mid-item (this run) | End-of-item (out of scope) |
|---------------------|----------------------------|
| WRITE IC → reclaim → continue same unit | Handoff only — **no** reclaim |

**Default reclaim = clean session**, not host `/compact`:

| Host | After WRITE, tell the user to run |
|------|-----------------------------------|
| Claude Code | `/clear` |
| Grok Build | `/new` (or `/clear`) |
| OpenCode | new/clear session per host |

Then: `/workflow:continue` or execute continue on `smoke-unit` (read `resume_loads`, restate
NEXT). Optional `/compact` with focus only if staying in-thread is preferred — not required.

**IC-only stop without reclaim path is incomplete.**

Full auto-clear is **not** required (user or outer orchestrator runs host_command). Agent must
emit the `workflow_reclaim` YAML signal + Continue card.

## Setup

- Load execute/continue + `context-compact.md`.
- Unit: `.agent-tools/planning/smoke-unit/`.
- Do **not** fully implement plan Tasks 2–4; prove checkpoint + reclaim instructions + (after
  clear) resume steering only.

## Forced condition

Dumb-zone / mid-phase / **tasks remain**.

## Required actions

1. FREEZE  
2. WRITE full IC with `compact_focus` + `resume_loads`  
3. EMIT fenced `workflow_reclaim` block (`reclaim: clean-session`, correct `host_command`)  
4. Present Continue card: run host_command, then continue  
5. After operator clears (or in a follow-up clean session): RESUME — resume_loads + NEXT = Task 2  

## Done when

- IC on disk  
- Signal + host_command present in final mid-item message  
- After clear: continue same unit from disk (manual or second session)  
- `python -m tests.workflow.harness analyze <run-dir>`  
