# `/swarm` Test Harness

A permanent harness for exercising the `/swarm` orchestrator end-to-end against engineered
scenarios, and turning the resulting role logs into evidence-linked improvements to the swarm
role templates and skills.

Design: [`../../planning/swarm/test-harness-design.md`](../../planning/swarm/test-harness-design.md).
Plan: [`../../planning/swarm/implementation-plan-test-harness.md`](../../planning/swarm/implementation-plan-test-harness.md).

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

1. **Generate a throwaway repo from a scenario:**

   ```bash
   tests/swarm/new-run.sh cli-task-manager      # convenience wrapper (default scenario if omitted)
   # or, equivalently:
   python -m tests.swarm.harness generate cli-task-manager
   ```

   `new-run.sh` runs from anywhere, lists scenarios (`--list`), and has a `--path` mode that
   prints only the run dir — handy for `cd "$(tests/swarm/new-run.sh --path cli-task-manager)"`.

   Builds `tests/swarm/runs/<name>-<timestamp>/` — a real git repo seeded with the scenario's
   sources, a charter, swarm `config.yml`, the **current** `src/swarm/roles/*` (so you always
   test live role content), and the backlog. It prints the exact next step.

2. **Run the orchestrator** (in an agent session), from the generated repo:

   ```
   cd tests/swarm/runs/<name>-<timestamp>
   /swarm backlog.md
   ```

   This produces per-dispatch session logs under
   `.agent-tools/swarm/sessions/<run-id>/<item>/<role>-<n>.md`.

3. **Analyze the run** with the project-scoped skill:

   ```
   /swarm:test <run-dir>
   ```

   It runs the deterministic `ingest` (logs → `observations.json`), checks the scenario's
   hard invariants (loud fail on violation), judges the observation checklist with citations,
   clusters issues, and proposes minimal, evidence-linked evolve-style diffs to
   `src/swarm/roles/*.md` (and `SKILL.md` / `references/`) for your review. The run report is
   written to `tests/swarm/runs/<run-dir>/analysis.md`.

Re-running `generate` after applying analyze's diffs tests the **improved** role content,
closing the loop.

## Layout

```
tests/swarm/
  scenarios/<name>/     committed scenario definitions (scenario.yml, backlog.md, charter/, seed/)
  harness/              deterministic Python (generate, ingest, cli) + unit tests
  runs/                 GITIGNORED — generated repos + analysis outputs
```

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
    begins with `/swarm:init`, which detects the stack, authors the charter, and bootstraps
    the umbrella itself. Use this to exercise `/swarm:init` (e.g. `greenfield-init`). Note the
    charter then varies run-to-run, so it's a less controlled input — keep these scenarios
    focused on init + a simple orchestrator pass.
- `seed/` — initial application sources, including any files deliberately engineered to force
  a merge conflict or a post-merge integration-test failure.

## Note: the first dogfood run is a separate session

Building the harness (tooling + skill + scenario + unit tests) is independent of *running* a
full orchestrator dogfood. The first real `/swarm` run against `cli-task-manager` is a
deliberately deferred, separate session — the harness exists so that run is repeatable and its
output is analyzable.
