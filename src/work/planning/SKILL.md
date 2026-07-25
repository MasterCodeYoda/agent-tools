---
name: work:plan
description: Create implementation plans from requirements
argument-hint: "[--worktree] [requirements.md path, work item ID (LIN-123, PROJ-456), or feature description]"
user-invocable: true
---

# Implementation Planning

Transform requirements into actionable implementation plans. For requirements discovery first,
use `/work:refine`.

## User Input

```text
$ARGUMENTS
```

## Flags & input

Extract `--worktree` → `WORKTREE_MODE=true` and strip; else false.

**Hard refuse:** already inside a worktree → cannot nest (`ERROR: Already inside a git worktree…`).

Empty input: file mode → list `./planning/*/requirements.md`; PM mode → prompt issue key; else ask
what to plan.

| Pattern | Action |
|---------|--------|
| `./planning/<project>/requirements.md` or dir | Load requirements; plan |
| Issue key / PM URL | Fetch as requirements (`planning/pm-integration.md`) |
| `http(s)://` | PM fetch or WebFetch |
| Directory | Load/review existing plan |
| Text | Use as feature; suggest refine if vague/complex |

## Requirements source mode

Detect file vs PM per @work `planning/pm-integration.md` (explicit path/key → artifacts →
project context → MCP → fallback file). State determination; allow course-correct.

## Decomposition mode

Doctrine: @work `references/decomposition-modes.md`.

- **Vertical-slice** — Vertical Slice Breakdown  
- **Deliverable-partition** — Deliverable Breakdown + verbatim parent-AC ownership  

Detect: inherit from refine → explicit user → work-shape heuristics → fallback vertical (feature)
or deliverable-partition (foundation). State determination; allow course-correct. Templates:
@work `planning/templates.md` Variant A/B.

## Context & requirements

**Load** `references/context-gathering.md` end-to-end: project detect, ticket-hidden research +
design confirm, prefactoring, load requirements (file/PM), user confirm + dependency echo.

## Draft implementation plan

Task breakdown patterns: `planning/task-breakdown.md`. Density/segmentation: @work
`context-engineering.md` › Plan segmentation.

**Do not write** `implementation-plan.md` / session-state until approval
(`references/plan-approval.md`). Exception: may write research, design, and (per visual rules)
`visual-plan.html` pre-approval for human review.

Target: `./planning/<project>/implementation-plan.md`.

**Load and fill** @work `planning/templates.md` › Implementation Plan Document Template
(frontmatter deps, Approach, Research grounding, Design, Structure outline, Intended changes,
Breakdown, DoD).

**Hard segmentation** (substantial/multi-file; default unless trivial) — do not race to tactical
body without structure:

1. **Design confirm** — link design or skip reason; hold or stop for refine  
2. **Structure outline** — vertical (or deliverable) phases + verification (human deep-read)  
3. **Intended changes** — paths + snippets (human spot-check)  
4. **Breakdown + DoD** — tasks under structure  

Quality: cite research/design; vertical checkpoints unless deliverable-partition; snippets +
verify steps; structure scannable in one sitting. Deliverable-partition: parent ACs, traceability,
verbatim inheritance, gap-prevention.

### Session state (after approve only)

Plan-time shell from `planning/templates.md`: `session_count: 0`, `status: planned`, zeros,
awaiting approval → execute.

### PM after approve only

Plan-time status update: `planning/pm-integration.md` › Plan-Time Status Update. **Hard refuse:**
no PM update until approve.

### Leverage check

One reordering/simplification/addition that raises value or cuts risk? If yes: fold in + **Key
Insight** callout. If not: silent.

### Visual plan (optional)

**Before** approval gate: **load and follow** `references/visual-approval.md` (presentation only;
static HTML; convention-gated; non-blocking; same content as markdown; link don't auto-launch).

## Plan approval gate

**Load and follow** `references/plan-approval.md` end-to-end.

**Hard refuse:** do not execute, save plan/session-state, or update PM until explicit approve.
Approval = proceed-with-hypothesis (not freeze forever).

## Quality checklist (before present)

- [ ] Requirements/ACs clear; scope explicit  
- [ ] Research + design (or skip reasons); structure + tactical as required  
- [ ] Tasks complete (no optional tiers); risks noted  
- [ ] Visual attempted or skipped; plan presented for approval  

## Integration

`/work:refine` → requirements · `/work:execute` → plan + session-state · visual
`references/visual-approval.md` · PM `pm-integration.md` · audit P1s as next-cycle requirements.
