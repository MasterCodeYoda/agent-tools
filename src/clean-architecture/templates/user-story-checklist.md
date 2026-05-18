# User Story Implementation Checklist

## Story Information

**Story**: _________________________________
**Priority**: P1 ☐ | P2 ☐ | P3 ☐
**Estimated Effort**: _______________________
**Dependencies**: ___________________________

## Pre-Implementation Planning

### 1. Story Analysis
- [ ] User story is clearly defined with acceptance criteria
- [ ] Story is truly independent (can be deployed alone)
- [ ] Business value is understood
- [ ] Success metrics are defined

### 2. Domain Analysis
- [ ] Core business concepts identified
- [ ] Entities vs Value Objects decided
- [ ] Business rules and invariants documented
- [ ] Domain events identified (if any)

### 3. Technical Design
- [ ] Use case(s) identified
- [ ] Request/Response models designed
- [ ] External dependencies identified
- [ ] Data persistence needs determined

## Implementation Checklist

### Phase 1: Domain Layer

#### Entities/Value Objects
- [ ] Create domain entity/value object
- [ ] Define private fields (encapsulation)
- [ ] Implement business methods
- [ ] Validate invariants in constructor
- [ ] Validate invariants in state-changing methods
- [ ] Add domain events (if applicable)

#### Domain Services (if needed)
- [ ] Create domain service for cross-entity logic
- [ ] Ensure service is stateless
- [ ] Use domain language in method names

#### Tests
- [ ] Unit tests for entity creation
- [ ] Unit tests for business methods
- [ ] Unit tests for invariant validation
- [ ] Unit tests for domain services

**Checkpoint**: Domain logic complete and tested ✓

### Phase 2: Application Layer

#### Use Case Implementation
- [ ] Create use case class
- [ ] Define request model
- [ ] Define response model
- [ ] Implement execute method
- [ ] Handle domain exceptions
- [ ] Coordinate domain objects
- [ ] Define repository interface (if new)

#### Application Services (if needed)
- [ ] Define port interfaces for external services
- [ ] Create application-level validations
- [ ] Implement transaction boundaries

#### Tests
- [ ] Unit tests with mocked dependencies
- [ ] Test happy path
- [ ] Test error cases
- [ ] Test validation logic

**Checkpoint**: Use case complete and tested ✓

### Phase 3: Infrastructure Layer

#### Repository Implementation
- [ ] Implement repository interface
- [ ] Map domain to persistence model
- [ ] Map persistence model to domain
- [ ] Handle database transactions
- [ ] Implement query methods

#### External Service Integration (if needed)
- [ ] Implement gateway interfaces
- [ ] Handle external API calls
- [ ] Map external responses to domain
- [ ] Implement retry logic (if needed)
- [ ] Add circuit breaker (if needed)

#### Tests
- [ ] Integration tests with real database (test DB)
- [ ] Test CRUD operations
- [ ] Test complex queries
- [ ] Test transaction rollback
- [ ] Test external service integration

**Checkpoint**: Infrastructure complete and tested ✓

### Phase 4: Frameworks Layer

#### Entry Point Creation
- [ ] Create controller/command/handler
- [ ] Parse and validate input format
- [ ] Convert to application request
- [ ] Call use case
- [ ] Handle application exceptions
- [ ] Convert response to output format

#### Framework-Specific Setup
- [ ] Add routing/endpoint configuration
- [ ] Set up dependency injection
- [ ] Add authentication/authorization (if needed)
- [ ] Configure middleware (if needed)
- [ ] Add API documentation

#### Tests
- [ ] End-to-end test for happy path
- [ ] Test input validation
- [ ] Test error responses
- [ ] Test authentication (if applicable)

**Checkpoint**: Entry point complete and tested ✓

## Post-Implementation Validation

### Architecture Validation
- [ ] Dependencies flow inward only
- [ ] Domain has no external dependencies
- [ ] Application depends only on Domain
- [ ] Infrastructure implements Application interfaces
- [ ] Frameworks depends on all inner layers appropriately

### Code Quality
- [ ] All tests pass
- [ ] Code follows naming conventions
- [ ] Code is properly documented
- [ ] No TODO comments left
- [ ] No debugging code left

### Functional Validation
- [ ] Feature works end-to-end
- [ ] Acceptance criteria met
- [ ] Edge cases handled
- [ ] Error messages are clear
- [ ] Performance is acceptable

## Documentation

### Code Documentation
- [ ] Domain entities have docstrings
- [ ] Use cases have clear descriptions
- [ ] Complex logic is commented
- [ ] API endpoints are documented

### Team Documentation
- [ ] Update API documentation
- [ ] Update domain model diagrams (if changed)
- [ ] Note any architectural decisions made
- [ ] Document any technical debt incurred

## Definition of Done

**Before marking story as complete:**

- [ ] All implementation phases complete
- [ ] All tests pass (unit, integration, e2e)
- [ ] Code reviewed (self or peer)
- [ ] Documentation updated
- [ ] Feature works in integration environment
- [ ] No known bugs
- [ ] Technical debt documented (if any)
- [ ] Ready to ship to production

## Refactoring Notes

**Patterns observed** (note for future refactoring):
- Similar code seen in: _________________
- Potential abstraction: ________________
- Technical debt incurred: ______________

**Improvement opportunities**:
- [ ] Extract common validation
- [ ] Create base classes (after 3+ examples)
- [ ] Optimize queries
- [ ] Add caching
- [ ] Improve error handling

## Sign-off

**Developer**: _________________ **Date**: _______
**Reviewer**: _________________ **Date**: _______
**Product Owner**: _____________ **Date**: _______

---

## Quick Reference

### Layer Responsibilities Reminder

**Domain**: Business rules, entities, value objects
**Application**: Use cases, orchestration, DTOs
**Infrastructure**: Database, external services, file I/O
**Frameworks**: HTTP, CLI, GUI, entry points

### Common Mistakes to Avoid

❌ Putting business logic in controllers
❌ Domain entities knowing about databases
❌ Use cases containing business rules
❌ Skipping layers for "simple" features
❌ Fat repositories with business logic

### When to Stop and Refactor

- When you've seen the same pattern 3 times
- When tests become hard to write
- When adding features becomes painful
- When the team is confused about where code goes
- When performance becomes an issue