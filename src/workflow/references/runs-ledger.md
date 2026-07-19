# Runs ledger (line instrumentation)

**Load when:** continue records a phase-return, closes a unit, soft-checks thrash, or the user
asks for yield. This is the production-line scoreboard — not product-code logging
(`execution/logging.md`) and not L3 memory.

## Home

```text
.agent-tools/runs/
  README.md        # short: who writes / do not hand-edit vanity
  events.ndjson    # append-only event spine
  ledger.yml       # closed-run rollup rows
  yield.md         # optional regenerated glance (overwrite OK)
```

Scaffold via `/workflow:setup`. Prefer this path always (independent of planning-root migration).

**Language:** say **runs**, **run ledger**, **production line** — not “plant.”

## Single writer

| Actor | Writes events? |
|-------|----------------|
| `/workflow:continue` host | **Yes — primary** (after each phase-return) |
| Phase skills outside continue | Append one line if they complete a full phase alone |
| Human | Never required to fill forms |

Do **not** create a second per-unit orchestrator file. Session-state remains SoT for resume;
runs/ is plant-level (line-level) instrumentation that **survives** item prune via ledger rows.

## run_id

Mint on unit claim if missing: `r-YYYYMMDD-N` (N = next free that day). Store on unit
session-state frontmatter:

```yaml
run_id: r-20260718-1
track: micro | feature | research
reentry_counts:
  refine_from_execute_or_review: 0
  plan_from_execute_or_review: 0
thrash_bound_hits: 0
source_channel: cli | linear | github | chat | other
```

**Thrash bound is per `run_id`**, not per `/continue` invocation. Soft-check: if counters
already meet the bound when claiming, diagnose before burning another loop.

## Event line (NDJSON)

One object per line; justified by phase-return evidence only — never invent timestamps or events.

```json
{"ts":"2026-07-18T14:22:00-06:00","run_id":"r-20260718-1","unit":"SPEC-851","mode":"unit","track":"feature","phase":"review","status":"completed","events":["REVIEW_FINDINGS_CODE"],"from":"needs_review","to":"ready_execute","evidence":"P1=0 P2=2 P3=0","channel":"cli","fidelity":null}
```

| Field | Notes |
|-------|--------|
| `ts` | ISO-8601 when known |
| `run_id` | Required |
| `unit` | Issue key or slug |
| `mode` | unit \| swarm_* \| hard_stop* |
| `track` | micro \| feature \| research \| custom |
| `phase` | orient \| brainstorm \| refine \| plan \| execute \| review \| integrate \| compound \| portfolio |
| `status` | completed \| await_user \| blocked \| failed \| skipped |
| `events` | Names from unit-state-machine.md |
| `from` / `to` | States when transitioned |
| `evidence` | ≤120 chars locatable fact |
| `channel` | Ingress channel if known |
| `fidelity` | optional: review_ok \| review_theater \| compound_ok \| compound_none \| compound_missing |

### Host recipe (after each phase-return)

```text
1. Ensure run_id (+ track, reentry_counts) on session-state
2. Append one NDJSON line = phase_return + from/to + run_id + channel + track
3. If refine/plan reentry from execute/review → bump reentry_counts
4. If THRASH_BOUND → thrash_bound_hits += 1
5. On MERGED + COMPOUND_DONE → close run, append ledger.yml row (below)
6. Soft-fail if FS write fails — never hard-stop work for telemetry
```

**Do not** emit per-task, per-file-edit, or per-tool events (log bloat).

## Closed-run rollup (`ledger.yml`)

**When:** unit reaches `done` (merged + compound disposition), or explicit abandon.

**How:** compute from this `run_id`'s events + session-state counters — do not hand-wave.

```yaml
version: 1
runs:
  - run_id: r-20260718-1
    unit: SPEC-851
    track: feature
    opened: 2026-07-18
    closed: 2026-07-19
    channel: cli
    outcome: shipped   # shipped | abandoned | blocked_out
    sessions: 3
    ttm_hours: 28      # only if known; else null
    refine_reentries: 1
    plan_reentries: 0
    review_cycles: 2
    thrash_bound_hits: 0
    rework: true
    fidelity:
      review: ok       # ok | theater | missing | n/a
      compound: ok     # ok | none_reasoned | missing | n/a
```

**Shipped** under local-merge policy: merged to main + valid review evidence + compound
disposition (capture or reasoned none).

**Close recipe:**

```text
1. Count events for run_id: refine/plan reentries, REVIEW_* cycles, thrash
2. fidelity.review from last valid review evidence vs theater soft-check
3. fidelity.compound from COMPOUND_DONE + none_reasoned vs missing
4. rework: true if any execute/review → refine/plan edge in events
5. Append row to ledger.yml (create file with version: 1 if missing)
6. Clear open thrash urgency on session-state; keep run_id for history
```

## Yield glance (`yield.md`)

**Triggers (any):**

- User invokes continue with yield intent: `--yield`, `yield`, or “show run yield”
- Soft weekly offer: glance missing/older than 7d **and** ≥5 closed runs since last generate
- Optional: after close-run when user is in a recap and asks

**Never** block claim for metrics. **Never** hand-edit vanity numbers — regenerate from
`ledger.yml` (+ open runs from recent events if cheap).

### Yield document shape (overwrite entire file)

```markdown
# Run yield

Generated: <ISO date>
Closed runs in ledger: <N>

## KPIs (from ledger)

| KPI | Value |
|-----|--------|
| Shipped (last 30d) | n |
| Rework rate | % of closed with rework: true |
| Thrash rate | % with thrash_bound_hits > 0 |
| Review fidelity ok | % |
| Compound fidelity ok/none_reasoned | % |
| Median ttm_hours | value or n/a |

## By track

| track | shipped | rework |
|-------|---------|--------|

## Recent closed (max 10)

| run_id | unit | track | outcome | closed |
|--------|------|-------|---------|--------|

## Notes

One line only if something structural stands out (e.g. thrash cluster). Else omit.
```

Derived KPIs: ship rate, stuck open runs (optional from events), rework rate, thrash rate,
review/compound fidelity, median TTM when known, channel mix.

## Process self-improvement

Repeated thrash/rework/fidelity failures are **gap evidence**, not a license to edit skills.

1. Optionally capture a memory entry (`type: process`) via `/workflow:compound`.
2. Corpus changes only via **`/skills:evolve`** (detect → propose → validate → present).
3. Feed evolve with run_ids, oscillation notes, soft-check hits — not vibes.

Do **not** invent `/workflow:improve` or auto-patch the skill tree from the ledger.

## Anti-patterns

- Metric theater (phases-run vanity without outcomes)
- Dual FSM in `run.yml` fighting session-state
- PM comment spam per transition
- Full conversation dumps under `runs/`
- Hard-stopping continue when append fails
