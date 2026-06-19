---
name: workflow:setup
description: Initialize and maintain the planning/ docs the workflow family depends on, and collaborate with the user to define project-local conventions — work tracks, project-specific gates, and integration policy — that all /workflow phases honor.
argument-hint: "[optional: 'maintain' to refresh existing conventions, or blank to initialize]"
user-invocable: true
---

# Project Workflow Setup (`/workflow:setup`)

`/workflow:setup` is the **idempotent initializer and maintainer** for a project's `/workflow`
scaffolding. Run it once to bootstrap, and any time afterward to refresh. It does two things:

1. **Ensures the `planning/` docs** the workflow family depends on exist (the handoff scaffold
   with a durable orientation block; the conventions doc).
2. **Collaborates with you** to capture **project-local conventions** the generic `/workflow:*`
   skills can't infer — additional work tracks, project-specific gates, and integration/merge
   policy — and writes them to `planning/conventions.md`, which every phase honors.

It is **non-destructive**: it never clobbers existing content. In maintain mode it diffs detected
reality against what's recorded and offers targeted updates.

## User Input

```text
$ARGUMENTS
```

`maintain` (or `refresh`) → maintain mode against existing docs. Blank → initialize (and fall
through to maintain if docs already exist).

## Relationship to other skills

- **`/swarm:init`** — complementary, not overlapping. `/workflow:setup` is **swarm-independent**
  and writes only under `planning/`; it **never touches `.agent-tools/`**. If you also use
  `/swarm`, run `/swarm:init` for the shared charter (`.agent-tools/charter/`). Different files,
  no collision.
- **`/workflow:continue`** — the primary consumer of `planning/conventions.md`. It classifies the
  next slice into the right track, routes per the conventions, and applies the project gates.
- **All `/workflow:*` phases** honor the project gates and integration policy recorded here.

## Procedure

### 1. Detect current state (idempotent)

Survey what already exists; **read before writing**:

- `planning/` directory and any work-item subdirs (`planning/<project>/session-state.md`).
- `planning/conventions.md` — present → maintain mode; absent → initialize.
- `planning/session-state.md` (top-level handoff) and whether it has a durable orientation block.
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

### 3. Write `planning/conventions.md`

Create or update it. Suggested shape (adapt to the project; omit empty sections):

```markdown
# Project Workflow Conventions

> Project-local overrides honored by all `/workflow:*` phases. Maintained by `/workflow:setup`.

## Requirements source
<file | pm (tool)>

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

### 4. Ensure the handoff scaffold + durable orientation block

If `planning/session-state.md` is absent, scaffold a minimal one. If present but missing a durable
orientation block, **insert one near the top** (above the volatile dated status). The orientation
block is the stable "read these to orient" pointer list — it survives across sessions while the
status below it churns:

```markdown
## Project orientation  (durable — read these first)
- `planning/conventions.md` — work tracks, project gates, integration policy.
- <each track's process doc, e.g. `planning/discovery-loop.md`>
- `AGENTS.md` / `CONTRIBUTING.md` — general collaboration rules and gates.
```

Keep the handoff **light**: the durable block points at references; the dated status carries only
current state. Compress/archive verbose history per `@workflow:continue`.

### 5. Maintain mode

When conventions already exist: show the current conventions, diff against detected reality
(new work-item dirs, a PM tool now present, a track doc that moved), and offer **targeted** edits.
Never silently overwrite the user's recorded intent — confirm each change.

## What `/workflow:setup` does not do

- Does **not** plan, refine, or execute work — it sets up the scaffolding those phases use.
- Does **not** touch `.agent-tools/` or author a swarm charter — that's `/swarm:init`.
- Does **not** invent conventions the project doesn't have — absent extra tracks/gates, the
  conventions doc simply records the default feature track and the integration policy.
