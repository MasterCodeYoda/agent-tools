# Quality Checkpoints

Verify work meets standards at the right granularity for its decomposition mode (see @workflow-guide):

- **Vertical-slice mode**: per-layer gates plus a slice-completion checkpoint.
- **Deliverable-partition mode**: per-deliverable gates plus a sub-issue-completion checkpoint with verbatim AC verification.

## Layer Quality Gates (vertical-slice mode)

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

## Vertical Slice Checkpoint (vertical-slice mode)

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
- [ ] Behavioral diff against main confirms only expected changes (when relevant)

## Deliverable-Partition Quality Gates (deliverable-partition mode)

Per-deliverable gates replace per-layer gates. Each deliverable's shape determines its gates — a validator rule, a CI step, a hook installer, a contract type, or an infrastructure module each have different verification surfaces.

### Generic Per-Deliverable Gates

**Code Quality:**
- [ ] Deliverable is comprehensively built to its owned AC subset (no "minimal-now, full-later" partial shape)
- [ ] No business logic leaking into the wrong concern
- [ ] Public surface (API, CLI, config keys) is documented at the deliverable level

**Testing:**
- [ ] Positive-case test demonstrates the deliverable performs its function
- [ ] Negative-case test demonstrates the deliverable rejects what it should reject (especially for validators, contracts, or rule-enforcement deliverables)
- [ ] Integration evidence — the deliverable functions inside the system it ships to (CI run, validator pass on real code, hook firing on a real commit)

**AC Verification:**
- [ ] Every parent AC inherited by this sub-issue is verified verbatim — not a paraphrased equivalent
- [ ] Verification evidence is recorded (test name, CI run, manual check) so audit-on-close has a paper trail

### Sub-issue Completion Checkpoint

**Functional:**
- [ ] Every inherited verbatim parent AC is verified
- [ ] Deliverable functions in the system it ships to (not just in isolation)

**Integration:**
- [ ] Deliverable composes with prior-shipped deliverables in the dependency chain
- [ ] No regression in prior-closed sub-issues' verified ACs

**Quality:**
- [ ] Tests pass
- [ ] Linting / type checks pass
- [ ] No new warnings
- [ ] Code follows patterns
- [ ] Behavioral diff against main confirms only expected changes (when relevant)

**Gap-prevention (project-level audit):**
- [ ] No parent AC has been silently weakened during decomposition
- [ ] If any AC could not be met, a tracking issue exists with explicit approval to defer

## Slice / Sub-issue Completion Protocol

### When to Commit

Commit at the completion of each **vertical slice** (story) in vertical-slice mode, or each **sub-issue** (deliverable) in deliverable-partition mode. NOT at:
- Session boundaries only
- Feature/epic completion only
- Arbitrary "stopping points"

### Slice / Sub-issue Completion Checklist

Before moving to the next slice or sub-issue:

- [ ] All acceptance criteria for THIS slice/sub-issue met (in deliverable-partition mode: every inherited verbatim parent AC verified)
- [ ] Tests pass for THIS slice/sub-issue
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

| Layer | Coverage Floor | Quality Verification | Mutation Target |
|-------|---------------|---------------------|-----------------|
| Domain | 85% | Mutation testing — verify tests catch injected faults | 80%+ mutation score |
| Application | 75% | Sabotage test — manually break logic, confirm tests fail | 70%+ (P2 if 50-69%) |
| Infrastructure | 60% | Integration completeness — all repository paths exercised | N/A |
| Framework | 50% | E2E happy path — critical user journeys covered | Targeted on validation logic only |

See @test-strategy (`references/test-quality.md`, `references/mutation-testing.md`) for mutation testing tools, configuration, and the sabotage test technique.

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
6. For non-trivial changes, is there a simpler, more elegant approach?

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
