# Planning Templates

Reusable templates for planning vertical slices.

## Vertical Slice Template

Use for standard user story implementation:

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

## Quick Planning Template

For simpler stories that don't need full breakdown:

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

For larger features composed of multiple stories:

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

| Scenario | Template |
|----------|----------|
| Standard feature story | Vertical Slice |
| Small, clear change | Quick Planning |
| Multi-story feature | Epic |
| Research/investigation | Technical Spike |
| Fixing bugs | Bug Fix |
