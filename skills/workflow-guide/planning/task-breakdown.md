# Task Breakdown Patterns

Break down vertical slices into manageable tasks using P1/P2/P3 prioritization.

## Priority Classification

### P1 - Must Have (Core Functionality)

Essential for story completion. Without these, the feature doesn't work.

**Characteristics:**
- Required for basic functionality
- Blocks user from completing goal
- No workaround exists
- Part of acceptance criteria

**Examples:**
- Core domain logic
- Primary use case
- Essential data persistence
- Main user interface
- Critical path tests

### P2 - Should Have (Quality & Polish)

Improves the feature but not strictly necessary for initial deployment.

**Characteristics:**
- Enhances user experience
- Improves maintainability
- Adds robustness
- Nice for production readiness

**Examples:**
- Comprehensive validation
- Detailed error messages
- Performance optimizations
- Extended test coverage
- Logging and monitoring

### P3 - Nice to Have (Enhancements)

Adds value but can be deferred to future iterations.

**Characteristics:**
- Convenience features
- Advanced functionality
- Aesthetic improvements
- Future-proofing

**Examples:**
- Advanced UI features
- Analytics integration
- Detailed documentation
- Performance metrics
- Extended customization

## Task Breakdown Template

```markdown
## Tasks for [Story ID]: [Story Title]

### P1 - Must Have
Core tasks that must be completed:

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
- [ ] Implement basic input validation

#### Testing
- [ ] Unit test for core business logic
- [ ] Integration test for persistence
- [ ] E2E test for happy path

### P2 - Should Have
Quality improvements:

- [ ] Comprehensive input validation
- [ ] Enhanced error handling
- [ ] Additional test coverage (80%+)
- [ ] Structured logging

### P3 - Nice to Have
Future enhancements:

- [ ] Loading states
- [ ] Caching layer
- [ ] Documentation
- [ ] Analytics
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

**Small Story**
- 3-5 P1 tasks
- 2-3 P2 tasks
- 1-2 P3 tasks

**Medium Story**
- 5-8 P1 tasks
- 3-5 P2 tasks
- 2-3 P3 tasks

**Large Story**
- 8-12 P1 tasks
- 5-8 P2 tasks
- 3-5 P3 tasks

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

- [ ] All P1 tasks identified?
- [ ] Dependencies marked?
- [ ] Parallel work opportunities identified?
- [ ] Each task is atomic and testable?
- [ ] P2/P3 tasks can truly be deferred?
- [ ] Tasks align with acceptance criteria?
