
# Parallel mode — orchestrator

**Not a slash command.** Loaded only when `/workflow:continue` selects **parallel** mode
(@workflow `continue/references/portfolio-router.md`). Procedures live under
`workflow/parallel/`.

**Parallel mode** is multi-role, multi-item orchestration of backlog-scale work inside
`/workflow:continue`. When continue enters parallel mode with a **goal**, the host agent
becomes an **orchestrator**: it drives backlog items through the `/workflow`
lifecycle (refine → plan → implement → review → local-merge) by dispatching role-specialized
sub-agents in parallel waves, each item isolated in its own git worktree.

The orchestrator runs in your active session — no tmux, no daemon. Parallelism comes from (a)
git worktrees per item and (b) the host's native sub-agent dispatch. It stays responsive,
**never pushes to remote**, and merges to `main` locally with full test gates between merges.

## How continue enters this mode

| Path | Behavior |
|------|----------|
| Active `.agent-tools/parallel/active-run` | **parallel_resume** — `resume.md` then this loop |
| Explicit roadmap `∥` / `{wave}` (≥2 claimable) + parallel ready | **parallel_handoff** — goal = wave peer list |
| Continue args name a multi-item goal (issue list, milestone, backlog file, ≥2 ids) | **parallel** — same pre-launch confirmation as below |

Bare `/workflow` **status** may summarize an active run; it never enters the orchestrator.

- **Builds on unit phases.** Each worker runs ordinary `/workflow` phase commands
  (`:plan --worktree`, `:execute`, `:review`) inside a per-item worktree. Continue’s unit
  state machine is the sequential peer.
- **Refinement is host-side.** Orchestrator runs `/workflow:refine` in the main session with
  the user — not a sub-agent role.
- **Charter is shared ground truth** for parallel mode. Workers and orchestrator read
  `.agent-tools/charter/` as needed. Author via `/workflow:setup`. Unit-mode continue does
  **not** auto-load the full charter set.

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

Continue supplies the **goal** (wave list or multi-item args). Status-only summary of an
active run lives in bare `/workflow` (`references/status.md`) — not here.

### Goal → Orchestrator

**Precondition:** if `.agent-tools/charter/charter.md` is absent, stop: "No charter found.
Run `/workflow:setup` first." Also confirm `.agent-tools/parallel/roles/` (and config) exist
(from `/workflow:setup`); if missing, direct the user to re-run `/workflow:setup`.

**Explicit charter load (this session is parallel-mode):** Read the charter files now:
- Read `.agent-tools/charter/charter.md`
- Read `.agent-tools/charter/project.md`
- Read `.agent-tools/charter/engineering.md`
- Read `.agent-tools/charter/workflow.md`

(These are the full source of truth for identity, standards, and conventions during swarm work.)

Then run the orchestration loop:

#### Phase 1 — Goal interpretation & ingestion

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

#### Phase 2 — Initial classification

Classify each item's stage per `references/classification-rules.md` (read only
`session-state.md` frontmatter). Write the initial `state.yml`.

#### Phase 3 — Main loop

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

#### Dispatch

Each wave is **one message** with up to `concurrency_cap` (default 5) parallel native
`Agent`-tool dispatches. Assemble each prompt per `references/dispatch-mechanics.md`
(worker-contract + role file + charter reference + item context + any resume `fix_list`), and
pass the per-role model from `config.models`. Workers enter their worktree via `cd`. Capture
the dispatch prompt and the returned YAML into the per-dispatch session log.

#### Merge orchestration

Between waves, sequentially for each approved item: `git checkout main` → `git merge --no-ff`.
On conflict → one-shot **conflict-resolver** dispatch (workspace = main); on test failure
after merge → one-shot **integration-fixer** dispatch. A second failure of either →
TERMINAL_PAUSE. On success → `/git:worktree-delete` the item's worktree and mark `merged`.
Full detail in `references/dispatch-mechanics.md`.

#### Exit-state triage

| Trigger | Exit state | Behavior |
|---------|-----------|----------|
| All items merged | `GOAL_COMPLETE` | Final report; clear `active-run`; user pushes when ready |
| Worker `BLOCKED` (off-band need) or fix-it `FAILED` second time | `TERMINAL_PAUSE` | Write `state.yml` + `last_handoff`; leave `active-run`; continue **parallel_resume** |
| `NEEDS_CONTEXT` answerable in chat | `IN_FLIGHT_DECISION` | Ask (AskUserQuestion), stay loaded, apply answer, resume loop |
| `DONE_WITH_CONCERNS` worth user input | `IN_FLIGHT_DECISION` or log + continue | Decision rule: would the user want to weigh in before downstream roles act? |
| No items advanced, none in flight, candidates empty | `TERMINAL_PAUSE` (defensive) | Deadlock/classification bug; bail with diagnostic |

**IN_FLIGHT vs TERMINAL rule:** *"Can I act on the user's answer within this loaded session,
without requiring off-band work?"* — yes → IN_FLIGHT; no → TERMINAL.

#### `active-run` lifecycle

Created when the run starts; **cleared on GOAL_COMPLETE**; **preserved on TERMINAL_PAUSE** so
`/workflow:continue` parallel_resume can find the run.

## Attribution

Orchestration concept adapted from **swarm-forge** by Robert C. "Uncle Bob" Martin —
<https://github.com/unclebob/swarm-forge> (charter primitive, role-specialized agents,
per-item worktrees). Re-shaped: host native sub-agent dispatch (no tmux), roles aligned to
`/workflow` phases, host-mediated structured returns, entry only via `/workflow:continue`.

## Related paths

- `resume.md` — parallel_resume reconciliation
- `references/` — classification, dispatch, state/config schemas, return schema
- `roles/` — worker contract + role prompts (canonical; copied into project by setup)
- Decision: `docs/decisions/001-swarm-collapse-into-workflow.md`
