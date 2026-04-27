# Planning Templates

Reusable templates for planning work in **vertical-slice** and **deliverable-partition** decomposition modes. See @workflow-guide for mode selection criteria.

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
- Mode-appropriate quality gates per @workflow-guide (`implementation/quality-checkpoints.md`)

#### Sub-issue 2: [Deliverable name]

[Same structure as above]

### Implementation Order

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
- When Claude Code asks "keep or remove?" on session exit, always choose "keep" in parallel workflows
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

When the scenario is ambiguous, default to vertical-slice for feature work and deliverable-partition for foundation, infrastructure, or cross-cutting work. See @workflow-guide for full mode selection criteria.
