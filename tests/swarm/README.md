# `/swarm` Test Harness

A permanent harness for exercising the `/swarm` orchestrator end-to-end against engineered
scenarios, and turning the resulting role logs into evidence-linked improvements to the swarm
role templates and skills.

The design rationale is summarized in this README (the original working docs lived in
untracked `planning/` and were purged after completion — this README and the harness
code are authoritative).

## Why a harness (and not a `pytest`)

`/swarm <goal>` is **agent-driven** — running it means an agent interprets the skill,
dispatches sub-agents, makes IN_FLIGHT decisions, and runs host-side refinement with a human.
It is not a deterministic function a test runner can call and await. So the harness uses a
**bookends** model: deterministic Python on each side, with the agent-driven `/swarm` run in
the middle.

```
generate  →  [agent runs /swarm]  →  analyze
(Python)        (a session)          (swarm:test skill + Python ingest)
```

## The loop

`/swarm:test` front-ends the whole loop. Give it a **scenario name** to start a run, or a
**run dir** to analyze a finished one.

1. **Start a run** — `/swarm:test <scenario>` (e.g. `/swarm:test cli-task-manager`):

   It runs `tests/swarm/new-run.sh <scenario>` under the hood to build
   `tests/swarm/runs/<name>-<timestamp>/` — a real git repo seeded with the scenario's
   sources, a charter, swarm `config.yml`, the **current** `src/swarm/roles/*` (so you always
   test live role content), and the backlog. It then hands you a copy-paste block for a new
   terminal and waits.

   (The wrapper is still usable directly — `tests/swarm/new-run.sh --list`,
   `tests/swarm/new-run.sh <scenario>`, or `python -m tests.swarm.harness generate <scenario>`
   — if you prefer to drive the bookends by hand.)

2. **Run the orchestrator** in a separate agent session, from the generated repo:

   ```
   cd tests/swarm/runs/<name>-<timestamp>
   /swarm backlog.md
   ```

   A separate session is required: `/swarm` is agent-driven — it interprets the skill,
   dispatches sub-agents, and makes in-flight decisions — so it can't be run or backgrounded
   from the analysis session, and it must run in the generated repo's working directory.
   Init-first scenarios begin with `/swarm:setup` before `/swarm backlog.md`. This produces
   per-dispatch session logs under
   `.agent-tools/swarm/sessions/<run-id>/<item>/<role>-<n>.md`.

3. **Analyze** — tell the conversation the run is done (or, in a fresh session, run
   `/swarm:test <run-dir>`). Either way `/swarm:test` confirms the run finished, then runs the
   deterministic `ingest` (logs → `observations.json`), checks the scenario's hard invariants
   (loud fail on violation), judges the observation checklist with citations, clusters issues,
   and proposes minimal, evidence-linked evolve-style diffs to `src/swarm/roles/*.md` (and
   `SKILL.md` / `references/`) for your review. The run report is written to
   `tests/swarm/runs/<run-dir>/analysis.md`.

Re-running a fresh `/swarm:test <scenario>` after applying analyze's diffs tests the
**improved** role content, closing the loop.

## Layout

```
tests/swarm/
  scenarios/<name>/     committed scenario definitions (scenario.yml, backlog.md, charter/, seed/)
  harness/              deterministic Python (generate, ingest, cli) + unit tests
  runs/                 GITIGNORED — generated repos + analysis outputs
  history/<run-id>/     committed, compacted summaries of runs worth remembering
```

## Run history

Generated runs under `runs/` are throwaway and gitignored, and their evidence is doubly
transient (session logs are gitignored inside the run repo; the orchestrator transcript lives
under `~/.claude/` on a retention clock). When a run drives a change or surfaces something
worth keeping, its **summary** — `analysis.md`, `observations.json`, and the otherwise-lost
`orchestrator.md` — is committed under `history/<run-id>/` instead. See
[`history/README.md`](history/README.md) for the convention. This is opt-in (`/swarm:test`
Phase 6 offers it); most runs need no entry.

## Running the harness unit tests

The deterministic tooling (`generate`, `ingest`) is covered by stdlib `unittest` tests — no
pip install required:

```bash
python -m unittest discover -s tests/swarm/harness/tests -t .
```

(They are also discovered by `pytest` if you have it installed.)

## Authoring a new scenario

Create `tests/swarm/scenarios/<name>/` with:

- `scenario.yml` — `purpose`, `expected_exit` (soft), `hard_invariants` (deterministic
  safety asserts), and `observation_checklist` (the behaviors the scenario is engineered to
  provoke). See `cli-task-manager/scenario.yml` for the schema.
- `backlog.md` — the local backlog the orchestrator ingests (items + `blocks` / `blocked_by`
  / `parallelizable_with` dependency metadata).
- `charter/` — **optional**, and it toggles the bootstrap mode:
  - **present → seeded:** `generate` writes the full `.agent-tools/` umbrella (charter +
    `config.yml` + current roles). The run starts directly at `/swarm backlog.md`. Use this
    when you want a *controlled, repeatable* orchestrator input (the common case — e.g.
    `cli-task-manager`).
  - **absent → init-first:** `generate` produces a **bare** repo (no `.agent-tools/`). The run
    begins with `/swarm:setup`, which detects the stack, authors the charter, and bootstraps
    the umbrella itself. Use this to exercise `/swarm:setup` (e.g. `greenfield-init`). Note the
    charter then varies run-to-run, so it's a less controlled input — keep these scenarios
    focused on init + a simple orchestrator pass.
- `seed/` — initial application sources, including any files deliberately engineered to force
  a merge conflict or a post-merge integration-test failure.

## Note: the first dogfood run is a separate session

Building the harness (tooling + skill + scenario + unit tests) is independent of *running* a
full orchestrator dogfood. The first real `/swarm` run against `cli-task-manager` is a
deliberately deferred, separate session — the harness exists so that run is repeatable and its
output is analyzable.
