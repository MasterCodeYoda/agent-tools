---
name: workflow:continue
description: Drive entry for workflow — resolve portfolio mode (swarm resume/handoff or unit state machine), drive work without inventing path; hard-stop when path is not established. Bare /workflow is status-only.
argument-hint: "[--worktree] [optional: work item ID, planning dir, or blank to auto-pick]"
user-invocable: true
---

# Continue (`/workflow:continue`)

**Drive entry** for the workflow family. Bare **`/workflow`** is portfolio **status** only
(read-only — @workflow `references/status.md`); it does **not** route here. Continue orients
from the resolved **planning root** (`.agent-tools/planning/` preferred; else `./planning/` —
see @workflow `references/planning-root.md`), **never invents a next unit**, then selects a
**portfolio mode**:

| Mode | When |
|------|------|
| **swarm_resume** | Active swarm run in progress / paused |
| **swarm_handoff** | Explicit roadmap `∥` / `{wave}` group at head (≥2 claimable) + swarm ready |
| **unit** | One claimable slice → **phase state machine** (cycles allowed under evidence guards) |
| **hard_stop** / **hard_stop_choice** | Nothing named, or sequencing choice / map-only |

When path is clear, run **silently** (no portfolio monologue). End-of-loop recap and review
ceremony still apply **except** at user-approval stops (see gates).

Not a recipe engine or horizon author. Phase skills run natively; continue only chooses *mode*,
*unit*, and *next legal transition*. Multi-unit maps: `/workflow:roadmap`. Multi-item parallel
**execution**: `/swarm` (auto-entered from here when eligible; still user-invocable as override).
Glance without driving: bare `/workflow`.
## User Input

```text
$ARGUMENTS
```

| Input | Meaning |
|-------|---------|
| *(empty)* | Soft-check → portfolio mode resolve → drive |
| Work item ID / PM URL / planning path / slug | Force **unit** mode on that target |
| `--worktree` | Isolated worktree for unit mode (see *Workspace*) |
| `--yield` / `yield` | Regenerate `.agent-tools/runs/yield.md` from ledger; summarize KPIs; **stop** (no unit claim unless also given a target) |

## Mandatory loads

| When | Load |
|------|------|
| Always (this skill) | Soft orientation rules below; refuse list |
| Path roots | @workflow `references/planning-root.md` |
| Before mode select | `references/portfolio-router.md` |
| Unit mode | `references/unit-state-machine.md`, `references/phase-return.md`, @workflow `references/tracks.md` |
| After phase-return | @workflow `references/runs-ledger.md` (append event; close-run on done) |
| Yield-only args | @workflow `references/runs-ledger.md` (regenerate yield.md) |
| Before review / integrate / recap / merge | `references/gates.md` |
| Context craft (research artifact, dumb zone, mid-phase compaction) | @workflow `references/context-engineering.md` |
| Cross-session / multi-agent pause | @workflow `references/handoff-package.md` (optional) |
| Orientation | `references/soft-checks.md` |
| Conventions present | `planning/conventions.md` (tracks, gates, merge policy, orientation entrypoint) |
| Schema / family contracts | `@workflow` (session-state, branch naming, PM mode, claim dialect) |

**Hard gates are not optional.** `gates.md` is a mandatory load, not a nice-to-read essay.

## Control loop

```text
if yield-only args → regenerate yield.md → summarize → stop
orient (conventions + soft-checks)
  → load portfolio-router → MODE
  → swarm_resume | swarm_handoff | unit SM | hard_stop*
  → on unit: classify → transition → phase → phase-return → runs append → re-classify … until stop
  → on done: close-run ledger row
  → handoff / recap per gates
```

## Orientation

Keep handoffs **light** — scan state, do not read a heavyweight narrative.

0. **Resolve planning root** (`.agent-tools/planning/` preferred). **Conventions**
   (`planning/conventions.md` if present): built-in + extra tracks, additive gates,
   integration/merge policy (incl. autonomous local merge), visual plan policy, orientation
   entrypoint / PM queue. Sparse overlay: absent sections keep built-in defaults. Built-in
   tracks always available: feature | micro | research (@workflow `references/tracks.md`).
1. **Soft-checks** (`references/soft-checks.md`) — theater review / missing compound / thrash
   counters on the prior or claimed unit before burning new loops.
2. **Scan** claimable units: `planning/*/session-state.md`, top-level handoff, roadmap /
   initiatives dialect, PM queue only when conventions say so (closed filter — never invent).
   Named NEXT without a planning dir is still claimable. Channel paste / issue key / 
   `workflow:claim` body → explicit unit (portfolio row 1).
3. **Portfolio mode** (`references/portfolio-router.md`) **before** unit claim. Do not invent
   a pseudo-slice to enter the machine.

### Path / invent rules (always on)

- **Never invent** NEXT from fatigue language (“you decide”, “pick something”) or residual-only notes.
- **Scaffolding ≠ inventing** — creating `planning/<slug>/` for a **named** unit is normal.
- **Named-without-shell** → claim and enter unit SM (usually `needs_refine`).
- **Fatigue without a unit id/path/slug** → hard_stop.
- Auto-invoke brainstorm/roadmap **only** when the unit SM routes there for a *claimed* unit;
  otherwise stop + offer.

### Hard-stop template

```markdown
### Path not established — stopping

Continue will not invent a next unit.

**Options:**
1. Name a concrete unit (issue id, slug, or `planning/<slug>/`) and re-run `/workflow:continue`
2. `/workflow:brainstorm` — single fuzzy concept
3. `/workflow:roadmap` — multi-unit destination + order (or resequence)
```

### Optional thin steering (v1)

**Default: no offer.** If the claimed unit carries an unacked greppable `steering_note:` that
affects whether to claim it, present at most one offer; on proceed, ack the note. No density latch.

## Portfolio modes (summary)

Full rules: `references/portfolio-router.md`.

1. Explicit args → **unit** (skip auto-swarm).
2. Active swarm run → **swarm_resume** (`/swarm:continue` semantics).
3. Explicit `∥` / `{wave}` at head, ≥2 claimable, swarm ready → **swarm_handoff** (auto).
4. Same but swarm not set up → one ask: setup then handoff, or sequential first peer.
5. Else single-unit claim order: `in_progress` → handoff/roadmap NEXT → planned queue.
6. map-only / sequencing choice without a resolvable unit → **hard_stop_choice**.
7. Nothing named → **hard_stop**.

**Auto-swarm eligibility is narrow:** only explicit parallel groups at the active head — not
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
execute on code findings; review → plan on structural findings). Happy path is still one walk.
After plan approve → **same-session execute** (no emit-and-stop default).

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
CLI, emit `handoff_package` per @workflow `references/handoff-package.md`. Default remains
same-session drive — do not emit-and-stop after plan by default.

## What `/continue` does not do

- Does **not** invent a next unit or NEXT pointer (unlisted / fatigue / residual-only).
- Does **not** hard-stop solely because a named unit lacks a planning directory.
- Does **not** auto-author roadmaps or brainstorm seeds (stop + offer unless unit SM routes there).
- Does **not** author plan/requirements content — phase skills do.
- Does **not** treat `visual-plan.html` (or any visual surface) as executable SoT or plan-approval proof.
- Does **not** skip review or invent review evidence; gates green ≠ reviewed.
- Does **not** skip compound after integrate without explicit `compound: none`.
- Does **not** push/PR unless project push policy allows — never production promotion.
- Does **not** implement multi-item parallelism itself — **routes** to `/swarm` when eligible;
  does not grab items an active swarm worker owns when in unit mode.
- Does **not** invent a swarm wave without explicit `∥` / `{wave}` grouping.
- Does **not** free-form thrash phases without artifact/decision evidence (thrash bound).
- Does **not** emit end-of-loop recap on user-approval stops.
- Does **not** edit the skill corpus mid-loop — process gaps → process memory + skill-source
  `/skills:evolve` when available (else upstream escalate; see `references/soft-checks.md`).
- Does **not** invent NEXT from open PM backlog scrape (PM queue only with conventions filter).

## Related

- **`@workflow`** — family contracts; bare `/workflow` → portfolio **status** (`references/status.md`)
- **`@workflow:setup`** — `conventions.md`, planning root, runs scaffold
- **`@workflow:roadmap`** — `→` / `∥` / `⚠` / NEXT maps continue consumes
- **`@workflow:brainstorm`** · **refine** · **plan** · **execute** · **review** · **compound**
- **`/swarm`** · **`/swarm:continue`** · **`/swarm:setup`** — parallel executor; override entry
- **`/skills:evolve`** — skill-source only; mutates process IP from detected gaps (not published to consumer projects)
- **`@superpowers:finishing-a-development-branch`** — integrate decision after clean review
