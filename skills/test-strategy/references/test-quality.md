# Test Quality Verification

How to verify that your tests actually catch bugs, beyond trusting coverage percentages.

## The Coverage Trap

High code coverage does not mean high test quality. Coverage tells you what code **ran**, not what was **verified**.

```
// 100% coverage, catches nothing
test "process order has coverage":
  order = createOrder(items: [item(price: 10)])
  processOrder(order)    // code executes = coverage
  // no assertion — any bug would go undetected

// 100% coverage, catches bugs
test "processing order calculates correct total":
  order = createOrder(items: [item(price: 10), item(price: 20)])
  result = processOrder(order)
  assert result.total == 30
  assert result.status == "fulfilled"
```

Both tests produce the same coverage number. Only one would catch a bug in the total calculation.

### Coverage as Floor, Not Goal

Use coverage to find **untested code**, not to measure test quality:

- **Below the floor** → you have gaps. Write tests for uncovered paths.
- **Above the floor** → tells you nothing about quality. Use mutation testing instead.

| Layer | Coverage Floor | Quality Verification |
|-------|---------------|---------------------|
| Domain | 85% | Mutation testing |
| Application | 75% | Sabotage test |
| Infrastructure | 60% | Integration completeness |
| Framework | 50% | E2E happy path |

## Mutation Testing

The most reliable way to measure test quality. Mutation testing makes small changes to your code (mutants) and checks whether your tests catch them.

### How It Works

```
1. Your code: if (total > 100) applyDiscount()
2. Mutant #1:  if (total >= 100) applyDiscount()   // boundary change
3. Mutant #2:  if (total > 100) { }                 // removed call
4. Mutant #3:  if (total < 100) applyDiscount()     // negated condition

For each mutant:
  - Run your tests
  - If tests FAIL → mutant killed (your tests caught the bug)
  - If tests PASS → mutant survived (your tests missed it)

Mutation score = killed / total mutants
```

### Mutation Testing Tools

| Language | Tool | Notes |
|----------|------|-------|
| Python | [mutmut](https://mutmut.readthedocs.io/) | Simple CLI; good for small-medium projects |
| TypeScript/JS | [Stryker](https://stryker-mutator.io/) | Most mature JS/TS mutator; supports multiple test runners |
| C# / .NET | [Stryker.NET](https://stryker-mutator.io/docs/stryker-net/introduction/) | MSTest, NUnit, xUnit support |
| Java / Kotlin | [PIT](https://pitest.org/) | Fast; JUnit/TestNG integration |
| Rust | [cargo-mutants](https://mutants.rs/) | Cargo integration; automatic source analysis |
| Go | [go-mutesting](https://github.com/zimmski/go-mutesting) | AST-based mutation |

### When to Run Mutation Tests

- After completing a vertical slice (before commit)
- When coverage is high but confidence is low
- On domain logic where correctness is critical
- As a quality gate in CI for critical paths

Don't run on the entire codebase every time — target the code you changed.

## Assertion Quality Analysis

Not all assertions are equal. Stronger assertions catch more bugs.

### Assertion Strength Progression

| Level | Assertion Type | Example | Catches |
|-------|---------------|---------|---------|
| 0 | No assertion | `processOrder(order)` | Nothing |
| 1 | Existence check | `assert result is not null` | Null returns |
| 2 | Type check | `assert result is Order` | Wrong type |
| 3 | Partial value check | `assert result.status == "done"` | Status bugs |
| 4 | Full value check | `assert result == expected` | Most value bugs |
| 5 | Behavioral check | `assert result == expected AND sideEffect occurred` | Value + integration bugs |

**Aim for level 3-5.** Level 0-2 assertions are test smells.

### Quick Audit

Scan your test files for these warning signs:

- Tests with no `assert` / `expect` / `should` statements
- Tests that only assert on truthiness (`assert result`, `expect(result).toBeTruthy()`)
- Tests where the expected value is computed, not literal
- Tests that assert the same thing the implementation computes

## The Sabotage Test

A manual alternative to mutation testing. Use it when:

- Mutation testing tools aren't available for your language
- You want a quick check on a specific piece of logic
- You're reviewing someone else's tests

### How to Sabotage Test

1. **Pick a critical line** of production code
2. **Introduce a bug** (change a `>` to `>=`, remove a null check, alter a calculation)
3. **Run the tests**
4. **If all tests pass** → your tests are insufficient for that line
5. **Revert the sabotage** and write a test that catches it

```
// Production code
function calculateShipping(weight):
  if weight > 50: return weight * 2.5    // sabotage: change to weight * 3.0
  return weight * 1.5

// If tests still pass after sabotage, add:
test "heavy package shipping rate":
  assert calculateShipping(60) == 150.0  // catches the sabotaged value
```

### Sabotage Targets

Focus sabotage on:

- Boundary conditions (`>` vs `>=`, `<` vs `<=`)
- Business calculations (rates, totals, discounts)
- Error handling (what if you remove the check?)
- Conditional branches (what if you negate the condition?)

## Quality Signals

### Vanity Metrics (Look Good, Mean Little)

| Metric | Why It's Misleading |
|--------|-------------------|
| Code coverage % | Measures execution, not verification |
| Number of tests | More tests does not mean better tests |
| Test execution time | Fast tests that verify nothing are worthless |
| Lines of test code | Verbosity doesn't equal thoroughness |

### Genuine Signals

| Signal | What It Tells You |
|--------|------------------|
| Mutation score | Percentage of injected bugs your tests catch |
| Assertion density | Average meaningful assertions per test |
| Defect escape rate | Bugs that reach production despite tests |
| Refactoring confidence | Can you refactor without fear? |
| Test failure specificity | When a test fails, do you know exactly what broke? |

### The Ultimate Test Quality Question

> If a colleague introduced a subtle bug in this code, would your tests catch it?

If the answer is "I'm not sure," strengthen your assertions or add mutation testing.
