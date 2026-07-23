# Workflow process test harness

Bookends harness for **agent-driven** workflow process IP (context-compact first; more
scenarios later). Same idea as `tests/swarm/`: deterministic generate + analyze, human/agent
session in the middle.

```
generate  →  [agent runs protocol in run dir]  →  analyze
(Python)         (Claude / Grok / OpenCode)         (Python)
```

## Why not pure pytest?

Skills like context-compact require an agent to interpret procedure, write planning artifacts,
and choose soft vs harness reclaim. A test runner cannot call that as a function. Hard
invariants on **disk after the session** are what we automate.

## Quick start

From the **agent-tools** repo root (skills published via `./setup.sh`):

```bash
# 1) Generate a throwaway run repo
tests/workflow/new-run.sh context-compact-soft
# or: python -m tests.workflow.harness generate context-compact-soft

# 2) Agent step (NOT automated) — see "What you must do" below

# 3) Analyze (deterministic)
python -m tests.workflow.harness analyze tests/workflow/runs/context-compact-soft-<timestamp>
```

Exit codes for analyze: `0` = all hard invariants PASS, `2` = FAIL, `1` = tool error.

## What is automated

| Step | Tool | Output |
|------|------|--------|
| List scenarios | `python -m tests.workflow.harness list` | names |
| Generate run | `new-run.sh` / `harness generate` | `tests/workflow/runs/<scenario>-<stamp>/` git repo + `DRIVE.md` |
| Hard invariant checks | `harness analyze` | `analysis.md`, `results.json`, exit code |
| Harness unit tests | `python -m pytest tests/workflow/harness/tests -q` | parser/analyze regression |

## What is NOT automated (you do this)

1. **Open a harness** — Claude Code, Grok Build, or OpenCode.
2. **`cd` into the generated run directory** (cwd = that mini-repo, not agent-tools root).
3. **Paste** the drive prompt from `DRIVE.md` / `prompts/drive.md`.
4. **Let the agent run** the context-compact protocol (write IC, soft Resume card, stop).
5. **Return to a terminal** and run `analyze` on that run path.
6. **Repeat per harness** you care about (primary: claude, grok, opencode) — each needs its
   **own** generated run (or a clean re-generate); do not share a half-edited tree.

Optional resume check (manual): after soft stop, start a **new** message/session, say
“continue from latest IC only,” confirm first tools read `resume_loads` paths. Not in hard
invariants yet (would need log capture).

## Scenario: `context-compact-soft` (mid-item)

| | |
|--|--|
| **Purpose** | Mid-item: durable IC + clean-session reclaim path + continue same unit |
| **Unit** | `.agent-tools/planning/smoke-unit/` |
| **Default reclaim** | **`/clear`** (Claude) or **`/new`** (Grok) — not `/compact` |
| **Pass (agent)** | WRITE IC + `workflow_reclaim` signal + exact `host_command` + Continue card |
| **Pass (driver)** | Run host_command, then `/workflow:continue` / execute continue; resume_loads + NEXT |
| **Not automated** | Invoking `/clear`/`/new` (user or outer orchestrator / software-factory later) |
| **Not this scenario** | End-of-item handoff |
| **Hard checks** | IC fields on disk (analyze). Signal/continue judged by operator or logs. |

Optional host hooks: @workflow `references/hooks/reclaim-hooks.md` (Stop coach + SessionStart re-seed).

## Layout

```
tests/workflow/
  scenarios/<name>/
    scenario.yml          # hard_invariants + checklist
    seed/                 # copied into each run
    prompts/drive.md      # agent paste block
  harness/                # generate + analyze (stdlib)
  runs/                   # GITIGNORED throwaway repos
  history/                # optional committed summaries
  new-run.sh
  README.md
```

## Harness matrix (primary work surfaces)

| Scenario | Claude Code | Grok Build | OpenCode |
|----------|-------------|------------|----------|
| `context-compact-soft` | run once | run once | run once (soft path) |
| harness `/compact` focus | optional bonus | optional bonus | skip / soft only |

## After a PASS worth keeping

```bash
# optional — commit a compact summary, not the full run repo
mkdir -p tests/workflow/history/<run-id>
cp tests/workflow/runs/<run-id>/analysis.md tests/workflow/history/<run-id>/
cp tests/workflow/runs/<run-id>/results.json tests/workflow/history/<run-id>/
```

## Relation to swarm harness

| | swarm | workflow |
|--|-------|----------|
| Middle step | `/swarm` multi-agent | context-compact / workflow skills |
| Evidence | role session logs | unit `session-state.md` IC fields |
| Skill front-end | `/swarm:test` | none yet (CLI + README is enough) |

## Troubleshooting

- **analyze FAIL before any agent work** — expected; generate only seeds pre-compact state.
- **Skills look old** — from agent-tools root run `./setup.sh`, then new session.
- **Agent implemented tasks 2–4** — scenario fail for process fidelity; re-generate and re-drive
  with emphasis on FREEZE / do not implement.
- **cwd wrong** — planning root will not resolve; always `cd` into the run dir first.
