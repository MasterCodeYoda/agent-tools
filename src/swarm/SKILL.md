---
name: swarm
description: Backlog-scale orchestration on top of /workflow — drives PM items through refine → plan → implement → review → local-merge via role-specialized sub-agents dispatched in parallel waves, each item isolated in its own git worktree. Bare /swarm summarizes state; /swarm <goal> runs the orchestrator; /swarm:setup sets up the charter and .agent-tools/ umbrella; /swarm:continue resumes a paused run.
user-invocable: true
argument-hint: "[no args for state summary | <goal> e.g. a milestone, issue list, or backlog file]"
---

# Swarm

`/swarm` is the parent skill for the **swarm** family — multi-role, multi-item orchestration
of backlog-scale work built **on top of** `/workflow`. When you invoke `/swarm <goal>`, the
host agent becomes an **orchestrator**: it drives backlog items through the `/workflow`
lifecycle (refine → plan → implement → review → local-merge) by dispatching role-specialized
sub-agents in parallel waves, each item isolated in its own git worktree.

The orchestrator runs in your active session — no tmux, no daemon. Parallelism comes from (a)
git worktrees per item and (b) the host's native sub-agent dispatch. It stays responsive,
**never pushes to remote**, and merges to `main` locally with full test gates between merges.

## Commands in This Family

| Command | Purpose |
|---------|---------|
| `/swarm` (no args) | Summarize swarm state — active run, item stages, or whether the project is initialized |
| `/swarm <goal>` | Run the orchestrator on a goal (milestone, issue list, backlog file) |
| `/swarm:setup` | Author the project charter + setup the `.agent-tools/` umbrella |
| `/swarm:continue` | Resume the most recent paused run, reconciling state against ground truth |

## Relationship to `/workflow`

- **Builds on `/workflow`, not around it.** Each worker runs an ordinary `/workflow` command
  (`/workflow:plan --worktree`, `/workflow:execute`, `/workflow:review`) inside a per-item
  worktree. `/workflow` behavior is unchanged.
- **Refinement is host-side.** The orchestrator runs `/workflow:refine` itself, in the main
  session, conversationally with you — it is not a sub-agent role.
- **Charter is shared ground truth.** Workers and the orchestrator read
  `.agent-tools/charter/` (loaded via `AGENTS.md`). Run `/swarm:setup` first if absent.

## Safety (non-negotiable)

- **No agent ever pushes to remote.** Not workers, not the orchestrator. `git push` is always
  user-initiated.
- **Local merges only**, into `main`, with the full test suite run between merges.
- **Strict worktree deferral** — worktrees are created/removed only via `/git:worktree-create`
  and `/git:worktree-delete`. The orchestrator never calls `git worktree` directly and never
  uses the `Agent` tool's `isolation: "worktree"` option.

## Reference material

Detailed algorithms live in `references/` and the role prompts in `roles/`:

- `references/classification-rules.md` — stages, classification sources, status→stage, reconciliation
- `references/dispatch-mechanics.md` — wave scheduling, dispatch assembly, worktree deferral, **merge orchestration**, session logs
- `references/structured-return-schema.md` — the worker return schema + parse rules
- `references/state-yml-schema.md` — per-run `state.yml` + atomic writes
- `references/config-yml-schema.md` — `config.yml` + test-command discovery
- `roles/worker-contract.md` + `roles/<role>.md` — prompts the orchestrator assembles per dispatch

## Behavior

Parse `$ARGUMENTS`:

```text
$ARGUMENTS
```

### No arguments → State summary

1. Read `.agent-tools/swarm/active-run` if present.
   - **Present** → load `sessions/<run-id>/state.yml` and summarize: goal, per-item stages,
     anything in flight, merge queue, and the exit state if paused. Suggest `/swarm:continue`
     if `status: terminal_pause`.
   - **Absent** → check for charter (`.agent-tools/charter/charter.md`) and
     `.agent-tools/swarm/config.yml`. If present, report initialized + idle and suggest
     `/swarm <goal>`. If `sessions/` has past runs, list the last few by run-id.
   - **Not initialized** (no charter) → summarize what's missing and offer to run `/swarm:setup`.
2. Handle a malformed/orphaned `active-run` per `references/state-yml-schema.md` (surface and
   offer to clear).

### `<goal>` provided → Orchestrator

**Precondition:** if `.agent-tools/charter/charter.md` is absent, stop: "No charter found.
Run `/swarm:setup` first." Also confirm `roles/` and `references/` exist under
`.agent-tools/swarm/` (written by `/swarm:setup`); if missing, direct the user to re-run
`/swarm:setup`.

Then run the orchestration loop:

#### Phase 1 — Goal interpretation & ingestion (§6.1)

Interpret the goal and resolve it to a concrete item list:

| Goal form | Interpretation |
|-----------|----------------|
| `"Linear v0.3.0 milestone"` | MCP query: issues in that milestone |
| `"AER-101, AER-115, AER-120"` | Explicit issue list |
| `"all open bugs labeled p1"` | PM query |
| `"./planning/v03-backlog.md"` | Parse local markdown |
| ambiguous (e.g. `"the auth refactor"`) | IN_FLIGHT_DECISION — ask for scope |

PM-first via MCP; file fallback. Then **always** show a pre-launch confirmation:
`Resolved <goal> to N items. First 5: <list>. Proceed? [y/n]`. No surprise launches.

Generate a run-id (`<YYYY-MM-DD>-<5-char-nonce>-<goal-slug>`), create
`sessions/<run-id>/`, write the run-id into `active-run`, and start `orchestrator.md`.

#### Phase 2 — Initial classification (§6.2)

Classify each item's stage per `references/classification-rules.md` (read only
`session-state.md` frontmatter). Write the initial `state.yml`.

#### Phase 3 — Main loop (§6.3)

```
(A) MERGE SWEEP        — merge approved items into main (see merge orchestration below)
(B) RE-CLASSIFY        — items whose workers returned, + unrefined items gating the next wave
(C) REFINEMENT         — for unrefined items in the next wave's path, run /workflow:refine
                         host-side, interactively with the user (serial); re-classify after each
(D) GOAL CHECK         — all items merged → GOAL_COMPLETE → exit
(E) NEXT-WAVE SCHEDULE — compute the wave (references/dispatch-mechanics.md). Empty wave with
                         items remaining → investigate; likely TERMINAL_PAUSE
(F) DISPATCH WAVE      — single message, N parallel sub-agent dispatches
(G) AWAIT RETURNS      — collect, parse, update state.yml atomically
(H) EXIT-STATE TRIAGE  — see below; else loop back to (A)
```

#### Dispatch (§6.5)

Each wave is **one message** with up to `concurrency_cap` (default 5) parallel native
`Agent`-tool dispatches. Assemble each prompt per `references/dispatch-mechanics.md`
(worker-contract + role file + charter reference + item context + any resume `fix_list`), and
pass the per-role model from `config.models`. Workers enter their worktree via `cd`. Capture
the dispatch prompt and the returned YAML into the per-dispatch session log.

#### Merge orchestration (§6.8)

Between waves, sequentially for each approved item: `git checkout main` → `git merge --no-ff`.
On conflict → one-shot **conflict-resolver** dispatch (workspace = main); on test failure
after merge → one-shot **integration-fixer** dispatch. A second failure of either →
TERMINAL_PAUSE. On success → `/git:worktree-delete` the item's worktree and mark `merged`.
Full detail in `references/dispatch-mechanics.md`.

#### Exit-state triage (§6.7)

| Trigger | Exit state | Behavior |
|---------|-----------|----------|
| All items merged | `GOAL_COMPLETE` | Final report; clear `active-run`; user pushes when ready |
| Worker `BLOCKED` (off-band need) or fix-it `FAILED` second time | `TERMINAL_PAUSE` | Write `state.yml` + `last_handoff`; leave `active-run`; `/swarm:continue` resumes |
| `NEEDS_CONTEXT` answerable in chat | `IN_FLIGHT_DECISION` | Ask (AskUserQuestion), stay loaded, apply answer, resume loop |
| `DONE_WITH_CONCERNS` worth user input | `IN_FLIGHT_DECISION` or log + continue | Decision rule: would the user want to weigh in before downstream roles act? |
| No items advanced, none in flight, candidates empty | `TERMINAL_PAUSE` (defensive) | Deadlock/classification bug; bail with diagnostic |

**IN_FLIGHT vs TERMINAL rule:** *"Can I act on the user's answer within this loaded session,
without requiring off-band work?"* — yes → IN_FLIGHT; no → TERMINAL.

#### `active-run` lifecycle (§8.4)

Created when the run starts; **cleared on GOAL_COMPLETE**; **preserved on TERMINAL_PAUSE** so
`/swarm:continue` can find the run.

## Phase status

- **Phase 1:** `/swarm` state summary + `/swarm:setup`. ✓
- **Phase 2 (this build):** `/swarm <goal>` orchestrator loop, `/swarm:continue`, six role
  templates, reference schemas, session logs, `active-run`. ✓
- **Phase 3:** cross-CLI worker dispatch via shell-out (per-role CLI selection). Not yet.

The authoritative design lives at `planning/swarm/design.md` in the agent-tools repo.

## References

### Attribution

The swarm orchestration concept is adapted from **swarm-forge** by Robert C. "Uncle Bob"
Martin — <https://github.com/unclebob/swarm-forge>.

**Adapted from swarm-forge:**
- the constitution/charter primitive (layered project context with precedence);
- role-specialized agents;
- per-item worktree isolation.

**Re-shaped for this design:**
- **No process orchestration.** swarm-forge uses tmux + macOS Terminal + watchdog scripts;
  `/swarm` uses the host agent's native sub-agent dispatch with no multi-terminal control.
- **Roles aligned to the `/workflow` lifecycle** — planner / implementer / reviewer, plus
  one-shot conflict-resolver / integration-fixer; refinement runs host-side.
- **Host-mediated structured returns** instead of swarm-forge's inter-agent file-queue
  messaging — sub-agents return a strict status schema to the orchestrator; there is no
  inter-sub-agent messaging.
