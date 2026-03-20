# Task Breakdown Patterns

Break down vertical slices into a flat list of required tasks organized by layer. All tasks derived from acceptance criteria are required — there are no optional tiers.

## Task Classification

Every task in the plan must be one of:

1. **Required** — Derived from acceptance criteria or necessary for the feature to work. These go in the task list.
2. **Out of Scope** — Genuinely future work not covered by acceptance criteria. These go in the Out of Scope section.

There is no middle ground. If a task maps to an acceptance criterion, it is required regardless of whether it feels like "polish" or "enhancement."

## Task Breakdown Template

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

## Breaking Down Complex Stories

### Vertical Split (Recommended)

```
Story 1: Basic create functionality
Story 2: Advanced validation
Story 3: Bulk operations
```

Each delivers complete, working functionality.

### Horizontal Split (Avoid)

```
Story 1: Build all backend
Story 2: Build all frontend
Story 3: Integration
```

Delays value delivery, increases integration risk.

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
