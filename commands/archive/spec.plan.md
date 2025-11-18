# /spec.plan - Plan Implementation with Linear

Plan the implementation of a feature or fix tracked in Linear.

## Instructions

### 1. Identify the Linear Issue

Get the Linear issue ID (e.g., LIN-123) and review:
- Issue title and description
- Acceptance criteria
- Priority and timeline
- Related issues or dependencies

### 2. Analyze Current State

```bash
# Review existing code structure
tree src/ -L 3

# Search for related code
grep -r "relevant_term" src/

# Check for existing tests
pytest -k "relevant_test" --collect-only
```

### 3. Create Implementation Plan

#### Vertical Slice Planning

For each user story, identify the minimal slice through all layers:

```markdown
## Story: [LIN-123] User can create a task

### Vertical Slice:
1. **Domain Layer**
   - [ ] Create Task entity (minimal properties)
   - [ ] Add validation rules

2. **Application Layer**
   - [ ] CreateTaskUseCase
   - [ ] CreateTaskRequest/Response models

3. **Infrastructure Layer**
   - [ ] TaskRepository.create() method
   - [ ] Database migration (if needed)

4. **Framework Layer**
   - [ ] POST /tasks endpoint
   - [ ] Request validation

5. **Tests**
   - [ ] Unit tests for entity
   - [ ] Unit tests for use case
   - [ ] Integration test for repository
   - [ ] E2E test for API endpoint

### Time Estimate: 2-3 hours

### Dependencies:
- None (first story in feature)

### Risk Assessment:
- Low complexity
- Standard pattern
- No external dependencies
```

### 4. Break Down into Tasks

Create subtasks in Linear or track locally:

```markdown
## Tasks for LIN-123:

### P1 - Must Have (for story completion)
- [ ] Task entity with title and description
- [ ] Create use case implementation
- [ ] Repository create method
- [ ] API endpoint
- [ ] Basic tests

### P2 - Should Have (improvements)
- [ ] Additional validation
- [ ] Error handling improvements
- [ ] Comprehensive test coverage

### P3 - Nice to Have (polish)
- [ ] Performance optimization
- [ ] Additional logging
- [ ] Documentation
```

### 5. Document Technical Decisions

```markdown
## Technical Decisions:

### Approach:
- Using vertical slicing (not horizontal layers)
- Following file-per-use-case pattern
- Implementing minimal viable slice first

### Patterns:
- Repository pattern for data access
- Use case pattern for business logic
- Result pattern for error handling

### Trade-offs:
- Starting simple (can add complexity later)
- No premature optimization
- YAGNI principle applied
```

### 6. Create Planning Document

Save the plan in `planning/LIN-123-implementation-plan.md`:

```markdown
# LIN-123: [Feature Title]

## Story
As a [user type], I want [capability] so that [benefit].

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Implementation Plan
[Vertical slice details]

## Tasks
[Task breakdown]

## Technical Decisions
[Key decisions and rationale]

## Testing Strategy
- Unit tests: [approach]
- Integration tests: [approach]
- E2E tests: [approach]

## Definition of Done
- [ ] Code complete
- [ ] All tests passing
- [ ] Code review approved
- [ ] Documentation updated
- [ ] No quality issues (`./scripts/check_all.py` passes)
```

### 7. Update Linear

Update the Linear issue with:
- Link to planning document
- Time estimate
- Any blockers or dependencies identified
- Status change to "In Progress"

### 8. Get Feedback (Optional)

If unsure about approach:
- Share plan with team
- Request review on technical decisions
- Adjust based on feedback

## Planning Checklist

Before starting implementation:
- [ ] Linear issue understood
- [ ] Acceptance criteria clear
- [ ] Vertical slice identified
- [ ] Tasks broken down
- [ ] Technical approach decided
- [ ] Testing strategy defined
- [ ] Time estimate provided
- [ ] Linear issue updated

## Remember

- Plan vertically, not horizontally
- Start with the smallest viable slice
- Document decisions for future reference
- Keep Linear updated for team visibility
- YAGNI - don't over-engineer the plan