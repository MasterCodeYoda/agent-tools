# Test Design

Writing tests that verify behavior, survive refactoring, and serve as documentation.

## Good Tests vs Bad Tests

### Good Tests

A good test has four qualities:

1. **Describes behavior** — The test name tells you what the system does
2. **Survives refactoring** — Renaming a private method doesn't break it
3. **Fails meaningfully** — When it fails, you know what's wrong
4. **Is independent** — No test depends on another test's execution

```
// Good: describes observable behavior
test "expired tasks are excluded from active list":
  task = createTask(deadline: yesterday)
  active = getActiveTasks()
  assert task not in active

// Good: tests a business rule
test "discount applies when cart total exceeds threshold":
  cart = Cart(items: [item(price: 150)])
  assert cart.discount == 15
```

### Bad Tests

```
// Bad: tests implementation detail
test "calls sortBy('date') on task array":
  spy = mock(Array)
  getActiveTasks()
  assert spy.sortBy was called with "date"

// Bad: mirrors the implementation
test "add sets total to sum of prices":
  cart.add(item(price: 10))
  cart.add(item(price: 20))
  assert cart._total == 30  // testing private state

// Bad: tests nothing meaningful
test "createTask returns a task":
  result = createTask(title: "test")
  assert result is not null
```

## Testing Observable Behavior

Every test should assert on at least one of these:

| Observable Output | Example |
|-------------------|---------|
| Return value | `assert result == expected` |
| State change (via public API) | `assert list.count == 1` |
| Side effect at boundary | `assert email was sent to user` |
| Exception / error | `assert raises ValidationError` |

If your assertion requires accessing private fields or internal state, the test is coupled to implementation.

## One Logical Assertion Per Test

Each test verifies **one behavior**, though it may use multiple `assert` statements to fully describe that behavior:

```
// One behavior, multiple asserts — fine
test "created task has correct properties":
  task = createTask(title: "Buy groceries", priority: "high")
  assert task.title == "Buy groceries"
  assert task.priority == "high"
  assert task.status == "pending"

// Multiple behaviors — split these
test "task creation and deletion":  // BAD: two behaviors
  task = createTask(title: "test")
  assert task exists
  deleteTask(task.id)
  assert task not exists
```

**Why?** When a multi-behavior test fails, you can't tell which behavior is broken without reading the test code.

## Tests That Survive Refactoring

The highest-value tests are those that stay green when you restructure code without changing behavior.

### Refactoring-proof patterns

```
// Test through the public API, not the helper
test "task list is sorted by deadline":
  create(deadline: tomorrow)
  create(deadline: yesterday)
  tasks = getAll()
  assert tasks[0].deadline < tasks[1].deadline
```

This test doesn't care whether sorting happens in the repository, a service, or a helper function. It verifies the **outcome**.

### Refactoring-fragile patterns

```
// Coupled to a specific helper
test "sortTasksByDeadline returns sorted list":
  result = sortTasksByDeadline(unsortedList)
  assert result is sorted
```

If you inline `sortTasksByDeadline` into the repository, this test breaks even though behavior hasn't changed.

## Naming Conventions

Test names should read as behavioral specifications:

### Pattern: `[context] → [expected outcome]`

```
"empty cart → total is zero"
"expired coupon → returns invalid error"
"admin user → can delete any task"
```

### Pattern: `[action] [condition] [result]`

```
"returns error when email is malformed"
"sends notification after task is assigned"
"excludes deleted items from search results"
```

### Avoid

```
"test1"                          // meaningless
"testCreateTask"                 // describes the method, not the behavior
"should work correctly"          // vague
"test_create_task_with_valid_title_returns_task_with_correct_title_and_id"  // too verbose
```

## Test Structure: Arrange-Act-Assert

Every test follows the same three-part structure:

```
test "overdue tasks appear in reminder list":
  // Arrange — set up preconditions
  task = createTask(deadline: yesterday)

  // Act — perform the action under test
  reminders = getReminders()

  // Assert — verify the outcome
  assert task in reminders
```

Keep each section short. If Arrange is long, consider a test helper or fixture. If Act is more than one or two lines, you may be testing too much at once.

## Test Helpers and Fixtures

Extract repeated setup into helpers, but keep them simple and visible:

```
// Good: named helper that's easy to understand
function createExpiredTask(title = "test"):
  return createTask(title: title, deadline: yesterday)

// Good: factory with sensible defaults
function buildCart(itemCount = 1, itemPrice = 10):
  items = repeat(itemCount, () => item(price: itemPrice))
  return Cart(items: items)
```

**Avoid** deeply nested or magical test fixtures that obscure what's being tested. A developer reading the test should understand the setup without jumping to multiple helper definitions.

## Spec-First Testing

When the contract is known upfront — from an API spec, a requirements document, or a well-defined interface — write tests directly from the specification before implementation.

### When to Use

- API endpoint with a defined request/response contract
- Feature with explicit acceptance criteria
- Library function with documented behavior
- Migration where old behavior must be preserved exactly

### How It Differs from TDD

| | TDD | Spec-First |
|---|-----|------------|
| **Starting point** | Unclear interface | Known contract |
| **Test discovery** | Incremental, one at a time | Batch from specification |
| **Design role** | Tests drive the interface | Tests verify the interface |
| **Refactoring** | Interface may evolve | Interface is stable |

### Workflow

```
1. Read the specification (API doc, acceptance criteria, contract)
2. Write ALL test cases from the spec (not incrementally)
3. Run tests — all should fail (no implementation yet)
4. Implement until all tests pass
5. Add edge case tests discovered during implementation
```

### Example

```
// From API spec: POST /tasks returns 201 with task, 400 for invalid input

test "POST /tasks with valid title returns 201 and task":
  response = post("/tasks", { title: "Buy groceries" })
  assert response.status == 201
  assert response.body.title == "Buy groceries"
  assert response.body.id is not empty

test "POST /tasks with empty title returns 400":
  response = post("/tasks", { title: "" })
  assert response.status == 400
  assert response.body.error contains "title"

test "POST /tasks with missing body returns 400":
  response = post("/tasks", {})
  assert response.status == 400
```

### Guard Against Specification Drift

When using spec-first testing, the specification is your source of truth. If the implementation needs to diverge from the spec:

1. Update the spec first
2. Update the tests to match
3. Then update the implementation

Never let the implementation silently diverge from the specification — that's how API contracts break.
