---
name: workflow:continue
description: Resume the next slice of work — resolve a known path, pick one claimable unit, drive the full workflow loop silently when healthy; hard-stop when path is not established
argument-hint: "[--worktree] [optional: work item ID, planning dir, or blank to auto-pick the next slice]"
user-invocable: true
---

# Continue the Next Slice (`/workflow:continue`)

A thin **sequential orchestrator** over the `/workflow` family. It orients from what
`planning/` already records, **resolves a claimable next unit without inventing one**, and
drives that single slice through the full workflow loop — refine → plan → execute → review →
finish → compound — **auto-advancing through phases that need no human input and stopping only
where your input is genuinely required**.

**Loop executor first:** when the path is clear, run **silently** (no portfolio monologue).
"Silent" means no pre-claim steering chat — the end-of-loop recap and review ceremony still apply
**except** when the loop ends on a user-approval gate (see *End-of-loop recap* — no recap there).

It is **not** a recipe engine and **not** a horizon author. The underlying `/workflow:*` skills
carry their own structure; `/continue` only decides *which* slice and *which* phase comes next,
then lets each phase run natively. Multi-unit maps are authored by `/workflow:roadmap`.

For backlog-scale **parallel** work — many items at once, each in its own worktree — use
**`/swarm`**, not this. `/continue` is the sequential, one-slice-at-a-time counterpart. The two
coexist without colliding (see *Coexistence with `/swarm`* below).

## User Input

```text
$ARGUMENTS
```

### Argument interpretation

| Input | Meaning |
|-------|---------|
| *(empty)* | Auto-pick the next slice by scanning `planning/` (orientation below). |
| Work item ID (`LIN-123`, `PROJ-456`) or PM URL | Target that item. |
| `./planning/<project>/` or a planning file path | Target that project's slice. |
| `--worktree` (flag, combinable with any of the above) | Run the slice in an isolated git worktree instead of the main workspace (see *Workspace*). |

## What `/continue` does

```
orient → PRE-CLAIM path resolve → (hard stop | claim ONE unit) → stage table →
         drive the loop → handoff → stop
```

One slice, start to a natural stopping point. Do **not** layer prescriptive steps on top of the
`/workflow:*` skills — let each run its own structure.

## Orientation

Keep handoffs **light** — orient by scanning current state, not by reading a heavyweight
narrative block.

0. **Load project conventions.** If `planning/conventions.md` exists (or the handoff's *Project
   orientation* block points to convention docs), read it first. It is authored/maintained by
   `@workflow:setup` and may define:
   - **Additional work tracks** — a project unit may belong to a non-feature track (a discovery
     loop, a labeling cycle, a release checklist) that **overrides** the default phase table below
     and follows its own process doc. Classify the slice into the right track *before* routing.
   - **Project-specific gates** — checks **additive to** the review gate (cross-cutting safety,
     regression/holdout adoption, contract lockstep). Apply them before treating a slice as done.
   - **Integration / merge policy** — honor the project's recorded policy.
   - **Orientation entrypoint & queue location** — conventions may redirect *where* to orient and
     *what* the queue is (e.g. a milestone handoff at a non-default path like
     `planning/<milestone>/SESSION-HANDOFF.md`, with per-item state nested deeper than the default
     `planning/*/session-state.md` glob in step 1). When conventions specify an orientation method,
     follow it over the default scan below.
   Absent → use the defaults in this skill as-is.
1. **Scan** for claimable units: `planning/*/session-state.md` frontmatter (schema in `@workflow`),
   optional top-level handoff pointer, optional `planning/roadmap.md` (or initiatives/workstreams
   if that dialect is in use), PM queue only when conventions say so. **Named NEXT slugs without a
   planning dir yet are still claimable** (shell is not the passport — see resolvable unit below).
2. **Run Pre-claim path resolution** (next section) **before** the stage table. Do not invent a
   pseudo-slice so you can enter the table.
3. **Confirm the precise stage** of the claimed unit from artifacts on disk (`session-state.md`,
   requirements/plan if any) and in-flight state. **Missing planning dir is fine** — classify as
   early loop (usually refine) and let the phase skill create the shell.

## Pre-claim path resolution (hard gate — before stage table)

**Continue never invents a next unit.** It does not pick work nobody named (no fatigue “you
decide,” no residual-only initiative sentence). It never auto-invokes `/workflow:brainstorm` or
`/workflow:roadmap` — only **stops and offers** those commands (unless the user explicitly invoked
them this turn).

**Scaffolding ≠ inventing.** Creating (or letting refine/plan create) `planning/<slug>/` for a
unit **already named** by args / handoff NEXT / roadmap NEXT is normal loop entry — not inventing
path. Cold-start hard-stop is for **unlisted** work only.

### Path established? (first match wins)

| # | Condition | Action |
|---|-----------|--------|
| 1 | Explicit target in `$ARGUMENTS` (issue id, PM URL, planning path, or stable slug) | Claim that unit (warn if leaving `in_progress` behind) |
| 2 | Live `status: in_progress` slice (with live branch if required by project) | Resume it |
| 3 | Conventions / handoff orientation names a resolvable NEXT | Claim that unit |
| 4 | Roadmap / workstream head names a **resolvable** unit (`NEXT` not `map-only`) | Claim that unit |
| 5 | ≥1 resolvable `status: planned` unit (or PM-equivalent per conventions) | Claim next by priority/order |
| 6 | None of the above | **HARD STOP — path not established** |

**Brownfield non-break:** a planned queue or PM backlog **without** `planning/roadmap.md` is still
path established (row 5). Roadmap is optional altitude, not a passport.

**Resolvable unit** = a concrete identity already named as next work:

- issue id / PM URL, **or**
- existing `planning/<slug>/` path, **or**
- **stable slug/name from handoff `NEXT` / roadmap `NEXT` / workstream list** (planning dir optional)

— **not** a vague initiative sentence, residual-only note, or fatigue language.

**Named-without-shell is claimable:** if NEXT says `sys-foo` and `planning/sys-foo/` does not exist
yet, **claim `sys-foo`** and enter the stage table (almost always → refine; shell is phase output).

**Multiple named NEXTs (∥ or a list):** path is established. Claim **one** — first listed in the
handoff `NEXT` block, else roadmap `NEXT` / stream order. Continue is sequential; parallel peers
remain available for a later claim.

**Fatigue language is not path:** "you decide", "just continue", "pick something" without a unit
id/path/slug → still **HARD STOP** (same template). Do not invent NEXT.

**Authority:** `in_progress` wins over roadmap NEXT. Do not grab swarm in-flight IDs (see
Coexistence). Filter swarm-owned items from any offer list.

### Hard-stop template (path not established)

```markdown
### Path not established — stopping

Continue will not invent a next unit.

**Options:**
1. Name a concrete unit (issue id, slug, or `planning/<slug>/`) and re-run `/workflow:continue`
2. `/workflow:brainstorm` — single fuzzy concept
3. `/workflow:roadmap` — multi-unit destination + order (or resequence)
[If any named-but-unstarted candidates exist in handoff/roadmap, those *are* claimable under
rows 3–4 — hard-stop only when nothing is named. List up to 3 only as orientation if you
somehow stopped with named candidates present (should not happen).]
```

Remain stopped until the user provides a unit or runs a path skill. **Do not hard-stop solely
because a named unit lacks a planning directory.**

### Optional thin steering (v1 — evidence only)

**Default: no offer.** Do not hunt for leverage at orient.

If the **claimed next unit** (or handoff) carries a greppable unacked `steering_note:` that would
affect whether to claim it, present **at most one** offer (proceed | pause for roadmap/brainstorm |
other unit). On **proceed**, treat that note as acked for this unit (record ack in handoff or
note) so it does not re-prompt every continue. No interaction-density latch and no steering modes
in v1.

### After claim

Only then classify track and enter the stage table. If the unit has **no planning dir yet**,
route from artifacts (none → direction from roadmap/handoff one-liner counts as direction chosen →
usually `/workflow:refine`, which creates the shell).

## Coexistence with `/swarm`

`/continue` and `/swarm` keep **entirely separate state stores** — `/continue` only touches the
human-facing `planning/<project>/session-state.md` artifacts; `/swarm` owns
`.agent-tools/swarm/`. They never write the same file. Still, guard against picking an item a
swarm run is actively driving:

1. Check `.agent-tools/swarm/active-run`. If absent or the run is not `in_progress`, proceed
   normally.
2. If a swarm run **is** `in_progress`, read its `sessions/<run-id>/state.yml` and treat as
   **off-limits** any item with a live `in_flight` role or an un-merged worktree.
3. **Warn** that swarm is driving the backlog in parallel, then **pick only a disjoint item** —
   one swarm is not touching. If no free item remains, say so and stop (suggest letting swarm
   finish, or `/swarm:continue`). Never grab an item out from under an active swarm worker.

## Stage → next phase (each row is a gate)

**First, classify the slice's track** (Orientation step 0). If project conventions assign it to a
non-feature track, follow **that track's process doc** instead of this table — it carries its own
structure and its own review-equivalent. The table below is the **default feature track**.

Classify the slice's stage from what's on disk (artifacts, branch, commits, review state) —
the same artifact-driven classification `/swarm` uses — then route:

| Current state | Next phase |
|---|---|
| Unit is multi-stream / horizon-only (no single claimable scope) | **Stop + offer** `/workflow:roadmap` (do not invent streams) |
| Idea still fuzzy, direction unchosen | `/workflow:brainstorm` (offer/run for **this unit** only) |
| Direction chosen (incl. roadmap/handoff one-liner), no or weak requirements — **planning dir optional** | `/workflow:refine` (creates `planning/<slug>/` as needed) |
| Requirements clear, no implementation plan | `/workflow:plan` |
| Plan approved, work not started **or in progress** | `/workflow:execute` (resume where the plan left off) |
| Code exists, not reviewed | `/workflow:review` (or `/code-review`) — fix every finding; **record review evidence** (below) |
| Reviewed clean, not integrated | Finish the branch (see `@superpowers:finishing-a-development-branch`) — **stop to confirm the merge by default**, unless the project's Integration / merge policy authorizes autonomous merge **and** the autonomous-merge preconditions below are all met |
| Integrated / merged | `/workflow:compound` (or an explicit skip line — below), then update the handoff |

**Each row is a gate, not a suggestion.** Don't jump from "code exists" to "merged" without the
review pass — that's a process bug, not a shortcut. **Brainstorm and refine are skip-by-default
only when the existing artifact is consistent with the current governing decision.** When a
`brainstorm.md` / `requirements.md` / issue already exists for the slice, first check it against the
decision record / domain doc it realizes. If the decision has moved since the artifact was written —
stale phasing, a renamed vendor with intact old ceremony, ACs the current decision no longer supports
— **re-enter `/workflow:refine` in resize mode** (see @workflow (`planning/pm-integration.md`) ›
Backlog Resize) before planning or executing. The most-detailed written artifact is not the
authority; the current decision is. Only when the artifact already matches the current decision do you
skip the phase that produced it.

Within one `/continue` invocation, walk this table for the chosen slice, advancing through
phases automatically **until you hit a user-input gate or the slice completes**.

### Review gate — operational definition (not optional)

**Project hygiene gates (typecheck, lint, test, build, architecture validators, issue-ref, etc.)
are never a substitute for the review phase.** Green gates only mean "validation passed"; they do
**not** mean "reviewed clean." **Slice size does not skip review** — S-sized verify/harden work and
docs-touching product code still require a real review pass before integrate.

A slice is **reviewed** only when all of the following hold:

1. **A real review pass ran for this slice** in this session (or a prior session with durable
   evidence): **`/workflow:review`** (preferred), `/code-review`, or an equivalent structured review
   using the same standards — multi-lens findings with P1–P3 priorities and a verdict, **not** a
   casual self-glance while gates are green.
2. **Confirmed P1–P3 findings are fixed** (or deferred only as the project conventions allow —
   typically only genuine P4/nits, or a deferral recorded on a follow-up PM issue). Project
   conventions may require fixing P3s; honor that bar when present.
3. **Review evidence is recorded** before integration — and it must be **non-theater** (schema
   below). Preferred: a PM/issue comment (Linear/Jira). Minimum: the same fields in
   `planning/<item>/session-state.md`.

#### Valid review evidence (schema)

Evidence is valid only when it includes **all** of:

| Field | Required content |
|-------|------------------|
| `method` | How review ran: `workflow-review` \| `code-review` \| `structured-agents` (name the lenses) |
| `date` | ISO date of the review pass |
| `verdict` | `clean` \| `findings-fixed` (after remediation) — not a free-form "LGTM" |
| `findings` | Counts by priority, e.g. `P1=0 P2=2 P3=1` (zeros explicit when none) |
| `disposition` | One line: what was fixed, deferred (with issue id), or `none` |

**Minimum handoff line** (session-state or top-level pointer):

```text
review: findings-fixed | 2026-07-09 | method=workflow-review | P1=0 P2=2 P3=1 | disposition=all fixed in <sha>
```

**Invalid evidence (treat as not reviewed):**

- `review: clean` with no `method` / findings counts
- "quick structured review" / "I looked at the diff" / "gates green so review clean"
- A PM comment that only restates gates without findings disposition
- Any claim of reviewed-clean that cannot name the review method and P1–P3 counts

A light "I looked at the diff" while CI is green is **not** review. Proceeding from execute straight
to merge without (1)–(3) and valid evidence is a process bug — treat the slice as still in the
"code exists, not reviewed" row. **Do not invent evidence** to unblock merge.

### Autonomous merge preconditions (hard ratchet)

When conventions authorize autonomous local merge, **all** of the following must be true before
merging without asking. If **any** is missing, **do not merge** — stop, run the missing phase, or
hand back. This is a hard refuse, not a judgment call.

1. **Reviewed-clean** per the operational definition above, with **valid evidence schema**
   (`method` + `date` + `verdict` + `findings` counts + `disposition`).
2. **Every project gate** from Orientation step 0 / `conventions.md` passes cleanly and objectively.
3. **All task requirements + constraints** for the slice are met (ACs / plan DoD).
4. **Loop recap** for this `/continue` invocation includes the **Review findings & disposition**
   block (see *End-of-loop recap* below) — same facts as the evidence, visible to the user.

If any item is missing, **do not autonomous-merge**. Wording like "clean validation pass" in
conventions means (1)+(2)+(3)+(4), never gates alone.

### Compound after integrate (not optional)

After the slice is integrated/merged, **before** treating the slice as fully complete and advancing
the top-level handoff to the next item:

1. Run `/workflow:compound` for durable insight from the slice, **or**
2. Record an explicit skip in the slice handoff / Last Session Summary:
   `compound: none — <one-line reason>` (e.g. trivial docs-only, pure renames with no new pattern).

Do not silently skip compound. Prefer capture when non-obvious patterns, gotchas, or process lessons
exist. Soft-check on the next `/continue` orientation: if the **most recently completed** slice in
the handoff has neither a compound capture note nor a `compound: none` line, surface it and either
compound that slice first or record the skip before picking up new work.

## Where to stop (inject user input)

Auto-advance only where no human decision is owed. **Stop and hand back** at any genuine gate:

- **Path not established** (pre-claim hard stop) — never invent NEXT.
- Direction or requirements are ambiguous (brainstorm/refine needs your call).
- A plan is ready for **approval** (`/workflow:plan` approval gate — never save/execute a plan
  without it). **No end-of-loop recap** at this stop — present the plan approval prompt only.
- Review surfaced findings that need a **triage decision**.
- **Review not yet completed** for a slice that has code (missing review pass, missing valid
  evidence schema, or missing recap Review findings block) — do not integrate; run
  `/workflow:review` first. **Refuse** autonomous merge rather than fabricating evidence.
- **Integration/merge needs confirmation — by default.** Stop and hand back before merging the slice
  to `main`. **Exception:** if the project's recorded **Integration / merge policy** (loaded in
  Orientation step 0 from `planning/conventions.md`) authorizes an autonomous local merge, follow it
  only when the **autonomous merge preconditions** above are all met (reviewed-clean with **valid**
  evidence *and* every project gate clean *and* requirements met *and* recap Review block present),
  then flip the issue status, write the handoff, run compound (or record `compound: none`), and
  emit the end-of-loop recap. Absent such a convention, treat the merge as a stop gate. Either way:
  stop on **genuine doubt** (a validation that didn't pass cleanly, an unmet constraint, a real
  judgment call), and **pushing/PRs are always user-initiated** — never push or open a PR
  autonomously, regardless of conventions (unless the project's recorded push policy explicitly
  allows main-push at agent judgment — still never production promotion).
- **Auto-invoked after a slice already completed this session.** If this `/continue` was triggered
  **automatically** (e.g. a scheduled wakeup you set to keep the loop alive across a long-running
  slice) rather than by the user, *and* a full slice has **already completed** in this session, do
  **not** silently pick up a new slice — **ask the user** whether to start another slice or stop.
  Scheduled wakeups exist to keep one slice's work moving, not to chain into fresh slices unattended;
  a wakeup that lands after the original slice finished should check in, not self-extend the backlog.
- Any `AskUserQuestion`-class decision the slice can't resolve on its own.

Stop only at genuine gates above; a stop saves state for clean resume.

## Workspace

**Default: the main workspace** — sequential single-slice work needs no isolation. If the slice
already has a worktree (from `/workflow:plan --worktree` or a paused item), **enter that existing
one** rather than creating a new one.

**`--worktree`**: create a new isolated worktree (or enter an existing matching one) for the
slice. Use this to run `/continue` in parallel with **other, non-workflow** sessions in the same
repo without stepping on each other. Worktree create/remove always defers to
`@git` (worktree-create / worktree-delete); **`/continue` never removes a worktree** — cleanup is
a separate, user-initiated action.

## Handoff tracking on completion

Before stopping, update the slice's `planning/<project>/session-state.md` as one coherent unit —
kept **light**:

1. Flip `status` / `progress` and record the branch (and worktree, if used).
2. Refresh **Current Focus** and a short **next-phase pointer** so the next pickup is unambiguous.
3. **Compress history.** Keep the most recent **Last Session Summary** verbatim; collapse older
   entries to one line each. When the log grows long, archive the verbose detail (e.g. to
   `planning/<project>/history-archive.md`) rather than letting `session-state.md` bloat. A fresh
   session should orient from a small file.
4. If the slice **merged/integrated**:
   - Ensure **valid review evidence** is present (schema above — PM comment preferred; handoff
     `review:` line minimum with `method` + findings counts + disposition).
   - Run `/workflow:compound` **or** record `compound: none — <reason>` (see *Compound after
     integrate*). Do not advance the top-level "next pickup" pointer until one of those is done.

Keep the slice's state and any top-level pointer consistent: if the pointer lags the slice
state, the next pickup is wrong.

## End-of-loop recap (required — hard gate, with one exception)

Every `/continue` invocation **ends with a user-visible recap** before the agent stops (slice
complete, paused without an active approval prompt, or blocked) — **except** at a
**user-approval stop** (below). Outside that exception the recap is not optional polish; it is
part of the skill contract. A missing or incomplete recap means the loop is not finished.

### Exception — user-approval stops (no recap)

When the loop ends because a phase skill is presenting a **user approval or decision prompt**
and waiting for that response, **do not emit the end-of-loop recap**. The approval prompt *is*
the final user-facing message for this invocation. Do not append Slice / Phases run / Where left
/ Review lines after (or before) it.

Examples (not exhaustive):

- `/workflow:plan` plan approval gate (Approve & Save / Approve & Execute / Revise)
- Brainstorm convergence choice
- Review findings triage that needs an explicit user decision
- Integration/merge confirmation stop
- Any other `AskUserQuestion`-class gate where the user must choose before the loop proceeds

At an approval stop: phase prompt only — no invented recap. After the user answers, next continue
recaps normally if that stop is not another approval gate.

**Recap still required for:** path-not-established, slice complete/merged, blocked without decision
prompt, paused mid-work without approve/choose UI.

### Always include (when recap applies)

| Block | Content |
|-------|---------|
| **Slice** | Work item id + one-line title |
| **Phases run** | Which workflow phases actually ran this invocation (e.g. plan → execute → review → merge) |
| **Where left** | Next phase / gate / pickup pointer |
| **Branch / commits** | Branch name and key SHAs if code moved |
| **Steering** | When relevant: `silent` · `path-not-established` · `offered (steering_note)` · user choice |

### When this loop produced or integrated code (required Review block)

If execute produced commits, or the slice is at/past "code exists", **and** this stop is not a
user-approval exception above, the recap **must** include a **Review findings & disposition**
block sourced from a real `/workflow:review` (or equivalent) pass — **not** from gate output:

```markdown
### Review findings & disposition
- **method:** /workflow:review (or structured-agents: <lenses>)
- **depth:** quick | standard | deep
- **target:** <range or paths reviewed>
- **findings:** P1=n · P2=n · P3=n
- **disposition:** <each finding fixed | deferred to ISSUE | none>
- **verdict:** APPROVE | REQUEST_CHANGES → remediated
```

Rules:

1. **No code-path recap without this block.** If you cannot fill it, you have not reviewed —
   status remains "code exists, not reviewed"; do not merge; do not claim reviewed-clean.
2. **Gates are a separate line** (typecheck/lint/test/…). Never put gate results inside the
   Review findings block or use them as a substitute for findings counts.
3. **Empty findings still report counts** (`P1=0 P2=0 P3=0`) and `disposition: none` — silence
   is not a valid substitute for "no findings."
4. **User-visible:** the block appears in the final message of the loop, not only in
   `session-state.md` or a PM comment. Durable evidence still goes to PM/handoff; the recap is
   how the human audits that review actually ran.
5. **If the loop stopped before review** for a non-approval reason, say so explicitly:
   `Review: not run — stopped at <gate>` rather than omitting the topic. (User-approval stops
   omit the entire recap per the exception above — do not add this line either.)

### When the loop did not touch product code

When recap applies, a shorter recap is fine (slice, phases, where left). Still state
`Review: n/a — no code this loop` so the omission is deliberate.

## Soft-check on next orientation

On next orient: theater `review:` lines (missing `method=` / findings counts) and missing compound
notes — surface before new work. Detail: `references/soft-checks.md`.

## What `/continue` does not do

- Does **not** invent a next unit or NEXT pointer (unlisted work / fatigue language / residual-only).
  Scaffolding `planning/<slug>/` for a **named** NEXT unit (or letting refine/plan do so) is allowed.
- Does **not** hard-stop solely because a named unit lacks a planning directory yet.
- Does **not** auto-invoke `/workflow:brainstorm` or `/workflow:roadmap` — stop + offer only.
- Does **not** author or rewrite roadmaps, workstreams, or brainstorm seeds.
- Does **not** re-run a phase that already produced its artifact (existing
  `brainstorm.md` / `requirements.md` / plan).
- Does **not** author plan or requirements content directly — that's `/workflow:plan` /
  `/workflow:refine`.
- Does **not** skip the review gate. Code → merge without `/workflow:review` (or equivalent)
  **and valid review evidence** is a process bug. Project gates green ≠ reviewed.
- Does **not** treat typecheck/lint/test/build (or other project hygiene gates) as the review.
- Does **not** claim reviewed-clean or autonomous-merge without a recap **Review findings &
  disposition** block matching the evidence schema.
- Does **not** invent `review: clean` theater to satisfy handoff or PM closeout.
- Does **not** skip compound after integrate without an explicit `compound: none` reason.
- Does **not** push or open PRs unless project conventions explicitly allow main-push at agent
  judgment — production promotion stays user-initiated either way.
- Does **not** drive multiple items in parallel — that's `/swarm`. It picks **one** slice and
  drives it sequentially.
- Does **not** grab an item an active swarm run is working.
- Does **not** run soft portfolio steering hunts; optional `steering_note` only (v1).
- Does **not** emit the end-of-loop recap when stopping on a user-approval gate — the phase's
  approval/decision prompt is the final message (see *End-of-loop recap* exception).

## Related

- **`@workflow`** — the parent: session-state schema, branch naming, decomposition modes, phase
  set, altitude triage. `/continue` routes over these; it doesn't restate them.
- **`@workflow:setup`** — authors/maintains `planning/conventions.md` (the project tracks, gates,
  and integration policy this skill loads in Orientation step 0). Run it to teach a project's local
  process to `/continue`.
- **`@workflow:roadmap`** — user-only multi-unit map author; continue consumes NEXT, never writes the map.
- **`@workflow:brainstorm`** — single-concept HITL; continue may route a claimed fuzzy unit here.
- **`/swarm`** — parallel, backlog-scale orchestration. `/continue` is its sequential counterpart.
  Swarm does **not** enforce continue's path-not-established gate (separate state store).
- **`@superpowers:finishing-a-development-branch`** — the integration decision point routed to
  after a clean review.
