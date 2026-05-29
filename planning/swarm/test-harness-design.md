# `/swarm` Test Harness — Design

**Status**: Design approved; ready for implementation planning.
**Date**: 2026-05-28
**Authors**: Matt Overlund + Claude (collaborative brainstorming)
**Scope**: A permanent, reusable harness for exercising `/swarm` end-to-end against engineered
scenarios, and turning the resulting role logs into evolve-style improvements to the swarm
role templates and skills.

---

## 1. Overview & Shape

The harness exercises the full `/swarm` orchestration lifecycle against deliberately
engineered scenarios, then feeds the resulting per-dispatch role logs back into targeted,
evidence-linked improvements of the role/skill content. It is a **repo-development tool**
(like `skills:evolve`), so it is **project-scoped** — installed only inside the agent-tools
repo, never published to user profiles.

### Central constraint: the orchestrator is agent-driven

`/swarm <goal>` is not a deterministic function a test runner can call and await — running it
means an agent interprets the skill, dispatches sub-agents, makes IN_FLIGHT decisions, and
runs host-side refinement with a human. The harness therefore uses a **bookends** model:
deterministic Python on each side, with the agent-driven `/swarm` run in the middle.

1. **`generate`** (deterministic Python) — builds a throwaway git repo from a scenario
   definition.
2. **agent runs `/swarm`** (not scriptable) — the human/agent runs the orchestrator on the
   generated repo, producing session logs.
3. **`analyze`** (agent-driven, backed by deterministic Python ingest) — auto-evaluates
   observed-vs-expected, clusters issues, proposes minimal role/skill diffs, and presents
   them for human review.

### Relationship to `/skills:evolve`

`/skills:evolve` is corpus-introspective: it reasons only from the static skill files and
targets `SKILL.md` units. It cannot ingest runtime evidence (role logs) or improve role
*templates* from execution traces. This harness is the **log-driven, evidence-based**
counterpart. We are deliberately building it as a standalone capability now (decision below),
and treating the experience as the concrete spec for a future `/skills:evolve` log-evidence
mode. (Hybrid path — "C" — agreed during brainstorming.)

A separate, pre-existing issue worth noting: `/skills:evolve`'s detection globs
`src/skills/*/SKILL.md`, which is stale relative to the flattened `src/<family>/` layout. Out
of scope here; flagged for a separate fix.

---

## 2. Layout

```
tests/
  swarm/                       # the E2E swarm harness (NEW)
    scenarios/<name>/          #   committed scenario definitions
      scenario.yml             #     intent, observation checklist, hard invariants, expected exit
      backlog.md               #     local backlog the orchestrator ingests (items + deps)
      charter/                 #     seed charter for the generated repo (deterministic; skips init)
      seed/                    #     initial app source; incl. files engineered to force conflict / integration break
    harness/                   #   deterministic Python (repo tooling; NOT published)
      generate.py              #     scenario → throwaway repo
      ingest.py                #     session logs → observations.json
      cli.py                   #     `python -m tests.swarm.harness generate|ingest <scenario>`
    runs/                      #   GITIGNORED — generated repos + analysis outputs
  skill-eval/scenarios/<name>/ # pre-existing static skill-eval fixtures (moved here in a precursor commit)
src/swarm/test/SKILL.md        # name: swarm:test, publish-target: project — the analyze driver
```

**Precursor (already done):** the previously-flat `tests/scenarios/*` static fixtures were
moved to `tests/skill-eval/scenarios/*` via `git mv` (history preserved) so the swarm harness
gets its own `tests/swarm/` grouping. No functional references broke; the only mention is a
dated historical entry in `src/skills/evolve/history.md`, intentionally left intact.

**Skill location:** `src/swarm/test/SKILL.md`, `name: swarm:test`, `publish-target: project`.
It is invocable as `/swarm:test` **only** inside the agent-tools repo (project-scoped, like
`skills`), and is kept out of the end-user swarm command table. Because it is project-scoped,
it may reference repo-root paths (`tests/swarm/...`, `src/swarm/roles/...`) directly — it only
ever runs in this repo.

---

## 3. Scenario Definition

Each scenario under `tests/swarm/scenarios/<name>/` is one engineered story. Expected results
are expressed as **intent + observation checklist + a thin layer of hard invariants** — never
exact-count assertions, which would be brittle against legitimate run-to-run variation.

### `scenario.yml`

```yaml
name: cli-task-manager
purpose: Exercise the full lifecycle incl. both merge-sweep failure paths and host-side refinement.
stack: python                  # generate seeds a pytest project
expected_exit: GOAL_COMPLETE    # the INTENDED terminal exit — checked softly (a scenario may
                                # legitimately end in TERMINAL_PAUSE); analyze reports observed
                                # vs. intended as a checklist item, not a hard failure

hard_invariants:               # deterministic safety layer — analyze FAILS LOUDLY if violated
  - no_remote_push              # no worker or orchestrator pushed to a remote
  - run_terminates              # reached SOME terminal exit state (not hung) — note: this is
                                # weaker than expected_exit; it only asserts the loop ended
  - every_item_terminal         # no item left stuck mid-stage at exit

observation_checklist:         # soft intent — seeds analyze's automated assessment
  - id: conflict-resolver-fires
    expect: item `complete-delete` conflicts with `add-list` at merge; conflict-resolver dispatched
  - id: integration-fixer-fires
    expect: `stats` passes own tests, breaks shared integration test post-merge; integration-fixer dispatched
  - id: review-fix-loop
    expect: at least one reviewer FIX_REQUESTED → implementer re-dispatch
  - id: host-refinement
    expect: `search` enters unrefined; orchestrator runs /workflow:refine host-side
  - id: parallel-wave
    expect: independent items dispatched in the same wave
```

### Roles & charter are not frozen

`generate` copies the **current** `src/swarm/roles/*` into the generated repo's
`.agent-tools/swarm/roles/` on every run. The harness therefore always tests live role
content — and re-running a scenario after an `analyze` pass tests the improved versions. The
`charter/` seed is committed per-scenario so the run is deterministic and skips agent-driven
`/swarm:init`.

---

## 4. `generate` (deterministic Python)

`python -m tests.swarm.harness generate <name>`:

1. Create `tests/swarm/runs/<name>-<timestamp>/`.
2. Lay down `seed/` sources; `git init` + initial commit (a real `main` with history, so
   worktrees and merges work).
3. Copy scenario `charter/` → `.agent-tools/charter/`; write `.agent-tools/swarm/config.yml`;
   copy **current** `src/swarm/roles/*` → `.agent-tools/swarm/roles/`; write
   `.agent-tools/.gitignore`.
4. Place `backlog.md` at the repo root of the generated repo.
5. Print the exact next step, e.g.:
   `cd tests/swarm/runs/<name>-<ts> && /swarm backlog.md`.

Pure scaffolding, no agent reasoning — unit-testable with pytest.

---

## 5. `analyze` (agent skill + Python ingest)

Two layers.

### 5.1 `ingest.py` (deterministic)

Walk the run's `.agent-tools/swarm/sessions/<run-id>/**`, parse each dispatch's frontmatter +
returned YAML, and emit `observations.json`:

- per-role dispatch counts and status-code tallies;
- malformed-return count;
- return sizes (brevity signal);
- missing decision logs;
- mechanical safety signals: any `git push`? any file/worktree touched outside the item's
  scope?

### 5.2 Agent assessment (the `/swarm:test` skill)

Read `scenario.yml` + `observations.json` + spot-read real log text, then:

1. **Invariants** — check the `hard_invariants` list; any violation is a loud FAIL (genuine
   regression).
2. **Checklist** — for each `observation_checklist` item, judge satisfied / not-satisfied from
   evidence, with citations. Mostly automated; escalate to the human only on genuine judgment
   calls.
3. **Cluster** issues into themes across logs (e.g., "reviewers omit concrete `fix_list`
   items", "implementer exceeded plan scope on item X").
4. **Propose** evolve-style diffs — one file, one gap, ≤40 lines, evidence-linked (citing the
   log evidence) — to `src/swarm/roles/*.md`, and to `src/swarm/SKILL.md` / `references/` when
   the gap is there.
5. **Present for review**, apply approved diffs, and write the run report to
   `tests/swarm/runs/<run>/analysis.md`.

This is the evolve loop (detect → propose → validate → present) with **swarm session logs as
the evidence source** — the concrete prototype of the deferred log-evidence evolve mode.

---

## 6. First Scenario, Error Handling, Testing the Harness

### 6.1 First scenario — `cli-task-manager`

A small, real Python CLI task manager (pytest), with a 5-item backlog engineered to hit every
role and both merge-sweep failure paths:

| Item | Exercises | Engineered so that… |
|------|-----------|---------------------|
| 1. Core model + store | planner→implementer→reviewer, clean merge | foundational; others depend on it |
| 2. `add` + `list` | parallel wave with #3 | independent of #3 (different files) |
| 3. `complete` + `delete` | **conflict-resolver** | touches the same store file as #2 → merge conflict |
| 4. `search` (left **unrefined**) | **host-side refiner** | enters backlog vague → orchestrator runs `/workflow:refine` |
| 5. `stats` | **integration-fixer** + **reviewer FIX_REQUESTED loop** | passes own tests but breaks a shared integration test post-merge; review likely requests a fix first |

One run yields logs covering: planner, implementer (incl. a fix-request re-dispatch), reviewer
(APPROVED + FIX_REQUESTED), conflict-resolver, integration-fixer, host-side refinement,
dependency-aware wave scheduling, and all three exit states.

### 6.2 Error handling

- `generate`: validate the scenario exists; timestamp run dirs (no collisions).
- `analyze`: tolerate missing logs (run not done), partial/TERMINAL_PAUSE runs (may be a
  scenario's expected outcome), and malformed logs (counted as a finding, not a crash).

### 6.3 Testing the harness itself

- `generate.py` and `ingest.py` are deterministic → pytest unit tests.
- The agent-driven assessment is validated by use, not unit tests.

---

## 7. Decisions Captured

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Execution model | Bookends (deterministic generate/analyze; agent runs `/swarm`) | Only model that yields real role logs while staying maintainable; honors agent-in-the-loop |
| Expected-results rigor | Intent + observation checklist + thin hard invariants | Robust to non-determinism; human judgment is the real signal; invariants still catch true regressions cheaply |
| `analyze` automation | Automated assessment first; human approves; escalate only judgment calls | Faster, repeatable; mirrors evolve's detect→propose→validate→present |
| `analyze` packaging | New project-scoped skill `swarm:test` + Python helpers | Discoverable, repeatable; separates deterministic Python from agent reasoning; no blocking evolve refactor |
| Evolve relationship | Standalone now; spec a future evolve log-evidence mode from this | Immediate value without an evolve rewrite (hybrid "C") |
| Test grouping | `tests/swarm/`; existing fixtures → `tests/skill-eval/scenarios/` (precursor, done) | Avoids collision with the distinct static-fixture paradigm |
| App stack | Python + pytest | Fast, deterministic, least ceremony |
| Backlog source | Local backlog file (not real Linear) | Disposable dogfood; no external writes |

## 8. Out of Scope

- Fully-automated unattended `/swarm` runs (headless agent) — the orchestrator's interactive
  steps (host-side refinement, IN_FLIGHT decisions) don't fit headless; and it would obscure
  what we're evaluating.
- Mocked workers — would test orchestrator plumbing, not real role-prompt quality (defeats the
  purpose).
- Building the `/skills:evolve` log-evidence mode — deferred; this harness is its prototype.
- Fixing the stale `src/skills/*/SKILL.md` glob in `/skills:evolve` — separate concern.
- Additional scenarios beyond `cli-task-manager` — added later as the library grows.
