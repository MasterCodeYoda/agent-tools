---
name: workflow
description: Parent skill for the workflow family — bare /workflow is portfolio status (read-only); /workflow:continue drives work. Horizon mapping, brainstorm, refine, plan, execute, review, audit, compound. Vertical-slice and deliverable-partition modes.
user-invocable: true
argument-hint: "[no args for portfolio status | unit id/path/slug for focused status | help]"
---

# Workflow

Parent skill for the `workflow` family: high-level philosophy, shared contracts (session-state,
branch naming, conventions), and navigation. **Procedures live in the sub-skills** — load those
for full detail.

## Invocation (like `/swarm`)

| Invocation | Behavior |
|------------|----------|
| **`/workflow`** (no args) | **Portfolio status** — read-only scan → report → **stop** |
| **`/workflow <id\|path\|slug>`** | **Focused status** on that unit — still read-only |
| **`/workflow:continue`** | **Drive** — portfolio mode + unit phase machine or swarm handoff/resume |
| Help / command list only | Summarize this table; do not force a drive hard-stop |

Bare `/workflow` does **not** proxy to continue. Status procedure: `references/status.md`
(mandatory load for bare invocation). Soft-check signals are **advisory** on status;
continue may **act** on the same checklist.

## Commands in This Family

| Command | Purpose |
|---------|---------|
| `/workflow` | **Status** — portfolio glance (read-only); focused status with a unit arg |
| `/workflow:continue` | **Drive** — mode resolve + claim + phase SM or swarm handoff/resume |
| `/workflow:setup` | Scaffold `planning/` hygiene + author `conventions.md` + memory link |
| `/workflow:prune` | Purge confirmed-complete planning items (approval-gated) |
| `/workflow:roadmap` | Multi-unit horizon map + NEXT + `→`/`∥` notation (user-approved) |
| `/workflow:brainstorm` | Single fuzzy concept → framed seed (HITL) |
| `/workflow:refine` | Requirements discovery (file or PM) |
| `/workflow:plan` | Implementation plan + session-state (approval gate; optional static HTML visual plan) |
| `/workflow:execute` | Session-based implementation loop |
| `/workflow:review` | Code review (PR / range / paths / uncommitted) |
| `/workflow:audit` | Multi-domain project audit |
| `/workflow:compound` | Capture durable knowledge; `--maintain` memory quality |

See each sub-skill for arguments and full procedure.

**Altitude triage:** @workflow (`references/horizon-altitudes.md`).

```text
   /workflow            ← status (read-only portfolio glance)
        ↓  (user chooses to drive)
   /workflow:continue   ← drive entry
        ├─ active swarm / explicit ∥ wave  →  /swarm (auto or resume)
        └─ one claimable unit             →  phase state machine
              brainstorm? ⇄ refine ⇄ plan ⇄ execute ⇄ review → finish → compound
              (cycles when artifact/decision evidence requires)

[multi-unit / path unknown]  /workflow:roadmap   (→ sequential · ∥ parallel · {wave})
```

## Behavior — bare `/workflow`

Parse `$ARGUMENTS` and run **`references/status.md`** end-to-end:

1. Resolve planning root; if missing → not-initialized report + offer `:setup` → stop.
2. Light scan: conventions, swarm `active-run`, claimable units, roadmap/handoff NEXT.
3. Surface soft-check signals as **advisory only** (no remediation).
4. Preview which mode `/workflow:continue` would enter — do not enter it.
5. Emit the status template → **stop**.

Never claim, invoke phases, append the runs ledger, merge, or enter swarm from bare status.
Direct phase commands (`:refine`, `:plan`, …) remain valid when the user already knows the phase.

## Philosophy

### Core Tenets

1. Do what works — simple processes over complex frameworks  
2. Work spans sessions — structure for continuity  
3. Speed + quality + detail  
4. Knowledge compounds — capture insight after non-trivial work  
5. User approves before durable commits (plans, roadmaps, brainstorm converge); continue never invents a queue (named NEXT without a planning shell is still claimable)  
6. Artifacts state the **current** target — re-derive when decisions change; git holds history. See `references/decision-records.md`  
7. Durable path decisions (`Chosen Direction`, stream lists, NEXT) are user-gated  

### Decomposition Modes

**Vertical slice** — end-to-end story, ship before next. Default for post-release feature work.  
**Deliverable-partition** — partition parent ACs across artifact sub-issues (foundation, cross-cutting).

Full selection doctrine, AC inheritance, anti-patterns: `references/decomposition-modes.md`.

## Requirements Source Mode

Binary per workflow: **file** (`requirements.md`) vs **PM** (issue is SoT). Detection and field
mappings: `planning/pm-integration.md`. Agent states mode and allows course-correct.

## Planning root

**Preferred home:** `.agent-tools/planning/`. **Legacy fallback:** `./planning/` if that directory
exists and the preferred root does not. Bare `planning/` in this family means *relative to the
resolved planning root*. Full rules: `references/planning-root.md`.

**Runs ledger** (line instrumentation, not planning work product): `.agent-tools/runs/` —
`references/runs-ledger.md`.

## Built-in tracks

| Track | Dose |
|-------|------|
| **feature** | Full line: refine → plan → execute → review → integrate → compound |
| **micro** | Issue-as-plan → execute → review (`quick`) → integrate → compound disposition |
| **research** | Frame → evidence → conclusion → compound; done is judgment once not-done signals clear |

Classification, micro/research process, review depth: `references/tracks.md`. Project
`conventions.md` may add tracks or adopt the **personal factory** pack (setup template).

**On-demand codebase research** (compress live-code truth for the unit) is **not** the same
as the research track — it is default context craft for almost all work. Dumb-zone norms,
plan-snippet quality, mid-phase intentional compaction: `references/context-engineering.md`.

## Project-Local Conventions

Optional `planning/conventions.md` (via `/workflow:setup`) is a **sparse overlay** of project-local
overrides — not a full replacement of built-in defaults. It may define: extra work tracks, horizon
layout, additive gates, integration/merge policy (including autonomous local merge), orientation/
PM queue, and optional **visual plan approval** policy (`never` | `on-substantial` | `always`).
Continue and execute honor recorded sections; **any section left out keeps the skill’s built-in
default** (e.g. visual plan stays `on-substantial` when the file never mentions it). File entirely
absent → all built-in defaults. Visual presentation is first-party static HTML
(`visual-plan.html`) and is non-blocking when skipped.

## Task Planning

All planned tasks are required (no priority tiers). Acceptance criteria are binary. Future ideas go
in **Out of Scope**, not deferred tasks.

## Session Continuity

### Planning Directory Structure

```
<planning-root>/          # .agent-tools/planning/ preferred; else ./planning/
├── roadmap.md            # optional (roadmap skill)
├── conventions.md        # optional (setup)
├── <project-name>/
│   ├── brainstorm.md     # optional
│   ├── requirements.md   # file mode only
│   ├── codebase-research.md  # on-demand code snapshot (almost all work)
│   ├── implementation-plan.md
│   ├── session-state.md
│   ├── visual-plan.html        # optional; approval presentation only
│   └── technical-decisions.md  # optional
└── archive/
```

```
.agent-tools/runs/        # line instrumentation (not under planning-root)
├── events.ndjson
├── ledger.yml
└── yield.md              # optional regenerated glance
```

Initiative/workstream dialects are honored when conventions say so.

### Session State Schema

```yaml
---
project: [name]
requirements_source: [file|pm]
work_item: [ISSUE-ID]
pm_tool: [linear|jira|manual]
session_count: [N]
status: [planned|in_progress|complete]
track: [feature|micro|research]   # optional; classify may set
run_id: r-YYYYMMDD-N              # optional until first continue claim
source_channel: [cli|linear|github|chat|other]
progress:
  total_tasks: [X]
  completed: [Y]
  percent: [Z%]
current_layer: [domain|infrastructure|application|framework]
branch: <type>/<issue-key or description>
worktree: <path>  # only with --worktree
visual_plan: <path-to-visual-plan.html | skipped — reason>  # optional; approval presentation only
reentry_counts:   # optional; thrash bound is per run_id
  refine_from_execute_or_review: 0
  plan_from_execute_or_review: 0
thrash_bound_hits: 0
---
## Current Focus
[What's being worked on]

## Last Session Summary
[Handoff context]

## Intentional Compaction
[Latest mid-phase snapshot when used — see references/context-engineering.md]

## Session History
[Append-only log]
```

> **Scope:** this template — including the append-only `Session History` log — is for **per-item**
> `planning/<item>/session-state.md`. The **top-level handoff** (`planning/session-state.md`) is a
> *light pointer*, not a log: it never carries an append-only history or completed/released-work
> records. See `@workflow:setup` §4.

### Branch Naming Convention

**Rule:** `<type>/<identifier>` exactly.

| Type | With issue key | Without |
|------|----------------|---------|
| Bug | `fix/INK-123` | `fix/login-validation` |
| Feature | `feat/INK-124` | `feat/user-dashboard` |

With an issue key, use the key as the **entire** identifier — no username prefixes, no appended
descriptions. Without: short lowercase-hyphenated (2–4 words).

**Anti-patterns:** `matt/ink-123-desc`, `feature/INK-123-long-name`, bare `INK-123`.

### Handoff Protocol

At session boundaries: update session state → commit → offer compound → handoff summary.

## Parallel Execution with Worktrees

Use for 2+ independent slices; not for sequential/shared-file work. Full rules:
`references/parallel-worktrees.md`. @git worktree-create / worktree-delete for agent mechanics.

## Common Pitfalls

- Over-engineering the first slice  
- Horizontal infra inside a vertical slice (N/A in deliverable-partition)  
- Premature abstraction  
- Skipping quality gates  
- 80% done syndrome  

Examples: `references/decomposition-modes.md`.

## Extended Guidance (load on demand)

| Area | Path |
|------|------|
| Portfolio status (bare `/workflow`) | `references/status.md` |
| Planning root | `references/planning-root.md` |
| Built-in tracks | `references/tracks.md` |
| Context engineering (dumb zone, research artifact, plan snippets, mid-phase compaction) | `references/context-engineering.md` |
| Runs ledger | `references/runs-ledger.md` |
| Handoff package (unit ↔ swarm) | `references/handoff-package.md` |
| Process payload (runtime adapters) | `references/process-payload.md` |
| Decomposition | `references/decomposition-modes.md` |
| Worktrees | `references/parallel-worktrees.md` |
| Plan templates | `planning/templates.md` |
| Visual plan approval (static HTML) | `planning/references/visual-approval.md` |
| Visual plan HTML template | `planning/templates/visual-plan.html` |
| Task breakdown | `planning/task-breakdown.md` |
| Quality gates | `execution/quality-checkpoints.md` |
| Deps in worktree | `execution/dependency-establishment.md` |
| Logging | `execution/logging.md` |
| PM + claim dialect | `planning/pm-integration.md` |
| Altitude | `references/horizon-altitudes.md` |
| Memory | `references/memory-primitives.md` |
| Decisions | `references/decision-records.md` |
| Critic pass | `references/critic-pass.md` |
| Planning example | `references/planning-example.md` |
| Conversation analysis | `references/conversation-analysis.md` |

## Related Skills

- **clean-architecture** — layers and dependency direction  
- **code-patterns** — language implementation  
- **test-strategy** — testing methodology  
- **qa** — E2E / NL specs  
- **skills:evolve** — skill-source only (`publish-target: project`); only path that *edits*
  process IP skills. Consumer projects capture process evidence and escalate upstream.

## Remember

YAGNI in-mode · ship early · refactor continuously · stay in mode · test behavior · compound
knowledge · never ad-hoc skill rewrites — evolve the corpus in the skill source via
`/skills:evolve` when installed, else capture evidence and take the gap upstream.
