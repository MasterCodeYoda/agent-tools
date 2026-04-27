# Task Breakdown Patterns

Break work into a flat list of required tasks. The shape of that list depends on decomposition mode (see @workflow-guide). All tasks derived from acceptance criteria are required — there are no optional tiers.

## Task Classification

Every task in the plan must be one of:

1. **Required** — Derived from acceptance criteria or necessary for the work to function. These go in the task list.
2. **Out of Scope** — Genuinely future work not covered by acceptance criteria. These go in the Out of Scope section.

There is no middle ground. If a task maps to an acceptance criterion, it is required regardless of whether it feels like "polish" or "enhancement."

## Vertical-Slice Task Breakdown Template

For vertical-slice mode (incremental feature work, especially user-facing). Tasks are organized by layer, completed bottom-up within the slice:

```markdown
## Tasks for [Story ID]: [Story Title]

All tasks are required for completion.

#### Domain Layer
- [ ] Create [Entity] with fields: [list fields]
- [ ] Implement validation for [business rule]

#### Application Layer
- [ ] Implement [UseCase] with basic flow
- [ ] Create request/response DTOs

#### Infrastructure Layer
- [ ] Add repository method: [method]
- [ ] Implement database persistence

#### Framework Layer
- [ ] Create [endpoint/UI component]
- [ ] Implement input validation

#### Testing
- [ ] Unit test for core business logic
- [ ] Integration test for persistence
- [ ] E2E test for happy path

### Out of Scope

Items not required by acceptance criteria but worth noting for future iterations:

- [Item 1] - [why it's deferred]
- [Item 2] - [why it's deferred]
```

## Deliverable-Partition Task Breakdown Template

For deliverable-partition mode (foundation, cross-cutting, or large-effort work). Tasks are organized per sub-issue, each owning a verbatim slice of the parent epic's acceptance criteria:

```markdown
## Tasks for Sub-issue [Sub-ID]: [Deliverable name]

All tasks are required for completion.

### Inherited parent ACs (verbatim, verified at this sub-issue's close)

- [ ] AC[n] — [exact text from parent, no paraphrasing]
- [ ] AC[m] — [exact text from parent, no paraphrasing]

### Sub-issue-specific tasks

- [ ] [Task derived from owned ACs — describes the deliverable, not a layer]
- [ ] [Task]
- [ ] [Task]

### Testing

- [ ] [Mode-appropriate test per @workflow-guide (`implementation/quality-checkpoints.md`)]
- [ ] [Negative-case / failure-mode test where the deliverable enforces a rule]

### Out of Scope

- [Item] - [why deferred, with tracking issue link if applicable]
```

The layer-by-layer breakdown does not apply: a deliverable may be a single artifact (a CI step, a validator rule, a hook installer) that doesn't span four layers. Plan tasks against the deliverable's actual shape.

## Estimation Guidelines

### Task Size Reference

| Task Type | Typical Scope |
|-----------|---------------|
| Simple domain entity | Small |
| Use case implementation | Small-Medium |
| Repository method | Small |
| API endpoint | Small-Medium |
| Unit tests (per layer) | Small |
| Integration tests | Medium |
| E2E tests | Medium |

### Story Size Guidelines

**Small Story**: 5-8 required tasks
**Medium Story**: 8-13 required tasks
**Large Story**: 13-20 required tasks

**Too Large?**
- Consider splitting into multiple stories
- Each story should deliver value independently

## Breaking Down Complex Work

### In Vertical-Slice Mode: Vertical Split (Recommended)

```
Story 1: Basic create functionality
Story 2: Advanced validation
Story 3: Bulk operations
```

Each delivers complete, working functionality through all layers.

### In Vertical-Slice Mode: Horizontal Split (Avoid)

```
Story 1: Build all backend
Story 2: Build all frontend
Story 3: Integration
```

Delays value delivery, increases integration risk. This anti-pattern applies *within* vertical-slice mode — building horizontal layers across stories defeats the slicing rationale.

### In Deliverable-Partition Mode: Per-Deliverable Split (Recommended)

```
Sub-issue 1: Library scaffold (owns parent AC1, AC3)
Sub-issue 2: Validator rules (owns parent AC2, AC4, AC5)
Sub-issue 3: CI pipeline (owns parent AC6, AC9)
Sub-issue 4: Documentation (owns parent AC7, AC8)
```

Each sub-issue ships its deliverable comprehensively to the AC subset it owns. The "horizontal" warning above does not apply — a single deliverable that spans all of one concern (e.g., the entire CI pipeline) is exactly the work in this mode.

### In Deliverable-Partition Mode: Avoid Premature Slicing

```
Sub-issue 1: Minimal CI + minimal validator + one library scaffolded
Sub-issue 2: Add second library + extend validator
Sub-issue 3: Add CI gates + ratchet validator strictness
```

Each "minimal X, full X later" boundary risks silently weakening parent ACs. Decompose by deliverable, not by maturity stages.

## Task Dependencies

### Identifying Dependencies

Mark tasks that depend on others:

```markdown
- [ ] Create User entity
- [ ] Create UserRepository (depends on: User entity)
- [ ] Implement CreateUserUseCase (depends on: UserRepository)
- [ ] Add POST /users endpoint (depends on: CreateUserUseCase)
```

### Parallel Work Opportunities

Identify tasks that can be done simultaneously:

```markdown
## Can Run in Parallel
- [ ] Design domain entities    | Track A
- [ ] Set up database schema    | Track B
- [ ] Design UI components      | Track C

## Integration Point (Sequential)
- [ ] Connect all layers
- [ ] Run E2E tests
```

## Progressive Elaboration

Start high-level, elaborate as you learn:

### Initial
```markdown
- [ ] Implement user registration
```

### After Analysis
```markdown
- [ ] Implement user registration
  - [ ] Create User entity with email validation
  - [ ] Add password hashing service
  - [ ] Implement RegisterUserUseCase
  - [ ] Create POST /register endpoint
  - [ ] Write tests for each layer
```

### During Implementation
```markdown
- [ ] Implement user registration
  - [x] Create User entity with email validation
  - [x] Add password hashing service
  - [ ] Implement RegisterUserUseCase
    - [ ] Validate unique email
    - [ ] Hash password
    - [ ] Save to database
  - [ ] Create POST /register endpoint
  - [ ] Write tests for each layer
```

## Task Review Checklist

Before starting implementation:

- [ ] All acceptance criteria covered by at least one task?
- [ ] Dependencies marked?
- [ ] Parallel work opportunities identified?
- [ ] Each task is atomic and testable?
- [ ] Out of Scope items are genuinely not in acceptance criteria?
- [ ] No required work hiding in Out of Scope?
