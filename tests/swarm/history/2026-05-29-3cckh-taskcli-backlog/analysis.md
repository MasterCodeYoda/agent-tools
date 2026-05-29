# Swarm Run Analysis — cli-task-manager (2026-05-29-3cckh-taskcli-backlog)

Analyzed 2026-05-29. Evidence sources: `orchestrator.md`, `state.yml`, `observations.json`,
and the complete Claude Code session history under
`~/.claude/projects/-Users-matthew-overlund-Source-OMG-agent-tools-tests-swarm-runs-cli-task-manager-20260529-095711/`
(orchestrator transcript `3ecc0c7c…jsonl` — 17 Task dispatches / 21 tool_result returns — plus
7 reviewer sub-sessions and the worker sidechains under `…/subagents/`).

## Hard invariants
- `no_remote_push`: **PASS** — `git remote -v` empty in run repo; `observations.safety.remotes=[]`
  and `push_mentions=[]`; the only "git push" string across the full transcript history is the
  skill's own negated policy text ("`git push` is always user-initiated").
- `run_terminates`: **PASS** — `state.yml.exit_state: GOAL_COMPLETE` (terminal).
- `every_item_terminal`: **PASS** — CTM-1..CTM-5 all `stage: merged`; suite 49 passed.

## Observation checklist
- `foundation-first`: **satisfied** — Waves 1–3 + merge sweep land CTM-1 (`main@e8c2a8f`) before
  dependents dispatch in Wave 4 (`orchestrator.md:19-30`).
- `parallel-wave`: **satisfied** — CTM-2/3/4 planners (Wave 4) and implementers (Wave 5) run in
  the same wave; transcript shows the three Plan dispatches issued together (`orchestrator.md:36-46`).
- `conflict-resolver-fires`: **satisfied (×2)** — CTM-2 merged clean; CTM-3 conflicted on `cli.py`
  → conflict-resolver `@8cb88fb`; CTM-4 conflicted on 3 regions → conflict-resolver `@ec208a4`
  (`orchestrator.md:49-55`; 2 resolver returns recovered from transcript).
- `host-refinement`: **satisfied** — CTM-4 entered `unrefined`; orchestrator refined host-side,
  wrote `planning/CTM-4/requirements.md`, advanced `unrefined→refined` (`orchestrator.md:32-34`).
  Note: the log describes the refinement decisions but does not name a `/workflow:refine`
  invocation explicitly.
- `integration-fixer-fires`: **not satisfied** — the CTM-5 planner pre-empted the intended
  empty-store divide-by-zero with an `if total==0` early return (`orchestrator.md:60,63`), so the
  integration test never broke and no integration-fixer was dispatched (0 of 17). Benign:
  scenario-seed weakness, not a role regression.
- `review-fix-loop`: **not satisfied** — all 5 reviewer returns are `APPROVED`; zero
  `FIX_REQUESTED` anywhere in the transcript. No implementer re-dispatch occurred.
- `clean-exit`: **satisfied** — all merged, `GOAL_COMPLETE`, active-run cleared (`orchestrator.md:70`).

Observed `exit_state` = expected (`GOAL_COMPLETE`). The two unsatisfied items are scenario-seed
weaknesses (proactive planning + clean first-pass approvals pre-empted both engineered failure
paths) — surfaced for a separate decision; the seed was not weakened.

## Issue clusters
- **C1 — Harness ingester extracts zero evidence (HIGH, tooling).** `ingest.py` reported
  `dispatch_count: 0` and flagged all 9 logs "malformed frontmatter": it expected leading
  frontmatter + a `## Return` block per `<role>-N.md`, but `worker-contract.md` persisted only a
  free-form `## Decision log` — the structured return went to the orchestrator transcript. The
  two halves of the harness disagreed. Fixed (see Proposals).
- **C2 — Reviewer wrote no decision logs (LOW).** Planner and implementer wrote `<role>-N.md` per
  item; no `reviewer-N.md` exists anywhere, though all 5 reviewers ran. Consistent with the
  contract's "best-effort" framing; weighted lightly.
- **C3 — Stale `log_file` pointers in state.yml (LOW).** For CTM-2/3/4/5, `last_completed.role:
  reviewer` but `last_completed.log_file` points at `…/planner-1.md` (a fallback, since the
  reviewer log does not exist). Same root cause as C2.
- **C4 — Reviewer approved a spec-nonconforming implementation (MEDIUM, real escape).** CTM-4
  search printed 0-based indices; its refined AC required an index "feedable to complete/delete"
  (1-based, like `list`). The CTM-4 reviewer return is bare — unlike the AC-by-AC verification in
  the CTM-1/2/3/5 returns, it carries no checklist, just `test_status: pass`. The bug escaped
  review and was caught only by a post-run live smoke test (`orchestrator.md:73-75`, fix `@37a02d1`).

## Proposals
- `src/swarm/roles/reviewer.md` — **C4** — **applied** — added one scope bullet: a green suite is
  necessary but not sufficient; verify each AC behaviorally, with special attention to ACs that
  reference another command's contract (e.g. an index "feedable to" another command), by
  exercising the commands together. Evidence: `orchestrator.md:73-75` + the bare CTM-4 reviewer
  return.
- `src/swarm/roles/worker-contract.md` — **C1 (worker side) / C2 / C3** — **applied** — workers now
  also persist their structured return (leading frontmatter + `## Return` block) into their
  `<role>-N.md` log, so a run can be summarized deterministically from session logs alone.
- `tests/swarm/harness/ingest.py` — **C1 (harness side)** — **applied** — added a transcript
  fallback: when no on-disk log carries a parseable return, the ingester locates the orchestrator
  transcript under `~/.claude/projects/` and recovers `{role, status, item}` per dispatch from the
  `tool_result` returns. On this run it recovered 18 returns (6 planner / 5 implementer / 5
  reviewer / 2 conflict-resolver). Both directions were approved so future runs are covered either
  way. All 11 existing `test_ingest` cases still pass.

Recovery note: 18 returns vs 17 Task dispatches — the extra is one planner-role return whose
`item:` did not parse (`item: unknown`), most likely the host-side CTM-4 refinement return, which
is formatted differently from a dispatched worker's. Best-effort enrichment; does not affect any
invariant.

## Exit
Observed `exit_state: GOAL_COMPLETE` matches the scenario's intended `expected_exit`. The run was
clean and correct but exercised only 5 of 7 engineered behaviors; the integration-fixer and
review-fix-loop paths were pre-empted by strong planning and clean first-pass reviews — a signal
that the scenario seed should force those failures harder if exercising those roles is the goal.
