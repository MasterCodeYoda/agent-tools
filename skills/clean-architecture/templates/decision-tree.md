# Clean Architecture Decision Tree

## Where Does This Code Belong?

Use this decision tree to determine the correct architectural layer for your code.

```
START HERE
    │
    ▼
┌──────────────────────────────────┐
│ What type of code are you writing?│
└──────────────────────────────────┘
    │
    ▼
Is it a business rule or concept?
    │
    ├─ YES ──► DOMAIN LAYER
    │
    ├─ NO ───► Is it orchestrating business operations?
    │              │
    │              ├─ YES ──► APPLICATION LAYER
    │              │
    │              ├─ NO ───► Does it connect to external systems?
    │                             │
    │                             ├─ YES ──► INFRASTRUCTURE LAYER
    │                             │
    │                             └─ NO ───► FRAMEWORKS LAYER
```

## Detailed Questions for Each Layer

### Domain Layer Questions

**Does your code represent:**
- □ A core business concept? (Entity)
- □ A value that describes something? (Value Object)
- □ A business rule that must always be true? (Invariant)
- □ A calculation pure to the business? (Domain Service)
- □ Something significant that happened? (Domain Event)

**If YES to any → DOMAIN LAYER**

**Examples:**
- `Order`, `Customer`, `Product` (Entities)
- `Money`, `Address`, `Email` (Value Objects)
- `PricingService`, `TaxCalculator` (Domain Services)
- `OrderPlaced`, `PaymentProcessed` (Domain Events)

**What NOT to put here:**
- ❌ Database operations
- ❌ HTTP/API calls
- ❌ File I/O
- ❌ Framework-specific code
- ❌ Use case orchestration

---

### Application Layer Questions

**Does your code:**
- □ Coordinate multiple domain objects?
- □ Define a user's intent or action? (Use Case)
- □ Transform between domain and external formats?
- □ Manage transactions across operations?
- □ Define what external services are needed? (Ports)

**If YES to any → APPLICATION LAYER**

**Examples:**
- `CreateOrderUseCase`, `ProcessPaymentUseCase` (Use Cases)
- `OrderRequest`, `OrderResponse` (DTOs)
- `NotificationService`, `PaymentGateway` (Port Interfaces)
- `OrderView`, `CustomerSummary` (Read Models)

**What NOT to put here:**
- ❌ Business rules (put in Domain)
- ❌ Concrete implementations (put in Infrastructure)
- ❌ HTTP/Framework concerns (put in Frameworks)
- ❌ Database queries (put in Infrastructure)

---

### Infrastructure Layer Questions

**Does your code:**
- □ Implement data persistence? (Repository Implementation)
- □ Call external APIs or services? (Gateway Implementation)
- □ Handle file system operations?
- □ Send emails or SMS messages?
- □ Manage caching or message queues?
- □ Implement a port defined in Application layer?

**If YES to any → INFRASTRUCTURE LAYER**

**Examples:**
- `SqlOrderRepository`, `MongoCustomerRepository` (Repositories)
- `StripePaymentGateway`, `SendGridEmailService` (Gateways)
- `RedisCache`, `RabbitMQPublisher` (Infrastructure Services)
- `S3FileStorage`, `LocalFileStorage` (Storage)

**What NOT to put here:**
- ❌ Business logic (put in Domain)
- ❌ Use case orchestration (put in Application)
- ❌ HTTP endpoints (put in Frameworks)
- ❌ User interface code (put in Frameworks)

---

### Frameworks Layer Questions

**Does your code:**
- □ Define HTTP endpoints or routes?
- □ Handle user input from CLI or GUI?
- □ Configure the application or framework?
- □ Set up dependency injection?
- □ Handle authentication/authorization at the boundary?
- □ Transform HTTP requests/responses?

**If YES to any → FRAMEWORKS LAYER**

**Examples:**
- `OrderController`, `CustomerController` (Web Controllers)
- `CreateTaskCommand`, `ListTasksCommand` (CLI Commands)
- `AuthMiddleware`, `ErrorHandler` (Middleware)
- `DatabaseConfig`, `AppSettings` (Configuration)
- `DependencyContainer`, `ServiceProvider` (DI Setup)

**What NOT to put here:**
- ❌ Business logic (put in Domain)
- ❌ Use case implementation (put in Application)
- ❌ Data access logic (put in Infrastructure)

## Quick Decision Matrix

| Question | Domain | Application | Infrastructure | Frameworks |
|----------|---------|------------|----------------|------------|
| Does it know about the database? | ❌ | ❌ | ✅ | ❌ |
| Does it know about HTTP? | ❌ | ❌ | ❌ | ✅ |
| Does it contain business rules? | ✅ | ❌ | ❌ | ❌ |
| Does it orchestrate operations? | ❌ | ✅ | ❌ | ❌ |
| Could it be used in a different application? | ✅ | ❌ | ❌ | ❌ |
| Does it depend on a framework? | ❌ | ❌ | ❌ | ✅ |
| Does it implement an interface? | ❌ | ❌ | ✅ | ❌ |
| Does it define an interface? | ✅ | ✅ | ❌ | ❌ |

## Common Confusions Clarified

### "Where do I put validation?"

**Input format validation** → Frameworks Layer
```python
# Frameworks layer - validating HTTP request format
def validate_request(data):
    if "email" not in data:
        raise HttpBadRequest("email field required")
```

**Business rule validation** → Domain Layer
```python
# Domain layer - validating business rules
class Email:
    def __init__(self, value):
        if "@" not in value:
            raise InvalidEmailError("Invalid email format")
```

### "Where do I put DTOs/ViewModels?"

**Request/Response DTOs** → Application Layer (with use case)
```python
# Application layer - colocated with use case
class CreateOrderRequest:
    customer_id: str
    items: List[OrderItem]
```

**Shared Read Models** → Application Layer (shared views)
```python
# Application layer - shared across multiple use cases
class OrderView:
    # Used by List, Get, Search use cases
```

### "Where do I put mappers?"

**Domain ↔ Database mapping** → Infrastructure Layer
```python
# Infrastructure layer
class OrderMapper:
    def to_domain(self, db_model) -> Order
    def to_db(self, order: Order) -> DbModel
```

**Domain ↔ DTO mapping** → Application Layer
```python
# Application layer
class OrderView:
    @classmethod
    def from_entity(cls, order: Order) -> 'OrderView'
```

### "Where do I put configuration?"

**Application configuration** → Frameworks Layer
```python
# Frameworks layer
class AppConfig:
    DATABASE_URL = os.getenv("DATABASE_URL")
    API_KEY = os.getenv("API_KEY")
```

**Business configuration** → Domain Layer
```python
# Domain layer - if it's a business rule
class PricingRules:
    DISCOUNT_THRESHOLD = 100.00
    TAX_RATE = 0.08
```

## Remember the Dependency Rule

Always check: **Does this create an outward dependency?**

```
✅ Allowed Dependencies:
Domain ← Application ← Infrastructure ← Frameworks

❌ Forbidden Dependencies:
Domain → Application (Domain can't know about use cases)
Application → Infrastructure (Use interfaces instead)
Infrastructure → Frameworks (Infrastructure doesn't know entry points)
```

## Still Unsure?

Ask yourself:
1. **Could this code exist without any frameworks?** → Domain or Application
2. **Could this code exist without knowing how data is stored?** → Domain or Application
3. **Is this code about WHAT the business is?** → Domain
4. **Is this code about WHAT the system does?** → Application
5. **Is this code about HOW things are done technically?** → Infrastructure
6. **Is this code about HOW users interact?** → Frameworks

When in doubt, start in an outer layer and refactor inward as patterns emerge.