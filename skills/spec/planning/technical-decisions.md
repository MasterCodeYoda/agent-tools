# Technical Decisions Documentation

This guide helps you document technical decisions made during vertical slice planning, ensuring future developers understand the "why" behind implementation choices.

## Decision Documentation Template

```markdown
# Technical Decisions for [Story/Feature]

## Decision: [Short Title]

### Status
[Proposed | Accepted | Deprecated | Superseded]

### Context
[What is the issue that we're seeing that is motivating this decision?]

### Decision
[What is the change that we're proposing and/or doing?]

### Consequences
[What becomes easier or more difficult because of this decision?]

### Alternatives Considered
1. **Option A**: [Description]
   - Pros: [Benefits]
   - Cons: [Drawbacks]
2. **Option B**: [Description]
   - Pros: [Benefits]
   - Cons: [Drawbacks]

### References
- [Link to relevant documentation]
- [Link to similar implementations]
```

## Common Decision Categories

### Architecture Decisions

#### Pattern Selection
```markdown
## Decision: Use Repository Pattern for Data Access

### Context
Need to abstract database operations for the Task entity.

### Decision
Implement repository pattern with interface in domain and implementation in infrastructure.

### Consequences
- ✅ Testable (can mock repository)
- ✅ Swappable implementations
- ✅ Clear separation of concerns
- ⚠️ Additional abstraction layer
- ⚠️ More initial setup code

### Alternatives Considered
1. **Direct database access**: Simpler but couples domain to infrastructure
2. **Active Record pattern**: Less separation but more Rails-like
3. **CQRS**: Too complex for current needs
```

#### State Management
```markdown
## Decision: Immutable Domain Entities

### Context
Need to ensure domain entities maintain valid state.

### Decision
Make domain entities immutable with methods returning new instances.

### Consequences
- ✅ Thread-safe by default
- ✅ Predictable state changes
- ✅ Easier to reason about
- ⚠️ More object creation
- ⚠️ Requires different update patterns
```

### Implementation Decisions

#### Technology Choices
```markdown
## Decision: Use Native Language Features Over Libraries

### Context
Choosing between native async/await vs. promise library.

### Decision
Use native async/await for asynchronous operations.

### Consequences
- ✅ No external dependencies
- ✅ Standard patterns
- ✅ Better IDE support
- ⚠️ Requires modern runtime
- ⚠️ Less advanced features

### YAGNI Applied
Not adding promise library until specific advanced features needed.
```

#### Data Storage
```markdown
## Decision: Start with In-Memory Repository

### Context
Building first vertical slice for task creation.

### Decision
Implement in-memory repository for initial development.

### Consequences
- ✅ Fast development cycle
- ✅ No infrastructure setup
- ✅ Easy testing
- ⚠️ Will need database later
- ⚠️ No persistence between restarts

### Migration Path
Replace with SQL repository in next iteration while keeping same interface.
```

### Testing Decisions

#### Test Strategy
```markdown
## Decision: Test Pyramid Approach

### Context
Determining testing strategy for vertical slices.

### Decision
Follow test pyramid: many unit tests, some integration, few E2E.

### Consequences
- ✅ Fast test execution
- ✅ Good coverage
- ✅ Quick feedback
- ⚠️ Need test infrastructure
- ⚠️ Multiple test types to maintain

### Test Distribution
- 70% unit tests (domain, use cases)
- 20% integration tests (repositories, external services)
- 10% E2E tests (critical user journeys)
```

## YAGNI Decision Framework

Document when you choose NOT to build something:

```markdown
## YAGNI: Advanced Search Features

### What We're NOT Building
Complex search with filters, sorting, and pagination.

### Why (YAGNI Reasoning)
- Current story only requires listing all items
- No user feedback requesting search
- Can be added as separate story later

### When to Reconsider
- User feedback indicates need
- Performance issues with full list
- Business requirement for filtering

### Minimal Alternative
Simple list with client-side filtering for now.
```

## Trade-off Documentation

### Performance vs. Simplicity
```markdown
## Trade-off: Simple Implementation Over Optimization

### Scenario
Choosing between optimized batch processing vs. simple loop.

### Decision
Use simple loop for initial implementation.

### Trade-off Analysis
| Factor | Simple Loop | Batch Processing |
|--------|------------|-----------------|
| Implementation Time | 1 hour | 4 hours |
| Complexity | Low | High |
| Performance | Adequate (<100 items) | Better (>1000 items) |
| Maintainability | Easy | Moderate |

### Decision Criteria
- Current load: <50 items
- Time constraint: Need to ship this week
- Team expertise: Limited batch processing experience

### Revisit When
- Processing >100 items regularly
- Performance becomes user issue
- Team gains expertise
```

### Flexibility vs. Specificity
```markdown
## Trade-off: Specific Solution for Current Need

### Scenario
Generic configurable system vs. specific implementation.

### Decision
Build specific solution for current use case.

### Reasoning
- Only one known use case
- Generic solution 3x more complex
- Can generalize when second use case appears
- YAGNI principle applies

### Future Generalization Triggers
- Second similar feature requested
- Pattern emerges across multiple stories
- Clear abstraction becomes apparent
```

## Decision Review Triggers

Document when to revisit decisions:

```markdown
## Review Triggers for [Decision]

### Time-based
- Review after 3 months
- Revisit before v2.0 release

### Metric-based
- If response time >2 seconds
- If memory usage >500MB
- If error rate >1%

### Event-based
- When adding second payment provider
- Before scaling to multiple regions
- If team size doubles

### Technical Debt
- Marked as technical debt
- Priority: Medium
- Estimated effort to change: 2 days
```

## Reversibility Assessment

```markdown
## Decision Reversibility: [High | Medium | Low]

### High Reversibility (Easy to Change)
- Using specific library
- Internal API design
- File organization

### Medium Reversibility (Some Effort)
- Database schema
- Public API contracts
- Core abstractions

### Low Reversibility (Difficult to Change)
- Programming language
- Database technology
- Distributed architecture

### Making Irreversible Decisions
- Gather more information
- Prototype if possible
- Get team consensus
- Document thoroughly
```

## Decision Log Format

Maintain a decision log for the project:

```markdown
# Decision Log

## 2024-01-15: Use Vertical Slicing
- **Category**: Architecture
- **Impact**: High
- **Reversibility**: Medium
- **Status**: Accepted

## 2024-01-16: Repository Pattern
- **Category**: Design Pattern
- **Impact**: Medium
- **Reversibility**: High
- **Status**: Accepted

## 2024-01-17: In-Memory Storage First
- **Category**: Implementation
- **Impact**: Low
- **Reversibility**: High
- **Status**: Accepted
- **Superseded by**: SQL Storage (2024-02-01)
```

## Quick Decision Checklist

Before making a technical decision:

- [ ] Is this decision necessary now? (YAGNI check)
- [ ] What problem does it solve?
- [ ] What are the trade-offs?
- [ ] How hard is it to change later?
- [ ] Does it align with vertical slicing principles?
- [ ] Have we considered simpler alternatives?
- [ ] Is the reasoning documented?
- [ ] When should we revisit this?