# Testing anti-patterns

Load from `@test-strategy` when reviewing or writing tests for common failure modes.

### Writing All Tests First

Don't write a complete test suite before any implementation. TDD is an **incremental** process — each test informs the next design decision.

**Why it fails:** You're guessing at the interface before you've learned from implementing it. You'll spend time rewriting tests when the design evolves.

### Testing Implementation Details

```
// Anti-pattern: testing HOW
test "calls validate() before save()":
  mock = spy(validator)
  createTask(title: "Buy groceries")
  assert mock.validate was called before mock.save

// Better: testing WHAT
test "invalid task is not persisted":
  createTask(title: "")
  assert taskCount() == 0
```

### Mocking Internal Collaborators

If you're mocking a class you own and that lives in the same system, you're probably testing wiring instead of behavior. See `references/mocking-and-contracts.md` for guidance on what to mock.

### Over-Testing Getters and Setters

Simple property access doesn't need dedicated tests. If a getter returns a value set by the constructor, that's tested implicitly through behavior tests.

### Duplicating Static Guarantees

Tests that verify properties already enforced by the compiler or linter:

```
// Anti-pattern: testing that a function rejects the wrong type
test "rejects non-string title":
  result = createTask(title: 42)       // compiler already prevents this

// Anti-pattern: testing that a required field exists
test "task has an id after construction":
  task = Task(title: "Buy groceries")
  assert task.id is not null            // type system guarantees non-null id

// Anti-pattern: testing exhaustive matching
test "handles all status values":
  for status in [Active, Archived, Deleted]:
    formatStatus(status)                // compiler enforces exhaustive match

// Anti-pattern: testing code formatting
test "functions use camelCase naming":
  // linter already enforces this
```

**Better: test the behavior around the same code:**

```
test "task id is unique across multiple creations":
  task1 = createTask(title: "First")
  task2 = createTask(title: "Second")
  assert task1.id != task2.id           // uniqueness is a business rule, not a type guarantee

test "archived tasks are excluded from active list":
  task = createTask(title: "Buy groceries")
  archive(task)
  assert task not in listActiveTasks()  // state transition behavior the compiler can't verify
```

**Why agents do this:** When generating tests for high coverage, agents gravitate toward easy-to-write assertions that verify structural properties. These feel productive but test the toolchain, not the system.

### Testing Private Methods

If you feel the need to test a private method, it's a signal that the method should either:
- Be extracted into its own module (and tested through its public API)
- Be tested indirectly through the behavior it supports

### Tautological Tests (AI-Specific)

Tests that mirror the implementation rather than verifying behavior independently:

```
// Anti-pattern: the test restates the implementation
function double(x): return x * 2

test "double returns x * 2":
  assert double(5) == 5 * 2   // just repeating the formula

// Better: test with expected concrete values
test "double returns twice the input":
  assert double(5) == 10
  assert double(0) == 0
  assert double(-3) == -6
```

**Why agents do this:** When you write both the implementation and the test, the test naturally mirrors your reasoning. Force yourself to use concrete expected values, not computed ones.

### Assertion-Free Testing (AI-Specific)

Tests that run code but never verify outcomes:

```
// Anti-pattern: no meaningful assertion
test "processes the order":
  order = createOrder(items: [item(price: 10)])
  processOrder(order)
  // ... no assertion — test "passes" because nothing threw

// Better: assert on the observable outcome
test "processing an order updates its status to fulfilled":
  order = createOrder(items: [item(price: 10)])
  processOrder(order)
  assert order.status == "fulfilled"
```

### Context Leakage (AI-Specific)

Tests that depend on shared mutable state or execution order:

```
// Anti-pattern: test depends on prior test's side effect
test "creates a task":
  createTask(title: "First")       // leaves state behind

test "lists all tasks":
  tasks = listTasks()
  assert tasks.count == 1          // depends on previous test

// Better: each test owns its state
test "lists all tasks":
  createTask(title: "First")       // arrange within the test
  tasks = listTasks()
  assert tasks.count == 1
```

