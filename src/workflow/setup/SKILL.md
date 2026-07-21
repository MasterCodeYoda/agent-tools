---
name: workflow:setup
description: Initialize and maintain planning root (.agent-tools/planning preferred), conventions (tracks, gates, integration), runs ledger scaffold, and shared memory under .agent-tools/memory/ (AGENTS.md memory-link) for the workflow family.
argument-hint: "[optional: 'maintain' to refresh existing conventions, or blank to initialize]"
user-invocable: true
---

# Project Workflow Setup (`/workflow:setup`)

`/workflow:setup` is the **idempotent initializer and maintainer** for a project's `/workflow`
scaffolding. Run it once to bootstrap, and any time afterward to refresh. It does three things:

1. **Ensures planning-root git hygiene** under the preferred root **`.agent-tools/planning/`**
   (legacy `./planning/` still honored until migrated — @workflow `references/planning-root.md`).
   `.gitkeep` + directory-local `.gitignore` so the area stays low-churn. Creates `conventions.md`
   *only when* the project has actual custom conventions. Top-level `session-state.md` only for
   live cross-slice handoff. Per-item state under `planning/<item>/` from plan/execute.
2. **Collaborates on project-local conventions** (non-defaults only) — tracks, gates, merge
   policy, orientation/PM queue, visual plan. Optional **personal factory** profile pack.
3. **Scaffolds** `.agent-tools/memory/` (+ AGENTS memory-link) and **`.agent-tools/runs/`**
   (events spine + empty ledger — @workflow `references/runs-ledger.md`).

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
  for `planning/` conventions; it also owns the **project shared-memory scaffold** under
  `.agent-tools/memory/` and the AGENTS.md memory-link block. It may reference other
  `.agent-tools/` config (e.g. personify). If you also use `/swarm`, run `/swarm:setup` for
  the shared charter (`.agent-tools/charter/`). Swarm does not invent a second memory-link format.
- **`/workflow`** (bare) — read-only portfolio **status**; scans conventions / planning root but
  never claims. Drive with **`/workflow:continue`**.
- **`/workflow:continue`** — the primary **drive** consumer of `planning/conventions.md`. It
  classifies the next slice into the right track, routes per the conventions, and applies the
  project gates. Path resolution may also consume a horizon map (`roadmap.md` or workstreams)
  when present.
- **`/workflow:roadmap`** — user-only multi-unit map author; default dialect `planning/roadmap.md`.
  Setup does **not** require a roadmap; record a non-default dialect only if the project already
  uses something else (e.g. `initiatives/` + `workstreams/`).
- **All `/workflow:*` phases** honor the project gates and integration policy recorded here.

## Procedure

### 1. Detect current state (idempotent)

Survey what already exists; **read before writing** (@workflow `references/planning-root.md`):

- Planning roots: `.agent-tools/planning/` (preferred) and/or legacy `./planning/`.
- Work-item subdirs under each root; active `in_progress` session-state if any.
- `planning/conventions.md` — present → maintain (diff for drift). Absent or only-defaults → no file.
- Top-level `planning/session-state.md` — live pointer only; otherwise do not create.
- `AGENTS.md` / `CLAUDE.md` / `CONTRIBUTING.md` and PM/MCP signals — pre-fill defaults.
- `.agent-tools/memory/` — maintain or plan create + AGENTS memory-link.
- `.agent-tools/runs/` — maintain or plan create (README, events, ledger).
- Legacy `docs/solutions/` — note migrate via `/workflow:compound --maintain --migrate-solutions`.

Report what you found and what's missing before changing anything.

### 1.5 Planning-root migration check (mandatory)

**Load and follow** `references/planning-migration.md` end-to-end for cases A–D.

| Case | Detect | Setup must |
|------|--------|------------|
| **A** Preferred only | `.agent-tools/planning/` exists; no `./planning/` | Hygiene only |
| **B** Neither | no planning roots | Create preferred empty hygiene — **never** create `./planning/` |
| **C** Legacy only | `./planning/` exists; preferred absent | **Propose migrate** to `.agent-tools/planning/`; require explicit user **yes**; apply with `git mv` when tracked; grep committed docs for hard-coded `./planning/` |
| **D** Both | both directories exist | **Dual-root repair** — do not leave silent dual; user chooses finish-merge / resolve conflicts / discard empty preferred / archive legacy |

**Hard refuses:**

- Do **not** create empty `.agent-tools/planning/` while live work remains only under `./planning/`
  (resolution would hide the live plant).
- Do **not** migrate or delete a non-empty root without explicit confirmation.
- Do **not** skip this check in maintain mode — every setup run re-detects.

If the user **declines** Case C migrate: continue setup using legacy as root; do not create
preferred until they accept migrate later.

After migrate or repair, all later steps use the **active** planning root only.

### 2. Collaborate to define conventions

Interview only for what can't be inferred. Confirm detected defaults rather than re-asking.

**Profile shortcut:** if the user wants a **personal factory** (solo throughput, local merge,
Linear optional), load and adapt `setup/templates/personal-factory-conventions.md` (micro +
research tracks, autonomous local merge when ratchet green, orientation/PM queue). Visual plan
approval is omitted so the built-in `on-substantial` default applies. Optionally write
`planning/research-loop.md` from `setup/templates/research-loop.md`.

Otherwise capture into `planning/conventions.md` only non-defaults:

- **Requirements-source mode** — file vs PM (and PM tool).
- **Work tracks** — built-in always: feature, micro, research (`references/tracks.md`). Ask only
  for **extra** project tracks (name, classification, process doc). Personal factory documents
  micro + research in conventions so merge/visual defaults apply with them.
- **Project-specific gates** — additive to standard review.
- **Integration / merge policy** — personal factory: autonomous local merge when ratchet green;
  push/PR user-initiated.
- **Orientation / queue** — NEXT SoT; optional closed PM filter (`workflow:claimable`); never invent.
- **Visual plan approval** — omit for built-in `on-substantial` (including personal factory);
  only record when non-default (`never` / `always` / custom output path).
- **Durable design docs vs planning/** — planning transient; promote to `docs/design/` when durable.
- **Decision-record layers + genre** — default `current-state` (`references/decision-records.md`).

### 3. Write `planning/conventions.md` (only when it has real content)

Create (or update) it **only if** the project has non-default conventions:
- Custom requirements source (e.g. `pm (linear)`)
- Personal factory profile or explicit micro/research conventions text (recommended for solo)
- Extra tracks beyond built-ins, or process overrides
- Project-specific gates beyond the standard review gate
- Non-default integration / merge policy (including autonomous local merge)
- Orientation / PM queue filter
- Non-default visual plan approval policy (anything other than implicit
  `on-substantial`)
- Non-default decision-record layers or the `classic-immutable` genre

If everything is default (file mode + built-in tracks only + standard local-only policy with
merge confirm), **do not create** the file. Built-in micro/research classification still works
from `references/tracks.md` when conventions are absent; personal merge/visual overrides need
a conventions file.

When content *does* exist, use this shape (omit empty sections):

```markdown
# Project Workflow Conventions

> Project-local overrides honored by all `/workflow:*` phases. Maintained by `/workflow:setup`.
> **Sparse overlay:** only record non-defaults. Any section omitted here keeps the skill’s
> built-in default (e.g. visual plan approval remains `on-substantial` unless this file sets it).

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

## Visual plan approval   (only if non-default)
- **Policy:** never | on-substantial | always
- **Output path:** planning/<project>/visual-plan.html   # optional
```

### 3.5 Ensure planning-root git hygiene (directory-local)

**Active root only** (after §1.5). Preferred when migrated or Case B; legacy only if Case C
declined. Never author hygiene under a second parallel root.

Every planning directory must have:

- A `.gitkeep` (to preserve empty directory structure in the repo).
- A `.gitignore` that ignores everything by default, with explicit exceptions only for allowed files.

For the top-level planning root:
```gitignore
*
!.gitkeep
!conventions.md
!session-state.md
!roadmap.md
!research-loop.md
```

(If the project uses committed `initiatives/` or `workstreams/`, add matching `!` exceptions when
those dirs are intentional live orchestration — only when the project already chose that dialect.)

For each work-item subdirectory (`planning/<item>/`):
```gitignore
*
!.gitkeep
```

These rules are **directory-local** inside the planning root’s `.gitignore` and per-item
`.gitignore` (no planning/ exceptions required in the project root `.gitignore`).

In initialize mode: ensure planning-root hygiene. Create `conventions.md` or a top-level
`session-state.md` **only when there is actual content to record**. **Always** run §5 / §5.1
(memory) and **§5.2 (runs)** — independent of conventions content.

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

Keep any handoff **light** — an index, not a log. It holds only: the active-horizon pointer (→ roadmap → unit), the orientation block above, and genuinely-open **unscoped backlog**. It must **not** accumulate release notes (those live in CHANGELOG / tags), completed- or pruned-work narratives, prune records, or items merely pending a routine step (e.g. a merged-but-unpushed fix awaiting a prod release — `git status` shows push state). Unlike a per-item `session-state.md`, the top-level handoff has **no append-only `Session History`** section. Compress/prune per `@workflow:continue`.

### 5. Project shared memory scaffold (`.agent-tools/memory/`)

Idempotent. Create missing pieces; never clobber non-empty entry/solution files.

**Directory tree** (create dirs + defaults if absent):

```text
.agent-tools/memory/
  MEMORY.md
  state.yml
  entries/          # keep with .gitkeep if empty
  solutions/        # keep with .gitkeep if empty
```

**Default `MEMORY.md`** (only when file is missing):

```markdown
# Project memory index

Agent working knowledge for this repo (patterns, gotchas, lessons, debugging solutions).
Maintained by `/workflow:compound`. Not a substitute for ADRs, CONTRIBUTING, or Codex/domain docs.

## Entries

<!-- One-line pointers to entries/<slug>.md — added by compound capture/maintain -->

## Solutions

Debugging post-mortems live under `solutions/<category>/`. Search by `symptoms` / `tags` in
frontmatter; browse by category. Do not enumerate every solution here.
```

**Default `state.yml`** (only when file is missing):

```yaml
schema_version: 1
interval_days: 7
last_maintain_at: null
snooze_until: null
last_maintain_result: null
solutions_migrated_from_docs: false
```

**Empty dirs:** add `entries/.gitkeep` and `solutions/.gitkeep` if the directories would otherwise be empty.

If `MEMORY.md` or `state.yml` already exist with real content, leave them; only fill missing keys in `state.yml` with documented defaults (never overwrite user values).

### 5.1 AGENTS.md memory-link block

`AGENTS.md` is the canonical agent orientation file. Insert (or refresh) a **marker-bounded** block for shared memory — same mechanism as the charter-link from `/swarm:setup`, different markers.

Emit each marker as a standard HTML comment whose inner content is exactly:

- **opening marker** — content: `agent-tools:memory-link begin`
- **closing marker** — content: `agent-tools:memory-link end`

If `AGENTS.md` does not exist, create it with this block. If it exists, insert near the top (after charter-link if present) or refresh the existing marked block in place — never duplicate.

Block body (replace `[[BEGIN-MARKER]]` / `[[END-MARKER]]` with the two HTML comments):

```markdown
[[BEGIN-MARKER]]
## Project agent memory

This project keeps **shared agent working knowledge** under [`.agent-tools/memory/`](.agent-tools/memory/).

| Path | Contents |
|------|----------|
| [`MEMORY.md`](.agent-tools/memory/MEMORY.md) | Index of entries (and a pointer to solutions) |
| `entries/` | Patterns, gotchas, lessons, process invariants |
| `solutions/` | Debugging post-mortems by category |

**What it is:** portable, git-committed knowledge any harness should use — how we got burned, how to operate, reusable patterns.

**What it is not:** ADRs (`docs/decisions/`), CONTRIBUTING/gates, Codex/domain docs, planning scratch, or personify voice.

**Loading policy:** Read [`MEMORY.md`](.agent-tools/memory/MEMORY.md) when compounding, debugging, or hitting an unfamiliar seam; open individual entry/solution files on demand. Do **not** auto-import the entire tree every turn. Capture and maintain via `/workflow:compound` (and `/workflow:compound --maintain`).
[[END-MARKER]]
```

On maintain/re-run: refresh the marked block to the canonical text (safe; only the marked region is replaced). If markers are missing or malformed, stop and ask — never speculatively rewrite AGENTS.md.

### 5.2 Runs ledger scaffold (`.agent-tools/runs/`)

Idempotent. Create missing pieces; never clobber non-empty `events.ndjson` / `ledger.yml`.

```text
.agent-tools/runs/
  README.md
  events.ndjson    # may be empty file
  ledger.yml       # version: 1 + runs: [] if new
```

**Default `README.md`** (only when missing):

```markdown
# Runs ledger

Append-only production-line events (`events.ndjson`) and closed-run rollups (`ledger.yml`).
Written by `/workflow:continue` from phase-return. Do not hand-edit vanity metrics.
See agent-tools workflow skill: `references/runs-ledger.md`.
Regenerate `yield.md` on demand from ledger/events.
```

**Default `ledger.yml`** (only when missing):

```yaml
version: 1
runs: []
```

Touch empty `events.ndjson` if absent. Full schema: @workflow `references/runs-ledger.md`.

### 6. Maintain mode

When conventions already exist: show the current conventions, diff against detected reality
(new work-item dirs, a PM tool now present, a track doc that moved), and offer **targeted** edits.
Never silently overwrite the user's recorded intent — confirm each change.

Also evaluate the planning structure:
- **Re-run §1.5 migration check** (cases A–D) — maintain is not exempt.
- Check for `.gitkeep` and `.gitignore` on the **active** root (canonical exceptions).
- Per work-item subdir: `.gitkeep` + `.gitignore`.
- If `conventions.md` is default-only, offer to delete it.
- If top-level `session-state.md` has no active content, offer to delete it.

Also evaluate shared memory + runs:
- `.agent-tools/memory/` tree + AGENTS memory-link
- `.agent-tools/runs/` README + events + ledger
- Legacy `docs/solutions/` migrate note as before

## What `/workflow:setup` does not do

- Does **not** plan, refine, or execute work — it sets up the scaffolding those phases use.
- Does **not** author the swarm charter (that's `/swarm:setup`); it may interact with `.agent-tools/` for memory, runs, and planning root.
- Does **not** invent conventions the project doesn't have (except when user chooses personal factory pack).
- Does **not** create empty top-level `session-state.md` scaffolding.
- Does **not** migrate `docs/solutions/` or promote harness-local memories — `/workflow:compound --maintain`.
- Does **not** edit the skill corpus — process gaps → process memory + skill-source
  `/skills:evolve` when available (else upstream; never invent a workflow-local improve command).
- Does **not** force planning migration without explicit yes — but **does** always run the
  migration **check** (§1.5) and must not create a dual-root trap.
