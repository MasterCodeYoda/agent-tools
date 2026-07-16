# TDD: Red-Green-Refactor

Load from `@test-strategy` when driving design with tests.

When the interface is unclear or you want tests to drive design, use TDD.

### Red — Write a Failing Test

```
test "returns validation error when title is empty":
  result = createTask(title: "")
  assert result is error
  assert result.message contains "title"
```

**Rules:**
- Write exactly ONE test
- Run it — confirm it **fails**
- The failure message should be clear and meaningful
- If it passes immediately, you either don't need this test or your test is wrong

### Green — Make It Pass

Write the **simplest code** that makes the test pass. This means:

- Hard-coding is acceptable temporarily
- Ignore edge cases not covered by a test
- Don't add code "just in case"
- Resist the urge to write the "real" implementation

```
function createTask(title):
  if title is empty:
    return error("title is required")
  return Task(id: generateId(), title: title)
```

### Refactor — Clean Up

With all tests green, improve the code without changing behavior:

- Extract duplicated logic
- Improve names
- Simplify conditionals
- Apply design patterns where they reduce complexity

**Critical rule:** Tests must stay green throughout refactoring. If a test breaks, you changed behavior, not structure.

### Per-Cycle Checklist

Use this quick reference during each Red-Green-Refactor cycle:

#### Red Phase
- [ ] Test describes a single behavior
- [ ] Test name explains the expected outcome
- [ ] Test fails for the right reason (not a syntax error)
- [ ] Failure message is clear

#### Green Phase
- [ ] Only wrote code to pass the failing test
- [ ] Didn't add speculative functionality
- [ ] All tests pass (not just the new one)

#### Refactor Phase
- [ ] All tests still pass
- [ ] Removed duplication introduced in Green
- [ ] Names are clear and intention-revealing
- [ ] No dead code or unused parameters

