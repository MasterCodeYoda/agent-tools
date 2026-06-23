---
name: swarm:init
description: Initialize (or re-initialize) a project for swarm + workflow — author the project charter from detected evidence, link it from AGENTS.md (with conditional CLAUDE.md/GEMINI.md symlinks), and write the .agent-tools/ umbrella with swarm config. Idempotent and never destructive.
user-invocable: true
argument-hint: "[no args — interactive; runs re-init mode automatically if a charter already exists]"
---

# Initialize Swarm (`/swarm:init`)

`/swarm:init` is the single entry point for **charter authoring** and project
bootstrapping. It is interactive, **evidence-grounded** (it infers from the project before
asking), and **idempotent** (re-running detects existing state and reconciles section by
section). It is the only owner of charter authoring — there is no `/workflow:init`.

What it produces:

```
<target-project>/
  .agent-tools/
    charter/
      charter.md         ← entry point, precedence rules, file index
      project.md         ← what the project IS
      engineering.md     ← how we BUILD
      workflow.md        ← how we MOVE
    swarm/
      config.yml         ← orchestrator preferences (committed); schema_version: 1
      roles/             ← role templates copied from the canonical set (committed, editable)
        worker-contract.md
        planner.md
        implementer.md
        reviewer.md
        conflict-resolver.md
        integration-fixer.md
    .gitignore           ← umbrella gitignore (add-don't-remove policy)
  AGENTS.md              ← marker-bounded charter-link block (created or refreshed)
  CLAUDE.md → AGENTS.md  ← symlink if .claude/ present
  GEMINI.md → AGENTS.md  ← symlink if .gemini/ present AND user confirmed
```

> **Note.** `/swarm:init` does **not** create `sessions/` or `active-run` — those are
> per-run transient state created by the orchestrator (`/swarm <goal>`) at runtime and are
> gitignored.

## Critical Rules

- **NEVER use `git -C <path>`.** The session is already in the correct working directory;
  use plain `git`.
- **Never destructive.** Never overwrite a user's charter content, role file, or
  agent-memory file without explicit consent. When in doubt, stop and ask.
- **`./planning/` and QA artifacts are carve-outs.** Do not move `./planning/` or any QA
  test artifacts (`sentinel.config.yaml`, NL specs, Playwright config) under `.agent-tools/`.
  They stay in their natural locations (design §9.2, §9.3).

## User Input

```text
$ARGUMENTS
```

`/swarm:init` is interactive and ignores positional arguments; any input is treated as
informal context for the dialogue.

## Phase 0 — Mode Detection (fresh vs. re-init)

Check whether `.agent-tools/charter/` already exists:

- **Absent** → **fresh init**. Proceed through Phases 1–4.
- **Present** → **re-init mode**. Jump to [Re-Init Flow](#re-init-flow) after running the
  detection phase (you still re-detect to compute drift).

Before any writes in either mode, check `git status`. If there are uncommitted changes in
files this skill may touch (`AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `.agent-tools/`), warn the
user and ask whether to proceed. Never silently overwrite working-tree state.

## Phase 1 — Detection (evidence gathering)

Scan the project to build a grounded picture **before** asking anything. Gather from:

| Source | What it reveals |
|--------|-----------------|
| Package manifests (`package.json`, `Cargo.toml`, `pyproject.toml`, `go.mod`, …) | Stack, language, framework, top-level deps |
| Lock files (`package-lock.json`, `pnpm-lock.yaml`, `uv.lock`, …) | Confirmed package manager |
| Test config (`jest.config.*`, `pytest.ini`, `vitest.config.*`, `playwright.config.*`) | Test framework, coverage gates |
| Linter config (`.eslintrc.*`, `ruff.toml`, `.golangci.yml`, `biome.json`) | Engineering standards in play |
| Formatter config (`.prettierrc`, `pyproject.toml [tool.black]`) | Style enforcement |
| CI config (`.github/workflows/*`, `.gitlab-ci.yml`, `circle.yml`) | Release process, required gates |
| Existing `AGENTS.md` / `CLAUDE.md` / `GEMINI.md` | Conventions already documented |
| Existing `.agent-tools/charter/` | Triggers re-init mode (Phase 0) |
| Git remote (`git remote -v`) + recent commits (`git log --oneline -20`) | Deploy hints, commit-message style |
| `README.md` (top of file) | Product context, audience |
| `./planning/` directory | Active or past `/workflow` usage |
| **ADRs** (`docs/adr/`, `docs/decisions/`, `docs/architecture/decisions/`, `.adr/`, root `ADR-*.md`) | **First-class evidence** for project + engineering charter sections; often the only durable record on greenfield projects |
| **PM tool** (project-memory mentions, available MCP tools, git remote, `.github/ISSUE_TEMPLATE/`, recent-commit issue-key patterns) | PM identity (Linear / Jira / GitHub Issues / none); confirm if ambiguous |

Read ADR **titles + statuses** (don't slurp whole files). Identify the PM tool. Note which
agent directories exist (`.claude/`, `.gemini/`, `.factory/`, `.grok/`, …) for the symlink
decision.

## Phase 2 — Summarize Findings

Present a concise summary of what was detected (stack, package manager, test/lint/format
tooling, CI gates, ADR titles + statuses, detected PM tool, existing agent-memory files,
which agent dirs are present). This grounds the dialogue and lets the user correct
misdetections before any questions.

## Phase 3 — Dialogue

Principles (design §4.2):

- **Infer from evidence wherever possible**; ask only when ambiguity is real.
- **Pre-fill smart defaults**; the user confirms with Enter or edits.
- **Target < 8 questions** for a typical fresh init.

Use `AskUserQuestion` when available; otherwise ask in small, related groups.

Good (ask): "I see strict TypeScript. Is `any` acceptable in fast cases, or never?" ·
"No coverage floor in CI — set one in the charter? (suggest 80% new code, no floor on
legacy)."

Bad (detected — don't ask): "What test framework do you use?" · "Do you want strict typing?"

## Phase 4 — Write Outputs

Write everything under the `.agent-tools/` umbrella plus the agent-memory link. Create
`.agent-tools/` and `.agent-tools/charter/` and `.agent-tools/swarm/` as needed.

### 4.1 Charter files

Each file has stable headers (so re-init can diff section by section) and an
evidence-grounded body filled from detection + dialogue. Keep them **sparse** — the charter
loads into every agent's context. Empty sections are explicit:
`_No project-specific rules; standard practices apply._`

Each file carries frontmatter:

```yaml
---
last_updated: <YYYY-MM-DD>
---
```

**`charter/charter.md`** (~30 lines)

```markdown
---
last_updated: <YYYY-MM-DD>
---
# Project Charter

## Precedence
Earlier files win on conflict: project > engineering > workflow. Precedence is
conflict-resolution only; most content is additive.

## File Index
- `project.md` — what this project is (identity, stack, surfaces, vocab, stakeholders).
- `engineering.md` — how we build (tests, types, lint, architecture, quality gates, DoD).
- `workflow.md` — how we move (PM, branching, commits, merge, review, release, docs).

## Maintenance
Authored by `/swarm:init`. Re-run `/swarm:init` to update; it reconciles section by section.
```

**`charter/project.md`** (~120 lines) — headers: `# Project: <name>`, `## Identity`,
`## Stack`, `## Surfaces`, `## Domain Vocabulary`, `## Stakeholders`, `## Out of Scope`.

**`charter/engineering.md`** (~150 lines) — headers: `# Engineering Standards`,
`## Testing`, `## Types`, `## Linting & Formatting`, `## Architecture`,
`## Code Quality Gates`, `## Security`, `## Definition of Done`.

**`charter/workflow.md`** (~120 lines) — headers: `# Workflow Conventions`,
`## PM Integration`, `## Branching`, `## Commits`, `## Merge Policy`, `## Review`,
`## Release`, `## Documentation`.

Authoring philosophy: evidence-grounded (not fill-in-the-blanks), sparse over verbose,
headers stable / body specific, reference don't restate (e.g. "TDD-strict per
@test-strategy" is enough).

### 4.2 Swarm config

Write `.agent-tools/swarm/config.yml`:

```yaml
schema_version: 1

# Project-stable orchestrator preferences. Safe to edit by hand.

# Concurrency cap for parallel dispatch waves
concurrency_cap: 5

# Role chain (which roles execute, in what dispatch order)
role_chain:
  - planner
  - implementer
  - reviewer

# Model selection per role. Tier labels (most_capable | mid_tier | fast) map to actual
# model IDs per host CLI; or pin an exact model ID.
models:
  planner: most_capable
  implementer: mid_tier
  reviewer: most_capable
  conflict_resolver: most_capable
  integration_fixer: most_capable

# CLI per role (Phase 3; defaults to host CLI for all in Phase 2).
# The orchestrator role is always the host and cannot be overridden here.
clis:
  planner: claude
  implementer: claude
  reviewer: claude
  conflict_resolver: claude
  integration_fixer: claude

# Test command run by the merge sweep after each merge into main.
# null = orchestrator auto-detects from manifests + charter engineering.md.
test_command: null

# Backlog source defaults (if /swarm <goal> doesn't specify a source explicitly)
backlog:
  default_source: <linear|jira|github-issues|file>   # set from detected PM tool
  default_filter: null

# Session log retention
sessions:
  retention_days: null   # null = keep indefinitely

# Pre-launch confirmation
pre_launch:
  always_confirm: true

# Output verbosity
output:
  per_wave_summary: brief   # brief | verbose | quiet
```

Set `backlog.default_source` from the detected PM tool (fall back to `file` if none).

### 4.2b Role templates

Copy the six canonical role templates into `.agent-tools/swarm/roles/` so the orchestrator
(`/swarm <goal>`) and the project can use and customize them:

```
worker-contract.md   planner.md   implementer.md
reviewer.md          conflict-resolver.md   integration-fixer.md
```

Source them from the installed `swarm` skill's `roles/` directory (the canonical set shipped
with agent-tools). These files are **committed** and **editable per project**.

**On re-init**, never silently overwrite a locally-edited role file. For each role file that
differs from the canonical version, present the diff and offer:
`keep-local` / `replace-with-canonical` / `merge` / `show-diff` (§7.9). Only copy files that
are missing or that the user chooses to replace.

### 4.3 Umbrella gitignore

Create or update `.agent-tools/.gitignore` with the **add-don't-remove** policy (add missing
entries; never delete user-added ones):

```
# Managed by Agent Tools. User edits respected on re-run.

# Swarm transient state, managed by /swarm:init (per-run; not project source)
swarm/active-run
swarm/sessions/
```

This is the single canonical umbrella-gitignore implementation. It does **not** modify the
repo-root `.gitignore`.

### 4.4 AGENTS.md charter-link block

`AGENTS.md` is the **single canonical** agent-memory file. Insert (or refresh) a
marker-bounded block. If `AGENTS.md` doesn't exist, create it with this block. If it exists,
insert the block (typically near the top) or refresh the existing one in place — never
duplicate it.

The block is wrapped in two **HTML-comment markers** so re-init can find and refresh it
later. Emit each marker as a standard HTML comment (open with `<!` `--`, close with `--` `>`)
whose inner content is exactly:

- **opening marker** — content: `agent-tools:charter-link begin`
- **closing marker** — content: `agent-tools:charter-link end`

Write the block below into `AGENTS.md`, replacing `[[BEGIN-MARKER]]` / `[[END-MARKER]]` with
those two HTML comments:

```markdown
[[BEGIN-MARKER]]
## Project Charter

This project uses a structured charter at `.agent-tools/charter/`.
Load these files in order before acting; earlier files take precedence on conflict:

1. [`.agent-tools/charter/charter.md`](.agent-tools/charter/charter.md) — entry + precedence rules
   `@.agent-tools/charter/charter.md`
2. [`.agent-tools/charter/project.md`](.agent-tools/charter/project.md) — project identity
   `@.agent-tools/charter/project.md`
3. [`.agent-tools/charter/engineering.md`](.agent-tools/charter/engineering.md) — engineering non-negotiables
   `@.agent-tools/charter/engineering.md`
4. [`.agent-tools/charter/workflow.md`](.agent-tools/charter/workflow.md) — workflow conventions
   `@.agent-tools/charter/workflow.md`
[[END-MARKER]]
```

So the first line written to `AGENTS.md` is the opening HTML comment, and the last is the
closing HTML comment. The block uses both plain markdown links (universally readable) and
`@`-paths (Claude auto-imports; other agents read them as informational text).

### 4.5 Conditional agent-memory symlinks

Picky-named files are **symlinks to `AGENTS.md`**, never separate content:

| Condition | Action |
|-----------|--------|
| `.claude/` present | Create `CLAUDE.md → AGENTS.md` symlink automatically (Claude is known-picky) |
| `.gemini/` present | **Ask** before creating `GEMINI.md → AGENTS.md` symlink |
| `.factory/`, `.grok/`, `.codex/`, `.agents/`, … | No symlink by default; create only if the user explicitly opts in. (Codex loads AGENTS.md natively from `~/.codex/` global + project root; CODEX.md symlink is rarely needed.) |

Create symlinks with a relative target from the repo root, e.g. `ln -s AGENTS.md CLAUDE.md`.
If a picky-named file already exists as a **regular file** (not a symlink), do not clobber
it — surface it and ask how to proceed (it may contain real content to fold into
`AGENTS.md`).

## Re-Init Flow

Triggered when `.agent-tools/charter/` already exists (Phase 0). Idempotent and
non-destructive:

1. **Summarize current state** — charter file `last_updated` dates, which agent-memory files
   are linked, whether `swarm/config.yml` exists, and any locally-edited files.
2. **Re-run detection** (Phase 1) and **compute drift** — new dependencies, framework
   changes, new ADRs since the charter's `last_updated`, changed CI gates.
3. **Per charter section**, present *current* vs. *proposed* and ask `keep / replace / edit`.
   Default to **keep** on no response.
4. **Refresh the AGENTS.md marker block** only if the charter file set or paths changed;
   otherwise leave it untouched.
5. **Symlink integrity check** — verify each picky-named symlink still points at the real
   `AGENTS.md`; if broken or replaced by a regular file, surface and ask.
6. **`config.yml`** — if present, leave user edits intact; only add newly-introduced keys
   with documented defaults (never overwrite existing values).
7. **Role templates** — for each role file, diff the project copy against the canonical
   version; for any that differ, offer `keep-local / replace-with-canonical / merge /
   show-diff` (§7.9). Copy only missing files or those the user chooses to replace; never
   silently overwrite a customized role file.

## Safety / Failure Modes

- **Uncommitted changes before write** → warn + ask; never silently overwrite working tree.
- **Markers missing or malformed** in `AGENTS.md` on re-init → stop and ask; never
  speculatively rewrite an agent-memory file.
- **Broken symlink** (doesn't resolve to `AGENTS.md`) → surface and ask.
- **Locally-edited charter content** with unfamiliar structure → preserve; offer to refactor
  only if the user opts in.
- **Picky-named regular file** where a symlink was expected → never clobber; ask.

## Completion

Report what was written/changed:

- charter files created or updated (with which sections changed in re-init);
- `.agent-tools/swarm/config.yml` written;
- `.agent-tools/swarm/roles/` copied (and any locally-edited files preserved on re-init);
- `.agent-tools/.gitignore` created/updated;
- `AGENTS.md` charter-link block inserted/refreshed;
- which symlinks were created (and any skipped pending confirmation);
- a reminder to **commit** the new/changed files (no push — that's always user-initiated).

Then note: the charter now loads automatically for any agent that reads `AGENTS.md`,
including single-agent `/workflow` runs. With the charter and role templates in place, the
project is ready for `/swarm <goal>`.
