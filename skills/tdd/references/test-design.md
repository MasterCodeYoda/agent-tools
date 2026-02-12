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
