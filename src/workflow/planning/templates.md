# Planning Templates

Reusable templates for planning work in **vertical-slice** and **deliverable-partition** decomposition modes. See @workflow for mode selection criteria.

## Vertical Slice Template

Use for standard user story implementation in vertical-slice mode (incremental feature work delivering observable value, especially user-facing).

```markdown
## Story: [WORK-ITEM-ID] Story Title

### User Story
As a [user type], I want [capability] so that [benefit].

### Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

### Vertical Slice Breakdown

#### 1. Domain Layer
- **Entities/Models**
  - [ ] Entity name (properties: field1, field2)
  - [ ] Value objects if needed
- **Business Rules**
  - [ ] Validation logic
  - [ ] Domain-specific constraints
- **Domain Services** (if needed)
  - [ ] Complex business operations

#### 2. Application Layer
- **Use Cases**
  - [ ] PrimaryUseCase (main flow)
- **DTOs**
  - [ ] Request model
  - [ ] Response model

#### 3. Infrastructure Layer
- **Repository Methods**
  - [ ] create() / save()
  - [ ] findById() / get()
- **External Services**
  - [ ] API integrations
- **Database**
  - [ ] Schema changes
  - [ ] Migrations

#### 4. Framework Layer
- **API/UI**
  - [ ] Endpoint/Component
  - [ ] Input validation
  - [ ] Response formatting

#### 5. Testing Strategy
- **Unit Tests**
  - [ ] Domain entity tests
  - [ ] Use case tests
- **Integration Tests**
  - [ ] Repository tests
- **E2E Tests**
  - [ ] Complete flow test

### Dependencies
- Blocked by: [List any blockers]
- Depends on: [List dependencies]

### Risk Assessment
- **Complexity**: Low / Medium / High
- **Unknowns**: [List technical unknowns]
```

## Deliverable-Partition Template

Use for foundation, cross-cutting, or large-effort work where vertical slicing risks process-induced slowdown or gaps in requirements / Definition of Done conformance.

**Sub-cases:**

- *Foundation / pre-first-release* — greenfield scaffolding, validators, CI/CD, base contracts. No deployed surface yet to slice through.
- *Cross-cutting / large-effort* — post-first-release work like contract-first shared-library changes, compliance roll-outs, framework migrations, pipeline epics decomposed by event boundary.

The mechanism is identical for both sub-cases: decompose by deliverable, AC traceability matrix in the parent, verbatim AC ownership in each sub-issue, per-deliverable Definition of Done.

```markdown
## Epic: [WORK-ITEM-ID] Epic Title

### Mode

Deliverable-partition — sub-case: [Foundation / pre-first-release | Cross-cutting / large-effort]

### Overview

[What this epic produces, named in deliverable terms — not as user-facing increments]

### Why deliverable-partition (not vertical slice)

[1–2 sentences explaining the selection. Examples: "No deployed surface yet; epic produces N distinct artifacts each with its own AC subset." Or: "Contract change must land before downstream consumers can adopt; vertical slicing would force partial-shape commits."]

### Parent Acceptance Criteria

- [ ] AC1 — [verbatim text]
- [ ] AC2 — [verbatim text]
- [ ] AC3 — [verbatim text]
- [ ] AC4 — [verbatim text]

### AC Traceability Matrix

| Parent AC | Owning sub-issue | Verified at |
|-----------|------------------|-------------|
| AC1 | Sub-issue 1 | Sub-issue 1 close |
| AC2 | Sub-issue 2 | Sub-issue 2 close |
| AC3 | Sub-issue 1 | Sub-issue 1 close |
| AC4 | Sub-issue 3 | Sub-issue 3 close |

Every parent AC must appear in exactly one row. Audit-on-close: zero orphans before parent epic closes.

### Sub-issue Breakdown

#### Sub-issue 1: [Deliverable name]

**Inherits (verbatim from parent, verified at this sub-issue's close):**

- [ ] AC1 — [exact text from parent, no paraphrasing]
- [ ] AC3 — [exact text from parent, no paraphrasing]

**Sub-issue-specific tasks:**

- [ ] [Task derived from owned ACs]
- [ ] [Task]

**Dependencies:**

- Blocked by: [other sub-issues, if any]

**Definition of Done:**

- All inherited parent ACs verified
- Sub-issue-specific tasks complete
- Mode-appropriate quality gates per @workflow (`execution/quality-checkpoints.md`)

#### Sub-issue 2: [Deliverable name]

[Same structure as above]

### Implementation Order

0. [Prefactoring / enabling work, if any] — behavior-preserving, committed separately before feature work (omit when the change is already easy)
1. Sub-issue 1 — [dependency rationale]
2. Sub-issue 2 — [dependencies on 1, if any]
3. Continue...

### Gap-prevention check (run before parent epic closes)

- [ ] Every parent AC appears in exactly one sub-issue's "Inherits" block.
- [ ] No sub-issue has paraphrased ACs; each is verbatim from the parent.
- [ ] Every closed sub-issue verified its inherited ACs.
- [ ] Any deferred AC has a tracking issue + explicit approval; otherwise the parent does not close.

### Out of Scope

- [Item] - [why deferred, with tracking issue link if applicable]
```

The template scales down for smaller deliverable-partition work (fewer sub-issues, shorter AC list). Use the full structure even at small scale — the matrix and verbatim AC blocks are the gap-prevention mechanism, not optional decoration.

## Quick Planning Template

For simpler stories in vertical-slice mode that don't need full layer breakdown:

```markdown
## Story: [ID] Title

**Goal**: One-sentence description

**Slice**:
- Domain: [What entities/logic]
- Application: [What use cases]
- Infrastructure: [What persistence]
- Framework: [What endpoints/UI]

**Tests**: [Testing approach]

**Risks**: [Main concerns]
```

## Epic Planning Template

For larger features composed of multiple stories in vertical-slice mode. For deliverable-partition epics (foundation, cross-cutting, large-effort work), use the Deliverable-Partition Template above instead.

```markdown
# Epic: [EPIC-ID] Epic Title

## Overview
[High-level description of the feature]

## Business Value
[Why this matters to users/business]

## Stories Breakdown

### Story 1: [Title]
- **Priority**: P1
- **Slice**: [Brief description]
- **Dependencies**: None

### Story 2: [Title]
- **Priority**: P1
- **Slice**: [Brief description]
- **Dependencies**: Story 1

### Story 3: [Title]
- **Priority**: P2
- **Slice**: [Brief description]
- **Dependencies**: Story 1

## Implementation Order
0. [Prefactoring / enabling work, if any] - behavior-preserving, committed separately before feature work (omit when the change is already easy)
1. Story 1 - [Reason]
2. Story 2 - [Reason]
3. Story 3 - [Reason]

## Parallel Execution Potential

Identify which stories can be worked on concurrently in separate worktrees.

| Group | Stories | Dependencies | Notes |
|-------|---------|--------------|-------|
| A (sequential) | Story 1 | None | Must complete first — foundational |
| B (parallel) | Story 2, Story 3 | Story 1 | Independent after Story 1; can run in separate worktrees |

**Parallel execution prerequisites**:
- Use `/workflow:plan --worktree` to create a worktree at planning time with docs committed, OR manually commit planning docs before running `/workflow:execute --worktree`
- Stories in the same parallel group must not modify the same files
- Each parallel session uses: `/workflow:execute --worktree ./planning/<project>/`
- Merge one branch at a time, running full tests after each merge

**Worktree safety**:
- Sessions NEVER remove worktrees — cleanup is a separate, user-initiated action after all sessions complete
- Respect the worktree exit prompt behavior of your agent (see @git (worktree-create) and @git (worktree-delete) for agent-specific guidance). In parallel workflows, prefer keeping the worktree until after merging.
- Only the user removes worktrees, after all branches are merged

## Success Metrics
- [ ] Metric 1
- [ ] Metric 2

## Rollout Plan
- Phase 1: [What ships first]
- Phase 2: [What ships next]
```

## Technical Spike Template

For research/investigation stories:

```markdown
## Spike: [ID] Investigation Topic

### Question to Answer
[What we need to learn]

### Success Criteria
- [ ] Question 1 answered
- [ ] Question 2 answered
- [ ] Decision made on approach

### Investigation Plan
1. Research [topic]
2. Prototype [solution]
3. Measure [metrics]
4. Document findings

### Timebox
Maximum: [time limit]

### Deliverables
- [ ] Findings document
- [ ] Proof of concept (optional)
- [ ] Recommendation
- [ ] Next steps
```

## Bug Fix Template

For vertical slices that fix issues:

```markdown
## Bug: [BUG-ID] Issue Description

### Problem
[What's broken]

### Root Cause
[Why it's broken - may need investigation]

### Solution
[How to fix it]

### Affected Layers
- [ ] Domain: [Changes needed]
- [ ] Application: [Changes needed]
- [ ] Infrastructure: [Changes needed]
- [ ] Framework: [Changes needed]

### Testing
- [ ] Reproduce bug
- [ ] Verify fix
- [ ] Regression tests
- [ ] Edge cases

### Prevention
[How to prevent similar issues]
```

## Implementation Plan Document Template

The plan document written by `/workflow:plan` to `./planning/<project>/implementation-plan.md`. The YAML frontmatter carries dependency metadata (`blocks` / `blocked_by` / `parallelizable_with`) that downstream orchestration (`/swarm`) reads to schedule parallel waves. The Breakdown section has both mode variants — Variant A (vertical-slice) and Variant B (deliverable-partition); use the one matching the selected decomposition mode (see @workflow for selection criteria).

```markdown
---
project: [project-name]
work_item: [ISSUE-ID or null]
blocks: []                  # items this work blocks (issue keys or item names)
blocked_by: []              # items that must complete before this work starts
parallelizable_with: []     # peer items safe to run concurrently (no shared files/ordering)
---
# Implementation Plan: [Feature Title]

## Approach

[High-level approach description]
[Key architectural decisions]
[Why this approach was chosen]

## Research grounding

- **Codebase research:** `./planning/<project>/codebase-research.md` (or light / skipped — reason)
- **Summary:** [2–5 sentences from research — how it works today and edit blast radius]
- **Discard research if:** [staleness condition]

Do not invent modules or paths that research did not establish. Full craft:
@workflow (`references/context-engineering.md`).

## Design

- **Design discussion:** `./planning/<project>/design-discussion.md` (or light / skipped — reason)
- **Confirm:** design still holds for these ACs — if not, stop and re-enter refine (do not
  silently rewrite ACs here)
- **Patterns to follow / reject:** [from design]
- **Open questions closed for implement:** [list or none]

## Structure outline

**Human deep-read surface.** Vertical phases with verification (vertical-slice mode) or
deliverable order with per-deliverable verification (deliverable-partition). Not a horizontal
“all DB → all services → all API → all UI” dump when vertical-slice applies.

| Phase | What lands | Verify before next |
|-------|------------|--------------------|
| 1 | … | [test / command / check] |
| 2 | … | … |

**Seam / signature shape (when useful):** [types, endpoints, interfaces — C-header density]

## Intended changes (snippets)

**Tactical segment — agent fuel; human spot-check.** For each non-obvious edit site, give path
+ short snippet or precise before→after shape. Compression of **intent**, not the full final PR.

### [path/or/symbol]

```text
// before (sketch) → after (sketch)
```

- **Why:** …
- **Verify:** [test / command / manual check after this step]
- **Structure phase:** [which phase above]

### [next edit site]

…

## Breakdown (use the variant matching selected mode)

### Variant A: Vertical Slice Breakdown (vertical-slice mode)

#### Slice 1: [Core Functionality]

**Issue**: [ISSUE-ID]
**Commit Point**: After all layers complete for this slice
**PM Update**: Mark [ISSUE-ID] as Done

##### Domain Layer

- [ ] [Entity/model with specific fields]
- [ ] [Validation rules]
- [ ] [Business logic]

##### Application Layer

- [ ] [Use case implementation]
- [ ] [Request/Response DTOs]

##### Infrastructure Layer

- [ ] [Repository methods needed]
- [ ] [External service integrations]
- [ ] [Database changes]

##### Framework Layer

- [ ] [API endpoints or UI components]
- [ ] [Input validation]

##### Slice Completion

- [ ] Tests passing
- [ ] Code committed with issue reference
- [ ] PM tool updated (issue → Done)

#### Slice 2: [Enhancement] (if applicable)

[Same structure - include Issue, Commit Point, PM Update, and Slice Completion]

### Variant B: Deliverable Breakdown (deliverable-partition mode)

#### Parent Acceptance Criteria

- [ ] AC1 — [verbatim text]
- [ ] AC2 — [verbatim text]
- [ ] AC3 — [verbatim text]

#### AC Traceability Matrix

| Parent AC | Owning sub-issue | Verified at |
|-----------|------------------|-------------|
| AC1 | Sub-issue 1 | Sub-issue 1 close |
| AC2 | Sub-issue 2 | Sub-issue 2 close |
| AC3 | Sub-issue 1 | Sub-issue 1 close |

Every parent AC must appear in exactly one row. Audit-on-close: zero orphans before parent epic closes.

#### Sub-issue 1: [Deliverable name]

**Issue**: [SUB-ISSUE-ID]
**Commit Point**: After deliverable ships and all inherited ACs verified
**PM Update**: Mark [SUB-ISSUE-ID] as Done

**Inherited parent ACs (verbatim, verified at this sub-issue's close):**

- [ ] AC1 — [exact text from parent]
- [ ] AC3 — [exact text from parent]

**Sub-issue-specific tasks:**

- [ ] [Task derived from owned ACs]
- [ ] [Task]

**Dependencies:**

- Blocked by: [other sub-issues, if any]

**Sub-issue Completion:**

- [ ] All inherited verbatim parent ACs verified
- [ ] Tests passing (positive + negative cases per @workflow `execution/quality-checkpoints.md`)
- [ ] Code committed with sub-issue reference
- [ ] PM tool updated (sub-issue → Done)

#### Sub-issue 2: [Deliverable name]

[Same structure]

#### Gap-prevention check (run before parent epic closes)

- [ ] Every parent AC appears in exactly one sub-issue's "Inherited" block.
- [ ] No sub-issue has paraphrased ACs; each is verbatim from the parent.
- [ ] Every closed sub-issue verified its inherited ACs.
- [ ] Any deferred AC has a tracking issue + explicit approval; otherwise the parent does not close.

## Task Breakdown

All tasks below are required for completion. Every task maps to an acceptance criterion or is necessary for the feature to work correctly. There are no optional tiers — if it's in this list, it must be done before the work is considered complete.

- [ ] [Task 1] - [brief description]
- [ ] [Task 2] - [brief description]
- [ ] [Task 3] - [brief description]
- [ ] [Task 4] - [brief description]
- [ ] [Task 5] - [brief description]

### Out of Scope

Items not required by acceptance criteria but worth noting for future iterations:

- [Item 1] - [why it's deferred]
- [Item 2] - [why it's deferred]

## Technical Decisions

### [Decision 1]

- **Context**: [Why this decision matters]
- **Options**: [Alternatives considered]
- **Decision**: [What we chose]
- **Rationale**: [Why]

### [Decision 2]

[Same format]

## Testing Strategy

- **Approach**: [Select testing strategy — see @test-strategy]
- **Unit Tests**: [Approach for domain/use case testing]
- **Integration Tests**: [Approach for infrastructure testing]
- **E2E Tests**: [Approach for complete flow testing]

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| [Risk 1] | Low/Med/High | Low/Med/High | [Strategy] |

## Implementation Order

0. [Prefactoring / enabling work, if any] - behavior-preserving, committed separately before
   feature work begins (omit this step entirely when the change is already easy — see
   §Prefactoring Assessment)
1. [First task/slice] - [Why first]
2. [Second task/slice] - [Dependencies]
3. [Continue...]

## Definition of Done

### Per Slice/Story

- [ ] All layers implemented for this slice
- [ ] Tests passing for this slice
- [ ] Code committed with issue reference
- [ ] PM tool updated (issue → Done)

### Per Feature (Epic)

- [ ] All slices complete (using above checklist per slice)
- [ ] All tasks complete — no deferred items
- [ ] All acceptance criteria verified against the plan before closing
- [ ] Code reviewed
- [ ] Documentation updated
- [ ] Deployed to staging
```

## Session State Template (plan-time initialization)

Written by `/workflow:plan` to `./planning/<project>/session-state.md` after plan approval. The generic schema, as it evolves during execution, is in @workflow › Session Continuity.

```yaml
---
project: [project-name]
requirements_source: [file|pm]
work_item: [ISSUE-ID]          # Set when PM issue is linked
pm_tool: [linear|jira|manual]  # Set when PM tool is detected
session_count: 0
status: planned
progress:
  total_tasks: [count from plan]
  completed: 0
  percent: 0%
current_layer: not_started
branch: <type>/<issue-key or description>
worktree: <path>  # Only set when using --worktree; absolute path to worktree directory
visual_plan: "<path-to-visual-plan.html> | mode=static-html | status=published"  # optional; or "skipped — <reason>"
created: [timestamp]
---

## Status
Planning complete. Awaiting user approval.

## Next Steps
1. User reviews and approves plan
2. Run `/workflow:execute ./planning/[project]/` when ready

## Session History
[Empty - will be populated during execution]
```

`visual_plan` is **metadata only**. Execute and continue orientation use
`implementation-plan.md` (+ session status), never the visual HTML body. Full contract:
@workflow (`planning/references/visual-approval.md`).

## Plan Approval Prompt

Presented by `/workflow:plan` at the approval gate — before any documents are saved, PM tools updated, or execution started.

When a visual approval surface was published or skipped, include the **Visual plan** line (path
or skip reason). Omit the line only when the visual step was not attempted at all (policy
`never`). Approval always applies to the markdown plan that will be saved.

```markdown
## Plan Ready for Review

**Project**: [project-name]
**Source**: [requirements.md path, issue ID, or description]

### Summary

[2-3 sentence overview of the approach]

### Slices

1. **[Slice 1 name]** - [brief description] ([N] tasks)
2. **[Slice 2 name]** - [brief description] ([N] tasks)

### Task Breakdown

- **Required**: [N] tasks (all derived from acceptance criteria)
- **Out of Scope**: [N] items noted for future iterations

### Key Technical Decisions

- [Decision 1]: [brief rationale]
- [Decision 2]: [brief rationale]

**Visual plan**: [absolute or repo-relative path to visual-plan.html] (mode=static-html) — review surface only; executable plan is markdown below
<!-- or: **Visual plan**: skipped — <reason> -->

**Will be saved to**: `./planning/[project]/implementation-plan.md`
(Executable source of truth for `/workflow:execute`. The visual plan is presentation only.)

---

**How would you like to proceed?**

1. **Approve & Save** - Finalize planning documents (and update PM tool if applicable)
2. **Approve & Execute** - Save plan, then begin implementation immediately
3. **Revise** - Make changes to the plan before approving
```

## Parallel Execution Prompts (plan-time)

Presented by `/workflow:plan` (Step 7) only when the plan has 2+ independent slices/stories.

**If `WORKTREE_MODE=true`** (worktree already created and docs committed):

```markdown
### Parallel Execution Available

This plan has [N] independent slices that can be executed in parallel using separate worktrees.

Planning docs are already committed in this worktree. To start parallel execution:

1. **In this terminal** (worktree already exists):
   ```bash
   /workflow:execute ./planning/[project]/
   ```
   Execute will detect the existing worktree from session-state.md — no `--worktree` flag needed.

2. **In a new terminal** (for additional parallel sessions):
   ```bash
   /workflow:execute --worktree ./planning/[project]/
   ```

**Note**: Only use parallel execution when slices are truly independent (don't modify the same files).
```

**If `WORKTREE_MODE=false`** (no worktree):

```markdown
### Parallel Execution Available

This plan has [N] independent slices that can be executed in parallel using separate worktrees:

| Group | Slices | Can Run In Parallel |
|-------|--------|---------------------|
| A | [Slice 1] | Sequential (foundational) |
| B | [Slice 2, Slice 3] | Yes — after Group A |

**To execute in parallel:**

1. **Commit planning docs first** (required for worktrees):
   ```bash
   git add ./planning/[project]/ && git commit -m "docs: add planning for [project]"
   ```
2. **Start separate sessions**, each in its own terminal:
   ```bash
   /workflow:execute --worktree ./planning/[project]/
   ```
3. Each session will create its own worktree and branch automatically.

**Or** use `/workflow:plan --worktree` next time to automate worktree creation at planning time.

**Note**: Only use parallel execution when slices are truly independent (don't modify the same files).
```

## Template Selection Guide

| Scenario | Template | Mode |
|----------|----------|------|
| Standard user-facing feature story | Vertical Slice | vertical-slice |
| Small, clear feature change | Quick Planning | vertical-slice |
| Multi-story user-facing feature | Epic Planning | vertical-slice |
| Foundation / pre-first-release scaffolding (libraries, validators, CI/CD, base contracts) | Deliverable-Partition | deliverable-partition (Foundation sub-case) |
| Cross-cutting / large-effort post-first-release work (contract-first changes, compliance roll-outs, framework migrations, pipeline epics) | Deliverable-Partition | deliverable-partition (Cross-cutting sub-case) |
| Research/investigation | Technical Spike | mode-agnostic |
| Fixing bugs | Bug Fix | mode-agnostic |

When the scenario is ambiguous, default to vertical-slice for feature work and deliverable-partition for foundation, infrastructure, or cross-cutting work. See @workflow for full mode selection criteria.
