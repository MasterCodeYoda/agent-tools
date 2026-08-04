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

Scaffold via `/work:setup`. Prefer this path always (independent of planning-root migration).

**Language:** say **runs**, **run ledger**, **production line**.

## Single writer

| Actor | Writes events? |
|-------|----------------|
| `/work:continue` host | **Yes — primary** (after each phase-return) |
| bare `/work` (status) | **Never** — read-only portfolio glance |
| Phase skills outside continue | Append one line if they complete a full phase alone |
| Human | Never required to fill forms |

Do **not** create a second per-unit orchestrator file. Session-state remains SoT for resume;
runs/ is line-level instrumentation that **survives** item prune via ledger rows.

## run_id + identity envelope (claim-time)

Mint on unit claim if missing: `r-YYYYMMDD-N` (N = next free that day). Store on unit
session-state frontmatter **and** echo on every NDJSON line (greppability > bytes).

```yaml
run_id: r-20260718-1
track: micro | feature | research
reentry_counts:
  refine_from_execute_or_review: 0
  plan_from_execute_or_review: 0
thrash_bound_hits: 0
source_channel: cli | linear | github | chat | other   # ingress only — not harness
# Identity envelope (capture early; analyze later — non-reconstructible if skipped)
harness: grok-build | claude-code | kevin-hermes | codex | cursor | other | unknown
agent_surface: work-continue | work-phase | kevin-start | swarm-worker | unattended | other
model: "<provider model id or unknown>"
skills_rev: "<short sha | full agent-tools-rev=… stamp | unknown | dirty>"
profile: kevin | null          # host profile name when applicable
workspace_kind: skill_source | product_repo | sandbox | unknown
task_shape: packaging | bug | multi_file | recovery | research | docs | other | unknown
```

| Field | Purpose |
|-------|---------|
| `harness` | Which coding host ran the line (Kevin vs Grok vs Claude …) |
| `agent_surface` | How process was invoked (continue vs freeform start vs swarm) |
| `model` | Fair comparison / scorecard bands |
| `skills_rev` | Published process IP attribution — **resolve at claim**, do not leave blank or habitually `unknown` when a stamp exists |
| `profile` | e.g. Hermes profile `kevin` |
| `workspace_kind` | Monorepo skill-source vs product dogfood vs sandbox |
| `task_shape` | Coarse use-case for clustering with coding-confidence tracers |

### Resolving `skills_rev` (claim-time recipe)

Prefer the **first hit**. Record the short git SHA when present; include `installed-at=` in evidence or ledger note when useful for effectiveness review.

```text
1. Env (adapters may set these):
   KEVIN_RUN_SKILLS_REV
   AGENT_TOOLS_SKILLS_REV
2. Skills-root revision stamp (file content: agent-tools-rev=<sha> and installed-at=<ISO-UTC>):
   ~/.kevin/skills/.agent-tools-revision
   ~/.hermes/skills/.agent-tools-revision
   ~/.claude/skills/.agent-tools-revision
   ~/.grok/skills/.agent-tools-revision
   ~/.factory/skills/.agent-tools-revision
   ~/.codex/skills/.agent-tools-revision
   ~/.opencode/skills/.agent-tools-revision   # or project .opencode/skills/ when that is the install root
3. Skill-source workspace (only when workspace_kind = skill_source and you are editing this monorepo):
   git rev-parse --short HEAD  → skills_rev
   if working tree has uncommitted changes under src/ → append or use dirty (e.g. abc1234-dirty)
4. Else: skills_rev: unknown
```

**Stamp format** (written by `./setup.sh` / pack-install scripts):

```text
agent-tools-rev=<full or short git sha of agent-tools at publish/install>
installed-at=<YYYY-MM-DDTHH:MM:SSZ>
publish-agent=<claude|grok|factory|hermes|codex|opencode|kevin>
```

Hosts **must** attempt steps 1–3 before writing `unknown`. Soft-fail to `unknown` only when no stamp and not in skill-source. Do **not** invent a second orchestrator file.

**Detection defaults (host):** best-effort for other envelope fields; prefer env `KEVIN_RUN_HARNESS` when present.

**Thrash bound is per `run_id`**, not per `/continue` invocation. Soft-check: if counters
already meet the bound when claiming, diagnose before burning another loop.

### Product repos

When continue (or a full phase alone) runs in a **product** workspace: ensure
`.agent-tools/runs/` exists (scaffold empty `events.ndjson` + `ledger.yml` version 1 if missing)
and write **there**. Local capture is mandatory; export into skill-source for evolve is optional
later — never skip local write.

## Event line (NDJSON)

One object per line; justified by phase-return evidence only — never invent events.

**Timestamps:** wall-clock ISO-8601 **at append** (prefer offset, e.g. `-05:00`). **Do not**
backfill multiple phases with one fabricated `ts`. If repair is unavoidable, set optional
`"ts_quality":"backfill"` and prefer separate real times when known.

```json
{"ts":"2026-07-18T14:22:00-06:00","run_id":"r-20260718-1","unit":"SPEC-851","mode":"unit","track":"feature","phase":"review","status":"completed","events":["REVIEW_FINDINGS_CODE"],"from":"needs_review","to":"ready_execute","evidence":"P1=0 P2=2 P3=0","channel":"cli","harness":"grok-build","agent_surface":"work-continue","model":"claude-sonnet-4-5","skills_rev":"abc1234","profile":null,"workspace_kind":"skill_source","task_shape":"multi_file","fidelity":"review_ok","dose":{"research":"full","design":"full","structure":"full"}}
```

| Field | Notes |
|-------|--------|
| `ts` | Wall clock at append (required) |
| `run_id` | Required |
| `unit` | Issue key or slug |
| `mode` | unit \| swarm_* \| hard_stop* |
| `track` | micro \| feature \| research \| custom |
| `phase` | orient \| brainstorm \| refine \| plan \| execute \| review \| integrate \| compound \| portfolio |
| `status` | completed \| await_user \| blocked \| failed \| skipped \| started |
| `events` | Names from unit-state-machine.md |
| `from` / `to` | States when transitioned |
| `evidence` | ≤120 chars locatable fact |
| `channel` | **Ingress** only: cli \| linear \| github \| chat \| cron \| other |
| `harness` … `task_shape` | Identity envelope (required on claim; echo every line) |
| `fidelity` | optional: review_ok \| review_theater \| compound_ok \| compound_none \| compound_missing |
| `judgment` | optional: escalate \| human_veto \| draft_pending |
| `dose` | optional: `{research,design,structure}` each full / light / skip from phase-return when known |
| `ts_quality` | optional: `backfill` only when `ts` is not wall-clock-at-append |

### Escalate / veto receipts (required when they happen)

Judgment stops must leave a **disk receipt**, not only a chat line. When continue (or an
automation entry) hits escalate-tier stop, human/review veto, or draft-first hold:

1. Set phase_return `status: await_user` (or `blocked`) with event `ESCALATE`, `HUMAN_VETO`,
   and/or `DRAFT_PENDING` (@work `continue/references/unit-state-machine.md`).  
2. Append an NDJSON line with that event + ≤120 char evidence (what was proposed, why stopped).  
3. Optionally set `"judgment":"escalate"|"human_veto"|"draft_pending"`.  
4. Update session-state `pending_gate` / Current Focus with the staged recommendation.  
5. **Do not** re-drive the same red gate in a tight cron/automation loop — deliver once; wait
   for human or disk change.

Example:

```json
{"ts":"2026-07-23T10:00:00-06:00","run_id":"r-20260723-1","unit":"SPEC-900","mode":"unit","track":"feature","phase":"integrate","status":"await_user","events":["ESCALATE","USER_GATE"],"from":"needs_integrate","to":"await_user","evidence":"always-PR overlay; E-MERGE stop — human merge","channel":"cron","judgment":"escalate","fidelity":null}
```

These rows feed yield (escalate rate) and process seeds; they are production-line scoreboard,
not L3 memory.

### Host recipe (claim)

```text
1. Mint run_id if missing; ensure .agent-tools/runs/ scaffold in this workspace
2. Resolve skills_rev (recipe above) — prefer stamp/env over unknown
3. Stamp identity envelope on session-state (harness, agent_surface, model, skills_rev,
   profile, workspace_kind, task_shape) — unknown allowed only after resolution attempt;
   do not skip keys silently
4. Optional: first event status=started with full envelope (honest ts)
```

### Host recipe (after each phase-return)

```text
1. Ensure run_id + identity envelope + track + reentry_counts on session-state
2. Append one NDJSON line NOW with wall-clock ts = phase_return + from/to + run_id
   + channel + track + full identity envelope (+ dose when phase_return has it)
3. If ESCALATE / HUMAN_VETO / DRAFT_PENDING → include events + optional judgment field
4. If refine/plan reentry from execute/review → bump reentry_counts
5. If THRASH_BOUND → thrash_bound_hits += 1
6. On MERGED + COMPOUND_DONE (or abandon) → close run, append ledger.yml row (below)
7. Soft-fail if FS write fails — never hard-stop work for telemetry
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
    harness: grok-build
    agent_surface: work-continue
    model: claude-sonnet-4-5
    skills_rev: abc1234
    profile: null
    workspace_kind: skill_source
    task_shape: multi_file
    outcome: shipped   # shipped | abandoned | blocked_out
    sessions: 3
    ttm_hours: 28      # (last_event_ts - first_event_ts) hours if both real; else null
    refine_reentries: 1
    plan_reentries: 0
    review_cycles: 2           # REVIEW_* events that completed a review pass
    review_fix_cycles: 1      # code findings fixed without refine/plan reentry
    thrash_bound_hits: 0
    rework: true               # STRICT — see below
    deferred_p1: 0
    deferred_p2: 1
    deferred_p3: 0
    effectiveness_ref: null    # optional scorecard path#anchor; omit if none
    fidelity:
      review: ok       # ok | theater | missing | n/a
      compound: ok     # ok | none_reasoned | missing | n/a
```

**Shipped** under local-merge policy: merged to main + valid review evidence + compound
disposition (capture or reasoned none).

### Rework vs review-fix (do not conflate)

| Field | True / count when |
|-------|-------------------|
| `rework: true` | Any execute/review → **needs_refine** or **needs_plan** edge in this run_id's events, **or** thrash_bound_hits > 0 |
| `rework: false` | Happy path and/or in-place review code fixes only |
| `review_fix_cycles` | Number of REVIEW_FINDINGS_CODE (or review→execute fix loops) **without** a refine/plan reentry |

Yield **rework rate** uses `rework` only — not `review_fix_cycles`. Healthy P2 fix-in-place is
**not** rework.

**Close recipe:**

```text
1. Copy identity envelope from session-state / first event
2. Count refine/plan reentries, review_cycles, review_fix_cycles, thrash from events
3. rework: true only per strict table above
4. deferred_p* from last valid review evidence (0 if none / n/a)
5. ttm_hours from first→last event ts when both are wall-clock (not backfill); else null
6. fidelity.review / fidelity.compound as today
7. effectiveness_ref if scorecard/tracer linked; else omit/null
8. Append row to ledger.yml (create file with version: 1 if missing)
9. Clear open thrash urgency on session-state; keep run_id for history
```

## Yield glance (`yield.md`)

**Primary entry:** **`/work:maintain`** (ritual when yield due + approved, or force with `--yield` / `--all`).

**Triggers (any):**

- User invokes `/work:maintain` or `/work:maintain --yield` (or “show run yield”)
- Soft stewardship offer when due+signal — @work `maintain/references/cadence.md`
  (status advisory; continue end-of-loop approval-gated; never auto-run)
- **Compat:** `/work:continue --yield` / `yield` → hand off to maintain yield job (no claim)

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
| Rework rate | % of closed with rework: true (strict def — not review_fix) |
| Thrash rate | % with thrash_bound_hits > 0 |
| Review fidelity ok | % |
| Compound fidelity ok/none_reasoned | % |
| Median ttm_hours | value or n/a |

## By track

| track | shipped | rework |
|-------|---------|--------|

## By harness (when identity present)

| harness | shipped | rework | notes |
|---------|---------|--------|-------|

## Recent closed (max 10)

| run_id | unit | track | harness | workspace_kind | outcome | closed |
|--------|------|-------|---------|----------------|---------|--------|

## Notes

One line only if something structural stands out (e.g. thrash cluster). Else omit.
```

Derived KPIs: ship rate, stuck open runs (optional from events), rework rate (strict), thrash
rate, review/compound fidelity, median TTM when known, channel mix, harness mix when fields
populated. **Missing identity on old rows:** report as `unknown`; do not invent backfill.

## Process self-improvement

Repeated thrash/rework/fidelity failures are **gap evidence**, not a license to edit skills
(in-project copies or published installs).

1. Optionally capture a memory entry (`type: process`) via `/work:compound` with
   `related: [run_id]` — symptoms, hypothesized skill gap, candidate skill paths.
2. **Never** invent a workflow-local “improve” command, and **never** auto-patch skills from
   the ledger mid-loop.
3. **Where corpus text actually changes** (dual path — evolve is skill-source only):
   - **Skill source** (agent-tools, or any checkout that owns the `src/**` skill tree and has
     `/skills:evolve` installed): run **`/skills:evolve`** (detect → propose → validate →
     present). Prefer seed shape: `run_ids` + `hypothesized_gap` + `candidate_skills`
     (cluster runs before elevating). Evolve inventories all of `src/**`, including
     workflow/swarm.
   - **Consumer projects** (published workflow/swarm only; no project-scoped skills family):
     keep the process entry / run evidence; take the gap **upstream** (issue, PR, or a session
     in the skill source). Do **not** fork process IP by editing installed skill files.
4. Runtime adapters honor @work `references/process-payload.md` — do not fork the line.

## Anti-patterns

- Metric theater (phases-run vanity without outcomes)
- Dual FSM in `run.yml` fighting session-state
- PM comment spam per transition
- Full conversation dumps under `runs/`
- Hard-stopping continue when append fails
- Marking `rework: true` for in-place review fixes (use `review_fix_cycles`)
- Batching many phases under one fabricated `ts`
- Overloading `channel` with harness identity
- Skipping identity “until we need metrics” (capture early; analyze late)
- Per-tool / token traces in `events.ndjson`
