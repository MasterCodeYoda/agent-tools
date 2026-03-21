---
name: test-strategy
description: Testing strategy for agents. Covers strategy selection (TDD, spec-first, property-based, contract, characterization), Red-Green-Refactor, tracer bullet testing, behavior-driven test design, mocking, property testing, and test quality verification. Language-agnostic with AI-specific anti-patterns.
---

# Testing Strategy

A framework for selecting and applying the right testing approach for each situation, ensuring every test provides genuine confidence in system behavior.

## When to Use This Skill

Activate this skill when:

- Executing work via `/workflow:execute` — testing integrates with the execution loop
- Writing tests for new functionality
- Planning test strategy during `/workflow:plan`
- Refactoring existing code while preserving behavior
- Designing interfaces for testability
- Evaluating test quality beyond coverage percentages

## Strategy Selection

Not every situation calls for the same testing approach. Select based on what you're building:

| Situation | Strategy | Why |
|-----------|----------|-----|
| Interface is unclear or evolving | **TDD (Red-Green-Refactor)** | Tests drive the design; each cycle reveals the next interface decision |
| Contract is well-known upfront | **Spec-First Testing** | Write tests from the specification, then implement to satisfy them |
| Data transformations / parsers | **Property-Based Testing** | Generates edge cases humans miss; verifies invariants across input space |
| Service boundaries / APIs | **Contract Testing** | Ensures producer and consumer agree on the interface shape |
| Legacy code, original authors gone | **Characterization Testing** | Intent unknown — capture what it does as proxy before making changes |
| AI-generated code, not fully reviewed | **Characterization → Specification** | Intent unverified — capture what it does, then validate against intended behavior |
| Refactoring code with known intent | **Specification Testing** | Intent known — encode what it *should* do, not what it currently does. Catches bugs too. |
| Straightforward CRUD | **Example-Based Tests** | Simple input/output cases are sufficient; don't over-engineer |

### Characterization vs. Specification: The Intent Decision

The choice between characterization and specification testing depends on **whether intent is verified**, not on code age:

- **Specification tests** encode what the code *should* do. Use when you or your team wrote the code with known, reviewable intent. These catch bugs in current code — characterization tests would enshrine them.
- **Characterization tests** encode what the code *currently does*. Use when intent is unknown or unverified — true legacy code, or AI-generated code that was accepted without full review.
- **AI-generated code is a special case**: an agent that wrote a function last week is not meaningfully different from a developer who left the company last year, from the perspective of "do we know *why* it does what it does?" Characterization testing surfaces "what did the AI actually build?" which is the prerequisite to "is that what we wanted?"

**Emergent interactions** warrant targeted characterization even in known-intent code. When decomposing a monolith, individual responsibilities may be well-understood, but their interactions (transaction boundaries, commit ordering, shared mutable state accumulation, error propagation paths) are often emergent rather than designed. Test these interaction seams with characterization before refactoring.

### Combining Strategies

Most features use more than one strategy. A typical vertical slice might use:

- **TDD** for domain logic where the interface is being discovered
- **Contract tests** for the external API boundary
- **Property-based tests** for a data transformation within the domain
- **Example-based tests** for the framework layer (API endpoint, controller)

A pre-refactoring test investment should prioritize:
1. **Specification tests** for each planned component's behavior (written against the monolith, validated after extraction)
2. **Transaction boundary tests** that verify commit ordering and partial-failure behavior — the area where intent may not be fully designed
3. **Skip broad characterization** of complex functions — they're too complex to meaningfully characterize as a unit if you understand the intent

## Philosophy

### Tests Verify Behavior, Not Implementation

Good tests describe **what** the system does through its public interfaces. They don't care **how** it does it internally. This means:

- Test through public APIs and return values, not private methods
- Assert on observable outcomes (return values, state changes, side effects), not internal state
- Write tests that survive refactoring — if you rename a private helper, no test should break

### Mock at Architectural Boundaries (Service Abstractions)

Prefer tests that exercise real collaborators working together within a layer. Mock at **service abstraction boundaries** — the interfaces that separate architectural layers:

- **Service abstractions** (repository, gateway, event publisher): Mock these in use case tests. They are architectural boundaries by design. Prefer fakes (in-memory implementations) over mocking frameworks.
- **Unmanaged external services** (third-party APIs, message buses, SMTP): Always mock. These are both boundaries and external systems.
- **Never mock** internal collaborators within the same layer, domain objects, value objects, or implementation details behind a service abstraction.

The principle is *mock at the boundary, not at the class*. When your test mocks an internal collaborator that has no service abstraction interface, it's testing wiring, not behavior.

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

### Respect Static Guarantees

Don't write tests for what the type system already guarantees, nor the linter.

Type systems enforce nullability, type correctness, exhaustive matching, and required fields at compile time. Linters enforce style, unused variables, complexity, and import ordering. Writing runtime tests for these properties adds noise, slows suites, and creates false maintenance burden — all without catching a single real bug.

Focus test energy on **behavior the compiler can't verify**:

- Business rules and domain invariants
- State transitions and temporal ordering
- Integration correctness across system boundaries
- Data integrity when crossing serialization/network/storage boundaries
- Race conditions and concurrency behavior

**The boundary test:** If removing your test and introducing the bug it guards against would cause a **compile error or lint failure**, the test is redundant. Delete it and spend that effort on a behavioral test instead.

### AI-Specific Discipline

When generating tests, agents face unique failure modes that human developers don't. Guard against:

- **Tautological tests** — Tests that restate the implementation as assertions. If you wrote the code and the test in the same session, verify the test would catch a real bug.
- **Assertion-free tests** — Tests that execute code but never assert anything meaningful. Every test must assert on an observable outcome.
- **Context leakage** — Tests that pass because they share mutable state with other tests. Each test must be independently runnable.
- **Unverified intent** — AI-generated code has the same intent gap as legacy code. An agent that wrote a function last week is not meaningfully different from a developer who left the company — you may not know *why* it does what it does. When working with AI-generated code that wasn't fully reviewed, apply characterization testing first to surface "what did the AI actually build?", then specification testing to verify "is that what we wanted?".
- **Untested mutations** — After writing tests, run mutation testing (or manual sabotage) on domain logic to verify tests catch real bugs, not just exercise code paths. See `references/mutation-testing.md`.

See `references/test-quality.md` for a complete quality verification framework.

## TDD: Red-Green-Refactor

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

## Testing with Vertical Slices

Testing integrates naturally with vertical slice delivery, regardless of which strategy you select.

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

For each remaining behavior, apply the appropriate testing strategy:

```
for each behavior in remaining_behaviors:
  write a failing test (using TDD, spec-first, or property-based as appropriate)
  implement minimal code to pass
  refactor if needed, run full tests
```

### 4. Slice Complete

When all behaviors pass:

- Run the full test suite (not just new tests)
- Refactor across the slice if patterns emerged
- Commit with issue reference

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

## Debugging Failing Tests

When a test fails, resist the urge to guess from the error message. Apply structured reasoning:

1. **Read the full test.** Understand every assertion — tests often check multiple conditions. The failing assertion may not be the most informative one.
2. **Distinguish the crash site from the root cause.** A `StackOverflowError` at line 185 doesn't mean line 185 is buggy — trace back to what caused the infinite recursion. An `AssertionError` on a return value means the bug is upstream.
3. **Trace the execution path.** Follow each function call from the test into production code to its actual definition. Don't assume behavior from names — `format()` might be shadowed by a module-level function, `equals()` might be overridden.
4. **Check the opposite hypothesis.** Before concluding you've found the bug, ask: "What if this code is correct and the issue is elsewhere?" Look for evidence that would refute your theory.

These principles are especially important for AI agents, who tend to pattern-match on error messages rather than tracing actual execution paths.

## References

- `references/test-design.md` — Writing good tests: naming, structure, what to assert, spec-first testing
- `references/mocking-and-contracts.md` — When and how to mock, dependency injection, contract testing
- `references/interface-design.md` — Designing interfaces that are easy to test
- `references/refactoring.md` — Refactoring safely under test coverage
- `references/property-testing.md` — Property-based testing patterns, tools, and when to use
- `references/test-quality.md` — Mutation testing, assertion quality, the coverage trap
- `references/mutation-testing.md` — Tool configuration, incremental strategies, agent-driven survivor analysis

### Language-Specific Test Organization

**Rust:** For source files exceeding ~300 LOC (or where test LOC exceeds production LOC), extract tests into a sibling `tests.rs` submodule rather than inlining them. Declare `#[cfg(test)] mod tests;` in the source file and use `use super::*;` in `tests.rs` to retain private item access. See `@code-patterns` → Rust → **Test File Organization** for full thresholds and file layout rules.

## Commands

- `/workflow:audit` — Audit test suite quality against these principles (tests domain)
- `/workflow:review` — Code review references these patterns for test quality assessment

## Related Skills

- **code-patterns**: Language-specific testing tools and frameworks
- **clean-architecture**: Layer-specific testing strategies
- **qa**: E2E test specification authoring. **E2E boundary**: test-strategy owns testing philosophy, assertion design, and strategy selection at all levels including E2E; qa owns the NL spec authoring pipeline and Playwright integration. test-strategy defines *how* to write good test assertions; qa defines *what* E2E flows to cover and manages the spec-to-test pipeline.

## Credits

Adapted from [Matt Pocock's TDD skill](https://github.com/mattpocock/skills/tree/main/tdd), reshaped for agent-driven workflow integration, expanded with strategy selection, property-based testing, contract testing, and AI-specific anti-patterns.
