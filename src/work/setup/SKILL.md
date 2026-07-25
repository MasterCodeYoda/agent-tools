---
name: work:setup
description: Initialize and maintain planning root, conventions, runs ledger, shared memory, project charter, and parallel-mode config/functions for the work family.
argument-hint: "[optional: 'maintain' to refresh existing conventions, or blank to initialize]"
user-invocable: true
---

# Project Work Setup (`/work:setup`)

`/work:setup` is the **idempotent initializer and maintainer** for a project's `/work`
scaffolding. Run it once to bootstrap, and any time afterward to refresh. It owns:

1. **Planning-root git hygiene** under preferred **`.agent-tools/planning/`** (legacy
   `./planning/` still honored — @work `references/planning-root.md`).
2. **Project-local conventions** (non-defaults only) — tracks, gates, merge, orientation/PM
   queue, visual plan. Optional **personal factory** profile pack.
3. **`.agent-tools/memory/`** (+ AGENTS memory-link) and **`.agent-tools/runs/`**.
4. **Project charter** (`.agent-tools/charter/`) + AGENTS charter-link + optional agent
   memory symlinks — required for parallel mode; useful ground truth for any session that
   loads it.
5. **Parallel-mode readiness** under `.agent-tools/parallel/` (config.yml + function packets +
   umbrella gitignore). On-disk path retained; operator entry is continue’s parallel mode
   only — @work `parallel/MODE.md`. Decision:
   `docs/decisions/001-swarm-collapse-into-workflow.md`.

It is **non-destructive** and **minimalist**: never creates empty or default-only scaffolding;
never clobbers existing real content without consent. Maintain mode diffs reality vs recorded.

## User Input

```text
$ARGUMENTS
```

`maintain` (or `refresh`) → maintain mode against existing docs. Blank → initialize (and fall
through to maintain if docs already exist).

## Relationship to other skills

- **`/work`** (bare) — read-only portfolio **status**; never claims. Drive with
  **`/work:continue`**.
- **`/work:continue`** — primary drive consumer of conventions; parallel mode when eligible.
- **`/work:roadmap`** — multi-unit map author; setup does not require a roadmap.
- **All `/work:*` phases** honor project gates and integration policy recorded here.
- **No second setup command** for charter/parallel — this skill is the only owner.

## Procedure

### 1. Detect current state (idempotent)

Survey what already exists; **read before writing** (@work `references/planning-root.md`):

- Planning roots: `.agent-tools/planning/` (preferred) and/or legacy `./planning/`.
- Work-item subdirs under each root; active `in_progress` session-state if any.
- `planning/conventions.md` — present → maintain (diff for drift). Absent or only-defaults → no file.
- Top-level `planning/session-state.md` — live pointer only; otherwise do not create.
- `AGENTS.md` / `CLAUDE.md` / `CONTRIBUTING.md` and PM/MCP signals — pre-fill defaults.
- `.agent-tools/memory/` — maintain or plan create + AGENTS memory-link.
- `.agent-tools/runs/` — maintain or plan create (README, events, ledger).
- `.agent-tools/charter/` — present → charter re-setup path in §5.3; absent → offer charter.
- `.agent-tools/parallel/config.yml` + `functions/` — parallel-mode readiness.
- Legacy `docs/solutions/` — note migrate via `/work:maintain --migrate-solutions`.

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
  (resolution would hide the live planning work).
- Do **not** migrate or delete a non-empty root without explicit confirmation.
- Do **not** skip this check in maintain mode — every setup run re-detects.

If the user **declines** Case C migrate: continue setup using legacy as root; do not create
preferred until they accept migrate later.

After migrate or repair, all later steps use the **active** planning root only.

### 2. Collaborate to define conventions

Interview only for what can't be inferred. Confirm detected defaults rather than re-asking.

**Profile shortcut:** if the user wants a **personal factory** (solo throughput, local merge,
Linear optional), load and adapt `templates/personal-factory-conventions.md` (micro +
research tracks, autonomous local merge when ratchet green, orientation/PM queue). Visual plan
approval is omitted so the built-in `on-substantial` default applies. Optionally write
`planning/research-loop.md` from `templates/research-loop.md`.

Otherwise capture into `planning/conventions.md` only non-defaults:

- **Requirements-source mode** — file vs PM (and PM tool).
- **Work tracks** — built-in always: feature, micro, research (`references/tracks.md`). Ask only
  for **extra** project tracks (name, classification, process doc). Personal factory documents
  micro + research in conventions so merge/visual defaults apply with them.
- **Project-specific gates** — additive to standard review.
- **Integration / merge policy** — personal factory: autonomous local merge when ratchet green;
  push/PR user-initiated.
- **Orientation / queue** — NEXT SoT; optional closed PM filter (`work:claimable`); never invent.
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
# Project Work Conventions

> Project-local overrides honored by all `/work:*` phases. Maintained by `/work:setup`.
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
brainstorm → refine → plan → execute → review → finish → compound  (the `/work` phase table)

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
(memory), **§5.2 (runs)**, and **§5.3 (charter + parallel readiness)** — independent of
conventions content (charter may be deferred if user declines, but always offer).

### 4. Handoff scaffold (top-level `session-state.md`) — optional

A top-level `planning/session-state.md` is a **light optional pointer**, not a requirement.

- Create or maintain it **only when** there is an active cross-project handoff, an open root-level slice, or a need to point at a non-default queue location.
- Per-item state is created under `planning/<item>/session-state.md` by `/work:plan` and `/work:execute` when real work on a slice begins.
- `/work:continue` already treats a top-level pointer as optional: "honor it — but do not require one. The scan of `planning/*/session-state.md` is the source of truth."

If a top-level file exists but is empty or has no live status, remove it in maintain mode (or let the user prune it).

When a top-level handoff *is* present and useful, include a durable orientation block near the top:

```markdown
## Project orientation  (durable — read these first)
- `planning/conventions.md` — work tracks, project gates, integration policy. (May be absent when only defaults apply.)
- `AGENTS.md` / `CONTRIBUTING.md` — general collaboration rules and gates.
```

Keep any handoff **light** — an index, not a log. It holds only: the active-horizon pointer (→ roadmap → unit), the orientation block above, and genuinely-open **unscoped backlog**. It must **not** accumulate release notes (those live in CHANGELOG / tags), completed- or pruned-work narratives, prune records, or items merely pending a routine step (e.g. a merged-but-unpushed fix awaiting a prod release — `git status` shows push state). Unlike a per-item `session-state.md`, the top-level handoff has **no append-only `Session History`** section. Compress/prune per `@work:continue`.

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
Capture via `/work:compound`; steward via `/work:maintain`. Not a substitute for ADRs,
CONTRIBUTING, or Codex/domain docs.

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
last_stewardship_at: null
last_yield_at: null
last_maintain_at: null
last_prune_at: null
snooze_until: null
last_maintain_result: null
last_prune_result: null
last_stewardship_result: null
solutions_migrated_from_docs: false
```

Cadence formula: @work `maintain/references/cadence.md`. When refreshing an existing
`state.yml`, **add** missing keys with null defaults; never overwrite user values.

**Empty dirs:** add `entries/.gitkeep` and `solutions/.gitkeep` if the directories would otherwise be empty.

If `MEMORY.md` or `state.yml` already exist with real content, leave them; only fill missing keys in `state.yml` with documented defaults (never overwrite user values).

### 5.1 AGENTS.md memory-link block

`AGENTS.md` is the canonical agent orientation file. Insert (or refresh) a **marker-bounded** block for shared memory — same mechanism as the charter-link (§5.3), different markers.

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

**Loading policy:** Read [`MEMORY.md`](.agent-tools/memory/MEMORY.md) when compounding, debugging, or hitting an unfamiliar seam; open individual entry/solution files on demand. Do **not** auto-import the entire tree every turn. Capture via `/work:compound`; steward (prune + yield + memory) via `/work:maintain`.
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
Written by `/work:continue` from phase-return. Do not hand-edit vanity metrics.
See agent-tools work skill: `references/runs-ledger.md`.
Regenerate `yield.md` via `/work:maintain` (or `--yield`).
```

**Default `ledger.yml`** (only when missing):

```yaml
version: 1
runs: []
```

Touch empty `events.ndjson` if absent. Full schema: @work `references/runs-ledger.md`.

### 5.3 Charter + parallel-mode readiness

Owns project charter and parallel orchestrator scaffolding. Templates live under
@work `parallel/templates/`; canonical functions under @work `parallel/functions/`. Detailed
orchestrator behavior: @work `parallel/MODE.md`.

**Hard refuses:** never `git -C`; never overwrite charter/function-packet content without
consent; never move `./planning/` or QA artifacts under `.agent-tools/`.

#### Detection (evidence before questions)

Scan package manifests, lockfiles, test/lint/format/CI config, existing AGENTS/CLAUDE, git
remote + recent commits, README head, ADRs, PM tool signals, agent dirs (`.claude/`, …).
Summarize findings; let the user correct misdetections.

#### Charter files (`.agent-tools/charter/`)

Each file: frontmatter `last_updated: <YYYY-MM-DD>`; stable headers; sparse bodies.

| File | Role |
|------|------|
| `charter.md` | Entry + precedence + index — skeleton `parallel/templates/charter-entry.md` |
| `project.md` | Identity, stack, surfaces, vocabulary, stakeholders, out of scope |
| `engineering.md` | Testing, types, lint/format, architecture, gates, security, DoD |
| `workflow.md` | PM, branching, commits, merge, review, release, docs |

Fresh: author from evidence + dialogue (< ~8 questions). Re-setup when charter exists: per
section keep / replace / edit (default **keep**); refresh AGENTS charter-link every re-setup.

#### Parallel config + functions (`.agent-tools/parallel/`)

**Path migrate (mandatory when present):**

1. If `.agent-tools/swarm/` exists and `.agent-tools/parallel/` does not → rename
   `swarm` → `parallel` (`git mv` when tracked; plain `mv` otherwise).
2. If `.agent-tools/parallel/roles/` exists and `functions/` does not → rename
   `roles` → `functions`. **Do not** keep dual trees or alias maps; rewrite `config.yml`
   keys to `function_chain` / verb function ids (plan, implement, review, …) when present
   as old planner/implementer keys — prefer full rewrite from template if ambiguous.
3. If both old and new names exist at either step → stop and ask.

- Write `config.yml` from `parallel/templates/config.yml.md`; set `backlog.default_source`
  from detected PM (else `file`). On re-setup: add missing keys only; never overwrite values
  once the new schema is in place.
- Copy function packets into `.agent-tools/parallel/functions/` from skill
  `parallel/functions/` (`worker-contract`, `plan`, `implement`, `review`,
  `resolve-conflict`, `fix-integration`). On re-setup: for locally edited files offer
  keep-local / replace-with-canonical / merge / show-diff.
- Do **not** create `sessions/` or `active-run` (runtime, gitignored).

#### Umbrella gitignore

Create/update `.agent-tools/.gitignore` with **add-don't-remove** from
`parallel/templates/umbrella-gitignore.md`. Does not modify repo-root `.gitignore`.

#### AGENTS.md charter-link block

Markers (HTML comments): `agent-tools:charter-link begin` / `agent-tools:charter-link end`.
Insert or refresh (never duplicate). Canonical body:

```markdown
## Project Charter

This project uses a structured charter at `.agent-tools/charter/`.

The charter captures durable project identity, engineering standards, and workflow conventions.
Shared ground truth when parallel mode or any session loads project conventions.

Files (load in order when needed; earlier take precedence on conflict):

1. [`.agent-tools/charter/charter.md`](.agent-tools/charter/charter.md) — entry + precedence + index
2. [`.agent-tools/charter/project.md`](.agent-tools/charter/project.md) — identity, stack, surfaces
3. [`.agent-tools/charter/engineering.md`](.agent-tools/charter/engineering.md) — standards, DoD
4. [`.agent-tools/charter/workflow.md`](.agent-tools/charter/workflow.md) — PM, branch, merge, review

**Loading policy:** Parallel mode and function dispatches **explicitly read** needed charter
files during orientation. Pure unit-mode `/work:*` sessions (including continue in unit mode)
do **not** auto-load the full charter set. Use textual references only — no `@` auto-import
of charter.
```

#### Conditional agent-memory symlinks

| Condition | Action |
|-----------|--------|
| `.claude/` present | `CLAUDE.md → AGENTS.md` automatically |
| `.gemini/` present | **Ask** before `GEMINI.md → AGENTS.md` |
| other agent dirs | No symlink unless user opts in |

Relative symlink from repo root. Never clobber a regular file — ask.

**Optional deferral:** if the user wants planning/memory only and declines charter for now,
record that parallel mode is **not ready** and continue; re-run setup later for §5.3.

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

Also evaluate shared memory + runs + charter + parallel readiness:
- `.agent-tools/memory/` tree + AGENTS memory-link
- `.agent-tools/runs/` README + events + ledger
- Charter re-setup drift (§5.3) when charter exists
- `parallel/config.yml` + `functions/` integrity
- Legacy `docs/solutions/` migrate note as before

## What `/work:setup` does not do

- Does **not** plan, refine, or execute work — it sets up the scaffolding those phases use.
- Does **not** invent conventions the project doesn't have (except when user chooses personal factory pack).
- Does **not** create empty top-level `session-state.md` scaffolding.
- Does **not** start a parallel run or create `active-run` / sessions.
- Does **not** migrate `docs/solutions/` or promote harness-local memories — `/work:maintain`.
- Does **not** edit the skill corpus — process gaps → process memory + skill-source
  `/skills:evolve` when available (else upstream; never invent a workflow-local improve command).
- Does **not** force planning migration without explicit yes — but **does** always run the
  migration **check** (§1.5) and must not create a dual-root trap.
