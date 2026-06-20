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

- **`/workflow:setup`** — the inverse. Setup authors `planning/conventions.md` + the handoff
  scaffold; prune reads the same conventions to know each project's status vocabulary, queue, PM
  mode, and which files are **live orchestration** (never prune targets).
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

**Protect the live orchestration set — never prune targets:** the handoff
(`session-state.md` / `SESSION-HANDOFF.md`), `conventions.md`, the queue (`work-streams.md`), any
**track process doc** (e.g. `discovery-loop.md`), and history archives still referenced by the
handoff. When in doubt about a meta file, protect it and surface it rather than proposing deletion.

### 2. Enumerate candidates

Collect prune **candidates** — never the protected set:

- **Work-item directories** (`planning/<item>/`, or `planning/<milestone>/<stream>/` for nested
  layouts), and entire **completed-milestone** dirs when scoped to one.
- **Loose `planning*` meta files** corresponding to completed work (a finished feature's design/spec
  doc, an orphaned plan file, a superseded tracker).

### 3. Verify completion (evidence, not just a status field)

For each candidate, gather **multiple signals** — a `status:` field alone is not proof:

- **Status** — the item's `session-state.md` frontmatter reads terminal in the project's vocabulary.
- **Git** — referenced merge commit(s) are present on the main branch; the item's branch is merged
  / deleted; no uncommitted work references the item.
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
- **Protected** — the live orchestration files, for transparency.

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
- Does **not** delete **live orchestration** docs (handoff, `conventions.md`, `work-streams.md`,
  track process docs, referenced archives).
- Does **not** purge without an explicit confirmation gate.
- Does **not** delete an item with **unmigrated durable knowledge** — it flags it for
  `/workflow:compound` first.
- Does **not** rewrite append-only history, and does **not** push.

## Related

- **`@workflow:setup`** — the inverse; authors what prune reclaims.
- **`@workflow:compound`** — capture durable knowledge before pruning a completed item.
- **`@workflow`** — session-state schema, the planning directory structure, and the `archive/`
  convention prune honors.
