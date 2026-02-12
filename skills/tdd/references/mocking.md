# Mocking Strategy

When and how to use test doubles, with a focus on mocking at system boundaries only.

## Core Principle: Mock at Boundaries

Mock the things you **don't own and can't control**. Use real implementations for everything else.

```
┌─────────────────────────────────────────┐
│            Your System                  │
│                                         │
│  Domain ──── Application ──── Framework │
│     │              │              │     │
│     └── real ──────┘── real ──────┘     │
│                                         │
└────────────┬──────────────┬─────────────┘
             │              │
         MOCK HERE      MOCK HERE
             │              │
        ┌────┴────┐   ┌────┴────┐
        │ Database│   │ Ext API │
        └─────────┘   └─────────┘
```

## What to Mock

### External APIs and Services

Third-party HTTP services, payment processors, email providers — anything with a network boundary.

```
// Mock the HTTP client or SDK, not your wrapper
test "sends welcome email after signup":
  emailService = mock(EmailService)
  signup(user: newUser, emailService: emailService)
  assert emailService.send was called with recipient: newUser.email
```

### Databases and Persistence

In unit tests, mock the repository interface. In integration tests, use a real database.

```
// Unit test: mock the repository
test "use case returns not found for missing task":
  repo = mock(TaskRepository, findById: returns(null))
  result = getTask(id: "missing-123", repo: repo)
  assert result is NotFoundError

// Integration test: real database
test "repository persists and retrieves task":
  repo = RealTaskRepository(testDatabase)
  repo.save(Task(title: "test"))
  found = repo.findById(savedId)
  assert found.title == "test"
```

### Time and Randomness

Inject clocks and random generators so tests are deterministic.

```
test "task is overdue when past deadline":
  clock = fixedClock(date: "2025-03-15")
  task = Task(deadline: "2025-03-14", clock: clock)
  assert task.isOverdue == true
```

### Filesystem and Environment

File reads, environment variables, configuration files.

## What NOT to Mock

### Your Own Modules

If you wrote it and it's part of the same system, use the real thing:

```
// Don't mock your own validator
// BAD
test "createTask calls validator":
  validator = mock(TaskValidator)
  createTask(title: "test", validator: validator)
  assert validator.validate was called

// GOOD — use the real validator, test the outcome
test "createTask rejects invalid title":
  result = createTask(title: "")
  assert result is ValidationError
```

### Internal Collaborators

If a service calls a helper, don't mock the helper. Test through the service's public API.

### Simple Value Objects

Entities, DTOs, and data structures — use real instances. They're fast and deterministic.

## SDK-Style Interfaces for Testability

Design your system boundaries as narrow interfaces that are easy to mock:

```
// Define a slim interface for the boundary
interface PaymentGateway:
  charge(amount, currency, token) → PaymentResult

// Production implementation
class StripeGateway implements PaymentGateway:
  charge(amount, currency, token):
    return stripe.charges.create(...)

// Test double
class FakePaymentGateway implements PaymentGateway:
  charges = []
  charge(amount, currency, token):
    charges.append({amount, currency, token})
    return PaymentResult(success: true)
```

This pattern gives you a clear contract at the boundary. The fake is simple, predictable, and tests can inspect its state.

## Dependency Injection for Testing

Accept dependencies through constructors or parameters instead of creating them internally.

### Python

```python
class TaskService:
    def __init__(self, repo: TaskRepository, clock: Clock = SystemClock()):
        self._repo = repo
        self._clock = clock

    def create(self, title: str) -> Task:
        task = Task(title=title, created_at=self._clock.now())
        return self._repo.save(task)

# In tests:
service = TaskService(repo=FakeTaskRepo(), clock=FixedClock("2025-01-01"))
```

### TypeScript

```typescript
class TaskService {
  constructor(
    private repo: TaskRepository,
    private clock: Clock = new SystemClock()
  ) {}

  create(title: string): Task {
    const task = new Task(title, this.clock.now());
    return this.repo.save(task);
  }
}

// In tests:
const service = new TaskService(new FakeTaskRepo(), new FixedClock("2025-01-01"));
```

### C#

```csharp
public class TaskService
{
    private readonly ITaskRepository _repo;
    private readonly IClock _clock;

    public TaskService(ITaskRepository repo, IClock? clock = null)
    {
        _repo = repo;
        _clock = clock ?? new SystemClock();
    }

    public Task Create(string title)
    {
        var task = new Task(title, _clock.Now());
        return _repo.Save(task);
    }
}

// In tests:
var service = new TaskService(new FakeTaskRepo(), new FixedClock(new DateTime(2025, 1, 1)));
```

## Fakes vs Mocks vs Stubs

| Type | Purpose | When to Use |
|------|---------|-------------|
| **Fake** | Working implementation with shortcuts | In-memory repositories, fake APIs |
| **Stub** | Returns pre-configured responses | When you need specific return values |
| **Mock** | Records interactions for verification | When verifying a side effect (email sent, event published) |

**Prefer fakes** for repositories and services. They're reusable, don't couple tests to call sequences, and behave like real implementations.

**Use mocks sparingly** — only when verifying that a side effect occurred (notification sent, event published). Over-mocking leads to brittle tests that break on refactoring.
