---
name: workflow:prune
description: Sweep planning/ for fully-completed work, verify completion against git history and PM tooling, present a summary for approval, then purge the confirmed-complete item directories and stale meta files (git-recoverable).
argument-hint: "[optional: a work item / dir / milestone to scope the sweep, or blank to sweep all of planning/]"
user-invocable: true
---

# Prune Completed Planning (`/workflow:prune`)

`/workflow:prune` is the **corollary to `/workflow:setup`**: setup *creates* the `planning/`
scaffolding the workflow family depends on; prune *reclaims* it once work is done. It sweeps
`planning/` for **fully-completed** items, **verifies** completion against evidence (git history +
PM tooling, as applicable), presents a summary, and — **only after you approve** — purges the
confirmed-complete item directories and stale meta files.

It is **conservative and non-destructive by default**: it proposes, you dispose. Nothing is deleted
without an explicit confirmation, and everything it removes stays recoverable via git history.

## User Input

```text
$ARGUMENTS
```

| Input | Meaning |
|-------|---------|
| *(empty)* | Sweep all of `planning/`. |
| A work item / dir / milestone | Scope the sweep to that item, directory, or completed milestone. |

To run report-only, just **decline at the confirmation gate** — the summary is produced before any
deletion.

## Relationship to other skills

- **`/workflow:setup`** — the inverse. Setup ensures hygiene and authors `planning/conventions.md` (only when non-default) + optional top-level handoff; prune reads conventions (if present) to know status vocabulary / PM mode / structure. Permanent keepers when present: conventions.md + .gitkeep + .gitignore. Queue/handoff/session-state files are pruned once their work is complete.
- **`/workflow:compound`** — capture durable knowledge **before** purging. Prune checks that a
  completed item's hard-won insight is already migrated (compound doc / ADR / runbook / memory) and
  **flags** any that isn't, rather than silently deleting the only record.
- **`/workflow:continue`** — never prune the active slice or anything the handoff names as next.

## Procedure

### 1. Load conventions & identify protected files

Read `planning/conventions.md` (if present) to learn:

- The project's **status vocabulary** (e.g. `complete`, `complete_merged`, `done` vs. the generic
  `complete`) — what "fully done" looks like here.
- **PM mode** (file vs Linear/Jira) — whether to cross-check an issue tracker.
- The **orientation/queue + structure** (flat `planning/<item>/` vs milestone-nested
  `planning/<milestone>/<stream>/`).

**Protect the live orchestration set — never prune targets:** `conventions.md`, the `.gitkeep` and `.gitignore` files (for directory structure), any **track process doc** (e.g. `discovery-loop.md`), and history archives still referenced by the handoff. 

The queue (`work-streams.md`), handoff (`session-state.md` / `SESSION-HANDOFF.md`), and `session-state.md` files are protected *only while active or incomplete*. Once the associated (cross-project) work is classified as CONFIRMED-COMPLETE, they become eligible for purge (the only permanent keepers are the structural `.gitkeep`/`.gitignore` and `conventions.md` when present). When in doubt about a meta file, protect it and surface it rather than proposing deletion.

### 2. Enumerate candidates

Collect prune **candidates** — never the protected set (structural .gitkeep/.gitignore, conventions.md, track process docs, referenced archives):

- **Work-item directories** (`planning/<item>/`, or `planning/<milestone>/<stream>/` for nested
  layouts), and entire **completed-milestone** dirs when scoped to one. This includes the `session-state.md`, handoff, and queue (`work-streams.md`) files inside/associated once classified as complete.
- **Loose `planning*` meta files** corresponding to completed work (a finished feature's design/spec
  doc, an orphaned plan file, a superseded tracker, or completed session-state/handoff/queue files).

**Not everything under `planning/` is a prunable work item.** A candidate is a *work item* only if
it carries work-tracking state — a `session-state.md`, a `pass-log.md`, a plan/requirements file, 
handoff files, or the queue (`work-streams.md`) once the (cross-project) work is complete. 

The structural `.gitkeep` and `.gitignore` files, `conventions.md`, track process docs, and referenced archives are **never** candidates. The queue (`work-streams.md`), handoff, and session-state are cross-project or item orchestration artifacts and become candidates once complete.

A subdirectory that holds **raw data / fixtures** (e.g. source PDFs, a golden set) or **shared tooling**
(scripts used by several items) is **out of scope** — treat it as keep, and surface it as "not a work
item" rather than proposing deletion. Also check **inter-candidate dependencies**: don't propose
purging a directory that other (kept) items still depend on — e.g. shared discovery tooling consumed
by passes you're keeping.

### 3. Verify completion (evidence, not just a status field)

**The definition of "complete" can be track-specific.** When a non-feature track governs the item
(per `conventions.md` — e.g. a discovery loop, a labeling cycle), read **that track's process doc**
for what *done* means and which artifact records it. A feature-track slice is done when its branch
merges to main; a **discovery pass** is done when its candidate is **adopted (banked into the
canonical bundle) or characterized**, with its `pass-log.md` findings **migrated** to the durable
record — *not* when a branch merges. Verify against the track's terminal definition, not a generic
merge-commit check.

For each candidate, gather **multiple signals** — a `status:` field alone is not proof:

- **Status** — the item's tracking artifact (`session-state.md` frontmatter, or a `pass-log.md`
  outcome) reads terminal in the project's / track's vocabulary.
- **Git** — referenced merge commit(s) are present on the main branch; the item's branch is merged
  / deleted; no uncommitted work references the item. (For tracks where completion isn't a merge —
  e.g. discovery — substitute the track's terminal evidence: adoption into the bundle, a recorded
  characterization.)
- **PM (if PM mode)** — the item's issue (e.g. `SPEC-###`, `LIN-###`) is **Closed/Done** in the
  tracker. Use the available PM tools; note when the tracker can't be reached.
- **Not active** — the handoff does **not** name the item as the active slice or the next step.
- **Knowledge migrated** — the item's durable insight is captured outside `planning/` (a compound
  doc, ADR, runbook, memory), or it had none worth keeping.

Classify each candidate:

| Class | Meaning | Action |
|---|---|---|
| **CONFIRMED-COMPLETE** | All applicable signals align | Propose for purge |
| **NEEDS-MIGRATION** | Done, but durable knowledge not yet captured | Propose **after** compound/migration; flag it |
| **ACTIVE / INCOMPLETE** | In progress, or named as next | Keep |
| **UNCERTAIN** | Signals conflict or evidence missing (e.g. status terminal but no merge commit found) | Keep; explain why |

Bias conservative: **only purge CONFIRMED-COMPLETE**. Anything ambiguous stays.

### 4. Present the summary

Show a table of every candidate with its class, the **evidence per signal** (status / merge commit /
PM status / handoff-referenced / knowledge-captured), and the recommendation. Explicitly list:

- **Will purge** (CONFIRMED-COMPLETE) — the exact dirs/files.
- **Migrate first** (NEEDS-MIGRATION) — what durable knowledge to capture before it's safe.
- **Keeping** (ACTIVE / UNCERTAIN) — and why.
- **Protected** — the permanent live orchestration files (conventions.md, .gitkeep, .gitignore, track process docs, referenced archives), for transparency. (Note: queue (`work-streams.md`), session-state.md, and handoff files are purged when their work is complete.)

### 5. Confirmation gate

Require **explicit approval** before deleting anything. Offer: approve all proposed, pick a subset,
or cancel. Never purge on implicit assent.

### 6. Purge (on approval)

- Remove the approved dirs/files with **`git rm -r`** so the deletion is tracked and recoverable via
  history (do not hard-delete untracked-only state without noting it).
- If the handoff or queue carries a **forward** pointer to a purged item, update it; **leave
  append-only history bullets intact** (they are accurate records).
- Stage the changes and report them; **commit only if the user asks** (this is a destructive change
  to durable docs — let the user review the diff first). Note the recovery path (the deletions are
  in git history).

## What `/workflow:prune` does not do

- Does **not** delete the **active slice**, anything **in progress**, or anything the handoff names
  as **next**.
- Does **not** delete **permanent live orchestration** docs (`conventions.md`, `.gitkeep`, `.gitignore`, track process docs, referenced archives). The queue (`work-streams.md`), handoff (`session-state.md` / `SESSION-HANDOFF.md`), and `session-state.md` may be purged once their (cross-project) work is complete.
- Does **not** purge without an explicit confirmation gate.
- Does **not** delete an item with **unmigrated durable knowledge** — it flags it for
  `/workflow:compound` first.
- Does **not** rewrite append-only history, and does **not** push.

## Related

- **`@workflow:setup`** — the inverse; authors what prune reclaims.
- **`@workflow:compound`** — capture durable knowledge before pruning a completed item.
- **`@workflow`** — session-state schema, the planning directory structure, and the `archive/`
  convention prune honors.
