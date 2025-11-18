# Task Breakdown Patterns

This guide helps you break down vertical slices into manageable tasks using prioritization patterns.

## Priority Classification System

### P1 - Must Have (Core Functionality)
These tasks are essential for the story to be considered complete. Without them, the feature doesn't work.

**Characteristics:**
- Required for basic functionality
- Blocks user from completing the story's goal
- No workaround exists
- Part of acceptance criteria

**Examples:**
- Core domain logic
- Primary use case
- Essential data persistence
- Main user interface
- Critical path tests

### P2 - Should Have (Quality & Polish)
These tasks improve the feature but aren't strictly necessary for initial deployment.

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
These tasks add value but can be deferred to future iterations.

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

### P1 - Must Have ✅
Core tasks that must be completed:

#### Domain Layer
- [ ] Create [Entity] with fields: [list fields]
- [ ] Implement validation for [business rule]
- [ ] Add [domain service] for [complex logic]

#### Application Layer
- [ ] Implement [UseCase] with basic flow
- [ ] Create request/response DTOs
- [ ] Handle primary success scenario

#### Infrastructure Layer
- [ ] Add repository method: [method]
- [ ] Implement database persistence
- [ ] Create necessary migrations

#### Framework Layer
- [ ] Create [endpoint/UI component]
- [ ] Implement basic input validation
- [ ] Return appropriate responses

#### Testing
- [ ] Unit test for core business logic
- [ ] Integration test for persistence
- [ ] E2E test for happy path

### P2 - Should Have 🎯
Quality improvements and robustness:

#### Enhanced Validation
- [ ] Add comprehensive input validation
- [ ] Implement business rule validations
- [ ] Create custom error messages

#### Error Handling
- [ ] Add try-catch blocks
- [ ] Implement fallback behavior
- [ ] Create user-friendly error responses

#### Testing
- [ ] Add edge case tests
- [ ] Increase code coverage to 80%+
- [ ] Add performance tests

#### Operations
- [ ] Add structured logging
- [ ] Implement monitoring hooks
- [ ] Add health check endpoints

### P3 - Nice to Have 💫
Future enhancements:

#### User Experience
- [ ] Add loading states
- [ ] Implement optimistic updates
- [ ] Add confirmation dialogs
- [ ] Create tooltips/help text

#### Performance
- [ ] Add caching layer
- [ ] Implement pagination
- [ ] Optimize database queries
- [ ] Add request debouncing

#### Documentation
- [ ] Write API documentation
- [ ] Create user guides
- [ ] Add code comments
- [ ] Generate API client

#### Analytics
- [ ] Track feature usage
- [ ] Add performance metrics
- [ ] Create dashboards
- [ ] Set up alerts
```

## Estimation Guidelines

### Task Size Reference

| Task Type | Typical Duration |
|-----------|-----------------|
| Simple domain entity | 30-60 min |
| Use case implementation | 1-2 hours |
| Repository method | 30-60 min |
| API endpoint | 1-2 hours |
| Unit tests (per layer) | 30-60 min |
| Integration tests | 1-2 hours |
| E2E tests | 1-2 hours |

### Story Size Guidelines

**Small Story (1-4 hours)**
- 3-5 P1 tasks
- 2-3 P2 tasks
- 1-2 P3 tasks

**Medium Story (4-8 hours)**
- 5-8 P1 tasks
- 3-5 P2 tasks
- 2-3 P3 tasks

**Large Story (1-2 days)**
- 8-12 P1 tasks
- 5-8 P2 tasks
- 3-5 P3 tasks

**Too Large? (>2 days)**
- Consider splitting into multiple stories
- Each story should deliver value independently

## Breaking Down Complex Stories

### Horizontal Split (Not Recommended ❌)
```
Story 1: Build all backend
Story 2: Build all frontend
Story 3: Integration
```

### Vertical Split (Recommended ✅)
```
Story 1: Basic create functionality
Story 2: Advanced validation
Story 3: Bulk operations
```

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

Identify tasks that can be done in parallel:

```markdown
## Parallel Track A (Domain Expert)
- [ ] Design domain entities
- [ ] Implement business rules
- [ ] Write domain tests

## Parallel Track B (Infrastructure Expert)
- [ ] Set up database schema
- [ ] Create repository interfaces
- [ ] Implement persistence

## Parallel Track C (Frontend Expert)
- [ ] Design UI components
- [ ] Implement forms
- [ ] Add client validation

## Integration Point
- [ ] Connect all layers
- [ ] Run E2E tests
- [ ] Deploy feature
```

## Progressive Elaboration

Start with high-level tasks and elaborate as you learn:

### Initial Breakdown
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
  - [ ] Add registration form UI
  - [ ] Write tests for each layer
```

### During Implementation
```markdown
- [ ] Implement user registration
  - [x] Create User entity with email validation
  - [x] Add password hashing service (using bcrypt)
  - [ ] Implement RegisterUserUseCase
    - [ ] Validate unique email
    - [ ] Hash password
    - [ ] Save to database
    - [ ] Send welcome email
  - [ ] Create POST /register endpoint
  - [ ] Add registration form UI
  - [ ] Write tests for each layer
```

## Task Review Checklist

Before starting implementation, review your task breakdown:

- [ ] All P1 tasks identified?
- [ ] Dependencies marked?
- [ ] Parallel work opportunities identified?
- [ ] Estimates seem reasonable?
- [ ] Each task is atomic and testable?
- [ ] P2/P3 tasks can truly be deferred?
- [ ] Tasks align with acceptance criteria?