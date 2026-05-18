# Clean Architecture Review Checklist

## Review Context

**Pull Request/Feature**: _____________________
**Developer**: _______________________________
**Reviewer**: ________________________________
**Date**: ____________________________________

## Layer Boundary Review

### Dependency Direction

**Check: All dependencies point inward**

- [ ] Domain imports nothing from outer layers
- [ ] Application imports only from Domain
- [ ] Infrastructure imports from Domain and Application
- [ ] Frameworks imports from all inner layers

**Violations Found:**
```
File: _________________ imports from wrong layer: _________________
File: _________________ imports from wrong layer: _________________
```

### Layer Responsibilities

**Domain Layer**
- [ ] Contains only business logic
- [ ] No framework dependencies
- [ ] No I/O operations
- [ ] No database knowledge
- [ ] Entities protect invariants
- [ ] Value objects are immutable

**Application Layer**
- [ ] Use cases orchestrate, don't implement business logic
- [ ] Request/Response DTOs are simple data carriers
- [ ] Interfaces defined for external dependencies
- [ ] No framework-specific code
- [ ] No direct infrastructure dependencies

**Infrastructure Layer**
- [ ] Implements interfaces defined in inner layers
- [ ] Handles all I/O operations
- [ ] Maps between domain and persistence models
- [ ] No business logic
- [ ] Proper error handling for external services

**Frameworks Layer**
- [ ] Thin controllers/handlers
- [ ] Input validation only (not business validation)
- [ ] Proper error transformation
- [ ] No business logic
- [ ] Delegates to use cases

## Code Quality Review

### Naming Conventions

**General**
- [ ] Classes use PascalCase
- [ ] Functions/methods use snake_case (Python) or camelCase (JS/TS/C#)
- [ ] Constants use UPPER_SNAKE_CASE
- [ ] Private members use underscore prefix (where applicable)
- [ ] Files use appropriate naming convention for language

**Domain-Specific**
- [ ] Entities named as nouns (Order, Customer, Product)
- [ ] Value objects describe attributes (Money, Address, Email)
- [ ] Use cases named as commands (CreateOrder, ProcessPayment)
- [ ] Events named in past tense (OrderCreated, PaymentProcessed)

### Encapsulation

- [ ] Domain entities have private fields
- [ ] State changes through methods, not direct access
- [ ] Collections not exposed directly (return copies)
- [ ] Appropriate use of properties/getters
- [ ] No public fields without justification

### SOLID Principles

**Single Responsibility**
- [ ] Each class has one reason to change
- [ ] Methods do one thing
- [ ] Clear separation of concerns

**Open/Closed**
- [ ] Code open for extension, closed for modification
- [ ] Uses interfaces/abstractions appropriately
- [ ] New features added without changing existing code

**Liskov Substitution**
- [ ] Derived classes substitutable for base classes
- [ ] Interface implementations fulfill contracts
- [ ] No additional constraints in implementations

**Interface Segregation**
- [ ] Interfaces are small and focused
- [ ] Clients not forced to depend on unused methods
- [ ] No "fat" interfaces

**Dependency Inversion**
- [ ] Depends on abstractions, not concretions
- [ ] High-level doesn't depend on low-level
- [ ] Both depend on abstractions

## Pattern Implementation

### Domain Patterns

**Entities**
- [ ] Have unique identity
- [ ] Protect business invariants
- [ ] Validate state changes
- [ ] Emit domain events when appropriate

**Value Objects**
- [ ] Immutable
- [ ] Equality by value, not reference
- [ ] Self-validating
- [ ] No identity

**Aggregates**
- [ ] Clear aggregate boundaries
- [ ] Single aggregate root
- [ ] Consistency boundary respected
- [ ] References by ID only

**Domain Services**
- [ ] Stateless operations
- [ ] Cross-entity business logic
- [ ] Named with domain language

### Application Patterns

**Use Cases**
- [ ] Single responsibility
- [ ] Clear request/response models
- [ ] Proper error handling
- [ ] Transaction management
- [ ] Side effects handled appropriately

**DTOs**
- [ ] Simple data structures
- [ ] No business logic
- [ ] Clear mapping from/to domain

### Repository Pattern

- [ ] One repository per aggregate root
- [ ] Methods express domain concepts
- [ ] Returns domain entities
- [ ] No query builder leakage
- [ ] Proper abstraction level

## Testing Review

### Test Coverage

**Unit Tests**
- [ ] Domain entities tested thoroughly
- [ ] Business rules validated
- [ ] Edge cases covered
- [ ] Error conditions tested

**Integration Tests**
- [ ] Use cases tested with mocks
- [ ] Repository implementations tested
- [ ] External service integrations tested
- [ ] Transaction rollback tested

**End-to-End Tests**
- [ ] Happy path tested
- [ ] Critical user journeys covered
- [ ] Error responses validated

### Test Quality

- [ ] Tests are readable and clear
- [ ] Test names describe what is tested
- [ ] Proper test data builders/fixtures
- [ ] No test interdependencies
- [ ] Fast test execution

## Security Review

- [ ] Input validation at boundaries
- [ ] No SQL injection vulnerabilities
- [ ] No sensitive data in logs
- [ ] Proper authentication/authorization
- [ ] Secrets not hardcoded
- [ ] Rate limiting where appropriate

## Performance Considerations

- [ ] No N+1 query problems
- [ ] Appropriate use of lazy/eager loading
- [ ] Caching strategy considered
- [ ] Database indexes appropriate
- [ ] No unnecessary data fetching

## Documentation

- [ ] Code is self-documenting
- [ ] Complex logic has comments
- [ ] Public APIs documented
- [ ] Architectural decisions recorded
- [ ] README updated if needed

## Common Anti-Patterns Check

### ❌ Anti-Patterns to Flag

**Anemic Domain Model**
- [ ] Entities with only getters/setters
- [ ] Business logic in services instead of entities
- [ ] No behavior in domain objects

**Fat Controllers**
- [ ] Business logic in controllers
- [ ] Direct database access from controllers
- [ ] Complex orchestration in entry points

**Leaky Abstractions**
- [ ] ORM entities used as domain entities
- [ ] Database structure reflected in domain
- [ ] Framework concepts in domain layer

**Generic Everything**
- [ ] Over-generic interfaces (IRepository<T>)
- [ ] Unnecessary abstraction layers
- [ ] Premature optimization

**Smart UI**
- [ ] Business logic in presentation layer
- [ ] Direct database calls from UI
- [ ] Validation only in UI

## Refactoring Opportunities

**Identify patterns for extraction:**
- [ ] Similar code in 3+ places
- [ ] Common validation logic
- [ ] Repeated error handling
- [ ] Similar repository methods

**Technical debt to document:**
- [ ] Temporary workarounds
- [ ] Performance optimizations needed
- [ ] Missing test coverage
- [ ] Incomplete error handling

## Overall Assessment

### Severity Levels

**🔴 Critical (Must Fix)**
- Breaking dependency rule
- Missing critical tests
- Security vulnerabilities
- Data corruption risks

**🟡 Major (Should Fix)**
- Poor encapsulation
- Missing error handling
- Inconsistent patterns
- Performance issues

**🟢 Minor (Consider Fixing)**
- Naming inconsistencies
- Missing documentation
- Code formatting issues
- Optimization opportunities

### Review Summary

**Architecture Compliance**: ⬜ Excellent | ⬜ Good | ⬜ Needs Work | ⬜ Poor

**Critical Issues Found**: ________

**Major Issues Found**: ________

**Minor Issues Found**: ________

### Recommendations

**Must Fix Before Merge:**
1. _________________________________
2. _________________________________
3. _________________________________

**Should Fix Soon:**
1. _________________________________
2. _________________________________

**Consider for Future:**
1. _________________________________
2. _________________________________

## Sign-off

**Reviewer Approval**: ⬜ Approved | ⬜ Approved with changes | ⬜ Needs major revision

**Reviewer Signature**: _______________

**Date**: _______________

**Notes**: _________________________________