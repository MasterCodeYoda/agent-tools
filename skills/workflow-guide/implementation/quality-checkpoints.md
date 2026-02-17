# Quality Checkpoints

Verify each layer and complete vertical slice meets standards.

## Layer Quality Gates

### Domain Layer

**Code Quality:**
- [ ] No framework dependencies (pure business logic)
- [ ] No infrastructure dependencies (no database, files, network)
- [ ] Entities have validation
- [ ] Business rules enforced
- [ ] Value objects are immutable

**Testing:**
- [ ] Unit tests for entities
- [ ] Validation edge cases tested
- [ ] Business rule scenarios covered
- [ ] No mocking required (pure logic)

**Common Issues:**
- Anemic domain models (logic in wrong layer)
- Leaky abstractions (infrastructure concerns)
- Missing validation
- Mutable state without protection

### Infrastructure Layer

**Code Quality:**
- [ ] Implements repository interfaces correctly
- [ ] Proper connection/session management
- [ ] Transaction boundaries respected
- [ ] Error handling for external failures
- [ ] Proper resource cleanup

**Testing:**
- [ ] Integration tests for repositories
- [ ] Error scenarios tested
- [ ] No business logic in repositories

**Common Issues:**
- Business logic in repositories
- Missing error handling
- Resource leaks
- N+1 query problems

### Application Layer

**Code Quality:**
- [ ] Single responsibility per use case
- [ ] Clear request/response DTOs
- [ ] Proper orchestration logic
- [ ] Transaction management defined
- [ ] No UI/HTTP concerns

**Testing:**
- [ ] Unit tests with mocked dependencies
- [ ] All use case paths tested
- [ ] Error scenarios handled

**Common Issues:**
- Fat use cases (doing too much)
- Missing transaction boundaries
- Authorization in wrong layer

### Framework Layer

**Code Quality:**
- [ ] Thin controllers (delegation only)
- [ ] Complete input validation
- [ ] Proper HTTP status codes
- [ ] Consistent error response format
- [ ] Security headers configured

**Testing:**
- [ ] E2E tests for happy path
- [ ] Error response tests
- [ ] Input validation tests

**Common Issues:**
- Business logic in controllers
- Missing input validation
- Incorrect status codes

## Vertical Slice Checkpoint

### Before Completion

**Functional:**
- [ ] Acceptance criteria met
- [ ] Works end-to-end
- [ ] Error messages user-friendly
- [ ] Performance acceptable

**Integration:**
- [ ] All layers connected properly
- [ ] Data flows correctly
- [ ] Transactions work end-to-end

**Quality:**
- [ ] Tests pass
- [ ] Linting passes
- [ ] No new warnings
- [ ] Code follows patterns

## Slice Completion Protocol

### When to Commit

Commit at the completion of each **vertical slice** (story), NOT at:
- Session boundaries only
- Feature/epic completion only
- Arbitrary "stopping points"

### Slice Completion Checklist

Before moving to the next slice:

- [ ] All acceptance criteria for THIS slice met
- [ ] Tests pass for THIS slice
- [ ] Code committed with descriptive message and issue ID
- [ ] PM tool updated (issue marked Done)
- [ ] Session state updated (if tracking)

### Commit Command Template

```bash
git add [specific files for this slice]
git commit -m "$(cat <<'EOF'
feat(scope): description (ISSUE-ID)

- Implementation detail 1
- Implementation detail 2

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

### PM Tool Update

Immediately after commit:
- **Linear**: Update issue state to Done
- **Jira**: Transition issue to Done
- **Manual**: Update issue status in your tracker

### Warning Signs

You may have batched commits if:
- More than one story's worth of changes uncommitted
- Multiple Linear/Jira issues stuck in "In Progress"
- Large `git diff` output spanning multiple features
- Anxiety about losing accumulated work

## Security Checkpoint

### Basic Security

- [ ] Input validation on all endpoints
- [ ] SQL injection prevention
- [ ] Authentication where needed
- [ ] Authorization checks in place
- [ ] Sensitive data not logged
- [ ] Secrets not in code

### Data Protection

- [ ] Passwords hashed (never plain text)
- [ ] PII handled appropriately
- [ ] Encryption for sensitive data

## Performance Checkpoint

### Response Time

- [ ] API response reasonable
- [ ] No obvious N+1 queries
- [ ] Database queries efficient

### Resource Usage

- [ ] No memory leaks
- [ ] Connections properly pooled
- [ ] Appropriate timeouts

## Test Strategy

### Test Pyramid

```
    E2E     (10%) - Critical paths
  Integration (20%) - Repository, services
    Unit    (70%) - Domain, use cases
```

For testing methodology and strategy selection, see @test-strategy.

### Coverage Floors and Quality Verification

Coverage is a **floor** (find untested code), not a goal. Use quality verification to ensure tests actually catch bugs.

| Layer | Coverage Floor | Quality Verification |
|-------|---------------|---------------------|
| Domain | 85% | Mutation testing — verify tests catch injected faults |
| Application | 75% | Sabotage test — manually break logic, confirm tests fail |
| Infrastructure | 60% | Integration completeness — all repository paths exercised |
| Framework | 50% | E2E happy path — critical user journeys covered |

See @test-strategy (`references/test-quality.md`) for mutation testing tools and the sabotage test technique.

## Pre-Commit Checklist

Before committing a slice:

- [ ] All acceptance criteria met
- [ ] Tests written and passing
- [ ] Linting passes
- [ ] No console errors
- [ ] Plan checkbox updated
- [ ] Session state reflects progress

## Quality Questions

Before marking complete, ask:

1. Would you deploy this to production?
2. Can another developer understand this?
3. Are edge cases handled?
4. Is the code maintainable?
5. Does it follow team patterns?

## When Quality Can't Be Met

If standards can't be met immediately:

```markdown
## Technical Debt Record
- **Issue**: [What standard wasn't met]
- **Reason**: [Why deferred]
- **Impact**: [Risk]
- **Remediation**: [How to fix]
- **Priority**: [When to address]
```

Document in session state and create follow-up task.
