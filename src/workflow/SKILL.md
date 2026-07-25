---
name: workflow
description: Parent skill for the workflow family — bare /workflow is portfolio status (read-only); /workflow:continue drives work; /workflow:maintain stewards prune + yield + memory. Horizon mapping, brainstorm, refine, plan, execute, review, audit, compound. Vertical-slice and deliverable-partition modes.
user-invocable: true
argument-hint: "[no args for portfolio status | unit id/path/slug for focused status | help]"
---

# Workflow

Parent skill for the `workflow` family: high-level philosophy, shared contracts, and navigation.
**Procedures live in the sub-skills** — load those for full detail. Bare `/workflow` is
**status only** — load `references/status.md`, not the family-contract encyclopedia.

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
| `/workflow:roadmap` | Multi-unit horizon map + NEXT + `→`/`∥` notation (user-approved) |
| `/workflow:brainstorm` | Single fuzzy concept → framed seed (HITL) |
| `/workflow:refine` | Requirements discovery (file or PM) |
| `/workflow:plan` | Implementation plan + session-state (approval gate; optional static HTML visual plan) |
| `/workflow:execute` | Session-based implementation loop |
| `/workflow:review` | Code review (PR / range / paths / uncommitted) |
| `/workflow:audit` | Multi-domain project audit |
| `/workflow:compound` | Capture durable knowledge (`--maintain` → `:maintain` compat) |
| `/workflow:maintain` | **Steward** — ritual prune check + schedule-aware yield/memory (force with flags / `--all`) |

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

1. Do what works — simple processes over complex frameworks  
2. Work spans sessions — structure for continuity  
3. Speed + quality + detail  
4. Knowledge compounds — capture insight after non-trivial work  
5. User approves before durable commits (plans, roadmaps, brainstorm converge); continue never invents a queue (named NEXT without a planning shell is still claimable)  
6. Artifacts state the **current** target — re-derive when decisions change; git holds history (`references/decision-records.md`)  
7. Durable path decisions (`Chosen Direction`, stream lists, NEXT) are user-gated  
8. Requirements / design / plan are **working hypotheses** — mid-code learning reclassifies (`references/context-engineering.md`)

**Decomposition:** vertical slice (default feature) vs deliverable-partition — full doctrine
`references/decomposition-modes.md`.

## Requirements source · planning root · tracks

| Topic | Detail |
|-------|--------|
| **File vs PM** | Binary per unit; detection `planning/pm-integration.md` |
| **Planning root** | Prefer `.agent-tools/planning/`; legacy `./planning/` — `references/planning-root.md` |
| **Runs ledger** | `.agent-tools/runs/` — `references/runs-ledger.md`; yield via `:maintain` |
| **Tracks** | feature · micro · research — `references/tracks.md` |
| **Context craft** | On-demand codebase research ≠ research track — `references/context-engineering.md` |
| **Compact** | Mid-item reclaim — `references/context-compact.md` |

## Project-local conventions

Optional `planning/conventions.md` is a **sparse overlay** (tracks, gates, merge policy, PM
queue, visual plan). Absent sections keep built-in defaults. Automation overlays (always-PR,
etc.) stay one process dialect — `references/approval-boundaries.md`.

## Family contracts (load on demand)

Session-state schema, branch naming, planning-dir layout, task-planning norms:
**`references/family-contracts.md`**. Write-time shells: `execution/templates/session-state.md`,
@workflow (`planning/templates.md`). **Not** required for bare status.

## Parallel worktrees

2+ independent slices: `references/parallel-worktrees.md` + @git worktree-create /
worktree-delete.

## High-leverage refs (load when needed)

| When | Path |
|------|------|
| Bare status | `references/status.md` |
| Drive / SM | `@workflow:continue` + its refs |
| Context craft / research / compact | `references/context-engineering.md`, `context-compact.md` |
| Family contracts | `references/family-contracts.md` |
| Tracks / root / ledger | `references/tracks.md`, `planning-root.md`, `runs-ledger.md` |
| Steward | `@workflow:maintain` |
| Runtime adapters / effort | `references/process-payload.md`, `model-runtime-policy.md` |
| Plan templates / visual | `planning/templates.md`, `planning/references/visual-approval.md` |
| Approval / pre-wake | `references/approval-boundaries.md`, `pre-wake-checklist.md` |

Secondary refs (memory, critic, examples, conversation analysis, hooks, …) live under
`references/` and phase trees — open by topic.

## Related Skills

- **clean-architecture** · **code-patterns** · **test-strategy** · **qa**
- **skills:evolve** — only path that *edits* process IP (`publish-target: project`); consumers
  capture evidence and escalate upstream.
