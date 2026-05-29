---
project: swarm-test-harness
requirements_doc: ./planning/swarm/test-harness-design.md
requirements_source: file
decomposition_mode: deliverable-partition
blocks: []
blocked_by: []
parallelizable_with: []
---

# Implementation Plan: `/swarm` Test Harness

## Approach

Build the bookends harness from the approved spec: deterministic Python (`generate`,
`ingest`) wrapped in a small CLI, a project-scoped `swarm:test` skill that drives the
agent-side `analyze`, and the `cli-task-manager` first scenario. The Python is TDD-friendly
(deterministic → unit-tested); the skill is prose validated by use; the scenario is validated
structurally (generate produces a valid repo from it). **The first real orchestrator dogfood
run is out of scope** (deferred session) — "done" here means tooling/skill/scenario/tests/docs
exist and unit tests pass.

### Key Insight

The `hard_invariants` checks are only as trustworthy as `ingest`'s mechanical detection.
`ingest` is the load-bearing deliverable: it must reliably extract safety signals (no remote
on the generated repo + no `push` in any log; no out-of-scope file writes per dispatch) and
per-role/status tallies. It is ordered before the skill that consumes it.

## Parent Acceptance Criteria

- [ ] **AC1** — `generate` builds a throwaway repo under `tests/swarm/runs/<name>-<ts>/` per
  spec §4: seed sources, `git init` + initial commit (real `main`), scenario `charter/` →
  `.agent-tools/charter/`, write `config.yml`, copy **current** `src/swarm/roles/*` →
  `.agent-tools/swarm/roles/`, write `.agent-tools/.gitignore`, place `backlog.md`, print the
  next-step command — and it validates the scenario exists + timestamps the run dir.
- [ ] **AC2** — The harness is a Python package invokable as
  `python -m tests.swarm.harness generate <name>`.
- [ ] **AC3** — `ingest` walks a run's `.agent-tools/swarm/sessions/<run-id>/**` and emits
  `observations.json` (per-role dispatch counts, status-code tallies, malformed-return count,
  return sizes, missing decision logs, safety signals), tolerating missing/partial/malformed
  logs; invokable as `python -m tests.swarm.harness ingest <run>`.
- [ ] **AC4** — Deterministic `generate` + `ingest` are covered by passing `pytest` unit
  tests.
- [ ] **AC5** — `src/swarm/test/SKILL.md` (`name: swarm:test`, `publish-target: project`)
  drives analyze per §5.2: check hard invariants (loud fail), judge checklist items with
  citations, cluster issues, propose evolve-style minimal diffs (one file / one gap / ≤40
  lines / evidence-linked), present for approval, write `analysis.md`.
- [ ] **AC6** — `tests/swarm/scenarios/cli-task-manager/` exists (`scenario.yml` +
  `backlog.md` with 5 dependency-linked items + `charter/` seed + `seed/` sources) engineered
  so item 3 conflicts with item 2 at merge, item 5 breaks a shared integration test
  post-merge, and item 4 enters unrefined; `generate` produces a valid repo from it.
- [ ] **AC7** — `tests/swarm/runs/` is gitignored and `tests/swarm/README.md` documents
  harness usage.

## AC Traceability Matrix

| Parent AC | Owning deliverable |
|-----------|--------------------|
| AC1, AC2 | D1 |
| AC3 | D2 |
| AC4 | D3 |
| AC5 | D4 |
| AC6 | D5 |
| AC7 | D6 |

---

## Deliverable Breakdown

### D1 — Harness package + `generate`
**Files:** `tests/swarm/harness/__init__.py`, `__main__.py`, `cli.py`, `generate.py`
**Inherited ACs:** AC1, AC2
- [ ] Package skeleton + `python -m tests.swarm.harness` CLI dispatch (argparse),
  `generate <scenario>` subcommand.
- [ ] `generate`: validate scenario exists; create timestamped `runs/<name>-<ts>/`; lay
  `seed/`; `git init` + initial commit; copy scenario `charter/` → `.agent-tools/charter/`;
  write `.agent-tools/swarm/config.yml`; copy **current** `src/swarm/roles/*` →
  `.agent-tools/swarm/roles/`; write `.agent-tools/.gitignore`; place `backlog.md`; print
  `cd … && /swarm backlog.md`.

### D2 — `ingest`
**Files:** `tests/swarm/harness/ingest.py` (+ `cli.py` `ingest` subcommand)
**Inherited ACs:** AC3
- [ ] Walk `sessions/<run-id>/**`; parse each dispatch's frontmatter + returned YAML (fenced
  block).
- [ ] Emit `observations.json`: per-role dispatch counts, status-code tallies,
  malformed-return count, return sizes, missing decision logs, safety signals (generated repo
  has no remote / no `push` in logs; out-of-scope file writes per dispatch).
- [ ] Tolerate missing logs (run not done), partial/TERMINAL_PAUSE runs, malformed logs
  (count, don't crash).

### D3 — Unit tests
**Files:** `tests/swarm/harness/tests/test_generate.py`, `test_ingest.py`, fixtures
**Inherited ACs:** AC4
- [ ] `generate` tests: builds expected tree, copies live roles, creates a real `main`,
  validates bad scenario name. Tiny throwaway fixture scenario + tmp dir.
- [ ] `ingest` tests: parses well-formed logs into correct tallies; handles
  malformed/missing/partial logs; flags a seeded safety violation.

### D4 — `swarm:test` analyze skill
**Files:** `src/swarm/test/SKILL.md` (`name: swarm:test`, `publish-target: project`)
**Inherited ACs:** AC5
- [ ] Procedure: run `ingest` → read `scenario.yml` + `observations.json` + spot-read logs →
  check hard invariants (loud FAIL) → judge checklist (cited) → cluster issues → propose
  evolve-style diffs to `src/swarm/roles/*.md` / `SKILL.md` / `references/` → present for
  approval → write `tests/swarm/runs/<run>/analysis.md`. No literal HTML-comment markers
  (publisher strips them).

### D5 — `cli-task-manager` scenario
**Files:** `tests/swarm/scenarios/cli-task-manager/{scenario.yml, backlog.md, charter/*, seed/*}`
**Inherited ACs:** AC6
- [ ] `scenario.yml` (intent + observation_checklist + hard_invariants + expected_exit per §3).
- [ ] `backlog.md`: 5 items with `blocks`/`blocked_by`/`parallelizable_with`; item 4
  (`search`) left deliberately unrefined.
- [ ] `charter/` seed (charter/project/engineering/workflow) for a Python+pytest CLI task
  manager.
- [ ] `seed/` sources engineered so #2 and #3 modify the **same** store/registry file (merge
  conflict) and a shared integration test exists that #5 (`stats`) breaks post-merge.
- [ ] Verify `generate cli-task-manager` produces a valid repo (structural check; orchestrator
  run is the deferred dogfood).

### D6 — Gitignore + docs
**Files:** `tests/swarm/.gitignore` (or root `.gitignore`), `tests/swarm/README.md`
**Inherited ACs:** AC7
- [ ] Gitignore `tests/swarm/runs/` (landed early, before any generate run).
- [ ] `tests/swarm/README.md`: the generate → run `/swarm` → analyze loop, scenario authoring,
  and the deferred-dogfood note.

#### Gap-prevention check
- [ ] Every AC owned by exactly one deliverable; matrix zero orphans.
- [ ] `src/swarm/` gains only `test/SKILL.md` (no other swarm files); no Phase-3 or
  evolve-mode files.

## Out of Scope (per spec §8)
- The first real orchestrator dogfood run (deferred session).
- Headless/unattended runs; mocked workers.
- Building the `/skills:evolve` log-evidence mode; fixing its stale glob.
- Additional scenarios beyond `cli-task-manager`.

## Technical Decisions
- **`ingest` is load-bearing** — built before the skill that depends on it.
- **Live-roles copy** — `generate` copies current `src/swarm/roles/*` each run so the harness
  always tests live content and re-runs validate evolve improvements (§3).
- **Scenario validated structurally only** — full behavioral validation is the deferred
  dogfood; this plan asserts generate succeeds.
- **Python stdlib-first** — argparse + pathlib + a YAML reader; follow `src/qa/tools/`
  conventions.

## Testing Strategy
- **Unit (deterministic):** pytest for `generate` + `ingest` (D3), TDD alongside D1/D2.
- **Skill (D4):** validated by use.
- **Scenario (D5):** structural validation via `generate`; behavioral deferred to dogfood.

## Implementation Order
D6 (gitignore first) → D1 (package + generate) → D2 (ingest) → D3 (unit tests) → D5 (scenario)
→ D4 (skill).

## Definition of Done
- [ ] All 6 deliverables complete; matrix zero orphans.
- [ ] `pytest tests/swarm/` green.
- [ ] `setup.sh` clean; `swarm:test` publishes project-scoped.
- [ ] `tests/swarm/runs/` gitignored; README present.
- [ ] Committed per `/git:commit`; **no push**. Dogfood run is a separate session.
