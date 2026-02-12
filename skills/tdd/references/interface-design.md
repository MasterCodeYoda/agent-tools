# Interface Design for Testability

Designing interfaces that are easy to test without sacrificing good design.

## Dependency Injection: Accept, Don't Create

The single most impactful pattern for testability. If a function creates its own dependencies, tests can't substitute them.

```
// Hard to test — creates its own dependency
function getOverdueTasks():
  repo = new DatabaseTaskRepository()    // locked to real database
  clock = SystemClock()                   // locked to real time
  return repo.findAll().filter(t => t.deadline < clock.now())

// Easy to test — accepts dependencies
function getOverdueTasks(repo: TaskRepository, clock: Clock):
  return repo.findAll().filter(t => t.deadline < clock.now())
```

The testable version accepts a `TaskRepository` interface and a `Clock`. In production, these are real implementations. In tests, they're fakes or stubs.

### Constructor vs Parameter Injection

**Constructor injection** — for dependencies that don't change per call:

```
class TaskService:
  constructor(repo: TaskRepository, clock: Clock):
    this.repo = repo
    this.clock = clock
```

**Parameter injection** — for dependencies that vary per call or are optional:

```
function processPayment(order: Order, gateway: PaymentGateway):
  return gateway.charge(order.total, order.currency)
```

Use constructor injection as the default. Parameter injection for strategies or one-off collaborators.

## Pure Functions Over Side Effects

Pure functions are the easiest code to test: given the same input, they always return the same output with no side effects.

```
// Pure — easy to test
function calculateDiscount(total: number, memberTier: string): number:
  if memberTier == "gold" and total > 100:
    return total * 0.15
  if total > 100:
    return total * 0.10
  return 0

// Impure — harder to test
function applyDiscount(cartId: string):
  cart = database.getCart(cartId)        // side effect: DB read
  discount = calculateDiscount(cart)
  database.updateCart(cartId, discount)  // side effect: DB write
  emailService.notify(cart.userId)       // side effect: email
```

**Strategy:** Push side effects to the edges. Keep the core logic pure.

```
// Core logic is pure and easily testable
function calculateOrder(items, memberTier):
  subtotal = sum(items.map(i => i.price))
  discount = calculateDiscount(subtotal, memberTier)
  return OrderSummary(subtotal, discount, total: subtotal - discount)

// Side effects happen at the boundary
function processOrder(orderId):
  order = repo.find(orderId)                    // read
  summary = calculateOrder(order.items, order.memberTier)  // pure
  repo.updateTotal(orderId, summary.total)      // write
```

## Minimal Surface Area

Every public method on an interface is a method you need to test (and mock, when used as a dependency). Keep interfaces small.

```
// Too broad — forces consumers to depend on things they don't use
interface TaskRepository:
  save(task)
  findById(id)
  findAll()
  findByStatus(status)
  findByAssignee(assignee)
  findOverdue()
  delete(id)
  deleteByStatus(status)
  count()
  countByStatus(status)

// Right-sized — each consumer depends on only what it needs
interface TaskWriter:
  save(task)

interface TaskReader:
  findById(id)
  findByStatus(status)

interface TaskDeleter:
  delete(id)
```

This follows the **Interface Segregation Principle**: no client should depend on methods it doesn't use.

### Build Only What You Need

In TDD, you only add methods when a test requires them. This naturally produces minimal interfaces:

```
// Cycle 1: "creating a task persists it"
// Only need: save(task)

// Cycle 2: "can retrieve a task by ID"
// Add: findById(id)

// Cycle 3: "overdue tasks appear in reminder list"
// Add: findOverdue()
```

## Deep Modules

A **deep module** has a simple interface but hides significant complexity. This is good for both design and testing.

```
// Shallow — simple interface, simple implementation (little value)
class TaskTitleValidator:
  validate(title: string): boolean:
    return title.length > 0

// Deep — simple interface, complex implementation (high value)
class TaskScheduler:
  schedule(task: Task): ScheduleResult
  // Internally handles: timezone conversion, conflict detection,
  // recurrence rules, notification scheduling, capacity checking
```

Deep modules reduce the number of things to test at the integration level. The complexity is encapsulated behind a simple contract.

### Testing Deep Modules

Test the **contract** (input → output), not the internal mechanics:

```
test "scheduling a task in a full timeslot returns conflict":
  scheduler = TaskScheduler(calendar: calendarWithFullSlot("Monday 9am"))
  result = scheduler.schedule(task(time: "Monday 9am"))
  assert result is Conflict

test "scheduling a recurring task creates all occurrences":
  result = scheduler.schedule(task(recurrence: weekly, count: 4))
  assert result.occurrences.count == 4
```

## Designing for Testability Without Sacrificing Design

Testability and good design are not in tension — they reinforce each other:

| Good Design Principle | Testing Benefit |
|----------------------|-----------------|
| Single Responsibility | Each test covers one focused behavior |
| Dependency Inversion | Dependencies are swappable in tests |
| Interface Segregation | Fewer methods to mock |
| Open/Closed | New behavior = new tests, existing tests unchanged |
| Pure functions | Deterministic, no setup needed |

**If making code testable requires distorting the design**, you're doing it wrong. Common mistakes:

- Making private methods public just for testing → test through the public API instead
- Adding test-only parameters → use dependency injection at construction time
- Creating god-interfaces → split into focused interfaces
- Exposing internal state → test observable behavior instead
