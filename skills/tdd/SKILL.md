---
name: tdd
description: Test-Driven Development methodology for agents. Covers the Red-Green-Refactor cycle, tracer bullet testing, behavior-driven test design, mocking strategy, and interface design for testability. Language-agnostic with practical guidance for writing tests that survive refactoring.
---

# Test-Driven Development

A methodology for building reliable software by writing tests before implementation, ensuring every line of production code exists to satisfy a verified behavior.

## When to Use This Skill

Activate this skill when:

- Executing work via `/workflow:execute` — TDD integrates with the execution loop
- Writing tests for new functionality
- Planning test strategy during `/workflow:plan`
- Refactoring existing code while preserving behavior
- Designing interfaces for testability

## Philosophy

### Tests Verify Behavior, Not Implementation

Good tests describe **what** the system does through its public interfaces. They don't care **how** it does it internally. This means:

- Test through public APIs and return values, not private methods
- Assert on observable outcomes (return values, state changes, side effects), not internal state
- Write tests that survive refactoring — if you rename a private helper, no test should break

### Integration-Style Tests Over Unit Mocking

Prefer tests that exercise real collaborators working together. Mock only at **system boundaries** — external APIs, databases, clocks, filesystems. When your test mocks an internal collaborator, it's testing the wiring, not the behavior.

### Tests Are Documentation

A well-named test suite is the most accurate documentation of your system's behavior. Each test name should read as a specification:

```
// Good: describes behavior
"returns empty list when no tasks match filter"
"raises error when deadline is in the past"

// Bad: describes implementation
"calls repository.findAll with correct params"
"sets _validated flag to true"
```

## The TDD Cycle with Vertical Slicing

TDD integrates naturally with vertical slice delivery. For each slice:

### 1. Planning — Confirm Behaviors

Before writing code, identify the **behaviors** this slice must exhibit:

```
Slice: "User can create a task"
Behaviors:
  - Creating a task with valid title returns the new task
  - Creating a task with empty title returns a validation error
  - Created tasks appear in the task list
```

### 2. Tracer Bullet — First Behavior End-to-End

Pick the simplest behavior and write **one test** that exercises the full path through your slice. This is your tracer bullet — it proves the layers connect.

```
test "creating a task with valid title returns the new task":
  result = createTask(title: "Buy groceries")
  assert result.title == "Buy groceries"
  assert result.id is not empty
```

Write the **minimum code** across all layers to make this pass. Stubs and simplifications are fine — the goal is a green test proving the wiring works.

### 3. Incremental Loop — Remaining Behaviors

For each remaining behavior, follow Red → Green → Refactor:

```
for each behavior in remaining_behaviors:
  RED:      write a failing test for this behavior
  GREEN:    write minimal code to make it pass
  REFACTOR: clean up, remove duplication, improve names
```

### 4. Slice Complete

When all behaviors pass:

- Run the full test suite (not just new tests)
- Refactor across the slice if patterns emerged
- Commit with issue reference

## Red-Green-Refactor

The core TDD cycle in detail:

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

## Per-Cycle Checklist

Use this quick reference during each Red-Green-Refactor cycle:

### Red Phase
- [ ] Test describes a single behavior
- [ ] Test name explains the expected outcome
- [ ] Test fails for the right reason (not a syntax error)
- [ ] Failure message is clear

### Green Phase
- [ ] Only wrote code to pass the failing test
- [ ] Didn't add speculative functionality
- [ ] All tests pass (not just the new one)

### Refactor Phase
- [ ] All tests still pass
- [ ] Removed duplication introduced in Green
- [ ] Names are clear and intention-revealing
- [ ] No dead code or unused parameters

## Common Anti-Patterns

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

If you're mocking a class you own and that lives in the same system, you're probably testing wiring instead of behavior. See `references/mocking.md` for guidance on what to mock.

### Over-Testing Getters and Setters

Simple property access doesn't need dedicated tests. If a getter returns a value set by the constructor, that's tested implicitly through behavior tests.

### Testing Private Methods

If you feel the need to test a private method, it's a signal that the method should either:
- Be extracted into its own module (and tested through its public API)
- Be tested indirectly through the behavior it supports

## References

- `references/test-design.md` — Writing good tests: naming, structure, what to assert
- `references/mocking.md` — When and how to mock, dependency injection for testability
- `references/interface-design.md` — Designing interfaces that are easy to test
- `references/refactoring.md` — Refactoring safely under test coverage

## Credits

Adapted from [Matt Pocock's TDD skill](https://github.com/mattpocock/skills/tree/main/tdd), reshaped for agent-driven workflow integration and language-agnostic application.
