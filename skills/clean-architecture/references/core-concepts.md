# Core Concepts of Clean Architecture

## The Dependency Rule

The single most important rule in Clean Architecture:

**Dependencies must point inward. Source code dependencies must point only inward, toward higher-level policies.**

### What This Means

- The innermost circles are the most general and highest level
- The outermost circles are the most specific and lowest level
- Code in inner circles cannot know anything about outer circles
- Data formats used in outer circles should not be used in inner circles

### The Four Layers

```
┌─────────────────────────────────────────────┐
│            Frameworks & Drivers             │
│  (Web, UI, DB, External Interfaces)         │
│ ┌─────────────────────────────────────────┐ │
│ │         Interface Adapters               │ │
│ │   (Controllers, Gateways, Presenters)   │ │
│ │ ┌───────────────────────────────────┐   │ │
│ │ │      Application Business         │   │ │
│ │ │         (Use Cases)               │   │ │
│ │ │ ┌───────────────────────────────┐ │   │ │
│ │ │ │   Enterprise Business         │ │   │ │
│ │ │ │      (Entities)               │ │   │ │
│ │ │ └───────────────────────────────┘ │   │ │
│ │ └───────────────────────────────────┘   │ │
│ └─────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```

## SOLID Principles

Clean Architecture is built on SOLID principles:

### Single Responsibility Principle (SRP)
- A class should have only one reason to change
- Separate concerns into different classes
- Each layer has a single, well-defined responsibility

### Open-Closed Principle (OCP)
- Software entities should be open for extension but closed for modification
- Use interfaces and abstractions to allow extension without changing existing code
- Add new features by adding new code, not changing old code

### Liskov Substitution Principle (LSP)
- Derived classes must be substitutable for their base classes
- Implementations must fulfill the contract of their interfaces
- Don't add constraints that weren't in the abstraction

### Interface Segregation Principle (ISP)
- Clients should not be forced to depend on interfaces they don't use
- Keep interfaces small and focused
- Split large interfaces into smaller, specific ones

### Dependency Inversion Principle (DIP)
- Depend on abstractions, not concretions
- High-level modules should not depend on low-level modules
- Both should depend on abstractions

## Entities and Value Objects

### Entities

**Definition**: Objects with a unique identity that persists over time and across different representations.

**Characteristics:**
- Have a unique identifier (ID)
- Identity remains constant even if attributes change
- Mutable - their state can change over time
- Equality is based on identity, not attributes

**Example:**
```
Entity: Order
- id: "order-123" (never changes)
- status: "pending" → "shipped" → "delivered" (changes)
- items: [...] (can be modified)

Two orders with same items but different IDs are different entities.
```

**Design Guidelines:**
- Protect invariants (business rules that must always be true)
- Encapsulate state changes through methods
- Validate state transitions
- Emit domain events when significant changes occur

### Value Objects

**Definition**: Objects that describe characteristics but have no conceptual identity.

**Characteristics:**
- No unique identifier
- Immutable - create new instances for changes
- Equality based on all attributes
- Can be freely shared

**Example:**
```
Value Object: Money
- amount: 100.00
- currency: "USD"

Two Money instances with same amount and currency are equal.
Money(100, "USD") === Money(100, "USD") // true
```

**Design Guidelines:**
- Make all attributes read-only/final
- Provide methods that return new instances
- Override equality to compare all attributes
- Consider making them records/data classes

### How to Decide: Entity or Value Object?

Ask these questions:
1. **Does it need unique identity?** → Entity
2. **Do we care about its lifecycle?** → Entity
3. **Can it be shared freely?** → Value Object
4. **Is it just describing something?** → Value Object

## Aggregates

**Definition**: A cluster of entities and value objects with defined boundaries and a root entity.

**Key Concepts:**
- **Aggregate Root**: The only entry point to the aggregate
- **Boundary**: Defines what's inside the aggregate
- **Consistency**: Enforces invariants across the aggregate
- **Transaction**: Save the entire aggregate as one unit

**Example:**
```
Aggregate: OrderAggregate
- Root: Order (Entity)
  - OrderItems (Entities)
  - ShippingAddress (Value Object)
  - PaymentDetails (Value Object)

// Access only through root
order.addItem(item)  // ✓ Correct
orderItem.update()   // ✗ Wrong - bypass root
```

**Design Rules:**
1. Reference other aggregates by ID only
2. One aggregate per transaction
3. Update through aggregate root only
4. Small aggregates are better

## Domain Services

**When to Use**: When an operation doesn't naturally belong to any entity or value object.

**Characteristics:**
- Stateless operations
- Defined in terms of domain model
- Part of the ubiquitous language

**Examples:**
- `PricingService.calculateDiscount(order, customer)`
- `TransferService.transfer(fromAccount, toAccount, amount)`
- `RiskAssessmentService.assessCreditRisk(application)`

**Not Domain Services:**
- Repository operations (infrastructure)
- External API calls (infrastructure)
- Use case orchestration (application)

## Encapsulation

### Principles

1. **Information Hiding**
   - Hide implementation details
   - Expose only what's necessary
   - Change internals without affecting clients

2. **Default to Private**
   ```
   BAD:
   class Order:
       items: List[Item]  # Public - can be modified directly

   GOOD:
   class Order:
       _items: List[Item]  # Private

       def add_item(self, item):
           # Validation and business logic here
           self._items.append(item)
   ```

3. **Expose Behavior, Not Data**
   ```
   BAD:
   balance = account.balance
   balance += 100
   account.balance = balance

   GOOD:
   account.deposit(100)
   ```

4. **Use Properties for Controlled Access**
   ```
   @property
   def total(self):
       return sum(item.price for item in self._items)
   ```

### Protecting Invariants

**Invariant**: A condition that must always be true.

**Examples:**
- Order total must equal sum of item prices
- Account balance cannot be negative
- Email must be valid format

**Protection Strategies:**
1. Validate in constructors
2. Validate in methods that change state
3. Make illegal states unrepresentable
4. Use value objects for complex validation

## Domain Events

**Definition**: Something significant that happened in the domain.

**Characteristics:**
- Named in past tense
- Immutable
- Contain relevant data about what happened
- Part of ubiquitous language

**Examples:**
- `OrderPlaced`
- `PaymentProcessed`
- `CustomerRegistered`
- `InventoryDepleted`

**Usage:**
- Decouple aggregates
- Trigger side effects
- Build audit logs
- Enable event sourcing

## Repository Pattern

**Purpose**: Abstract data access, keeping domain free of persistence concerns.

**Interface Characteristics:**
- Defined in domain or application layer
- Uses domain language, not database terms
- Returns domain entities, not data structures
- One repository per aggregate root

**Example:**
```
# Domain/Application Layer - Interface
interface OrderRepository:
    find_by_id(id: OrderId) -> Order?
    find_pending_orders() -> List[Order]
    save(order: Order) -> void

# Infrastructure Layer - Implementation
class SqlOrderRepository(OrderRepository):
    def find_by_id(self, id: OrderId):
        # SQL queries here
        row = db.query("SELECT * FROM orders...")
        return Order.from_row(row)
```

**What Repositories Are NOT:**
- Generic CRUD interfaces
- Direct database access from domain
- Query builders or ORMs exposed to domain
- Data access objects (DAOs)

## Summary

These core concepts form the foundation of Clean Architecture:

1. **Dependencies flow inward** - The fundamental rule
2. **SOLID principles** - Guide design decisions
3. **Entities have identity**, **Value Objects describe**
4. **Aggregates maintain consistency**
5. **Domain Services** for cross-entity operations
6. **Encapsulation** protects business rules
7. **Domain Events** communicate what happened
8. **Repositories** abstract persistence

Master these concepts before moving to implementation details.