# Clean Architecture: A Primer & Practical Guide

## Introduction

This guide provides a thorough, actionable introduction to applying Clean Architecture principles in software projects.
Inspired by works like "Clean Architecture" by Robert C. Martin and "Clean Architecture with Python" by Sam Keen (Packt,
2025), it focuses on designing modular, testable, and maintainable systems. Clean Architecture helps address common
challenges in software development, including tight coupling, spaghetti code, and difficulties in scaling or refactoring.

The guide emphasizes the Dependency Rule: dependencies should point inward, with outer layers relying on inner ones but
not vice versa. This promotes independence, allowing teams to swap technologies (e.g., databases or UI frameworks)
without disrupting core business logic. It's suitable for intermediate to advanced developers familiar with
object-oriented programming (OOP) basics.

Examples throughout use pseudo-code to illustrate concepts, making them applicable across languages and easier to adapt
to real-world projects.

## Core Concepts of Clean Architecture

Clean Architecture structures software into concentric layers, prioritizing business rules over technical details. The
central Dependency Rule ensures that high-level policies remain isolated from low-level implementations, resulting in
systems that are easier to test, maintain, and evolve.

### The Four Layers

1. **Domain Layer (Innermost)**: Contains core business entities, value objects, and rules. These elements are
   independent of external systems and focus on the "what" of the business. For example, a `Task` entity might include
   methods like `complete()` that enforce invariants, such as preventing a task from being completed multiple times.

2. **Application Layer**: Orchestrates use cases by coordinating domain objects. It defines operations like
   `CreateTaskUseCase`, handling requests and responses without knowledge of databases or UIs. This layer emphasizes the
   system's behavior in terms of business workflows.

3. **Infrastructure Layer**: Provides concrete implementations for abstractions defined in inner layers, such as
   repositories for data persistence or gateways for external services. It bridges the gap to real-world tools while
   keeping domain logic pure.

4. **Frameworks Layer (Outermost)**: Serves as entry points, such as web APIs, command-line interfaces (CLI), or other
   adapters. These are treated as plugins that can be replaced without affecting inner layers.

Key benefits include:

- **Independence**: Change databases, UIs, or frameworks with minimal impact on business logic.
- **Testability**: Isolate and unit-test inner layers using mocks or in-memory substitutes.
- **Maintainability**: Enforce clear boundaries to manage complexity in growing codebases.

## Implementation Strategy: Vertical Slicing with Layer Sanctity

Our implementation approach combines two orthogonal principles that work together to enable rapid value delivery while
maintaining architectural integrity.

### The Two Principles

**1. Implementation Order - Vertical Slicing:**

Features are implemented ONE USER STORY at a time, completing all architectural layers needed for that story:

- **Story-First Development**: Organize work around business capabilities (user stories) rather than technical layers
- **Priority-Driven**: Implement P1 (MVP) stories first, then P2, then P3
- **Complete Vertical Slices**: Each story delivers value end-to-end through all layers
- **Independent Deliverability**: Each story can be tested, demonstrated, and shipped independently
- **Checkpoint-Driven**: After each story, validate it works standalone before proceeding

**2. Architecture Rules - Layer Sanctity:**

While implementing vertically (by story), ALWAYS maintain horizontal layer boundaries:

- **Domain** (innermost): No dependencies on outer layers - pure business logic
- **Application**: Depends only on Domain layer abstractions
- **Infrastructure**: Depends on Domain and Application abstractions, provides concrete implementations
- **Framework** (outermost): Depends on all inner layers, serves as entry points

The Dependency Rule is non-negotiable: dependencies ALWAYS flow inward, regardless of implementation order.

### How They Work Together

These principles are orthogonal and complementary:

- **Vertical slicing** determines WHEN we build components (story order: P1 → P2 → P3)
- **Layer sanctity** determines HOW components depend on each other (dependencies always flow inward)
- **Together** they enable: rapid iteration, early value delivery, clean architecture, testability

### Example: Task Management Feature

```
Story 1 (P1): Create Task - MVP

Vertical Slice (complete all layers for this story):
├── Domain: Task entity with validation rules
│   - Enforces: description required, state transitions valid
│   - No dependencies on outer layers
│
│   Entity Task {
│     id: string
│     description: string
│     isComplete: boolean
│
│     method create() → Task
│     method markComplete() → void
│   }
│
├── Application: CreateTaskUseCase + Request/Response
│   - Depends only on: Domain (Task entity, TaskRepository interface)
│
│   Request CreateTaskRequest {
│     description: string
│     priority: integer
│   }
│
│   Response CreateTaskResponse {
│     task: TaskView
│     created: boolean
│   }
│
│   Interface TaskRepository {
│     method save(task: Task) → void
│   }
│
│   UseCase CreateTaskUseCase {
│     repository: TaskRepository
│
│     method execute(request: CreateTaskRequest) → CreateTaskResponse {
│       task = Task.create(request.description, request.priority)
│       repository.save(task)
│       return CreateTaskResponse(TaskView.fromEntity(task), true)
│     }
│   }
│
├── Infrastructure: DatabaseTaskRepository
│   - Implements: TaskRepository interface from Application
│   - Depends on: Domain (Task entity), Application (interface)
│
│   Class DatabaseTaskRepository implements TaskRepository {
│     database: DatabaseConnection
│
│     method save(task: Task) → void {
│       database.execute("INSERT INTO tasks ...")
│     }
│   }
│
└── Framework: POST /tasks endpoint
    - Depends on: Application (CreateTaskUseCase), Infrastructure (repository)

    Endpoint POST /tasks {
      useCase = CreateTaskUseCase(repository)
      response = useCase.execute(request)
      return HTTP 201 Created with response
    }

Horizontal Boundaries (enforced):
Framework ───> Infrastructure ───> Application ───> Domain
   (outer)        (concrete)         (orchestration)   (pure)

✅ CHECKPOINT: Can create tasks (shippable MVP)

Story 2 (P2): Complete Task - Next Increment

Vertical Slice:
├── Domain: Task.complete() method
│   - Validates: task not already complete, state transitions
│   - Extends existing Task entity
│
│   Entity Task {
│     // ... existing fields
│
│     method complete() → void {
│       if (isComplete) throw AlreadyCompleteError
│       isComplete = true
│       completedAt = now()
│     }
│   }
│
├── Application: CompleteTaskUseCase + Request/Response
│   - Reuses: Domain (Task entity), existing repository
│
│   Request CompleteTaskRequest {
│     taskId: string
│   }
│
│   UseCase CompleteTaskUseCase {
│     repository: TaskRepository
│
│     method execute(request: CompleteTaskRequest) → CompleteTaskResponse {
│       task = repository.findById(request.taskId)
│       if (!task) throw TaskNotFoundError
│       task.complete()
│       repository.save(task)
│       return CompleteTaskResponse(true)
│     }
│   }
│
├── Infrastructure: Update existing TaskRepository
│   - Add/update: findById() method
│
│   Class DatabaseTaskRepository implements TaskRepository {
│     method findById(id: string) → Task {
│       row = database.query("SELECT * FROM tasks WHERE id = ?", id)
│       return Task.fromRow(row)
│     }
│   }
│
└── Framework: PUT /tasks/{id}/complete endpoint
    - New endpoint following same patterns as Story 1

    Endpoint PUT /tasks/{id}/complete {
      useCase = CompleteTaskUseCase(repository)
      response = useCase.execute(CompleteTaskRequest(id))
      return HTTP 200 OK
    }

✅ CHECKPOINT: Can create AND complete tasks (shippable increment)
```

### Benefits of This Approach

**Early Value Delivery:**
- P1 story alone delivers working MVP
- Each subsequent story adds value without breaking previous stories
- Ship and get feedback early, iterate quickly

**Reduced Risk:**
- Build and validate incrementally
- Discover integration issues early (not at the end)
- Each checkpoint is a decision point: ship, pivot, or continue

**Maintained Architecture:**
- Layer boundaries enforced at all times
- Dependencies always flow inward
- Testability maintained (can mock any layer)
- Future refactoring simplified

**Team Collaboration:**
- Product owners manage story priorities (Linear, Jira, etc.)
- Engineers implement stories vertically
- Clear progress visibility (story checkpoints)
- Easy to parallelize (different team members take different stories)

## Key Principles and Patterns

Clean Architecture adapts well to modern development practices. Below are essential principles, illustrated with
pseudo-code examples from typical business applications.

### SOLID Principles

Apply SOLID (Single Responsibility, Open-Closed, Liskov Substitution, Interface Segregation, Dependency Inversion) to
create loosely coupled code. For instance:

- Use interfaces or protocols to define abstractions
- Split responsibilities to avoid "god classes"—e.g., separate order creation logic from validation
- Align with the Dependency Rule by inverting dependencies, injecting them rather than hard-coding

These principles, when combined with Clean Architecture, reduce fragility and enhance extensibility.

### Entities and Value Objects

Clean Architecture distinguishes between entities and value objects:

**Entities:**
- Have unique identity (typically an ID)
- Mutable (state changes over time)
- Equality based on identity, not attributes
- Example: `Order`, `Customer`, `Product`

```
Entity Order {
  id: string
  customerId: string
  items: List<OrderItem> (private)
  status: OrderStatus

  method create(customerId: string) → Order
  method addItem(item: OrderItem) → void
  method cancel() → void
}
```

**Value Objects:**
- No unique identity
- Immutable (never change after creation)
- Equality based on all attributes
- Example: `Money`, `Address`, `DateRange`

```
ValueObject Money {
  amount: decimal (readonly)
  currency: string (readonly)

  method add(other: Money) → Money
  method equals(other: Money) → boolean
}

ValueObject Address {
  street: string (readonly)
  city: string (readonly)
  state: string (readonly)
  zipCode: string (readonly)

  method equals(other: Address) → boolean
}
```

### Encapsulation and Attribute Visibility

Clean Architecture emphasizes hiding implementation details to maintain clear boundaries between layers. Proper
encapsulation is critical to architectural integrity.

#### Encapsulation Principles

1. **Default to Private**: All internal state should be private by default unless there's a specific, functional need
   for external access.
2. **Expose Behavior, Not State**: Classes should expose methods that perform operations rather than allowing direct
   state manipulation.
3. **Use Properties for Controlled Access**: When external access is needed, use properties to maintain control over
   validation, computation, or future changes.
4. **Document Public Interfaces**: Any truly public attribute must be documented as part of the class's public API
   contract.

#### Examples

```
// Good: Proper encapsulation
Class BankAccount {
  accountNumber: string (private)
  balance: decimal (private)
  transactions: List<Transaction> (private)

  property AccountNumber: string (read-only) {
    get → return accountNumber
  }

  property Balance: decimal (read-only) {
    get → return balance
  }

  method deposit(amount: decimal) → void {
    if (amount <= 0) throw InvalidAmountError
    balance += amount
    transactions.add(Transaction("deposit", amount))
  }

  method withdraw(amount: decimal) → void {
    if (amount <= 0) throw InvalidAmountError
    if (amount > balance) throw InsufficientFundsError
    balance -= amount
    transactions.add(Transaction("withdrawal", amount))
  }
}

// Bad: Exposing implementation details
Class BankAccount {
  accountNumber: string (public)  // Can be modified externally
  balance: decimal (public)        // Invariants can be violated
  transactions: List<Transaction> (public)  // Internal list can be corrupted
}
```

This approach ensures that:
- Internal implementation can change without breaking external code
- Class invariants are protected
- The public interface is minimal and intentional
- Dependencies between layers remain properly inverted

### Domain-Driven Design (DDD) Integration

Model the business domain using entities (mutable objects with identity), value objects (immutable descriptors),
aggregates (clusters of related objects), and repositories (abstractions for persistence). Bounded contexts help avoid
monolithic designs.

In practice:

- Place entities and value objects in a `Domain/` or `domain/` directory
- Define domain services for pure business logic, such as calculating order totals
- Use repositories to abstract storage—e.g., in-memory for tests, database for production

**Aggregates**: Cluster related entities and value objects under a single root entity. Only the root can be accessed
from outside the aggregate. This enforces consistency boundaries.

```
Aggregate OrderAggregate {
  root: Order (public)
  items: List<OrderItem> (private)

  // Only access items through Order methods
  Order.addItem() → adds to items collection
  Order.removeItem() → removes from items collection
}
```

### Use Cases in the Application Layer

The application layer implements a **file-per-use-case pattern** where each use case is defined in its own file with
colocated request and response models. This approach enhances modularity, discoverability, and maintainability.

#### File-Per-Use-Case Pattern

Each use case file contains:
- The use case class (suffixed with `UseCase`)
- Request model (suffixed with `Request`)
- Response model (suffixed with `Response`)
- All models are colocated for cohesion

Shared view models are placed in separate view files at the appropriate level (context or functional area).

Example structure:
```
Application/
├── Tasks/
│   ├── Views          # TaskView (shared read model)
│   ├── CreateTask     # CreateTaskUseCase + Request/Response
│   ├── UpdateTask     # UpdateTaskUseCase + Request/Response
│   └── CompleteTask   # CompleteTaskUseCase + Request/Response
```

Example use case:

```
// File: Application/Tasks/CreateTask

Request CreateTaskRequest {
  description: string
  priority: integer (default: 0)
}

Response CreateTaskResponse {
  task: TaskView
  created: boolean
}

Interface TaskRepository {
  method save(task: Task) → void
}

UseCase CreateTaskUseCase {
  repository: TaskRepository

  constructor(repo: TaskRepository) {
    this.repository = repo
  }

  method execute(request: CreateTaskRequest) → CreateTaskResponse {
    task = Task.create(request.description, request.priority)
    repository.save(task)
    return CreateTaskResponse(
      task: TaskView.fromEntity(task),
      created: true
    )
  }
}
```

This pattern ensures:
- Clear separation of concerns
- Self-contained use cases
- Easy discoverability (file name = action)
- Reduced cognitive load per file

### Gateways and Repositories in Infrastructure

Implement domain interfaces here. Gateways integrate external services (e.g., email APIs), while repositories handle
data access.

Organize as:

- `Infrastructure/Repositories/` or `infrastructure/repositories/` for persistence implementations
- `Infrastructure/Gateways/` or `infrastructure/gateways/` for external integrations

Ensure implementations depend on domain abstractions, not the other way around.

**Repository Pattern**:
- Define interface in Application/Domain layer
- Implement in Infrastructure layer
- One repository per aggregate root
- Methods express business concepts (e.g., `findActiveOrders()` not `executeSql()`)

```
// Application layer - interface definition
Interface OrderRepository {
  method findById(id: string) → Order?
  method save(order: Order) → void
  method findActiveOrders() → List<Order>
}

// Infrastructure layer - implementation
Class SqlOrderRepository implements OrderRepository {
  database: DatabaseConnection

  method findById(id: string) → Order? {
    row = database.query("SELECT * FROM orders WHERE id = ?", id)
    if (!row) return null
    return Order.fromRow(row)
  }

  method save(order: Order) → void {
    database.execute("INSERT INTO orders ...", order)
  }

  method findActiveOrders() → List<Order> {
    rows = database.query("SELECT * FROM orders WHERE status = 'active'")
    return rows.map(row → Order.fromRow(row))
  }
}
```

### Entry Points in Frameworks

Use frameworks for web APIs, CLIs, or other entry points. Employ dependency injection for composability.

The frameworks layer should be thin, delegating to use cases:

```
HTTP Request → Controller → Use Case → Domain Logic → Repository
                   ↓
              Response DTO
```

Example API controller:

```
Controller TasksController {
  createUseCase: CreateTaskUseCase
  completeUseCase: CompleteTaskUseCase

  constructor(create: CreateTaskUseCase, complete: CompleteTaskUseCase) {
    this.createUseCase = create
    this.completeUseCase = complete
  }

  endpoint POST /tasks {
    request = parseBody<CreateTaskRequest>()
    response = createUseCase.execute(request)
    return HTTP 201 Created with response
  }

  endpoint PUT /tasks/{id}/complete {
    request = CompleteTaskRequest(id: pathParam("id"))
    response = completeUseCase.execute(request)
    return HTTP 200 OK with response
  }
}
```

## Polyglot Architecture Integration

Clean Architecture principles enable straightforward integration across multiple languages by maintaining strict
boundaries and clear interfaces.

### Bounded Contexts and Language Choice

Bounded contexts can be implemented in different languages based on domain needs:
- Choose languages that best fit the domain's requirements (e.g., Python for ML, C# for enterprise integrations)
- Each context maintains its own domain model
- Contexts communicate through well-defined interfaces

### Cross-Language Boundaries

**Anti-Corruption Layers**: Place translation logic at language boundaries. Each domain maintains its own model; the
anti-corruption layer translates external models to internal ones. This prevents external concepts from polluting the
domain.

**Interface-Based Communication**:
- Define contracts (interfaces/protocols/schemas) at boundaries
- Communication via HTTP APIs or message queues
- Never share domain objects directly across language boundaries
- Each domain validates and translates incoming data

**Dependency Direction**: Dependencies point inward even across languages. Infrastructure in Language A can call
Application layer in Language B via well-defined APIs, but never directly couple to Language B's domain objects.

**Communication Patterns**:
- **Synchronous**: HTTP/REST APIs for request-response workflows
- **Asynchronous**: Message queues for event-driven, decoupled workflows
- **Contracts**: Shared JSON schemas or protocol buffers for consistency

### Integration Example

```
C# Domain (Orders) ←→ [API/Messages] ←→ Python Domain (Analytics)
       ↓                                          ↓
Domain Model A                            Domain Model B
ACL translates                            ACL translates
at boundary                               at boundary
```

**Key Principle**: Architecture enforces separation; language boundaries are treated as another form of layer boundary.
Communication happens through defined interfaces, maintaining the inward-pointing dependency rule.

## Testing Strategies

Follow the testing pyramid: Prioritize unit tests for the domain layer, integration tests for application and
infrastructure, and limited end-to-end tests.

### Testing Pyramid

- **Unit Tests (Most)**: Test domain entities, value objects, and domain services in complete isolation. Fast, numerous,
  no dependencies.
- **Integration Tests (Medium)**: Test use cases with mocked or real repositories and gateways, or test infrastructure
  implementations against databases/services.
- **End-to-End Tests (Fewest)**: Test entire workflows through the API. Slow, brittle, cover happy paths and critical
  flows only.

### Best Practices

- **Domain Layer**: Pure unit tests with no dependencies. Mock external interfaces.
- **Application Layer**: Test use cases with mocked repositories and gateways.
- **Infrastructure Layer**: Integration tests against real databases (use test containers or in-memory providers).
- **Architectural Fitness Functions**: Use custom scripts or tools to enforce layer boundaries (e.g., ensure domain
  doesn't reference infrastructure).

Mirror test structure to source code, e.g., `tests/domain/` and `tests/application/`.

Example tests:

```
// Unit test - Domain layer
Test "Order creation sets initial status" {
  order = Order.create(customerId: "customer-1")

  assert order.status equals OrderStatus.Pending
  assert order.items.isEmpty equals true
}

// Integration test - Application layer
Test "CreateOrderUseCase saves order" {
  mockRepository = Mock<OrderRepository>()
  useCase = CreateOrderUseCase(mockRepository)
  request = CreateOrderRequest(customerId: "customer-1", items: [])

  response = useCase.execute(request)

  assert response.created equals true
  verify mockRepository.save was called once
}

// Integration test - Infrastructure layer
Test "SqlOrderRepository persists order" {
  testDatabase = createTestDatabase()
  repository = SqlOrderRepository(testDatabase)
  order = Order.create(customerId: "customer-1")

  repository.save(order)
  retrieved = repository.findById(order.id)

  assert retrieved.id equals order.id
  assert retrieved.customerId equals "customer-1"
}
```

## Requirements for Adopting Clean Architecture

- **Prerequisites**: Strong OOP knowledge, understanding of interfaces/abstractions, familiarity with dependency
  injection
- **Project Structure**: Use directories that reflect layers (`Domain/`, `Application/`, `Infrastructure/`,
  `Frameworks/`)
- **Best Practices**:
    - Prioritize inward dependencies; avoid direct cross-layer imports
    - Write tests first (TDD) to guide design
    - Use dependency injection (manual or via frameworks)
    - Incorporate repositories for data and event buses for cross-cutting concerns
- **Common Pitfalls**: Overengineering for small projects; neglecting performance in outer layers; allowing
  architectural drift without enforcement tools

| Aspect               | Recommendation                        | Examples                         |
|----------------------|---------------------------------------|----------------------------------|
| Interfaces           | Define in Application layer           | Repository, Gateway interfaces   |
| Persistence          | Abstract with repositories            | In-memory (tests), DB (prod)     |
| Dependency Injection | Use framework or manual patterns      | Built-in container, manual       |
| Testing              | Pyramid approach                      | Unit, integration, E2E           |

## Benefits for Developers and Teams

- **Individual Developers**: Gain skills in modular design, simplifying debugging and feature addition.
- **Teams**: Enable parallel development (e.g., UI work independent of domain); reduce onboarding via clear structures.
- **Long-Term**: Lower maintenance costs, faster delivery, and easier tech stack evolution.

## Summary

Clean Architecture empowers projects to focus on business value over infrastructure. Start with the Dependency Rule and
layers, then iterate with tests and refactoring. The four-layer structure, clear boundaries, and dependency inversion
work universally across languages and frameworks.

Key takeaways:
- Implement vertically by user story (P1, P2, P3)
- Maintain layer boundaries horizontally (dependencies flow inward)
- Default to private encapsulation
- Use pseudo-code to think about principles before syntax
- Test at every layer appropriately

## Appendix: Language-Specific Quick Reference

This section provides syntax mappings for common Clean Architecture patterns across languages. Refer to your language's
documentation for detailed implementation guidance.

### Type System Comparison

| Concept          | C# Pattern                              | Python Pattern                     |
|------------------|-----------------------------------------|------------------------------------|
| Entity           | `class` with private fields             | `@dataclass` with `_` prefix       |
| Value Object     | `record Money(decimal, string)`         | `BaseModel` with `frozen = True`   |
| DTO/Request      | `record CreateRequest(...)`             | `BaseModel` (Pydantic)             |
| Interface        | `interface IRepository`                 | `Protocol` (typing)                |
| Nullable         | `Order?` (nullable reference types)     | `Optional[Order]` (typing)         |

### Encapsulation

| Language | Private Field          | Public Property (Read-Only)      | Controlled Access     |
|----------|------------------------|----------------------------------|-----------------------|
| C#       | `private decimal _bal` | `public decimal Bal => _bal;`    | Property with getter  |
| Python   | `self._balance`        | `@property def balance: ...`     | `@property` decorator |

### Interfaces and Abstractions

**C# Interface:**
```csharp
public interface IOrderRepository
{
    Task<Order?> FindByIdAsync(string id);
    Task SaveAsync(Order order);
}
```

**Python Protocol:**
```python
from typing import Protocol, Optional

class OrderRepository(Protocol):
    async def find_by_id(self, order_id: str) -> Optional[Order]: ...
    async def save(self, order: Order) -> None: ...
```

### Dependency Injection

**C# (Built-in Container):**
```csharp
// Program.cs
builder.Services.AddScoped<PlaceOrderUseCase>();
builder.Services.AddScoped<IOrderRepository, SqlOrderRepository>();

// Controller
public class OrdersController : ControllerBase
{
    private readonly PlaceOrderUseCase _useCase;

    public OrdersController(PlaceOrderUseCase useCase) => _useCase = useCase;
}
```

**Python (FastAPI):**
```python
# dependencies.py
async def get_order_repository() -> OrderRepository:
    return SqlOrderRepository(session)

# router
@router.post("/orders")
async def create_order(
    request: CreateOrderRequest,
    repository: OrderRepository = Depends(get_order_repository)
):
    use_case = PlaceOrderUseCase(repository)
    return await use_case.execute(request)
```

### Project Structure

**C# Convention:**
```
Solution.sln
├── Domain/                  # Class library, no dependencies
├── Application/             # References Domain only
│   └── Orders/
│       ├── PlaceOrder.cs   # Use case + request/response
│       └── OrderViews.cs
├── Infrastructure/          # References Application + Domain
│   └── Repositories/
└── WebApi/                  # References all (for DI)
    └── Controllers/
```

**Python Convention:**
```
project/
├── domain/                  # Pure domain, no dependencies
├── application/             # Depends on domain only
│   └── orders/
│       ├── place_order.py  # Use case + request/response
│       └── views.py
├── infrastructure/          # Depends on application + domain
│   └── repositories/
└── frameworks/              # Depends on all
    └── api/
        └── routers/
```

### Testing Libraries

| Purpose              | C#                           | Python                      |
|----------------------|------------------------------|-----------------------------|
| Test Framework       | xUnit, NUnit, MSTest         | pytest                      |
| Mocking              | Moq, NSubstitute             | unittest.mock, pytest-mock  |
| Assertions           | FluentAssertions             | Built-in assert             |
| Async Testing        | Built-in                     | pytest-asyncio              |
| Type Checking        | Built-in compiler            | mypy                        |

### Naming Conventions

| Element            | C#              | Python          |
|--------------------|-----------------|-----------------|
| Classes            | PascalCase      | PascalCase      |
| Methods            | PascalCase      | snake_case      |
| Variables          | camelCase       | snake_case      |
| Private Fields     | `_camelCase`    | `_snake_case`   |
| Constants          | PascalCase      | UPPER_SNAKE     |
| Interface Prefix   | `I` (IRepo)     | No prefix       |

## Further Reading

- **"Clean Architecture" by Robert C. Martin** - Foundational text on architectural principles
- **"Domain-Driven Design" by Eric Evans** - Deep dive into DDD concepts
- **"Implementing Domain-Driven Design" by Vaughn Vernon** - Practical DDD implementation
- **"Clean Architecture with Python" by Sam Keen** - Language-specific application
