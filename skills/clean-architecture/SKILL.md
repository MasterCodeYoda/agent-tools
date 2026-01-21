---
name: clean-architecture
description: Guide projects through Clean Architecture patterns with strict layer boundaries, vertical slicing, and dependency inversion. Use when implementing features following Clean Architecture, creating domain models, application use cases, or validating architectural compliance. Language-agnostic with support for Python, TypeScript, C#, and extensible to others.
---

# Clean Architecture

A language-agnostic guide for implementing Clean Architecture principles with strict layer boundaries, vertical slicing,
and dependency inversion.

## When to Use This Skill

Activate this skill when:

- Starting a new Clean Architecture project
- Implementing features with clear layer separation
- Creating domain entities, value objects, or aggregates
- Building application layer use cases
- Designing repository patterns and gateways
- Validating layer boundaries and dependencies
- Learning or teaching Clean Architecture patterns
- Reviewing code for architectural compliance

## Quick Decision Tree

**"Where does this code belong?"**

Ask yourself these questions in order:

1. **Is it a business rule or core concept?**
    - YES → **Domain Layer**
    - Pure business logic, no external dependencies
    - Examples: Order, Customer, Money, OrderStatus
    - See: `references/layer-patterns.md#domain`

2. **Does it orchestrate business operations?**
    - YES → **Application Layer**
    - Coordinates domain objects, defines workflows
    - Examples: CreateOrderUseCase, ProcessPaymentUseCase
    - See: `references/layer-patterns.md#application`

3. **Does it connect to external systems?**
    - YES → **Infrastructure Layer**
    - Databases, APIs, file systems, email services
    - Examples: SqlOrderRepository, EmailGateway
    - See: `references/layer-patterns.md#infrastructure`

4. **Is it a user interface or entry point?**
    - YES → **Frameworks Layer**
    - HTTP endpoints, CLI commands, GUI, message handlers
    - Examples: OrderController, CreateOrderCommand
    - See: `references/layer-patterns.md#frameworks`

## Core Architectural Rules

### The Dependency Rule (MANDATORY)

**Dependencies ALWAYS flow inward:**

```
[Frameworks] → [Infrastructure] → [Application] → [Domain]
  (outer)         (concrete)       (orchestration)   (pure)
```

**This means:**

- Domain knows nothing about outer layers
- Application knows only about Domain
- Infrastructure knows about Application and Domain
- Frameworks knows about all inner layers

**Never violate this rule.** Inner layers cannot import from, reference, or know about outer layers.

### Implementation Strategy: Vertical Slicing + Layer Sanctity

We combine two orthogonal principles:

**1. Vertical Slicing (WHEN to build)**

- Build ONE user story at a time, end-to-end
- Complete all layers for that story before moving on
- Priority-driven: P1 (MVP) → P2 → P3

**2. Layer Sanctity (HOW to build)**

- Maintain strict architectural boundaries
- Dependencies always flow inward
- Each layer has specific responsibilities

See: `references/vertical-slicing.md` for detailed workflow.

### Example: Building "Create Task" Feature

```
Story: As a user, I want to create a task

Implementation Order (Vertical):
1. Domain: Task entity with validation
2. Application: CreateTaskUseCase with Request/Response
3. Infrastructure: TaskRepository implementation
4. Framework: POST /tasks endpoint
5. Tests: All layers
✓ CHECKPOINT: Feature works end-to-end

Dependencies (Horizontal):
Domain ← Application ← Infrastructure ← Framework
(No reverse arrows allowed!)
```

## Core Concepts

### Entities vs Value Objects

**Entities:**

- Have unique identity (ID)
- Mutable state over time
- Equality by ID
- Example: Order, Customer, Product

**Value Objects:**

- No identity
- Immutable
- Equality by all attributes
- Example: Money, Address, DateRange

See: `references/core-concepts.md#entities-value-objects`

### Encapsulation Principles

1. **Default to private** - All attributes private unless justified
2. **Expose behavior, not state** - Methods over getters
3. **Controlled access** - Use properties when needed
4. **Protect invariants** - Never allow invalid state

See: `references/core-concepts.md#encapsulation`

### Use Cases and Application Services

Each use case should:

- Have single responsibility
- Define clear Request/Response models
- Orchestrate domain objects
- Be framework-agnostic
- Return domain-agnostic responses

Pattern:

```
UseCase + Request + Response = Single File
```

See: `references/layer-patterns.md#application-patterns`

## Language-Specific Implementation

Choose your implementation language for specific patterns, tools, and examples:

- **Python**: `languages/python/guide.md`
    - Type hints, dataclasses, protocols
    - Tools: mypy, ruff, pytest

- **TypeScript**: `languages/typescript/guide.md`
    - Branded types, Result pattern, domain events
    - Recommended: NestJS (backend), Next.js App Router (full-stack)
    - ORM: Prisma (default), Drizzle (alternative)
    - Tools: ESLint, Jest, Zod

- **C#**: `languages/csharp/guide.md`
    - Interfaces, dependency injection
    - Tools: .NET CLI, xUnit

- **Rust**: `languages/rust/guide.md`
    - Traits, ownership, Result pattern
    - Recommended: Axum (API), Tauri v2 (Desktop)
    - Tauri v2: Capabilities/ACL, tauri-specta bindings, events
    - Database: SQLx (default), Diesel (alternative)
    - Tools: Clippy, rustfmt, cargo-nextest, insta

- **Other Languages**: See `languages/README.md` for adding support

## Example Implementation: Task Manager

A complete, evolving example showing Clean Architecture patterns:

- Start: `example-task-manager/README.md`
- Domain patterns: `example-task-manager/domain.md`
- Application patterns: `example-task-manager/application.md`
- Infrastructure: `example-task-manager/infrastructure.md`
- Frameworks: `example-task-manager/frameworks.md`

The example starts simple (CRUD) and documents how to evolve it to handle:

- Authentication and authorization
- Complex business rules
- Event-driven patterns
- Performance optimization

## Validation and Quality Checks

### Architectural Validation

Check your implementation with language-specific validators:

**Python:**

```bash
python .claude/skills/clean-architecture/languages/python/validators/validate_imports.py
python .claude/skills/clean-architecture/languages/python/validators/validate_structure.py
```

**TypeScript:**

```bash
npx tsx .claude/skills/clean-architecture/languages/typescript/validators/validate_imports.ts
```

### Manual Review Checklist

Before committing code:

- [ ] Dependencies flow inward only
- [ ] Domain has no external dependencies
- [ ] Use cases are framework-agnostic
- [ ] Repositories return domain entities
- [ ] Controllers/endpoints are thin
- [ ] Business logic is in domain
- [ ] Tests mirror source structure

See: `templates/architecture-review.md`

## Templates and Workflows

### Quick Start Templates

- **Layer Selection**: `templates/decision-tree.md`
- **User Story Implementation**: `templates/user-story-checklist.md`
- **Code Review Criteria**: `templates/architecture-review.md`

### Workflow: Implementing a New Feature

1. **Understand the requirement**
    - Identify domain concepts
    - Define use cases
    - Plan data flow

2. **Implement vertically by story**
    - Start with domain entities
    - Add application use case
    - Implement infrastructure
    - Create framework entry point
    - Write tests for each layer

3. **Validate architecture**
    - Run language-specific validators
    - Review dependency directions
    - Check encapsulation

4. **Checkpoint**
    - Feature works end-to-end
    - Tests pass
    - Architecture intact

See: `references/vertical-slicing.md`

## Common Pitfalls and Solutions

### Pitfall 1: Framework Logic in Domain

**Problem**: HTTP concerns, database logic in entities
**Solution**: Keep domain pure, move I/O to outer layers

### Pitfall 2: Anemic Domain Model

**Problem**: Entities with only getters/setters
**Solution**: Move behavior into entities, protect invariants

### Pitfall 3: Use Case Doing Too Much

**Problem**: Business logic in application layer
**Solution**: Push logic down to domain, orchestrate in application

### Pitfall 4: Skipping Layers

**Problem**: Controller directly accessing repository
**Solution**: Always go through use cases

### Pitfall 5: Shared Mutable State

**Problem**: Entities exposing collections directly
**Solution**: Return copies, use immutable value objects

See: `references/common-mistakes.md` for more anti-patterns.

## Core References

Essential reading for deep understanding:

- **Core Concepts**: `references/core-concepts.md`
    - Dependency Rule, SOLID principles
    - Entities, Value Objects, Aggregates
    - Domain services, Domain events

- **Layer Patterns**: `references/layer-patterns.md`
    - Detailed responsibilities per layer
    - Common patterns and implementations
    - Inter-layer communication

- **Vertical Slicing**: `references/vertical-slicing.md`
    - Story-based development workflow
    - Maintaining boundaries while iterating
    - Checkpoint-driven development

- **Implementation Strategy**: `references/implementation-strategy.md`
    - Combining vertical and horizontal approaches
    - Priority-driven development
    - Incremental architecture

- **Agent-Native Architecture**: `references/agent-native-architecture.md`
    - Building applications where agents are first-class citizens
    - Tool design: parity, granularity, composability
    - Files as universal interface, context injection patterns

## Testing Strategies

### Test Pyramid Approach

```
     /\      E2E Tests (Few)
    /  \     - Complete workflows
   /    \    - Happy paths only
  /------\   Integration Tests (Some)
 /        \  - Use cases with real repositories
/          \ - Infrastructure with databases
/------------\ Unit Tests (Many)
               - Domain logic isolation
               - Pure functions
               - No external dependencies
```

### Layer-Specific Testing

- **Domain**: Pure unit tests, no mocks needed
- **Application**: Mock repositories and gateways
- **Infrastructure**: Integration tests with real resources
- **Frameworks**: E2E tests for critical paths

See: `references/testing-strategies.md`

## When NOT to Use Clean Architecture

Be pragmatic. Skip Clean Architecture for:

- Simple CRUD apps with no business logic
- Prototypes and throwaway code
- Scripts and utilities
- Projects with <3 developers
- Short-lived projects (<3 months)

Use Clean Architecture when:

- Complex business rules exist
- Multiple teams collaborate
- Long-term maintenance expected
- Technology might change
- Testability is critical

## Getting Help

### Quick Troubleshooting

**"Where does X go?"** → Use decision tree above
**"Can A depend on B?"** → Check dependency rule
**"How to test X?"** → See testing strategies
**"Is this overengineered?"** → Check "When NOT to use"

### Extended Resources

For deeper learning (loaded on request only):

- Academic papers: `references/external-resources.md#papers`
- Books and articles: `references/external-resources.md#books`
- Video courses: `references/external-resources.md#courses`
- Case studies: `references/external-resources.md#case-studies`

## Contributing

To add support for a new language:

1. Read `languages/README.md`
2. Create `languages/{language}/guide.md`
3. Add examples following existing patterns
4. Optional: Add validators
5. Update Task Manager example

## Summary

Clean Architecture enables:

- **Independence**: Change frameworks without touching business logic
- **Testability**: Test each layer in isolation
- **Maintainability**: Clear boundaries reduce complexity
- **Flexibility**: Adapt to changing requirements

Remember:

- Dependencies flow inward
- Build vertically, maintain horizontally
- Start simple, evolve as needed
- Be pragmatic, not dogmatic

Start with the decision tree, follow the patterns, and validate continuously.