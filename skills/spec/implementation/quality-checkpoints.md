# Quality Checkpoints

This guide defines quality checkpoints to verify each layer and the complete vertical slice meets standards before moving forward.

## Layer-Specific Quality Gates

### Domain Layer Checkpoint

#### Code Quality
```markdown
## Domain Layer Quality Checklist
- [ ] No framework dependencies (pure business logic)
- [ ] No infrastructure dependencies (no database, files, network)
- [ ] All entities have validation
- [ ] Business rules enforced in constructors/methods
- [ ] Immutable value objects where appropriate
- [ ] Domain events defined (if using event-driven)
```

#### Testing Requirements
```markdown
## Domain Testing Checklist
- [ ] Unit tests for all entities
- [ ] Validation edge cases tested
- [ ] Business rule scenarios covered
- [ ] No mocking required (pure logic)
- [ ] Test coverage >90%
- [ ] Tests run in <1 second
```

#### Common Issues to Check
- Anemic domain models (logic in wrong layer)
- Leaky abstractions (infrastructure concerns)
- Missing validation
- Mutable state without protection
- Complex constructors without factories

### Infrastructure Layer Checkpoint

#### Code Quality
```markdown
## Infrastructure Layer Quality Checklist
- [ ] Implements repository interfaces correctly
- [ ] Proper connection/session management
- [ ] Transaction boundaries respected
- [ ] Error handling for external failures
- [ ] Proper resource cleanup (using/finally)
- [ ] Configuration externalized
```

#### Testing Requirements
```markdown
## Infrastructure Testing Checklist
- [ ] Integration tests for repositories
- [ ] Test with real or in-memory database
- [ ] Error scenarios tested (connection failures)
- [ ] Transaction rollback tested
- [ ] Performance within acceptable limits
- [ ] No business logic in repositories
```

#### Common Issues to Check
- Business logic in repositories
- Missing error handling
- Resource leaks
- N+1 query problems
- Missing indexes for queries
- Incorrect transaction scope

### Application Layer Checkpoint

#### Code Quality
```markdown
## Application Layer Quality Checklist
- [ ] Single responsibility per use case
- [ ] Clear request/response DTOs
- [ ] Proper orchestration logic
- [ ] Transaction management defined
- [ ] Cross-cutting concerns handled
- [ ] No UI/HTTP concerns
```

#### Testing Requirements
```markdown
## Application Testing Checklist
- [ ] Unit tests with mocked dependencies
- [ ] All use case paths tested
- [ ] Error scenarios handled
- [ ] Transaction behavior verified
- [ ] Authorization rules tested
- [ ] Test coverage >80%
```

#### Common Issues to Check
- Fat use cases (doing too much)
- Missing transaction boundaries
- Incomplete error handling
- Authorization in wrong layer
- Direct infrastructure access
- Missing DTO validation

### Framework Layer Checkpoint

#### Code Quality
```markdown
## Framework Layer Quality Checklist
- [ ] Thin controllers (delegation only)
- [ ] Complete input validation
- [ ] Proper HTTP status codes
- [ ] Consistent error response format
- [ ] Security headers configured
- [ ] CORS settings appropriate
```

#### Testing Requirements
```markdown
## Framework Testing Checklist
- [ ] E2E tests for happy path
- [ ] Error response tests
- [ ] Input validation tests
- [ ] Authentication/authorization tests
- [ ] Rate limiting tested (if applicable)
- [ ] API documentation updated
```

#### Common Issues to Check
- Business logic in controllers
- Missing input validation
- Incorrect status codes
- Inconsistent response format
- Missing error handling
- Security vulnerabilities

## Complete Vertical Slice Checkpoint

### Functional Verification
```markdown
## Functionality Checklist
- [ ] Acceptance criteria met
- [ ] User can complete the story end-to-end
- [ ] All edge cases handled
- [ ] Error messages user-friendly
- [ ] Performance acceptable
- [ ] Works in target environment
```

### Integration Verification
```markdown
## Integration Checklist
- [ ] All layers connected properly
- [ ] Data flows correctly through layers
- [ ] Transactions work end-to-end
- [ ] External services integrated
- [ ] Monitoring/logging in place
- [ ] Deployment successful
```

### Non-Functional Requirements
```markdown
## NFR Checklist
- [ ] Response time <2 seconds
- [ ] Handles concurrent requests
- [ ] Graceful degradation on failures
- [ ] Security requirements met
- [ ] Accessibility standards met
- [ ] Mobile-responsive (if applicable)
```

## Testing Strategy Verification

### Test Pyramid Check
```
Verify test distribution:
┌────────────┐
│    E2E     │ 10%  - Critical user journeys
├────────────┤
│Integration │ 20%  - Repository, external services
├────────────┤
│    Unit    │ 70%  - Domain logic, use cases
└────────────┘

Ratios should be approximately:
- Many fast unit tests
- Some integration tests
- Few but critical E2E tests
```

### Test Coverage Targets

| Layer | Minimum Coverage | Ideal Coverage |
|-------|-----------------|----------------|
| Domain | 90% | 100% |
| Application | 80% | 90% |
| Infrastructure | 70% | 80% |
| Framework | 60% | 70% |
| **Overall** | **75%** | **85%** |

### Test Execution Time Targets

| Test Type | Target Time | Maximum Time |
|-----------|------------|--------------|
| Unit Tests | <5 seconds | <10 seconds |
| Integration | <30 seconds | <60 seconds |
| E2E Tests | <2 minutes | <5 minutes |
| **Full Suite** | **<3 minutes** | **<10 minutes** |

## Code Quality Metrics

### Complexity Metrics
```markdown
## Complexity Targets
- [ ] Cyclomatic complexity <10 per method
- [ ] Cognitive complexity <15 per method
- [ ] Class cohesion >0.5
- [ ] Maximum nesting depth <4
- [ ] Lines per method <50
- [ ] Lines per class <300
```

### Code Smell Detection
```markdown
## Common Code Smells to Check
- [ ] No duplicate code (DRY)
- [ ] No long parameter lists (>4)
- [ ] No feature envy
- [ ] No inappropriate intimacy
- [ ] No primitive obsession
- [ ] No shotgun surgery required
```

### Documentation Check
```markdown
## Documentation Requirements
- [ ] Public API documented
- [ ] Complex business logic explained
- [ ] README updated if needed
- [ ] API documentation generated
- [ ] Decision records created
- [ ] Deployment notes updated
```

## Security Checkpoint

### OWASP Top 10 Check
```markdown
## Security Checklist
- [ ] Input validation on all endpoints
- [ ] SQL injection prevention (parameterized queries)
- [ ] XSS prevention (output encoding)
- [ ] Authentication required where needed
- [ ] Authorization checks in place
- [ ] Sensitive data encrypted
- [ ] Security headers configured
- [ ] Rate limiting implemented
- [ ] Audit logging for sensitive operations
- [ ] Secrets not in code
```

### Data Protection
```markdown
## Data Protection Checklist
- [ ] PII handled appropriately
- [ ] Passwords hashed (never plain text)
- [ ] Sensitive data not logged
- [ ] Encryption at rest (if required)
- [ ] Encryption in transit (HTTPS)
- [ ] Data retention policies followed
```

## Performance Checkpoint

### Response Time Targets
```markdown
## Performance Targets
- [ ] API response <200ms (p50)
- [ ] API response <500ms (p95)
- [ ] API response <1000ms (p99)
- [ ] Database queries <100ms
- [ ] No N+1 query problems
- [ ] Appropriate caching implemented
```

### Load Testing
```markdown
## Load Test Verification
- [ ] Handles expected concurrent users
- [ ] Graceful degradation under load
- [ ] No memory leaks identified
- [ ] Database connections pooled
- [ ] Appropriate timeouts configured
- [ ] Circuit breakers implemented (if needed)
```

## Deployment Readiness

### Pre-Deployment Checklist
```markdown
## Deployment Checklist
- [ ] All tests passing
- [ ] Code reviewed and approved
- [ ] Documentation updated
- [ ] Database migrations ready
- [ ] Configuration for all environments
- [ ] Rollback plan defined
- [ ] Monitoring configured
- [ ] Alerts set up
```

### Post-Deployment Verification
```markdown
## Post-Deployment Checklist
- [ ] Health checks passing
- [ ] Smoke tests successful
- [ ] Metrics being collected
- [ ] No errors in logs
- [ ] Performance acceptable
- [ ] Users can complete story
```

## Continuous Quality

### Quality Tools Integration

Configure automated quality checks:

```yaml
# Example CI/CD quality gates
quality-checks:
  - linting:
      rules: recommended
      fail-on: warning
  - type-checking:
      strict: true
  - security-scan:
      severity: medium
  - test-coverage:
      minimum: 75%
  - complexity:
      max-cyclomatic: 10
```

### Quality Review Questions

Before marking a vertical slice complete:

1. **Would you be comfortable deploying this to production?**
2. **Can another developer understand and modify this code?**
3. **Are all edge cases handled gracefully?**
4. **Is the code maintainable long-term?**
5. **Does it follow team standards and patterns?**

## Quality Debt Tracking

If quality standards can't be met:

```markdown
## Technical Debt Record
- **Issue**: [What standard wasn't met]
- **Reason**: [Why it was deferred]
- **Impact**: [Risk/consequence]
- **Remediation**: [How to fix later]
- **Priority**: [High/Medium/Low]
- **Estimate**: [Effort to fix]
- **Deadline**: [When it must be addressed]
```

## Remember

- **Quality is built in, not tested in**
- **Each layer has its own quality gates**
- **Automate quality checks where possible**
- **Never compromise on security**
- **Performance is a feature**
- **Documentation is part of quality**