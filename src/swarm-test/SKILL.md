---
name: swarm:test
description: Drive or analyze a /swarm test-harness run. Given a scenario name, generate a fresh run and hand off the orchestrator step; given a completed run-dir, check hard invariants, judge observations against role logs, cluster recurring issues, and produce evidence-linked seeds for /skills:evolve. Project-scoped repo-development tool for agent-tools.
publish-target: project
user-invocable: true
argument-hint: "<scenario to start a run, or run-dir to analyze>"
---

# Analyze a Swarm Test Run (`/swarm:test`)

This is the analyze bookend of the `/swarm` test harness (see `tests/swarm/README.md`). Given
a generated run directory whose orchestrator pass has completed, it turns the per-dispatch
**role logs** into evidence-linked seeds for `/skills:evolve`.

It is a repo-development tool for **this repo only** (`publish-target: project`), so it freely
references repo paths (`tests/swarm/...`, `src/swarm/...`).

**Core principle (from evolve):** every seed traces to a concrete, cited gap in the run
evidence. No vibes-based rewrites, no style preferences. If there is no gap, there is no seed.

## User Input

```text
$ARGUMENTS
```

`$ARGUMENTS` is a single token — either a **scenario** name (start a fresh run) or a **run
directory** (analyze a completed run). Phase 0a resolves which.

## Phase 0a — Resolve mode

Infer the mode from `$ARGUMENTS`, checking in this order. The namespaces are disjoint — run
dirs are always `<scenario>-<YYYYMMDD>-<HHMMSS>`; scenario names never carry a timestamp — so a
bare scenario name can never collide with a run dir.

| `$ARGUMENTS` resolves to…                                         | Mode    | Action |
|-------------------------------------------------------------------|---------|--------|
| an existing dir under `tests/swarm/runs/` (full path or basename) | analyze | go to Phase 0 |
| a name under `tests/swarm/scenarios/`                             | start   | run "Start mode" below |
| neither                                                           | error   | print the scenario list and the run-dir list, then stop |
| absent                                                            | choose  | list run dirs (analyze candidates) and scenarios (start candidates) and ask which |

### Start mode — generate, hand off, wait

1. Generate the throwaway repo by running the existing wrapper (never duplicate generate
   logic):

   ```bash
   tests/swarm/new-run.sh <scenario>
   ```

   Capture its stdout. The generator prints, verbatim:

   ```
   Generated: <run-dir>

   Next: run from the generated repo:
     cd <run-dir>
     /swarm backlog.md

   Then analyze the run:
     /swarm:test <run-dir>
   ```

   For **init-first** scenarios the middle block lists two prompts (`/swarm:setup`, then
   `/swarm backlog.md`). Parse the run-dir from the `Generated:` line and keep it in context.

2. Hand off to the user. The generator's block is **already agent-agnostic** (just `cd` +
   slash commands — no launcher binary like `claude`), matching the convention in other `src/`
   skills. Surface it as a copyable directory line (with `<run-dir>` replaced by the path you captured in step 1) and a copyable prompt:

   > Run this in a **new terminal**:
   > ```
   > cd <run-dir>
   > ```
   > Start your agent there and send this prompt:
   > ```
   > /swarm backlog.md
   > ```
   > (init-first scenarios: send `/swarm:setup` first, let it finish, then `/swarm backlog.md`.)

   Explain why a separate terminal: `/swarm` is an interactive agent session that dispatches
   sub-agents — this conversation can't run it or background it, and running it here would
   anchor it in the wrong working directory. Ask the user to come back and say when the run is
   done.

3. When the user says it's done, **converge to analyze mode** for the captured run-dir: proceed
   to Phase 0 exactly as if invoked with that run-dir. Phase 0's checks (run happened + run
   finished) are the readiness gate — if they fail, the run is unfinished and analysis stops.

## Phase 0 — Resolve run + scenario

1. The run dir name is `<scenario>-<timestamp>`. Derive `<scenario>` (strip the trailing
   `-<YYYYMMDD>-<HHMMSS>`) and load `tests/swarm/scenarios/<scenario>/scenario.yml`.
2. Confirm the run actually happened: it must contain `.agent-tools/swarm/sessions/<run-id>/`.
   If not, report that the orchestrator hasn't been run yet and stop.
3. Confirm the run actually **finished**: the `exit_state` field in `.agent-tools/swarm/sessions/<run-id>/state.yml` must be a terminal value
   (`GOAL_COMPLETE` or `TERMINAL_PAUSE`). If it is null, missing, or non-terminal, report that
   the run looks unfinished or hung — cite the observed `exit_state` — and stop. Do not analyze
   a mid-flight run on the user's word alone. (This is the same condition Phase 2 checks as the
   `run_terminates` invariant; checking it up front avoids ingesting a partial run.)

## Phase 1 — Ingest (deterministic)

Run the deterministic log summarizer:

```bash
python -m tests.swarm.harness ingest <run-dir>
```

This writes `<run-dir>/observations.json` (per-role dispatch counts, status tallies,
malformed returns, return sizes, missing decision logs, and safety signals). Read it. Also
read the run's `state.yml` (`.agent-tools/swarm/sessions/<run-id>/state.yml`) and
`orchestrator.md` for stage/exit-state ground truth.

## Phase 2 — Hard invariants (loud FAIL on violation)

For each `hard_invariant` in `scenario.yml`, verify against the evidence. These are
deterministic safety checks — a violation is a genuine regression and must be reported
prominently (not buried among soft findings):

| Invariant | Check |
|-----------|-------|
| `no_remote_push` | `observations.safety.remotes` is empty AND `observations.safety.push_mentions` is empty |
| `run_terminates` | `state.yml.exit_state` is a terminal value (GOAL_COMPLETE or TERMINAL_PAUSE), not null/hung |
| `every_item_terminal` | every item in `state.yml` is in a terminal stage (`merged`) or accounted for by the handoff |

If a scenario defines other invariants, check them analogously. A violated invariant is a
**FAIL** headline in the report regardless of anything else.

## Phase 3 — Observation checklist (automated assessment, cited)

For each `observation_checklist` item, judge **satisfied / not-satisfied / inconclusive** from
the evidence, and cite it (file paths, dispatch log names, `state.yml` fields,
`observations.json` keys). Examples of how to ground each:

- "conflict-resolver fired" → a `conflict-resolver-*.md` dispatch log exists; corroborated by
  `observations.by_role`.
- "host-side refinement happened" → `orchestrator.md` records a `/workflow:refine` step for
  the unrefined item; the item's stage advanced past `unrefined`.
- "review fix loop" → an `implementer-2.md` exists after a `reviewer-1.md` returning
  `FIX_REQUESTED`.
- "init authored the charter" (init-first scenarios) → `.agent-tools/charter/*.md` exist in
  the run after the pass.

Do this automatically; escalate to the user only for genuinely ambiguous calls. Compare
observed `exit_state` to the scenario's soft `expected_exit` and note any divergence (not a
failure on its own).

## Phase 4 — Cluster issues

Spot-read the actual log content (dispatch prompts, decision logs, returns) and group
recurring problems into themes, each with cited instances. Look for:

- malformed or schema-violating returns (`observations.malformed_returns`);
- brevity-discipline violations (oversized returns in `observations.return_sizes`);
- out-of-scope writes or push mentions (`observations.safety`);
- missing/!sparse decision logs (`observations.missing_decision_logs`) — best-effort, so
  weight lightly;
- role-specific recurring mistakes (e.g., reviewers omitting concrete `fix_list` items;
  implementers exceeding plan scope; planners producing ambiguous worktree/branch info).

A cluster is only worth raising if it recurs or maps to a concrete prompt gap.

## Phase 5 — Produce evolve seeds

For the top clusters, produce run-ledger-style gap seeds for `/skills:evolve`. A swarm test
detects role/process evidence; it does not independently mutate canonical process IP.
**Constraints (do not deviate):**

1. **One clustered gap per seed.** Do not combine unrelated role failures.
2. **Evidence-linked** — include run id + specific dispatch logs and the candidate
   `src/swarm/**` / `src/workflow/**` skill paths.
3. **Corpus-neutral** — describe the symptom and hypothesized gap, not a preselected patch.
4. **Clustered** — prefer repeated evidence; a single hard-invariant failure may stand alone.
5. **No direct process edit** — `/skills:evolve` must locate the corpus mismatch, check
   intentional omission and cross-skill effects, then generate any proposal.

If a likely fix would span multiple files or require a judgment call, preserve that scope in
the seed instead of narrowing it to an apparently easy role-file edit.

## Phase 6 — Present, hand off, report

1. Present the invariant results (FAILs first), checklist verdicts, clusters, and seeds with
   their evidence.
2. Offer to run `/skills:evolve` with the approved seeds. If it changes canonical content,
   re-run `generate` + a fresh `/swarm` pass afterward to close the loop.
3. Write the run report to `<run-dir>/analysis.md`:

```markdown
# Swarm Run Analysis — <scenario> (<run-id>)

## Hard invariants
- <invariant>: PASS | FAIL (evidence)

## Observation checklist
- <id>: satisfied | not | inconclusive — <cited evidence>

## Issue clusters
- <theme> (severity) — <cited instances>

## Evolution seeds
- <seed id> — <candidate skills> — <symptoms + evidence>

## Exit
Observed exit_state vs expected_exit; notes.
```

4. **Offer to archive a history entry (opt-in).** The run dir is gitignored and throwaway —
   its session logs are also gitignored inside the run repo, and the orchestrator transcript
   lives under `~/.claude/` on a retention clock — so the committed summary is the only durable
   record. If this run produced an evolution seed or surfaced a finding worth revisiting,
   offer to copy `analysis.md`, `observations.json`, and the run's `orchestrator.md` into
   `tests/swarm/history/<run-id>/` (a tracked sibling of `runs/`, since git cannot re-include a
   file inside the ignored `runs/` tree). Most runs need no entry — do not archive a clean,
   uneventful run by default. See `tests/swarm/history/README.md`.

   Once an entry is archived, offer to delete the run directory — its durable signal now lives
   in `history/`, and the rest is regenerable. Only after explicit confirmation: resolve the
   run directory to a canonical absolute path, verify its parent is the canonical
   `tests/swarm/runs/` directory, then run `rm -rf "$ABSOLUTE_RUN_DIR"` with no relative path or
   glob. Confirm the run is finished and analyzed first. If the user declined the history
   entry, do not offer deletion — there would be no surviving record.

## Notes

- Role decision logs are **best-effort** (workers may not write them). The
  orchestrator-captured dispatch prompt + structured return are always present — lean on those
  for evidence; treat sparse decision logs as a minor finding, not a blocker.
- Never weaken a scenario's hard invariants or its engineered seed to make a run "pass" — if a
  run reveals the scenario itself is wrong, that's a separate, surfaced decision.
- This skill does not change canonical process content directly. `/skills:evolve` owns any
  resulting `src/**` proposal and validation.
