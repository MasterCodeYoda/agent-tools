---
name: workflow
description: Parent skill for the workflow family — horizon mapping, brainstorming, refinement, planning, execution, review, audit, compound, and knowledge capture. Supports vertical-slice and deliverable-partition decomposition modes.
user-invocable: true
---

# Workflow

Parent skill for the `workflow` family: high-level philosophy, shared contracts (session-state,
branch naming, conventions), and navigation. **Procedures live in the sub-skills** — load those
for full detail.

## Commands in This Family

| Command | Purpose |
|---------|---------|
| `/workflow:setup` | Scaffold `planning/` hygiene + author `conventions.md` + memory link |
| `/workflow:prune` | Purge confirmed-complete planning items (approval-gated) |
| `/workflow:roadmap` | Multi-unit horizon map + NEXT (user-approved) |
| `/workflow:brainstorm` | Single fuzzy concept → framed seed (HITL) |
| `/workflow:refine` | Requirements discovery (file or PM) |
| `/workflow:plan` | Implementation plan + session-state (approval gate) |
| `/workflow:execute` | Session-based implementation loop |
| `/workflow:review` | Code review (PR / range / paths / uncommitted) |
| `/workflow:audit` | Multi-domain project audit |
| `/workflow:compound` | Capture durable knowledge; `--maintain` memory quality |
| `/workflow:continue` | Drive next **known** slice; hard-stop if path not established |

See each sub-skill for arguments and full procedure.

**Altitude triage:** @workflow (`references/horizon-altitudes.md`).

```text
[multi-unit / path unknown]  /workflow:roadmap
        ↓ per claimable unit
brainstorm? → refine → plan → execute → review → finish → compound
        ↑
   /workflow:continue  (never invents NEXT)
```

## Philosophy

### Core Tenets

1. Do what works — simple processes over complex frameworks  
2. Work spans sessions — structure for continuity  
3. Speed + quality + detail  
4. Knowledge compounds — capture insight after non-trivial work  
5. User approves before durable commits (plans, roadmaps, brainstorm converge); continue never invents a queue  
6. Artifacts state the **current** target — re-derive when decisions change; git holds history. See `references/decision-records.md`  
7. Durable path decisions (`Chosen Direction`, stream lists, NEXT) are user-gated  

### Decomposition Modes

**Vertical slice** — end-to-end story, ship before next. Default for post-release feature work.  
**Deliverable-partition** — partition parent ACs across artifact sub-issues (foundation, cross-cutting).

Full selection doctrine, AC inheritance, anti-patterns: `references/decomposition-modes.md`.

## Requirements Source Mode

Binary per workflow: **file** (`requirements.md`) vs **PM** (issue is SoT). Detection and field
mappings: `planning/pm-integration.md`. Agent states mode and allows course-correct.

## Project-Local Conventions

Optional `planning/conventions.md` (via `/workflow:setup`) may define: extra work tracks, horizon
layout, additive gates, integration/merge policy (including autonomous local merge). Continue and
execute honor it. Absent → built-in defaults.

## Task Planning

All planned tasks are required (no priority tiers). Acceptance criteria are binary. Future ideas go
in **Out of Scope**, not deferred tasks.

## Session Continuity

### Planning Directory Structure

```
./planning/
├── roadmap.md              # optional (roadmap skill)
├── conventions.md          # optional (setup)
├── <project-name>/
│   ├── brainstorm.md       # optional
│   ├── requirements.md     # file mode only
│   ├── implementation-plan.md
│   ├── session-state.md
│   └── technical-decisions.md  # optional
└── archive/
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
progress:
  total_tasks: [X]
  completed: [Y]
  percent: [Z%]
current_layer: [domain|infrastructure|application|framework]
branch: <type>/<issue-key or description>
worktree: <path>  # only with --worktree
---
## Current Focus
[What's being worked on]

## Last Session Summary
[Handoff context]

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
| Decomposition | `references/decomposition-modes.md` |
| Worktrees | `references/parallel-worktrees.md` |
| Plan templates | `planning/templates.md` |
| Task breakdown | `planning/task-breakdown.md` |
| Quality gates | `execution/quality-checkpoints.md` |
| Deps in worktree | `execution/dependency-establishment.md` |
| Logging | `execution/logging.md` |
| PM | `planning/pm-integration.md` |
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

## Remember

YAGNI in-mode · ship early · refactor continuously · stay in mode · test behavior · compound knowledge.
