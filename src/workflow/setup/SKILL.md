---
name: workflow:setup
description: Initialize and maintain the planning/ docs the workflow family depends on, and collaborate with the user to define project-local conventions — work tracks, project-specific gates, and integration policy — that all /workflow phases honor.
argument-hint: "[optional: 'maintain' to refresh existing conventions, or blank to initialize]"
user-invocable: true
---

# Project Workflow Setup (`/workflow:setup`)

`/workflow:setup` is the **idempotent initializer and maintainer** for a project's `/workflow`
scaffolding. Run it once to bootstrap, and any time afterward to refresh. It does two things:

1. **Ensures `planning/` git hygiene** (`.gitkeep` + directory-local `.gitignore` in `planning/`
   and work-item subdirs) so the area stays low-churn. It creates `conventions.md` *only when*
   the project has actual custom conventions (extra tracks, gates, or non-default policy). It
   creates a top-level `session-state.md` *only when* there is an active cross-project handoff
   or open slice to track at the root. Per-item state lives under `planning/<item>/` and is
   created by plan/execute when work begins.
2. **Collaborates with you** to capture **project-local conventions** (only when they differ
   from the built-in defaults) — additional work tracks, project-specific gates, and integration/merge
   policy. When real content exists it writes `planning/conventions.md`; otherwise phases simply use
   the documented defaults.

It is **non-destructive** and **minimalist**: it never creates empty or default-only scaffolding.
It never clobbers existing real content. In maintain mode it diffs detected reality against
what's recorded (and removes default-only files if the user approves).

## User Input

```text
$ARGUMENTS
```

`maintain` (or `refresh`) → maintain mode against existing docs. Blank → initialize (and fall
through to maintain if docs already exist).

## Relationship to other skills

- **`/swarm:setup`** — complementary, not overlapping. `/workflow:setup` is **swarm-independent**
  and writes only under `planning/`; it may reference or contribute to `.agent-tools/` for other
  durable agent configuration (e.g. bounded personify profile). If you also use `/swarm`, run `/swarm:setup` for
  the shared charter (`.agent-tools/charter/`). Different primary scopes, no collision.
- **`/workflow:continue`** — the primary consumer of `planning/conventions.md`. It classifies the
  next slice into the right track, routes per the conventions, and applies the project gates.
- **All `/workflow:*` phases** honor the project gates and integration policy recorded here.

## Procedure

### 1. Detect current state (idempotent)

Survey what already exists; **read before writing**:

- `planning/` directory and any work-item subdirs (`planning/<project>/session-state.md`).
- `planning/conventions.md` — present → maintain (diff for drift). Absent or only-defaults → no file (defaults are implicit).
- Top-level `planning/session-state.md` — present with live pointer → maintain. Otherwise do not create/maintain one (per-item `planning/<item>/session-state.md` is the normal location; top-level is only a light optional pointer for cross-slice coordination).
- `AGENTS.md` / `CLAUDE.md` / `CONTRIBUTING.md` and any PM/MCP signals — to pre-fill defaults and
  avoid re-asking what the project already states.

Report what you found and what's missing before changing anything.

### 2. Collaborate to define conventions

Interview the user only for what can't be inferred. Confirm detected defaults rather than
re-asking. Capture, into `planning/conventions.md`:

- **Requirements-source mode** — file vs PM (and PM tool), per `@workflow`. Detect, confirm.
- **Work tracks.** The **default feature track**
  (`brainstorm → refine → plan → execute → review → finish → compound`) is always present. Ask
  whether the project has **additional tracks** that should *override* the default phase table for
  the units they govern — e.g. a research/discovery loop, a data-labeling cycle, a release
  checklist. For each extra track capture:
  - **Name** and a one-line description.
  - **Classification rule** — how to tell when the next unit belongs to this track vs. the feature
    track.
  - **Process** — the doc it follows (e.g. `planning/discovery-loop.md`) and that it **replaces**
    the default phase table for its units (including its own review-equivalent).
- **Project-specific gates** — checks **additive to** the standard review gate (e.g. cross-cutting
  safety, regression/holdout adoption, schema/contract lockstep). For each: what it verifies and
  the command/criterion to confirm it.
- **Integration / merge policy** — local vs remote, merge style, any banking/versioning, and the
  push policy. Default and recommended: **local integration only; pushing and PRs are
  user-initiated** (never autonomous).
- **Decision-record layers + genre.** Confirm (detect, don't over-ask) the file that plays each of
  the three doc roles, and the genre. **Decision layer** (researched decisions — default
  `docs/decisions/`, or a README `## Decisions` section), **domain layer** (how the system is
  designed/behaves — a docs site / `docs/` / README), **realization layer** (how much is built — the
  PM tracker / a milestone). **Genre:** the decisive default is `current-state` (records rewritten in
  place; no supersession/tombstones — see @workflow (`references/decision-records.md`)). Elect
  `classic-immutable` (append-only, superseded-not-rewritten) **only** for a regulated/contractual
  project where an immutable audit trail is itself a deliverable — the unlikely exception, not a
  co-equal option.

### 3. Write `planning/conventions.md` (only when it has real content)

Create (or update) it **only if** the project has non-default conventions:
- Custom requirements source (e.g. `pm (linear)`)
- One or more additional work tracks that override the default phase table
- Project-specific gates beyond the standard review gate
- Non-default integration / merge policy
- Non-default decision-record layers (a decision/domain layer that isn't `docs/decisions/` + the obvious docs home) or the `classic-immutable` genre

If everything is default (file mode + the standard feature track + standard local-only policy), **do not create** the file. All `/workflow:*` phases already assume the defaults when `conventions.md` is absent.

When content *does* exist, use this shape (omit empty sections):

```markdown
# Project Workflow Conventions

> Project-local overrides honored by all `/workflow:*` phases. Maintained by `/workflow:setup`.

## Requirements source
<file | pm (tool)>

## Decision records   (only if non-default — else the current-state defaults apply implicitly)
- Genre: current-state | classic-immutable   (default: current-state — rewrite in place, no supersession/tombstones)
- Decision layer: <docs/decisions/ | README §Decisions | …>
- Domain layer:   <docs site | docs/ | README>
- Realization layer: <Linear | Jira | milestone>

## Work tracks
### Default feature track
brainstorm → refine → plan → execute → review → finish → compound  (the `/workflow` phase table)

### <Extra track name>   (only if the project has one)
- **When it applies:** <classification rule>
- **Process:** follow `<doc>`; this **overrides** the feature-track phase table for these units.

## Project gates  (additive to the standard review gate)
- **<Gate>:** <what it checks> — verify with `<command/criterion>`.

## Integration / merge policy
<local-only / merge style / banking / push policy>
```

### 3.5 Ensure planning/ git hygiene (directory-local)

To keep `planning/` as a high-traffic but mostly transient area (reducing history churn), every planning directory must have:

- A `.gitkeep` (to preserve empty directory structure in the repo).
- A `.gitignore` that ignores everything by default, with explicit exceptions only for allowed files.

For the top-level `planning/`:
```gitignore
*
!.gitkeep
!conventions.md
!session-state.md
```

For each work-item subdirectory (`planning/<item>/`):
```gitignore
*
!.gitkeep
```

These rules are **directory-local** inside `planning/.gitignore` and per-item `.gitignore` (no planning/ exceptions are placed in the project root `.gitignore`).

In initialize mode: ensure `planning/` hygiene (`.gitkeep` + `.gitignore`). Create `conventions.md` or a top-level `session-state.md` **only when there is actual content to record** (see rules above). Per-item state and handoffs are created later by the phases that need them.

### 4. Handoff scaffold (top-level `session-state.md`) — optional

A top-level `planning/session-state.md` is a **light optional pointer**, not a requirement.

- Create or maintain it **only when** there is an active cross-project handoff, an open root-level slice, or a need to point at a non-default queue location.
- Per-item state is created under `planning/<item>/session-state.md` by `/workflow:plan` and `/workflow:execute` when real work on a slice begins.
- `/workflow:continue` already treats a top-level pointer as optional: "honor it — but do not require one. The scan of `planning/*/session-state.md` is the source of truth."

If a top-level file exists but is empty or has no live status, remove it in maintain mode (or let the user prune it).

When a top-level handoff *is* present and useful, include a durable orientation block near the top:

```markdown
## Project orientation  (durable — read these first)
- `planning/conventions.md` — work tracks, project gates, integration policy. (May be absent when only defaults apply.)
- `AGENTS.md` / `CONTRIBUTING.md` — general collaboration rules and gates.
```

Keep any handoff **light**. Compress history per `@workflow:continue`.

### 5. Maintain mode

When conventions already exist: show the current conventions, diff against detected reality
(new work-item dirs, a PM tool now present, a track doc that moved), and offer **targeted** edits.
Never silently overwrite the user's recorded intent — confirm each change.

Also evaluate the planning/ structure:
- Check for `planning/.gitkeep` and `planning/.gitignore` (with the canonical content above, including `!session-state.md` at top level).
- For every work-item subdirectory (detected via session-state.md, implementation-plan.md, etc.): check for `.gitkeep` and `.gitignore` (with `* \n !.gitkeep`).
- If the root `.gitignore` has any planning/ lines, note them (they are not required; hygiene is directory-local).
- If `conventions.md` exists but contains only defaults (no extra tracks/gates/policy), offer to delete it.
- If a top-level `session-state.md` exists but has no active content, offer to delete it.
- If anything structural is missing or incorrect: propose creating or fixing (idempotent, non-destructive). This keeps the "everything not explicitly allowed is ignored" contract and avoids empty scaffolding.

## What `/workflow:setup` does not do

- Does **not** plan, refine, or execute work — it sets up the scaffolding those phases use.
- Does **not** author the swarm charter (that's `/swarm:setup`); it may interact with `.agent-tools/` for other durable config.
- Does **not** invent conventions the project doesn't have. If only defaults apply, no `conventions.md` is created (phases fall back to built-in defaults).
- Does **not** create empty top-level `session-state.md` scaffolding. Top-level handoff is created only for a live cross-project pointer; normal per-item state is created under `planning/<item>/` by plan/execute.
