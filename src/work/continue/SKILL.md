---
name: work:continue
description: Drive entry for workflow — resolve portfolio mode (unit phase machine or parallel multi-item orchestrator), drive work without inventing path; hard-stop when path is not established. Bare /work is status-only.
argument-hint: "[--worktree] [optional: work item ID, planning dir, multi-item goal, or blank to auto-pick]"
user-invocable: true
---

# Continue (`/work:continue`)

**Drive entry** for the work family. Bare **`/work`** is portfolio **status** only
(read-only — @work `references/status.md`); it does **not** route here. Continue orients
from the resolved **planning root** (`.agent-tools/planning/` preferred; else `./planning/` —
see @work `references/planning-root.md`), **never invents a next unit**, then selects a
**portfolio mode**:

| Mode | When |
|------|------|
| **parallel_resume** | Active parallel run (`.agent-tools/parallel/active-run`) in progress / paused |
| **parallel_handoff** / **parallel** | Explicit roadmap `∥` / `{wave}` (≥2 claimable) + ready, or multi-item continue args |
| **unit** | One claimable slice → **phase state machine** (cycles allowed under evidence guards) |
| **hard_stop** / **hard_stop_choice** | Nothing named, or sequencing choice / map-only |

When path is clear, run **silently** (no portfolio monologue). End-of-loop recap and review
ceremony still apply **except** at user-approval stops (see gates).

Not a recipe engine or horizon author. Phase skills run natively; continue only chooses *mode*,
*unit* or *wave*, and *next legal transition*. Multi-unit maps: `/work:roadmap`. Multi-item
parallel **execution** is a continue mode (`parallel/*`) — not a separate slash family.
Glance without driving: bare `/work`.
## User Input

```text
$ARGUMENTS
```

| Input | Meaning |
|-------|---------|
| *(empty)* | Soft-check → portfolio mode resolve → drive |
| Work item ID / PM URL / planning path / slug | Force **unit** mode on that target |
| Multi-item goal (≥2 keys, milestone, backlog file) | Force **parallel** mode (`parallel/orchestrator.md`) |
| `--worktree` | Isolated worktree for unit mode (see *Workspace*) |
| `--yield` / `yield` | **Compat shim** → `/work:maintain --yield` (stewardship; no unit claim) |

## Mandatory loads

| When | Load |
|------|------|
| Always (this skill) | Soft orientation rules below; refuse summary |
| Full refuse catalog | `references/refuse.md` (with gates; or when orientation is ambiguous) |
| Family contracts (session-state / branch) | @work `references/family-contracts.md` (when writing state or branching) |
| Path roots | @work `references/planning-root.md` |
| Before mode select | `references/portfolio-router.md` |
| Parallel modes | @work `parallel/MODE.md` + `orchestrator.md` / `resume.md` as selected |
| Unit mode | `references/unit-state-machine.md`, `references/phase-return.md`, @work `references/tracks.md` |
| After phase-return | @work `references/runs-ledger.md` (append event; close-run on done) |
| Yield-only args (compat) | `@work:maintain` (yield job only) — not drive |
| Before review / integrate / recap / merge | `references/gates.md` |
| Context craft (research artifact, dumb zone, IC content) | @work `references/context-engineering.md` |
| Context compact (reclaim + resume control flow) | @work `references/context-compact.md` |
| Cross-session / multi-agent pause | @work `references/handoff-package.md` (optional) |
| Orientation | `references/soft-checks.md` |
| Approval tiers / claim-class / automation overlay | @work `references/approval-boundaries.md` (orientation; mandatory before integrate, draft-first ship, or automation entry) |
| Scheduled / unattended entry | @work `references/pre-wake-checklist.md` (before claim when automation-shaped) |
| Conventions present | `planning/conventions.md` (tracks, gates, merge policy, orientation entrypoint) |
| PM / claim dialect | @work `planning/pm-integration.md` when claiming from PM |

**Hard gates are not optional.** `gates.md` is a mandatory load, not a nice-to-read essay.

## Control loop

```text
if yield-only args → compat: /work:maintain --yield → stop (no claim)
orient (conventions + soft-checks)
  → load portfolio-router → MODE
  → parallel_resume | parallel_handoff | parallel | unit SM | hard_stop*
  → on unit: classify → transition → phase → phase-return → runs append → re-classify … until stop
  → on done: close-run ledger row
  → handoff / recap per gates
  → stewardship offer when due AND signal (soft-checks) — approval-gated; never auto-run
```

## Orientation

Keep handoffs **light** — scan state, do not read a heavyweight narrative.

0. **Resolve planning root** (`.agent-tools/planning/` preferred). **Conventions**
   (`planning/conventions.md` if present): built-in + extra tracks, additive gates,
   integration/merge policy (incl. autonomous local merge), visual plan policy, orientation
   entrypoint / PM queue. Sparse overlay: absent sections keep built-in defaults. Built-in
   tracks always available: feature | micro | research (@work `references/tracks.md`).
1. **Soft-checks** (`references/soft-checks.md`) — theater review / missing compound / thrash
   counters on the prior or claimed unit before burning new loops.
2. **Scan** claimable units: `planning/*/session-state.md`, top-level handoff, roadmap /
   initiatives dialect, PM queue only when conventions say so (closed filter — never invent).
   Named NEXT without a planning dir is still claimable. Channel paste / issue key / 
   `work:claim` body → explicit unit (portfolio row 1).
3. **Portfolio mode** (`references/portfolio-router.md`) **before** unit claim. Do not invent
   a pseudo-slice to enter the machine.

### Resume steering (unit claim / in_progress)

When claiming or resuming an `in_progress` unit, prefer **disk steering** over chat history:

1. Latest **Intentional Compaction** in the unit `session-state.md` (latest-IC-wins) and any
   `resume_loads` / `compact_focus` on that snapshot.  
2. `implementation-plan.md` + `codebase-research.md` / design as listed.  
3. Do **not** hard-stop claim solely because IC is missing — soft-check and fold into execute.

If dumb-zone or thrash soft-check fires **mid-drive** **and the unit still has work remaining**,
**load and run** @work `references/context-compact.md` (WRITE → signal + clean-session
host command → after reclaim, RESUME same unit). IC-only stop is incomplete. End-of-item uses
handoff, not reclaim.

### Path / invent rules (always on)

- **Never invent** NEXT from fatigue language (“you decide”, “pick something”) or residual-only notes.
- **Scaffolding ≠ inventing** — creating `planning/<slug>/` for a **named** unit is normal.
- **Named-without-shell** → claim and enter unit SM (usually `needs_refine`).
- **Fatigue without a unit id/path/slug** → hard_stop.
- **Silence is valid** when nothing is claimable (esp. automation entries) — do not invent work.
- Auto-invoke brainstorm/roadmap **only** when the unit SM routes there for a *claimed* unit;
  otherwise stop + offer.

### Hard-stop template

```markdown
### Path not established — stopping

Continue will not invent a next unit.

**Options:**
1. Name a concrete unit (issue id, slug, or `planning/<slug>/`) and re-run `/work:continue`
2. `/work:brainstorm` — single fuzzy concept
3. `/work:roadmap` — multi-unit destination + order (or resequence)
```

### Optional thin steering (v1)

**Default: no offer.** If the claimed unit carries an unacked greppable `steering_note:` that
affects whether to claim it, present at most one offer; on proceed, ack the note. No density latch.

## Portfolio modes (summary)

Full rules: `references/portfolio-router.md`.

1. Explicit **single** args → **unit** (skip auto-parallel).
2. Explicit **multi-item** args → **parallel**.
3. Active parallel run → **parallel_resume** (`parallel/resume.md`).
4. Explicit `∥` / `{wave}` at head, ≥2 claimable, parallel ready → **parallel_handoff** (auto).
5. Same but not set up → one ask: `/work:setup` then handoff, or sequential first peer.
6. Else single-unit claim order: `in_progress` → handoff/roadmap NEXT → planned queue.
7. map-only / sequencing choice without a resolvable unit → **hard_stop_choice**.
8. Nothing named → **hard_stop**.

**Auto-parallel eligibility is narrow:** only explicit parallel groups at the active head — not
“several units that look independent.” `⚠ A ∥ B` is a collision watch, not a launch package.

## Unit phase state machine (summary)

Full table: `references/unit-state-machine.md`. After each phase: `references/phase-return.md`.

```text
classify(disk + decisions) → guarded transition → invoke phase → phase_return → re-classify
```

**Track first:** `feature` | `micro` | `research` (or conventions custom). Micro uses
direct-issue execute + quick review; research uses conclusion deliverable — see tracks.md.

Feature states: `fuzzy` · `needs_refine` · `needs_plan` · `ready_execute` · `needs_review` ·
`needs_integrate` · `needs_compound` · `done` · `await_user` · `blocked`.

**Cycles are legal** when evidence says so (e.g. execute → refine on decision drift; review →
execute on code findings; review → plan on structural findings; `PROBLEM_REFRAMED` /
`DESIGN_FALSIFIED` / `HUMAN_STEER` mid-execute). Happy path is still one walk. Plan approve =
**proceed with hypothesis**, not freeze. After plan approve → **same-session execute** (no
emit-and-stop default).

**Skip** refine/plan only when track is micro (issue-as-plan) or artifacts match the **current
governing decision**. Stale artifact vs moved decision → re-enter refine (resize). Thrash bound:
>2 refine/plan re-entries from execute/review **per `run_id`** without new external evidence →
`await_user`. Corpus fixes → skill-source `/skills:evolve` (or upstream escalate), not in-loop
skill edits.

Append phase-return events to `.agent-tools/runs/` per `runs-ledger.md`.

### Review / merge / recap (always-on refuse)

Full schemas: `references/gates.md` (**mandatory load** before these transitions).

- **No** code → merge without real review + valid evidence (`method`, date, verdict, P1–P3
  counts, disposition).
- **No** treating typecheck/lint/test/build as review.
- **No** inventing `review: clean` theater.
- Autonomous merge only if conventions allow **and** all ratchet preconditions hold (reviewed +
  gates + ACs + recap Review block when recap applies).
- Compound after integrate, or explicit `compound: none — <reason>`.
- Recap required except at user-approval stops (plan approval, merge confirm, triage choose, …).

## Workspace

**Default: main workspace.** If the unit already has a worktree, enter it. `--worktree`: create
or enter via `@git` worktree-create; **continue never removes** a worktree.

## Handoff on stop

Update `planning/<project>/session-state.md` lightly: status/progress/branch; Current Focus +
next state; compress history (archive verbose detail). Optional light fields only when needed:
`pending_gate`, `last_transition`, `run_id` (see phase-return). After merge: valid review
evidence + compound disposition before advancing top-level NEXT pointer; **close-run** ledger
row per `runs-ledger.md`.

**Cross-session / multi-agent pause (optional):** if stopping mid-unit for another agent or
CLI, emit `handoff_package` per @work `references/handoff-package.md`. Default remains
same-session drive — do not emit-and-stop after plan by default.

## What `/continue` does not do

**Hard refuses (summary):** invent NEXT; skip/theater review; skip compound without reason;
push/PR without policy; thrash without evidence; ship draft-first/escalate as autonomous;
edit skill corpus mid-loop; push through plan when reclassify events fire.

Full catalog: **`references/refuse.md`** (mandatory load with gates when reviewing/integrating;
load anytime orientation is ambiguous).

## Related

- **`@work`** — family contracts; bare `/work` → portfolio **status** (`references/status.md`)
- **`@work:setup`** — planning, conventions, memory, runs, charter, parallel config/roles
- **`@work:roadmap`** — `→` / `∥` / `⚠` / NEXT maps continue consumes
- **`@work:brainstorm`** · **refine** · **plan** · **execute** · **review** · **compound**
- **`@work:maintain`** — stewardship (prune + yield + memory); continue may **offer**, never owns
- **Parallel mode** — @work `parallel/*` (entered only from this skill’s portfolio router)
- **`/skills:evolve`** — skill-source only; mutates process IP from detected gaps (not published to consumer projects)
- **`@superpowers:finishing-a-development-branch`** — integrate decision after clean review
