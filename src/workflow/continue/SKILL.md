---
name: workflow:continue
description: Resume the next slice of work — orient from planning/ state, pick one PM-defined value slice, and drive it through the full workflow loop, stopping only where user input is required.
argument-hint: "[--worktree] [optional: work item ID, planning dir, or blank to auto-pick the next slice]"
user-invocable: true
---

# Continue the Next Slice (`/workflow:continue`)

A thin **sequential orchestrator** over the `/workflow` family. It orients from what
`planning/` already records, picks **one** unit of PM-defined value (a slice / story / work
item), and drives that single slice through the full workflow loop — refine → plan → execute →
review → finish → compound — **auto-advancing through phases that need no human input and
stopping only where your input is genuinely required**.

It is **not** a recipe engine. The underlying `/workflow:*` skills carry their own structure;
`/continue` only decides *which* slice and *which* phase comes next from current state, then
lets each phase run natively.

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
orient → pick ONE slice → classify its stage → drive the full loop,
         pausing only at user-input gates → track the handoff → stop
```

One slice, start to a natural stopping point. Maximum steerability: you see each gate and the
final handoff, never a runaway. Do **not** layer prescriptive steps on top of the `/workflow:*`
skills — let each run its own structure.

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
1. **Scan** `planning/*/session-state.md` frontmatter (the schema in `@workflow`). Find the
   active slice:
   - A slice with `status: in_progress` (and a live `branch`) is already claimed — resume it
     unless the user named a different target.
   - Otherwise take the next `status: planned` slice by priority/order.
   - If a light top-level pointer exists (e.g. a project-wide `planning/session-state.md`),
     honor it — but do not require one. The scan is the source of truth.
2. **Honor an explicit target.** If the user named a work item or path, target that slice even
   if another is in progress (warn if you're leaving an in-progress slice behind).
3. **Confirm the precise stage** from the slice's own `planning/<project>/session-state.md` and
   any in-flight state (a half-applied change, an unreviewed commit, an open question).

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
| Idea still fuzzy, direction unchosen | `/workflow:brainstorm` |
| Direction chosen, requirements ambiguous or have TBDs | `/workflow:refine` |
| Requirements clear, no implementation plan | `/workflow:plan` |
| Plan approved, work not started **or in progress** | `/workflow:execute` (resume where the plan left off) |
| Code exists, not reviewed | `/workflow:review` (or `/code-review`) — fix every finding |
| Reviewed clean, not integrated | Finish the branch (see `@superpowers:finishing-a-development-branch`) |
| Integrated / merged | `/workflow:compound`, then update the handoff |

**Each row is a gate, not a suggestion.** Don't jump from "code exists" to "merged" without the
review pass — that's a process bug, not a shortcut. **Brainstorm and refine are skip-by-default**
when a `brainstorm.md` / `requirements.md` already exists for the slice — don't re-run a phase
that already produced its artifact.

Within one `/continue` invocation, walk this table for the chosen slice, advancing through
phases automatically **until you hit a user-input gate or the slice completes**.

## Where to stop (inject user input)

Auto-advance only where no human decision is owed. **Stop and hand back** at any genuine gate:

- Direction or requirements are ambiguous (brainstorm/refine needs your call).
- A plan is ready for **approval** (`/workflow:plan` approval gate — never save/execute a plan
  without it).
- Review surfaced findings that need a **triage decision**.
- Integration/merge needs **confirmation** (and pushing/PR is always user-initiated — never push
  or open a PR autonomously).
- Any `AskUserQuestion`-class decision the slice can't resolve on its own.

A stop is a feature: it returns control with state saved, so the next `/continue` (or you)
resumes cleanly.

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
4. If the slice **merged/integrated**, run `/workflow:compound` to capture durable insight (and
   write a cross-session memory if warranted — see the global memory instructions).

Keep the slice's state and any top-level pointer consistent: if the pointer lags the slice
state, the next pickup is wrong.

## What `/continue` does not do

- Does **not** re-run a phase that already produced its artifact (existing
  `brainstorm.md` / `requirements.md` / plan).
- Does **not** author plan or requirements content directly — that's `/workflow:plan` /
  `/workflow:refine`.
- Does **not** skip the review gate. Code → merge without `/workflow:review` (or `/code-review`)
  is a process bug.
- Does **not** push or open PRs — integration is local; pushing is user-initiated.
- Does **not** drive multiple items in parallel — that's `/swarm`. It picks **one** slice and
  drives it sequentially.
- Does **not** grab an item an active swarm run is working.

## Related

- **`@workflow`** — the parent: session-state schema, branch naming, decomposition modes, phase
  set. `/continue` routes over these; it doesn't restate them.
- **`@workflow:setup`** — authors/maintains `planning/conventions.md` (the project tracks, gates,
  and integration policy this skill loads in Orientation step 0). Run it to teach a project's local
  process to `/continue`.
- **`/swarm`** — parallel, backlog-scale orchestration. `/continue` is its sequential counterpart.
- **`@superpowers:finishing-a-development-branch`** — the integration decision point routed to
  after a clean review.
