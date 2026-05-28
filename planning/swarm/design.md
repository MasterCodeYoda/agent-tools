# Swarm Orchestration — Design

**Status**: Design approved; ready for implementation planning.
**Date**: 2026-05-28
**Authors**: Matt Overlund + Claude (collaborative brainstorming)
**Scope**: Introduce a `/swarm` skill family in agent-tools that delivers multi-role, multi-item orchestration of backlog-scale work on top of `/workflow`.

---

## 1. Executive Summary

`/swarm` is a new top-level skill family that lifts the coordination burden off the user when executing large-scale backlog work. The user invokes `/swarm <goal>` (e.g., `/swarm "Linear v0.3.0 milestone"`); a host-session **orchestrator** drives backlog items through the `/workflow` lifecycle (refine → plan → execute → review → merge) by dispatching **role-specialized sub-agents** in parallel waves, with each item isolated in its own git worktree.

The design intentionally **does not** introduce process orchestration (no tmux, no Terminal management); parallelism comes from (a) git worktrees per item and (b) the host agent's native sub-agent dispatch capabilities. The orchestrator runs in the user's active session, stays responsive, never pushes to remote, and merges to `main` locally with full test gates between merges.

A new **charter** primitive (a project-local, structured charter authored by `/swarm:init`) provides shared project ground truth across multi-role runs. The charter is linked from `AGENTS.md` (and conditional `CLAUDE.md`/`GEMINI.md` symlinks) so it loads naturally for any agent reading project memory, including single-agent `/workflow` runs that never invoke `/swarm`.

---

## 2. Goals & Non-Goals

### Goals

1. **Lift coordination burden** from the user when running backlog-scale work — orchestrator handles classification, dispatch, merge sequencing, and exit-state management.
2. **Build on `/workflow`**, not around it — workers run `/workflow` commands inside per-item worktrees; `/workflow` is unchanged in behavior, only modestly enhanced to capture dependency metadata.
3. **Project-injectable** — `/swarm:init` bootstraps the required artifacts (charter, swarm config, role templates) into any target project under a single `.agent-tools/` umbrella.
4. **Cross-agent** — published agent-agnostic via the existing agent-tools `src/` → `dist/<agent>/` model. Any agent that can launch agent-tools skills can act as orchestrator; workers may shell out to other CLIs (Phase 3).
5. **Stateful and recoverable** — work survives session boundaries, machine reboots, network loss; resume always reconciles against ground truth (disk + PM), never trusts cached state.
6. **Safety preserved** — no agent pushes to remote, ever; user owns merge-to-remote action.

### Non-Goals

- Multi-terminal control (tmux, Terminal management) — rejected explicitly.
- Auto-push to `origin/main` — never automated; permanent constraint.
- Long-running daemon orchestrator — orchestrator is an in-session stateful command.
- Cross-CLI orchestrator delegation (orchestrator IS the host agent; cannot be shell-out).
- Migration of `./planning/` to a hidden directory — intentional carve-out for daily-use friction reasons.
- Migration of QA artifacts (`sentinel.config.yaml`, NL specs, Playwright config) into the umbrella — intentional carve-out; they stay in the project's natural test location (§9.3).
- A separate "integrator" role for merge orchestration — orchestrator owns merging directly.
- Refiner as a sub-agent role — refinement is host-side (interactive, conversational).
- File-collision pre-detection in scheduler — handled at merge time via fix-it dispatch.
- Multiple concurrent swarm runs per project (single `active-run` pointer; v2 may relax).

---

## 3. Architecture Overview

### 3.1 Primitives

| Primitive | Type | Location | Owned by |
|---|---|---|---|
| **Charter** | Static, durable | `<target-project>/.agent-tools/charter/` | Authored by `/swarm:init`; consumed at runtime by both swarm sub-agents and any `/workflow` agent that loads `AGENTS.md` |
| **Orchestrator** | Dynamic, in-session | The host agent in the user's active session | The `swarm` skill's `<goal>` execution path |
| **Worker** | Dynamic, dispatched | Per-invocation sub-agent (native dispatch for Phase 2; shell-out for Phase 3) | Per-role; isolated worktree; fresh context per dispatch |

### 3.2 Command Surface

| Invocation | Behavior | Precondition |
|---|---|---|
| `/swarm` (no args) | Summarize repo state (initialized? active execution? backlog detected?). If not initialized, after summary ask to delegate to `/swarm:init`. If initialized + idle, suggest `/swarm <goal>` or `/swarm:continue`. | None |
| `/swarm <goal>` | Start orchestrator on `<goal>` | Charter exists. If not → error: "Run `/swarm:init` first." |
| `/swarm:init` | Initialize or re-initialize: detect state, dialogue, write charter, link agent-memory files, write swarm config + roles. Idempotent. | None |
| `/swarm:continue` | Resume the most recent TERMINAL_PAUSE'd execution; always reconciles state against ground truth. | `active-run` pointer exists. If not → informs user. |

### 3.3 Runtime Picture

```
┌─────────────────────────────────────────────────────────────────────┐
│ User's host-agent session                                           │
│                                                                     │
│   You ◄────► Orchestrator (host agent — bare /swarm <goal>)         │
│              │                                                      │
│              │  reads/writes                                        │
│              ▼                                                      │
│         .agent-tools/swarm/sessions/<run-id>/state.yml              │
│         .agent-tools/swarm/config.yml                               │
│         .agent-tools/swarm/roles/*.md                               │
│         .agent-tools/swarm/active-run                               │
│         .agent-tools/charter/*                                      │
│         AGENTS.md (charter-link block; auto-loaded by host)         │
│                                                                     │
│              │  dispatches in parallel (up to concurrency cap)      │
│              ▼                                                      │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │  Item AER-101 (worktree A, branch feat/AER-101)                │ │
│  │    one role active at a time:                                  │ │
│  │    Refiner (host-side) → Planner → Implementer → Reviewer      │ │
│  └────────────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │  Item AER-115 (worktree B, branch feat/AER-115)                │ │
│  │    Implementer active                                          │ │
│  └────────────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │  Item AER-120 (worktree C, branch feat/AER-120)                │ │
│  │    Reviewer active                                             │ │
│  └────────────────────────────────────────────────────────────────┘ │
│      ...up to concurrency_cap (default 5) active items              │
│                                                                     │
│  Each sub-agent returns structured YAML → orchestrator updates      │
│  state.yml. Approved items merged locally to main with full test    │
│  gates between merges. User owns push to origin.                    │
└─────────────────────────────────────────────────────────────────────┘
```

### 3.4 Lifecycle of One Backlog Item

```
unrefined         → Refiner (host-side: orchestrator runs /workflow:refine with user) → refined
refined           → Planner runs /workflow:plan --worktree                              → planned
planned           → Implementer runs /workflow:execute (in worktree)                    → implemented
implemented       → Reviewer runs /workflow:review (in worktree)                        → approved | fix-requested
fix-requested     → re-dispatch Implementer with fix_list                               → implemented (loop)
approved          → Orchestrator merges branch into main (local), tests, cleans up      → merged
                    (on conflict OR test-red: one-shot fix-it dispatch; failure → TERMINAL_PAUSE)
all items merged  → GOAL_COMPLETE; user reviews `git log main`, pushes when ready

(Note: stage names are lowercase; reviewer's status return `APPROVED` advances the item's
stage to `approved`. Status codes and stage names are distinct namespaces.)
```

**Worktree-per-item** (not per-role): each item has one worktree on one branch; roles dispatch into it sequentially as the item progresses through stages. Cross-item parallelism (N items × N worktrees concurrently) is where scale-out lives.

### 3.5 State Doctrine

Two layers of state, with strict separation:

| State | Owned by | Format | Purpose |
|---|---|---|---|
| **Orchestrator state** | `/swarm` | `.agent-tools/swarm/sessions/<run-id>/state.yml` | Backlog snapshot, per-item stage, in-flight dispatches, merge queue, last handoff |
| **Per-item workflow state** | Workers (via `/workflow`) | `<worktree>/planning/<item>/session-state.md` | Standard workflow session state — unchanged |

Orchestrator's working memory is `state.yml`. It reads per-item `session-state.md` only when classifying items at the start of each wave, and only the YAML frontmatter — keeping its context bounded as concurrency scales.

`state.yml` is treated as a **hint, not gospel**. Disk truth (worktrees, branches, commits, session-state files) and PM truth take precedence; on `/swarm:continue`, the orchestrator always reconciles classification against ground truth before resuming.

### 3.6 Exit-State Model

```
GOAL_COMPLETE      → final report, session ends, active-run pointer cleared
IN_FLIGHT_DECISION → AskUserQuestion-style prompt; orchestrator stays loaded; resumes loop with answer
TERMINAL_PAUSE     → writes state.yml + handoff summary; session ends; active-run preserved
                     /swarm:continue resumes later (with reconciliation)
```

**Decision rule for IN_FLIGHT vs TERMINAL**: *"Can I act on the user's answer within this loaded session, without requiring them to do off-band work?"* — yes → IN_FLIGHT; no → TERMINAL.

---

## 4. `/swarm:init` Flow

`/swarm:init` is interactive, evidence-grounded, and idempotent. Single entry point for charter authoring and project bootstrapping. Re-init mode walks the user through diffs section-by-section.

### 4.1 Detection Phase

Before any questions, the skill scans the project to build a grounded picture.

| Source | What it reveals |
|---|---|
| Package manifests (`package.json`, `Cargo.toml`, `pyproject.toml`, `go.mod`, etc.) | Stack, language, framework, top-level deps |
| Lock files (`package-lock.json`, `uv.lock`, etc.) | Confirmed package manager |
| Test config (`jest.config.*`, `pytest.ini`, `vitest.config.*`) | Test framework, coverage gates |
| Linter config (`.eslintrc.*`, `ruff.toml`, `.golangci.yml`, `biome.json`) | Engineering standards in play |
| Formatter config (`.prettierrc`, `pyproject.toml [tool.black]`) | Style enforcement |
| CI config (`.github/workflows/*`, `.gitlab-ci.yml`, `circle.yml`) | Release process, required gates |
| Existing `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` | Extract project conventions already documented |
| Existing `.agent-tools/charter/` | Triggers re-init mode |
| Git remote (`git remote -v`) + recent commits | Deploy target hints, commit-message style |
| README.md (if present, top-of-file) | Product context, audience |
| Existing `./planning/` directory | Active or past `/workflow` usage |
| **ADRs** (`docs/adr/`, `docs/decisions/`, `docs/architecture/decisions/`, `.adr/`, root `ADR-*.md`) | **First-class evidence** for project + engineering charter sections; essential for greenfield projects where ADRs may be the only durable record |
| **PM tool detection** (project memory mentions, MCP availability, git remote, `.github/ISSUE_TEMPLATE/`, recent-commit issue-key patterns) | PM tool identity (Linear/Jira/GitHub Issues/none); confirm with user if ambiguous |

The skill summarizes findings (including ADR titles + statuses, detected PM tool) before asking any questions.

### 4.2 Dialogue Principles

- **Infer from evidence wherever possible**; ask only when ambiguity is real.
- **Smart defaults pre-filled**; user confirms with Enter or edits.
- **Target: < 8 questions** for a typical fresh init.

Examples (good):
- "I see strict TypeScript. Is `any` acceptable in fast cases or never?"
- "Coverage gate — no current floor in CI. Set one in the charter? (suggest 80% for new code; no floor on legacy)"

Examples (bad — detected, don't ask):
- "What testing framework do you use?" (already in config)
- "Do you want strict typing?" (already in tsconfig)

### 4.3 Output Set

```
<target-project>/
  .agent-tools/
    charter/
      charter.md         ← entry, precedence rules
      project.md         ← project identity
      engineering.md     ← engineering non-negotiables
      workflow.md        ← workflow conventions
    swarm/
      config.yml         ← orchestrator preferences (committed)
      roles/             ← role templates (copied from src/swarm/roles/, editable)
        worker-contract.md
        planner.md
        implementer.md
        reviewer.md
        conflict-resolver.md
        integration-fixer.md
    .gitignore           ← umbrella gitignore for transient files
  AGENTS.md              ← marker-bounded charter-link block inserted/refreshed
  CLAUDE.md → AGENTS.md  ← symlink if .claude/ present
  GEMINI.md → AGENTS.md  ← symlink if .gemini/ present AND user confirmed
```

### 4.4 Agent-Memory File Policy

**`AGENTS.md` is the single canonical source.** Picky-named files are **symlinks**, not separate files.

| Condition | Action |
|---|---|
| `.claude/` directory present | Create `CLAUDE.md → AGENTS.md` symlink automatically (Claude is known-picky) |
| `.gemini/` directory present | Ask user before creating `GEMINI.md → AGENTS.md` symlink |
| `.factory/`, `.grok/`, `.codex/`, etc. | Default no symlink; ask only if user has explicitly opted in |

**Linking syntax inside `AGENTS.md`** — uses both plain markdown links (universally readable) and `@`-style paths (Claude auto-imports, other agents see as informational text):

```markdown
<!-- agent-tools:charter-link begin -->
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
<!-- agent-tools:charter-link end -->
```

### 4.5 Re-Init Flow (Idempotent)

Triggered when `.agent-tools/charter/` already exists.

1. **Summarize current state**: charter file mtimes, linked agent-memory files, swarm config presence, local role-template edits.
2. **Re-run detection** on current project state; compute **drift** (new dependencies, framework changes, new ADRs since last charter update).
3. **For each charter section**, present current vs. proposed and ask `keep/replace/edit`.
4. **For locally-edited role files**, never overwrite without confirmation; offer `keep-local/replace-with-canonical/merge/show-diff`.
5. **Refresh marker-bounded blocks** in `AGENTS.md` / symlinked files (content unchanged unless charter path moved).
6. **Git status reminder** if uncommitted changes detected before any write.

### 4.6 Failure Modes / Safety

- **Uncommitted changes before write**: warn, ask to proceed; never silently overwrite working tree state.
- **Markers missing/malformed on re-init**: stop and ask; never speculatively rewrite agent-memory files.
- **Symlink integrity check**: verify each symlink still points at the real `AGENTS.md`; surface and ask if broken.
- **Locally-edited charter content** with unfamiliar structure: preserve in re-init; offer to refactor only if user opts in.
- **Locally-edited role files**: never replaced without explicit consent.

---

## 5. Charter Shape

The charter is *for the agents*, not for humans to admire. Each file has a single audience (orchestrator + workers), a single owner concept, and a soft length cap. Empty sections are explicitly allowed.

### 5.1 File Set & Responsibilities

| File | Owner concept | Soft cap |
|---|---|---|
| `charter.md` | Entry point + precedence rules + file index | ~30 lines |
| `project.md` | WHAT this project IS (identity, stack, surfaces, vocab, stakeholders, out-of-scope) | ~120 lines |
| `engineering.md` | HOW we BUILD (tests, types, lint, architecture, quality gates, DoD) | ~150 lines |
| `workflow.md` | HOW we MOVE (PM, branching, commits, merge, review, release, docs) | ~120 lines |

**No fifth file.** Swarm-runtime parameters (concurrency, role chain, model selection) live in `.agent-tools/swarm/config.yml` — not the charter — because the charter is project-level conventions that apply whether or not swarm is running.

### 5.2 Section Structure Per File

Stable headers; body filled by `/swarm:init` from detection + dialogue.

**`charter.md`**
```
# Project Charter
## Precedence       — one paragraph; "earlier files win"
## File Index       — links + one-line description of each
## Maintenance      — "authored by /swarm:init; re-run to update"; last-updated date
```

**`project.md`**
```
# Project: <name>
## Identity
## Stack
## Surfaces
## Domain Vocabulary
## Stakeholders
## Out of Scope
```

**`engineering.md`**
```
# Engineering Standards
## Testing
## Types
## Linting & Formatting
## Architecture
## Code Quality Gates
## Security
## Definition of Done
```

**`workflow.md`**
```
# Workflow Conventions
## PM Integration
## Branching
## Commits
## Merge Policy
## Review
## Release
## Documentation
```

### 5.3 Precedence Mechanics

Precedence (`project > engineering > workflow`) is **conflict-resolution only**. Most charter content is additive across files and never triggers precedence.

Realistic example:

- `project.md`: "we ship same-day for user-facing bugs"
- `engineering.md`: "TDD-strict; no production code without failing test first"
- → Conflict. Project wins for a hotfix scenario: ship the fix, add the test immediately after.

### 5.4 Authoring Philosophy

| Principle | Why |
|---|---|
| **Evidence-grounded** | `/swarm:init` fills defaults from detection (manifests, configs, ADRs, AGENTS.md). User confirms or edits. Templates are not "fill in the blanks." |
| **Sparse over verbose** | Charter is loaded into every agent's context. Bloat = lost effective context. |
| **Headers stable, body specific** | Re-init can diff section-by-section reliably. |
| **Empty sections explicit** | An empty section reads `_No project-specific rules; standard practices from @code-patterns apply._` |
| **Reference, don't restate** | If engineering.md says "TDD-strict per clean-architecture skill," that's enough — don't restate the discipline. |

### 5.5 Runtime Loading

1. Charter files at `.agent-tools/charter/*.md` (committed).
2. `AGENTS.md` has marker-bounded block (Section 4.4) listing all four with markdown links + `@`-paths.
3. **Host agent**: on session start, `AGENTS.md` is in default context. `@`-imports auto-load charter files (Claude).
4. **Worker sub-agent** (native dispatch): same `AGENTS.md`-default-context behavior.
5. **Shell-out worker** (Phase 3, non-host CLI): orchestrator injects charter content directly into the worker's prompt as system context (no `@` resolution available cross-CLI).

### 5.6 Maintenance & Drift

- **Updates**: re-run `/swarm:init`. Drift detection (new ADRs, dep changes, config changes) surfaces during re-init for section-by-section reconciliation.
- **Manual edits**: fully supported; re-init respects them via `keep/replace/edit` flow.
- **Version stamp**: each file has `last_updated: YYYY-MM-DD` in frontmatter.

---

## 6. The `/swarm <goal>` Orchestration Loop

The heart of the system. This section covers the orchestrator's main loop; role-prompt content and structured returns are in Section 7; state schemas are in Section 8.

### 6.1 Phase 1 — Goal Interpretation & Backlog Ingestion

| Goal form | Interpretation |
|---|---|
| `/swarm "Linear v0.3.0 milestone"` | MCP query: all issues in v0.3.0 milestone |
| `/swarm "AER-101, AER-115, AER-120"` | Explicit issue list |
| `/swarm "all open bugs labeled p1"` | PM query |
| `/swarm "./planning/v03-backlog.md"` | Local file: parse markdown |
| `/swarm "implement the auth refactor"` | Ambiguous → IN_FLIGHT_DECISION: ask user for scope |
| `/swarm` (no args) | Show current state.yml summary; offer continue/start/init |

**Pre-launch confirmation** (always shown, no magic threshold):

```
Resolved <goal> to N items. First 5: <list>. Proceed? [y/n]
```

User sees what was resolved every time. No surprise launches.

### 6.2 Phase 2 — Initial Classification

For each item, classify its current stage by reading:

| Source | Reveals |
|---|---|
| PM issue (Linear/Jira via MCP) | refinement state; status |
| `./planning/<item>/requirements.md` (file mode) | refinement state |
| `./planning/<item>/implementation-plan.md` | planned? |
| `git worktree list` | worktree exists for this item? |
| `<worktree>/planning/<item>/session-state.md` (frontmatter only) | execution progress, branch, status |
| `git log main` for branch merge | merged? |

Stages:

```
unrefined | refined | planning | planned | implementing | implemented
          | reviewing | approved | merged | fix-requested
```

Initial `state.yml` is written with full classified backlog. Subsequent classification is **incremental** — only re-classify items that might have changed since the previous wave.

### 6.3 Phase 3 — Main Loop

```
main loop:
  (A) BETWEEN-WAVE MERGE SWEEP
        for each item in stage=approved:
          attempt local merge to main
          on conflict OR test-red:
            dispatch one-shot fix-it sub-agent with full diagnostics
            re-attempt merge + tests
              success → cleanup branch + worktree (via /git:worktree-delete)
              failure → TERMINAL_PAUSE
          on clean: cleanup → mark stage=merged

  (B) RE-CLASSIFY items whose workers returned in last wave (and unrefined items
      that might gate the next wave's dispatch)

  (C) IN-PROCESS REFINEMENT
        unrefined_in_path = items in stage=unrefined whose refinement gates the
                             next wave (would otherwise advance to planner)
        if non-empty:
          for each item: orchestrator runs /workflow:refine in main session,
                          interactively with user (serial; conversational)
          re-classify after each refine

  (D) GOAL CHECK
        all items in stage=merged → GOAL_COMPLETE → exit

  (E) NEXT-WAVE SCHEDULING
        compute next wave (algorithm in 6.4)
        if wave empty AND items remain unmerged →
          investigate (deadlock? missing deps?) → likely TERMINAL_PAUSE

  (F) DISPATCH WAVE
        single message, N parallel sub-agent dispatches (one per item-stage transition)

  (G) AWAIT WAVE RETURNS
        collect structured returns; update state.yml atomically

  (H) EXIT-STATE TRIAGE
        any BLOCKED with off-band requirement     → TERMINAL_PAUSE
        any NEEDS_CONTEXT answerable in chat       → IN_FLIGHT_DECISION → resume
        any DONE_WITH_CONCERNS warranting attention → IN_FLIGHT_DECISION or log + continue
        else                                       → loop back to (A)
```

### 6.4 Phase 4 — Wave Scheduling (MVP)

```
candidates = items NOT in [merged, awaiting-user-input]

filter to items whose next stage has no upstream blocker:
  refined          → planner can dispatch
  planned          → implementer can dispatch
  implemented      → reviewer can dispatch
  fix-requested    → implementer can re-dispatch
  reviewing/implementing/planning → in flight, do not dispatch again

sort by:
  user-declared priority (state.yml)  →  PM priority field  →  FIFO

pick first N (N = config.concurrency_cap, default 5)

return as the wave
```

**File-collision avoidance** (MVP): not pre-checked. Two parallel implementers may touch overlapping files; conflicts surface at merge time and are handled by fix-it dispatch.

**Explicit dependencies**: items declare `blocks` / `blocked_by` in `state.yml` (sourced from refinement metadata). Orchestrator respects them in the candidate filter.

#### 6.4.1 Backlog Quality Preconditions

> Wave scheduling produces good outcomes only when the backlog items have been decomposed and linked during refinement. Items should declare `blocks` / `blocked_by` relationships and (optionally) `parallelizable_with` peers. When this metadata is missing, the orchestrator falls back to treating all items as independent in FIFO order — functional but suboptimal, with elevated merge-conflict risk.

The swarm design requires **workflow-skill enhancements** (Phase 1 deliverable) that update `/workflow:refine` and `/workflow:plan` to capture this metadata as part of refinement and planning outputs.

### 6.5 Phase 5 — Dispatch Mechanics

Each wave is a **single message** containing N parallel sub-agent dispatches (native `Agent` tool for hosts with native dispatch; same-CLI shell-out fallback for hosts without; cross-CLI shell-out for Phase 3 per-role CLI overrides).

Each dispatch call carries (in the prompt — orchestrator-assembled):

```
1. WORKER CONTRACT (prepended automatically; from .agent-tools/swarm/roles/worker-contract.md)
   - Structured return schema
   - Status code semantics
   - Brevity discipline
   - Session log writing requirement + format spec
   - Generic worker boundaries

2. ROLE-SPECIFIC PROMPT (from .agent-tools/swarm/roles/<role>.md)
   - Role identity line
   - Workflow command to run
   - Role-specific scope notes

3. CHARTER REFERENCE
   - For same-CLI workers: pointer only (worker auto-loads via AGENTS.md)
   - For cross-CLI shell-out workers: charter content injected directly

4. ITEM CONTEXT
   - Issue key, title, refined ACs
   - Planning doc path (if past planning)
   - Worktree path (if past planning)
   - Branch name (if past planning)

5. RESUME CONTEXT (if re-dispatch, e.g., fix-requested)
   - Previous role's return; specifically: fix_list

6. CLI ADDENDA (Phase 3, if applicable)
   - Per-CLI prompt adjustments from src/swarm/references/cli-addenda.md
```

**Worktree handling — strict deferral to existing git skills:**

| Operation | Implementation |
|---|---|
| Create per-item worktree | Planner role invokes `/workflow:plan --worktree`, which delegates to `/git:worktree-create`. Orchestrator never calls `git worktree add` directly. |
| Enter existing worktree (worker dispatch) | Prompt instructs `cd <worktree-path>`. |
| Remove worktree post-merge | Orchestrator dispatches via `/git:worktree-delete` (which has merge-safety checks + agent-aware path resolution). |
| Conflict-resolver sub-agent | Operates on main during in-progress merge; does NOT create a worktree. |

The orchestrator **does not** use the host's `isolation: "worktree"` Agent-tool option — that creates a temporary worktree managed by the host tool, which conflicts with our explicit worktree-per-item model.

**Model selection per role** (from `config.yml`): orchestrator passes the model parameter on each dispatch. Defaults: most-capable for refiner/planner/reviewer; mid-tier for implementer (most volume).

### 6.6 Phase 6 — Wave Completion & State Update

1. Collect all N returns from the wave.
2. Parse each — if malformed/unparseable, treat as `BLOCKED` with the error.
3. Update `state.yml` **atomically** (write to temp file, rename).
4. For each item: advance to the next stage based on the return's status field.
5. Run exit-state triage.

**Atomicity**: temp file + rename. After each wave, state is on disk; a crash between waves loses at most that wave's dispatch results, which can be re-derived by re-classifying from worktree state and PM.

### 6.7 Phase 7 — Exit-State Triage

| Trigger | Exit state | Behavior |
|---|---|---|
| All items in stage=merged | `GOAL_COMPLETE` | Final report (merge queue summary, what was done, what's now on main). Session ends. `active-run` cleared. User pushes when ready. |
| Worker returned `BLOCKED` with off-band requirement | `TERMINAL_PAUSE` | Write state.yml + handoff. Session ends. `/swarm:continue` resumes later. |
| Worker returned `NEEDS_CONTEXT` answerable in chat | `IN_FLIGHT_DECISION` | `AskUserQuestion`-style prompt. Stay loaded. Apply answer. Resume loop. |
| Worker returned `DONE_WITH_CONCERNS` warranting attention | `IN_FLIGHT_DECISION` if user input matters; else log + continue | Decision rule: would the user want to weigh in before downstream roles act on this work? |
| Merge sweep produced TERMINAL_PAUSE | `TERMINAL_PAUSE` | Already handled in (A); reflected here. |
| No items advanced, none in flight, candidates empty | `TERMINAL_PAUSE` (defensive) | Indicates deadlock or classification bug; bail with diagnostic. |
| Else | continue loop | Schedule next wave. |

### 6.8 Phase 8 — Merge Orchestration (Detail)

```
for each item in stage=approved:
  branch  = state[item].branch
  wt_path = state[item].worktree

  git checkout main
  git merge --no-ff <branch>

  if merge fails (conflict):
    capture conflict info: git status, file list, conflict markers
    dispatch ONE conflict-resolver sub-agent:
      prompt: full diagnostics + "resolve conflicts, complete merge, do not push"
      workspace: main (the merge is in progress on main)
    on return:
      if DONE → continue to test gate
      if FAILED → git merge --abort → TERMINAL_PAUSE

  run full test suite (project-specific command — see Section 8.6)
  if tests fail:
    capture test diagnostics
    dispatch ONE integration-fixer sub-agent:
      prompt: full diagnostics + "fix integration on main, commit, do not push"
    on return:
      re-run tests
      if pass → continue
      if fail → TERMINAL_PAUSE (main left in current state, diagnostic in handoff)

  on success:
    invoke /git:worktree-delete for <wt_path> (which handles branch cleanup safely)
    mark item stage=merged in state.yml
```

Merge sweep runs **between** dispatch waves, not in parallel — merge work is sequential and affects shared state.

### 6.9 Phase 9 — `/swarm:continue` (with Reconciliation)

`/swarm:continue` is resilient to all exit reasons, not just clean TERMINAL_PAUSE (machine reboot, network loss, terminal crash, power outage all leave state.yml in whatever state it was last atomically written to).

```
1. Read .agent-tools/swarm/active-run
     - if absent: inform user, suggest /swarm <goal>; exit.
     - if present: load .agent-tools/swarm/sessions/<run-id>/state.yml
       - if state.yml missing or unreadable: surface, offer to clear pointer.

2. NEVER trust state.yml as ground truth.
     - state.yml is a hint about intended state at last write.
     - actual ground truth is on disk (worktrees, branches, planning files,
       session-state.md) and in PM.

3. Display "Recovering — last known state from <state.yml.last_updated>.
   Re-classifying from project state..."

4. Re-classify ALL items not in stage=merged from disk + PM (Phase 6.2 logic).

5. Compare classified state vs. state.yml. Surface drifts:
     - "Item AER-101: state.yml had 'implementing'; re-classified as 'implemented'
       (commits past plan present, no review yet)."
     - "Item AER-110: state.yml had 'reviewing'; worktree missing. Re-classified
       as 'planned' (possible manual cleanup)."

6. Display reconciliation summary; ask user to confirm or correct before resuming.

7. Update state.yml with reconciled classification.

8. Enter main loop at Phase 3(A) (between-wave merge sweep first).
```

**Drift handling**: if reconciliation shows the goal is already complete (user manually merged everything), report GOAL_COMPLETE and exit. If the goal is no longer achievable (issues closed externally without merge), surface and ask user how to proceed.

---

## 7. Role Definitions & Structured-Return Contracts

This is the contract section. Workers don't return free-form output; they return a strict schema the orchestrator parses. At concurrency=5, this discipline keeps the orchestrator's context from drowning.

### 7.1 Role Set

**Sub-agent roles** (three): `planner`, `implementer`, `reviewer`.
**Ad-hoc sub-agent roles** (two, one-shot, dispatched only on merge failure): `conflict-resolver`, `integration-fixer`.
**Refiner is NOT a sub-agent role** — refinement is host-side; orchestrator runs `/workflow:refine` in the main session with the user.

### 7.2 Per-Role Specification

| Role | Wraps | Workspace | Outputs | Possible status returns |
|---|---|---|---|---|
| **Planner** | `/workflow:plan --worktree` | Main repo → creates worktree (via `/git:worktree-create`) | `implementation-plan.md` in worktree; worktree + branch created | `DONE`, `NEEDS_CONTEXT`, `BLOCKED` |
| **Implementer** | `/workflow:execute` | Existing per-item worktree | Commits on branch; tests green; `session-state.md` updated | `DONE`, `DONE_WITH_CONCERNS`, `NEEDS_CONTEXT`, `BLOCKED` |
| **Reviewer** | `/workflow:review <branch>` | Existing per-item worktree | Review summary; approval or fix_list | `APPROVED`, `FIX_REQUESTED`, `BLOCKED` |
| **conflict-resolver** | (no `/workflow` wrap) | Main (with in-progress merge) | Resolve conflicts, complete merge with `git add` + `git commit`; or `git merge --abort` | `DONE`, `FAILED` (one-shot) |
| **integration-fixer** | (no `/workflow` wrap) | Main (post-merge) | Diagnose + fix root cause, commit on main | `DONE`, `FAILED` (one-shot) |

Ad-hoc roles have **no `BLOCKED` or `NEEDS_CONTEXT` returns** — they're terminal one-shots. Failure → `TERMINAL_PAUSE`.

### 7.3 Worker Self-Awareness

Workers **know their own role identity** (e.g., "You are the implementer worker") but **do not know other roles exist**.

✅ OK: "You are the implementer worker. Your task is to run /workflow:execute on item AER-101 in worktree /path/to/wt."

❌ Not OK: "You are the implementer worker. Do not perform reviewer's work; that will happen in a later dispatch."

Role names live in orchestrator-side classification (state.yml, logs, role-template filenames). Workers see *boundaries and tasks*, not peer-role labels.

**Standard worker-prompt boundaries language:**

```
You are the [ROLE_NAME] worker. Your task is to run [WORKFLOW_COMMAND] for item
[ITEM_KEY] in worktree [WORKTREE_PATH].

Boundaries:
- Operate only on this item, only in this worktree.
- Do not push, do not merge to main, do not modify other branches or directories.
- Do not expand scope beyond what is specified.
- Complete your task and return the structured status. Do not continue beyond your task
  or speculate about subsequent steps.
```

### 7.4 Structured Return Schema

Every worker return is **YAML in a fenced code block**. Orchestrator parses; malformed returns are treated as `BLOCKED` with parse-error diagnostic.

```yaml
status: DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED | APPROVED | FIX_REQUESTED | FAILED
item: <issue-key>
role: planner | implementer | reviewer | conflict-resolver | integration-fixer
summary: |
  <2-4 sentences. What did you do, what's the headline result. NOT a transcript.>

artifacts:
  branch: <name or null>
  worktree: <path or null>
  commits: [<sha>, ...]                  # commits this role added
  files_changed: [<path>, ...]           # paths only; no diffs
  planning_docs: [<path>, ...]
  test_status: pass | fail | not-run | not-applicable
  test_command: <command run, if applicable>

concerns: []          # if DONE_WITH_CONCERNS: flagged observations + severity [info|warn|important]
needs: []             # if NEEDS_CONTEXT: specific questions for user
blocker:              # if BLOCKED: { what, why_offband_needed, suggested_action }
fix_list: []          # if FIX_REQUESTED: items reviewer wants implementer to address

next_action_recommended: <one phrase>
                      # orchestrator-readable hint: "ready for implementer", "needs reviewer",
                      # "ready for merge", "user input required"
```

**Why YAML in fenced block** (vs. a structured tool-call return): portable across CLIs (Phase 3 cross-CLI shell-out workers can produce the same format). Orchestrator parses with a YAML library — robust against the model's tendency to embellish around tool calls.

### 7.5 Status Code Semantics

| Status | Meaning | Orchestrator action |
|---|---|---|
| `DONE` | Role completed cleanly | Advance item to next stage |
| `DONE_WITH_CONCERNS` | Work complete but worker flagged observations | Read concerns; decide IN_FLIGHT_DECISION vs. log + continue |
| `NEEDS_CONTEXT` | Worker needs user-level information | IN_FLIGHT_DECISION — surface needs, get answers, re-dispatch with resume_context |
| `BLOCKED` | Worker cannot complete; off-band intervention required | TERMINAL_PAUSE with blocker detail in handoff |
| `APPROVED` | (Reviewer only) Implementation ready for merge | Item enters merge queue; merge sweep handles next |
| `FIX_REQUESTED` | (Reviewer only) Implementation needs changes per fix_list | Re-dispatch implementer with fix_list in resume_context |
| `FAILED` | (Ad-hoc roles only) One-shot attempt unsuccessful | TERMINAL_PAUSE with full diagnostic |

### 7.6 Brevity Discipline (Non-Negotiable at Scale)

Every role prompt includes this verbatim (via the prepended `worker-contract.md`):

```
RETURN DISCIPLINE
- Return is bounded by the YAML schema. Do not output anything outside the fenced block.
- summary: 2-4 sentences. Not paragraphs.
- Do NOT include: code excerpts, file diffs, test output transcripts, stream-of-consciousness,
  reasoning logs, exploration narratives.
- Detail belongs in the worktree (commits, planning docs, session-state.md). The orchestrator
  reads what it needs from those files directly.
- If you want to flag something nuanced, use the `concerns` field — short bullets, severity
  tagged ([info|warn|important]).
```

Rationale: at concurrency cap = 5, the orchestrator collects 5 returns per wave. If each is 2000 tokens, that's 10K tokens consumed per wave just on returns — over a multi-wave run, the orchestrator's context collapses.

### 7.7 Model Selection Per Role

Defaults (overridable in `config.yml`):

| Role | Default model tier | Why |
|---|---|---|
| Orchestrator | Host model (whatever user invokes /swarm with) | Coordination + user-facing; runs in main session |
| Planner | Most capable available | Design judgment; mistakes propagate to implementer |
| Implementer | Mid-tier (e.g., sonnet) | High volume; work is bounded by plan + tests |
| Reviewer | Most capable available | Catches what implementer missed; needs strong judgment |
| conflict-resolver | Most capable available | High stakes, one-shot |
| integration-fixer | Most capable available | High stakes, one-shot, debugging-heavy |

### 7.8 Session Logs (Per-Dispatch)

**Storage layout:**

```
.agent-tools/swarm/sessions/
  <run-id>/                              ← per-/swarm-<goal>-invocation
    state.yml                            ← per-run orchestrator state
    orchestrator.md                      ← orchestrator's own log: goal, classification, waves, decisions
    <item-key>/
      planner-1.md                       ← first planner dispatch
      implementer-1.md                   ← first implementer dispatch
      reviewer-1.md                      ← first reviewer dispatch
      implementer-2.md                   ← second implementer dispatch (fix-requested)
      reviewer-2.md                      ← re-review
```

**Per-invocation logs** (not per-issue append): each dispatch is an atomic unit. Cross-invocation comparison (e.g., glob `*/implementer-1.md` for all first-pass implementer dispatches) is the primary analytical use case.

**Run ID format**: `<YYYY-MM-DD>-<NONCE>-<goal-slug>`
- `NONCE`: 5 chars, lowercase alphanumeric only, random (36⁵ ≈ 60M values; collisions vanishingly rare)
- `goal-slug`: strip stopwords + hyphenate + ~20 chars cap

Examples:
- `2026-05-28-k3p9a-aer-v03`
- `2026-05-28-7m2xq-auth-refactor`
- `2026-05-28-9b4cn-bugs-p1`

**Log content per dispatch** (markdown + YAML frontmatter):

```markdown
---
run_id: 2026-05-28-k3p9a-aer-v03
item: AER-101
role: implementer
dispatch_num: 1
dispatched_at: 2026-05-28T10:47:23Z
returned_at: 2026-05-28T11:02:11Z
status: DONE
model: claude-sonnet-4-6
---

## Dispatch context (orchestrator-captured)
<the prompt the orchestrator sent — full text>

## Decision log (worker-written)
- [10:48:15] Read implementation-plan.md. 4 tasks identified.
- [10:49:02] Task 1: Started with domain entity. Chose <X> over <Y> because <Z>.
- [10:54:30] Task 1: Tests written + green. Moving to Task 2.
- [11:00:45] All tasks complete. Full suite green. Preparing return.

## Return (orchestrator-captured)
<the structured YAML the worker returned>
```

**Worker discipline** (in worker-contract.md): *"As you work, append decision-point entries to `.agent-tools/swarm/sessions/<run-id>/<item>/<role>-<n>.md` under the `## Decision log` heading. Brief bullets (timestamp + decision). NOT a transcript."*

**Reliability**: worker may forget to log. Orchestrator-captured dispatch+return is always present (orchestrator controls both). Worker decision log is best-effort. Sufficient for analysis even if decision log is sparse.

**Storage policy**: `.agent-tools/swarm/sessions/` is gitignored by default. User can opt to commit by adding `!sessions/` to `.agent-tools/.gitignore`.

### 7.9 Role File Organization

Role templates live in **two locations**:

1. **`src/swarm/roles/<role>.md`** — canonical default, ships with agent-tools.
2. **`<target-project>/.agent-tools/swarm/roles/<role>.md`** — project-local copy, editable per project.

**File set in `.agent-tools/swarm/roles/`:**

```
worker-contract.md     ← shared contract (schema, status semantics, brevity, log spec, boundaries)
planner.md             ← role-specific deltas only
implementer.md
reviewer.md
conflict-resolver.md
integration-fixer.md
```

**Six files, single canonical agent-agnostic versions. No per-CLI fanout.**

When `/swarm:init` detects a locally-modified role file (diff vs. canonical), it presents the diff and asks `keep-local/replace-with-canonical/merge/show-diff`. Never silently overwrites a customized role file.

### 7.10 Inheritance via Orchestrator-Prepended Worker-Contract

**Authoritative shared content** lives in `worker-contract.md`:
- Structured return schema
- Status code semantics
- Brevity discipline
- Session log writing requirement + format
- Generic worker boundaries

**Role-specific files** contain only what differs:
- Role identity line
- Workflow command to run
- Role-specific scope notes
- Role-specific return status subset

**How shared content reaches the worker** (CLI-agnostic):

Orchestrator's dispatch logic **mechanically prepends** `worker-contract.md` content to every dispatch prompt:

```
prompt = worker-contract.md content
       + role.md content
       + charter content (for cross-CLI workers; via @-import for same-CLI hosts)
       + item context
       + CLI addenda (Phase 3, if applicable)
```

**No `@-import` dependency in role files** — orchestrator does the concatenation. Portable across CLIs, no symlink chain to debug, DRY enforced mechanically.

---

## 8. State & Configuration Schemas

Two files, two purposes, two storage policies:

| File | Purpose | Owned by | Storage |
|---|---|---|---|
| `.agent-tools/swarm/config.yml` | Project-stable orchestrator preferences | User-editable; defaults written by `/swarm:init` | **Committed** — preferences are part of the project |
| `.agent-tools/swarm/sessions/<run-id>/state.yml` | Per-run mutable orchestrator state | Orchestrator (machine-written) | **Gitignored by default** — transient, per-run |
| `.agent-tools/swarm/active-run` | Pointer to current run-id | Orchestrator | **Gitignored** |

### 8.1 `config.yml` Schema

```yaml
schema_version: 1

# Concurrency cap for parallel dispatch waves
concurrency_cap: 5

# Role chain (which roles execute, in what dispatch order)
# Override only when intentionally simplifying (e.g., dropping reviewer for trivial backlogs)
role_chain:
  - planner
  - implementer
  - reviewer

# Model selection per role
# Tier labels (most_capable | mid_tier | fast) — orchestrator maps to actual
# model IDs based on host CLI (e.g., for Claude: opus | sonnet | haiku).
# Or specify an exact model ID to pin.
models:
  planner: most_capable
  implementer: mid_tier
  reviewer: most_capable
  conflict_resolver: most_capable
  integration_fixer: most_capable

# CLI per role (Phase 3; defaults to host CLI for all in Phase 2)
# Orchestrator role is always the host; cannot be overridden here.
clis:
  planner: claude
  implementer: claude
  reviewer: claude
  conflict_resolver: claude
  integration_fixer: claude

# Test command run by merge sweep after each merge into main
# null = orchestrator auto-detects from package manifests + charter engineering.md
test_command: null

# Backlog source defaults (if /swarm <goal> doesn't specify a source explicitly)
backlog:
  default_source: linear  # linear | jira | github-issues | file
  default_filter: null    # source-specific filter

# Session log retention
sessions:
  retention_days: null  # null = keep indefinitely; integer = prune older than N days

# Pre-launch confirmation
pre_launch:
  always_confirm: true  # show resolved-backlog confirmation before starting

# Output verbosity
output:
  per_wave_summary: brief  # brief | verbose | quiet
```

### 8.2 `state.yml` Schema (Per-Run)

Machine-managed; orchestrator writes atomically (temp file + rename) after each wave and merge-sweep cycle.

```yaml
schema_version: 1

# Run metadata
run_id: 2026-05-28-k3p9a-aer-v03
goal: "Linear v0.3.0 milestone"
goal_source: linear         # linear | jira | github-issues | file | inline
started_at: 2026-05-28T10:42:00Z
last_updated: 2026-05-28T11:17:22Z
status: in_progress          # in_progress | goal_complete | terminal_pause
exit_state: null             # null | GOAL_COMPLETE | IN_FLIGHT_DECISION | TERMINAL_PAUSE
exit_reason: null            # short text when exit_state is set

# Per-item state
items:
  - key: AER-101
    title: "Add multi-tenant booking holds"
    stage: implementing
    # stages: unrefined | refined | planning | planned | implementing | implemented
    #         | reviewing | approved | merged | fix-requested
    branch: feat/AER-101
    worktree: /Users/.../.claude/worktrees/aer-101
    blocks: [AER-115]              # items blocked by this one's completion
    blocked_by: []                  # items that must complete before this advances
    priority: null                  # null = use PM-derived; int = explicit override
    in_flight:                      # set when a worker dispatch is active
      role: implementer
      dispatched_at: 2026-05-28T11:00:00Z
      log_file: .agent-tools/swarm/sessions/2026-05-28-k3p9a-aer-v03/AER-101/implementer-1.md
    last_completed:                 # set when most recent worker dispatch returned
      role: planner
      completed_at: 2026-05-28T10:58:33Z
      status: DONE
      log_file: .agent-tools/swarm/sessions/2026-05-28-k3p9a-aer-v03/AER-101/planner-1.md
    fix_list: []                    # populated when stage=fix-requested

# Approved items awaiting merge sweep
merge_queue: []  # list of item keys in stage=approved

# Handoff (populated on TERMINAL_PAUSE; cleared on /swarm:continue resume)
last_handoff: null
# When set:
# last_handoff:
#   generated_at: 2026-05-28T12:14:00Z
#   reason: "Integration test failure on main after merging AER-115; one-shot fix-it failed."
#   user_actions_needed:
#     - "Inspect failed tests in worktree X"
#     - "Decide: revert AER-115 or fix forward"
#   diagnostic_files:
#     - .agent-tools/swarm/sessions/2026-05-28-k3p9a-aer-v03/AER-115/integration-fixer-1.md
```

**Notes:**
- `in_flight` and `last_completed` are mutually informative; contents move on return.
- `blocks` / `blocked_by` filled by Planner/Refiner during decomposition (per Section 6.4.1).
- `fix_list` persists across waves until consumed by the next implementer dispatch.
- Wave history is **not** in state.yml — it lives in `orchestrator.md`.

### 8.3 File Locations & Gitignore

```
<target-project>/
  .agent-tools/
    swarm/
      config.yml                                ← committed
      active-run                                ← gitignored
      sessions/                                 ← gitignored
        2026-05-28-k3p9a-aer-v03/
          state.yml
          orchestrator.md
          AER-101/
            planner-1.md
            implementer-1.md
            ...
      roles/                                    ← committed
        worker-contract.md
        planner.md
        ...
    .gitignore                                  ← created/updated by setup skills
```

**`.agent-tools/.gitignore`** contents:

```
# Managed by /swarm:init. User edits respected on re-run.

# Swarm transient state (per-run; not project source)
swarm/active-run
swarm/sessions/
```

**Re-run policy**: setup skills *add* missing entries; never *remove* user-added entries.

### 8.4 `active-run` Pointer

Plain text file containing exactly the active run-id, no decoration:

```
2026-05-28-k3p9a-aer-v03
```

| Command | Active-run interaction |
|---|---|
| `/swarm <goal>` | Generates new run-id; creates `sessions/<run-id>/`; writes run-id into `active-run`. On `GOAL_COMPLETE`, removes `active-run`. On `TERMINAL_PAUSE`, leaves in place. |
| `/swarm:continue` | Reads `active-run`. If absent → inform user. If present → loads `sessions/<run-id>/state.yml`, runs reconciliation, resumes. |
| `/swarm` (no args) | Reads `active-run` if present + summarizes current state. If absent → lists last N runs from `sessions/` sorted by run-id. |
| `/swarm:init` | No interaction with `active-run`. |

**Why text file, not symlink**: symlinks have cross-platform quirks (Windows), require special handling, and obscure intent. A one-line text file is unambiguous and version-control-friendly.

**Failure modes:**
- `active-run` exists but `sessions/<run-id>/` doesn't: surface and offer to clear pointer.
- `active-run` malformed: surface and offer to clear.
- `active-run` missing but `sessions/` has runs: treat as no active execution (explicit > clever).

### 8.5 Atomic Writes

State.yml updates use temp-file + rename:

```
write state.yml.tmp
fsync state.yml.tmp
rename state.yml.tmp → state.yml  # atomic on POSIX
```

Failure modes:
- Crash mid-write → `state.yml.tmp` may exist but is incomplete; rename never happens. `state.yml` retains last good state. Orchestrator on resume detects orphan `.tmp` and removes it.
- Crash mid-wave: `state.yml` reflects pre-dispatch state. Reconciliation on resume re-classifies (Phase 9 logic).

### 8.6 Test Command Discovery

Resolution order when `config.test_command` is null:

1. `config.yml`'s `test_command` (explicit override).
2. `charter/engineering.md`'s Testing section if it specifies a runnable command.
3. Package-manifest detection:
   - Node: `package.json` `scripts.test` → `npm test` / `pnpm test` / `yarn test` (per lockfile)
   - Python: `pyproject.toml` `[tool.pytest.ini_options]` or `tox.ini` / `Makefile` `test` target → `pytest` or `make test`
   - Go: `go test ./...`
   - Rust: `cargo test`
4. **If nothing detected**: orchestrator surfaces `NEEDS_CONTEXT`-equivalent IN_FLIGHT_DECISION asking user to specify, then writes the answer into `config.yml` for future runs.

### 8.7 Schema Versioning

Both files start with `schema_version: 1`.

- Orchestrator reads `schema_version` on load.
- Older than current expected → migrate in-place using codified migration steps.
- Newer than current → refuse to read; instruct user to update agent-tools.
- Migrations are forward-only; no downgrade path.

Migration details defer to implementation; principle is "version field present from v1."

---

## 9. Migration & Repo Changes

### 9.1 Target-Project Structure (With `.agent-tools/` Umbrella)

```
<target-project>/
  .agent-tools/                       ← NEW umbrella for agent-tools meta-artifacts (charter + swarm)
    .gitignore                        ← created/updated by /swarm:init
    charter/                          ← from /swarm:init
      charter.md
      project.md
      engineering.md
      workflow.md
    swarm/                            ← from /swarm:init
      config.yml                      (committed)
      active-run                      (gitignored)
      roles/                          (committed)
        worker-contract.md
        planner.md
        implementer.md
        reviewer.md
        conflict-resolver.md
        integration-fixer.md
      sessions/                       (gitignored)
        <run-id>/
          state.yml
          orchestrator.md
          <item-key>/
            ...

  AGENTS.md                           ← marker-bounded charter-link block (from /swarm:init)
  CLAUDE.md  → AGENTS.md              ← symlink if .claude/ present
  GEMINI.md  → AGENTS.md              ← symlink if .gemini/ present + user confirmed

  planning/                           ← UNCHANGED — carve-out; stays at root (§9.2)
    <project-name>/
      requirements.md
      implementation-plan.md
      session-state.md

  tests/e2e/ (or project's chosen test location)
                                      ← UNCHANGED — QA carve-out; stays in its natural
                                        test-tree location (§9.3). sentinel.config.yaml +
                                        NL specs + playwright.config.ts live here.
```

### 9.2 Why `./planning/` Stays at Root

- Planning files are **high-traffic during active work** — operators frequently `cat planning/<project>/session-state.md`, edit `implementation-plan.md`, etc.
- Hidden directories actively friction this daily-use pattern.
- The umbrella-discipline argument is real but weaker than the daily-use cost for this specific directory.
- Trade-off accepted: small inconsistency (`./planning/` visible at root; everything else under `.agent-tools/`) in exchange for ease of access.

This is an **intentional carve-out**, not tech debt to revisit.

### 9.3 QA Artifacts Stay in Their Natural Test Location (Carve-Out)

> **Design correction (2026-05-28):** An earlier version of this design called for migrating a `<target-project>/.sentinel/` directory into `<target-project>/.agent-tools/sentinel/` via `/qa:setup`. Inspection of the actual `/qa:setup` output and the one real consumer (`~/Source/OMG/inklings`) showed the premise was false. **QA artifacts are now an explicit carve-out, like `./planning/` (§9.2).**

**What the QA artifact actually is.** There is no `.sentinel/` directory. `/qa:setup` produces a `sentinel.config.yaml` plus NL specs and a Playwright config, and projects place these in a conventional test location. In the real consumer this is a **self-contained workspace package** at `tests/e2e/`:

- its own `package.json` + `node_modules/` (a pnpm/Turbo workspace member);
- `playwright.config.ts` with `testDir`, `globalSetup`, and a hardcoded `REPO_ROOT = resolve(__dirname, '../..')` depth assumption;
- its own `.claude/`, `.mcp.json`, `CLAUDE.md`;
- referenced by path from the monorepo root (`"test:e2e": "pnpm --dir tests/e2e test"`).

**Why it's a carve-out (not umbrella content).** The umbrella's purpose (§9) is to gather agent-tools *meta-artifacts* (charter, swarm state) out of the repo root. QA test infrastructure is not root clutter and not agent-tools meta-state — it's a build-integrated test package living exactly where developers expect it. Burying it under a hidden `.agent-tools/` directory would:

- break the monorepo wiring (root `pnpm --dir tests/e2e` script, pnpm/Turbo workspace globs, CI invocations, the `../..` depth assumption);
- require automated rewriting of build configuration — high blast radius;
- reproduce the **exact** daily-use friction §9.2 rejects for `./planning/`, only worse (this directory is tooling-integrated, not merely high-traffic).

**Decision.** `/qa:setup` continues to write QA artifacts in the project's chosen test location. There is **no `.agent-tools/sentinel/`, no migration, and no `/qa:setup` change** required by the swarm work. The `.agent-tools/` umbrella covers charter + swarm only.

This is an **intentional carve-out**, not tech debt to revisit.

### 9.4 `.agent-tools/.gitignore` Policy

Created (or updated) by `/swarm:init`. Per-umbrella gitignore — does NOT modify root `<repo>/.gitignore`. Local to `.agent-tools/`; respects user-added entries on re-runs.

### 9.5 Agent-Tools Repo Changes (in `src/`)

**New: `src/swarm/` family**

```
src/swarm/
  SKILL.md                          ← family overview + bare /swarm + /swarm <goal> orchestrator
  init/
    SKILL.md                        ← /swarm:init
  continue/
    SKILL.md                        ← /swarm:continue
  roles/                            ← canonical role templates
    worker-contract.md
    planner.md
    implementer.md
    reviewer.md
    conflict-resolver.md
    integration-fixer.md
  references/
    state-yml-schema.md
    config-yml-schema.md
    structured-return-schema.md
    classification-rules.md
    dispatch-mechanics.md
    cli-addenda.md                  ← Phase 3: per-CLI prompt addenda (initially empty)
    cross-cli-dispatch.md           ← Phase 3: per-CLI specifics, limitations
```

Three invocable skills register via existing publisher conventions: `name: swarm`, `name: swarm:init`, `name: swarm:continue`. Publisher flattens the latter two for Claude/Factory automatically.

**Unchanged: `src/qa/*`** — QA artifacts are a carve-out (§9.3); they stay in the project's natural test location. No `.agent-tools/sentinel/`, no migration, no path-reference changes.

**Updated: `src/workflow/refine/SKILL.md`** — capture `blocks` / `blocked_by` / `parallelizable_with` per refined item.

**Updated: `src/workflow/planning/SKILL.md` + `src/workflow/SKILL.md`** — surface dependency declarations during planning; write into `implementation-plan.md` frontmatter.

**Unchanged: rest of `src/workflow/*`** — single-agent behavior is otherwise untouched.

**Publisher (`tools/publish-skills.sh`)**: no changes required. Existing flattening logic handles `swarm`, `swarm:init`, `swarm:continue` automatically.

**Setup (`setup.sh`)**: no changes required. New swarm skills use default `publish-target: user-profile`.

**Documentation**:
- README.md: add `/swarm` family to Commands section; add `.agent-tools/` umbrella explanation (charter + swarm) to Project Structure.
- `src/swarm/SKILL.md` References section: attribution (Section 11).

---

## 10. Phasing

Three phases. Each shippable independently; each delivers value on its own.

### 10.1 Phase 1 — Foundation + `/swarm:init`

**Goal**: lay the structural foundation without yet introducing the orchestrator.

| Deliverable | Notes |
|---|---|
| `src/swarm/SKILL.md` (skeleton) | Family overview + bare `/swarm` (state summary only). On `<goal>` invocation, returns "Orchestrator not yet implemented." |
| `src/swarm/init/SKILL.md` | Full `/swarm:init`: detection (manifests, configs, ADRs, PM tools, AGENTS.md), dialogue, charter authoring, AGENTS.md linking with markers, conditional symlinks, idempotent re-init |
| Charter file structure | `charter.md` + `project/engineering/workflow.md` with stable headers + evidence-grounded body templates |
| `.agent-tools/` umbrella + `.agent-tools/.gitignore` | Created by `/swarm:init` |
| `src/workflow/refine/SKILL.md` enhancement | Capture `blocks` / `blocked_by` / `parallelizable_with` per refined item |
| `src/workflow/planning/SKILL.md` + `src/workflow/SKILL.md` enhancement | Surface dependency declarations during planning; write into `implementation-plan.md` frontmatter |
| Documentation | README updates; src/swarm/SKILL.md References section with attribution |

**Value at end of Phase 1**:
- Charter exists; loaded by any `/workflow` agent via AGENTS.md
- Single-agent `/workflow` runs benefit from charter context
- Refinement and planning capture richer metadata
- `.agent-tools/` umbrella established (charter + swarm)
- `/swarm` CLI surface stub exists

**Risk**: lowest. Mostly mechanical.

### 10.2 Phase 2 — Swarm Orchestrator MVP

**Goal**: core /swarm orchestration loop, published agent-agnostic.

| Deliverable | Notes |
|---|---|
| `src/swarm/SKILL.md` full implementation | Bare `/swarm` summary + `/swarm <goal>` full orchestrator loop |
| `src/swarm/continue/SKILL.md` | `/swarm:continue` with reconciliation logic |
| `src/swarm/roles/` — all six canonical templates | `worker-contract.md`, `planner.md`, `implementer.md`, `reviewer.md`, `conflict-resolver.md`, `integration-fixer.md` |
| `src/swarm/references/` | All schemas, classification rules, dispatch mechanics, merge-sweep procedure |
| Session log infrastructure | `.agent-tools/swarm/sessions/<run-id>/` layout; atomic write strategy |
| `active-run` pointer mechanics | Create/clear lifecycle |
| In-process refinement (host-side) | Orchestrator runs `/workflow:refine` in main session for unrefined items |
| Backlog source: PM-first via MCP, file fallback | Linear/Jira/GitHub Issues; local backlog file |
| Native sub-agent dispatch | For each target host CLI's native mechanism (Claude `Agent` tool; verify Droid/Grok equivalents) |
| Merge sweep | Clean + conflict + test-red paths; ad-hoc fix-it dispatch one-shot, then TERMINAL_PAUSE |
| Exit-state model implementation | GOAL_COMPLETE / IN_FLIGHT_DECISION / TERMINAL_PAUSE behaviors |
| Documentation | README updated with /swarm command table |

**Value at end of Phase 2**:
- User can run `/swarm "Linear v0.3.0 milestone"` and have the orchestrator drive the backlog through plan → implement → review → local merge
- Coordination burden lifts; user only handles IN_FLIGHT_DECISIONs and TERMINAL_PAUSEs

**Per-host functionality at end of Phase 2**:
- Claude as host: orchestrator fully functional with native `Agent` tool dispatch.
- Droid / Grok as host: functional only if those CLIs have native sub-agent dispatch; otherwise gated on Phase 3 same-CLI shell-out.

**Risk**: moderate. Orchestrator loop is non-trivial; merge sweep + fix-it paths have failure modes; workflow enhancements from Phase 1 are required for the scheduler to produce useful dispatch graphs.

**Phase 2 hard requirements** (from Phase 1):
- Charter must exist (precondition check)
- Workflow refine/plan enhancements live

### 10.3 Phase 3 — Cross-CLI Worker Dispatch

**Goal**: enable any-agent-as-orchestrator with any-agent-as-worker, including cross-CLI dispatch where worker's CLI ≠ orchestrator's CLI.

**Hard prerequisites (verifiable upfront):**

1. **Confirm non-interactive CLI invocation support** for each agent-tools target:
   - Claude: `claude -p "<prompt>"` — known to work.
   - Droid: verify the equivalent (`droid exec`, etc.) and any flags needed to suppress interactive UI.
   - Grok: verify the equivalent.
   - **This is the single concrete blocker for P3.**

2. **Confirm role-template agent-agnosticism**: test that canonical worker-contract + role templates produce compliant structured returns when used by each target CLI's shell-out. If a CLI consistently breaks the format, solve it via:
   - **Iterate the canonical template phrasing** (preferred — most divergence is solvable by better phrasing).
   - **Orchestrator-side per-CLI prompt addenda** (`src/swarm/references/cli-addenda.md`): the orchestrator appends a small per-CLI suffix at dispatch time. User-edited project templates remain CLI-blind; per-CLI adjustments live centrally.
   - **Document limited support** for any role × CLI combination that can't reliably function even with addenda.

   **No role-template fanout**. Single canonical agent-agnostic templates only. Period. Fanout was rejected because it multiplies project-side complexity (6 templates × N CLIs) and breaks per-role CLI configurability in `config.yml`.

**Deliverables:**

| Deliverable | Notes |
|---|---|
| Shell-out invocation adapters per CLI | Invocation form + stdout capture + working-directory + error handling |
| `config.yml`'s `clis` field activation | Per-role CLI selection (orchestrator always = host) |
| Charter + worker-contract + role-prompt + CLI-addenda assembly | Mechanical concatenation in orchestrator; addenda map central |
| YAML-fenced-block parser for shell-out stdout | Strip CLI banners/noise; extract structured return; parse failure → `BLOCKED` |
| Bash + Monitor integration for backgrounded shell-out dispatch | Concurrent shell-out for parallel waves |
| `src/swarm/references/cli-addenda.md` | Per-CLI addendum snippets (initially empty; populated only when needed) |
| `src/swarm/references/cross-cli-dispatch.md` | Per-CLI specifics, known limitations, role × CLI compatibility notes |
| Documentation | README updates for cross-CLI capability |

**Phase 3 is genuinely optional.** Phase 2 (on Claude host) is a complete, useful system. Phase 3 extends it to multi-CLI deployments — useful if/when the user wants cheaper implementer dispatch via a non-Claude CLI, or wants to validate role outputs across CLIs.

### 10.4 Out of Scope (Across All Phases)

| Item | Disposition | Why |
|---|---|---|
| Long-running daemon orchestrator | Out — never | Orchestrator is a stateful in-session command |
| Auto-push to origin/main | Out — never | User-gated push is the hard safety boundary |
| Integrator role for merge orchestration | Out — merged into orchestrator | Merge is orchestrator's job; conflicts → ad-hoc dispatch |
| Migration of `./planning/` → `.agent-tools/planning/` | Out — permanent carve-out | Daily-use friction; stays at root |
| File-collision pre-detection in scheduler | Future v2 | MVP relies on merge-time conflict resolution |
| Multiple concurrent swarm runs per project | Future v2 | Single-pointer `active-run` enforces serial |
| `/swarm:gc` for session log cleanup | Future v2 | Manual `rm -rf` works for MVP |
| `/swarm:status` as dedicated command | Folded into bare `/swarm` | Single command surface |
| Refiner as sub-agent role | Rejected — host-side | Refinement is conversational; sub-agent shape doesn't fit |
| Per-CLI role-template fanout | Rejected | Multiplies project surface; breaks per-role CLI configurability |
| Cross-CLI orchestrator delegation | Out — never | Orchestrator IS the host; cannot be shell-out |
| Streaming responses from shell-out workers | Out | Workers return final structured YAML, not intermediate state |
| Mixed-CLI Agent-tool-style native dispatch | Out | Adds API-surface coupling for no clear gain over shell-out |
| Hyper-customized role templates beyond defaults | Out of MVP | Project-local edit-after-init sufficient |

### 10.5 Phasing Decision Criteria

- Phase 1 ships first regardless; even if Phase 2 takes time, charter + workflow enhancements deliver immediate value.
- Phase 2 ships as soon as the orchestrator loop is verified working on a real backlog (likely the user's own Linear backlog as the dogfooding case). Initially Claude-host.
- Phase 3 ships only when/if there's a concrete reason to dispatch workers via non-Claude CLIs.

---

## 11. Attribution

The swarm orchestration concept in this design is adapted from **swarm-forge** by Robert C. "Uncle Bob" Martin:

- https://github.com/unclebob/swarm-forge

**Concepts adapted**:
- The constitution/charter primitive (layered prompts with precedence)
- Role-specialized agents
- Per-item worktree isolation

**Concepts re-shaped**:
- Process orchestration: swarm-forge uses tmux + macOS Terminal + watchdog scripts; this design uses the host agent's native sub-agent dispatch instead, with no multi-terminal control.
- Roles: swarm-forge uses architect/coder/reviewer; this design aligns roles to `/workflow` lifecycle stages (planner/implementer/reviewer + ad-hoc conflict-resolver/integration-fixer; refiner runs host-side).
- Notification protocol: swarm-forge uses file-based `pending-messages` queues between agent processes; this design uses host-mediated structured returns, eliminating inter-sub-agent messaging entirely.
- Cross-agent posture: swarm-forge supports CLI selection per role; this design extends with the broader agent-tools cross-CLI publishing model and shell-out worker dispatch.

This attribution belongs in `src/swarm/SKILL.md`'s References section.

---

## Appendix A — Glossary

| Term | Definition |
|---|---|
| **Orchestrator** | The host agent running in the user's session when `/swarm <goal>` is invoked. Drives the backlog through the lifecycle. |
| **Worker** | A dispatched sub-agent that runs one `/workflow` command on one item in one worktree, then returns a structured status. |
| **Role** | The function a worker performs (planner, implementer, reviewer, conflict-resolver, integration-fixer). Workers know their own role; not peers'. |
| **Wave** | A single message containing N parallel sub-agent dispatches, where N ≤ concurrency cap. |
| **Run** | One `/swarm <goal>` invocation, identified by run-id, with its own session subdir and state.yml. |
| **Charter** | Project-local structured project context (charter.md + project/engineering/workflow.md), authored by `/swarm:init`. |
| **Item** | A unit of work in the backlog (typically a PM issue). Progresses through stages from unrefined → merged. |
| **Stage** | An item's current position in the lifecycle (unrefined, refined, planning, planned, implementing, implemented, reviewing, approved, merged, fix-requested). |
| **Exit state** | The orchestrator's terminal disposition: GOAL_COMPLETE, IN_FLIGHT_DECISION, or TERMINAL_PAUSE. |
| **active-run** | Plain-text pointer file at `.agent-tools/swarm/active-run` containing the current run-id. |
| **Worker contract** | Shared boilerplate (`worker-contract.md`) orchestrator prepends to every worker dispatch prompt. |
| **CLI addenda** | Per-CLI prompt suffixes (Phase 3) appended by orchestrator when dispatching to non-host CLIs that need adjusted phrasing. |
