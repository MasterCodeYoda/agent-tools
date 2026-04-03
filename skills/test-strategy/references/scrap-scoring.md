# SCRAP — Structural Complexity Rating for Assessment of test Prose

A composite quality metric for test code, adapted from [Uncle Bob Martin's reference implementation](https://github.com/unclebob/scrap). Where CRAP (Change Risk Anti-Patterns) scores production code risk, SCRAP scores test code structural quality — surfacing tests that are too complex, too weak, or too tangled to provide genuine confidence.

SCRAP is designed for AI agent consumption. It produces numeric scores and actionability classes that agents can use as optimization targets when improving test suites.

## Core Formula

Per test function:

```
SCRAP = saturating_complexity_score(complexity) + smell_penalties
```

### Complexity

```
complexity = 1
  + branch_count
  + scored_setup_depth
  + helper_indirection
  + (helper_hidden_lines / 8)
```

**Definitions:**

- **branch_count** — Control flow constructs inside the test: `if`, `else`, `match`, `switch`, `case`, `for`, `while`, ternary operators, `try/catch` with branching logic. Exclude simple `with` context managers and single-level `for` used for table-driven parameterization.
- **scored_setup_depth** — Nesting depth of setup constructs: `let` bindings, `with` blocks, context managers, fixture injection chains, `beforeEach` nesting, `setUp` inheritance depth. For API-contract-style tests (see below), subtract 2 (floor 0) — shallow setup is expected for integration tests.
- **helper_indirection** — Calls to test-local helper functions or builder methods defined in the same test file or test utilities module. Factory methods from production code don't count.
- **helper_hidden_lines** — Estimated lines hidden behind helper calls. When test helpers abstract away setup, that complexity doesn't vanish — it just becomes invisible. Count the body lines of each called helper. Divide by 8 to dampen.

### Saturating Complexity Score

Rather than `complexity^2` (which makes outliers useless), use a saturating curve:

```
score = floor + (cap - floor) * (1 - e^(-rise_rate * (complexity - 1)))
```

**Policy defaults:** `cap = 25.0`, `rise_rate = 0.18`, `floor = 1.0`

This means:
- Complexity 1 → score 1.0 (trivial test)
- Complexity 3 → score 8.4
- Complexity 5 → score 13.5
- Complexity 10 → score 20.6
- Complexity 20+ → approaches 25.0 (capped)

The curve rises steeply from trivial to moderate but prevents very large tests from producing meaninglessly extreme scores.

## Smell Penalties

Additive penalties on top of the complexity score. Each smell represents a structural anti-pattern:

| Smell | Penalty | Trigger | Why It Matters |
|-------|---------|---------|----------------|
| `no-assertions` | +10 | Zero assertion statements | Test provides zero verification — pure coverage theater |
| `low-assertion-density` | +6 | Exactly 1 assertion in a test longer than 10 lines (non-table-driven, non-API-contract) | Long test with minimal verification — probably exercising, not asserting |
| `multiple-phases` | +5 | More than one act/assert cycle, or multiple unrelated assertion clusters separated by actions | Test is doing too many things — when it fails, which phase broke? |
| `high-mocking` | +4 | More than 3 mocks, stubs, patches, or `with-redefs` in a single test | Excessive mocking signals testing wiring, not behavior |
| `large-example` | +4 | Test body exceeds 20 lines (non-API-contract) | Long tests are hard to understand and maintain |
| `helper-hidden-complexity` | +4 | Helper-hidden lines exceed 8 | Abstracting setup into helpers hides but doesn't eliminate complexity |
| `temp-resource-work` | +3 | Test creates temp files, directories, processes, or threads | Resource management in tests signals integration-level concerns in a unit test |
| `literal-heavy-setup` | +3 | Large inline data structures (maps/dicts with 10+ keys, arrays with 10+ elements, multi-line string literals) | Big inline fixtures obscure the test's intent |

### API-Contract Exception

Some tests are legitimately longer because they verify an external contract (HTTP request/response, CLI argument parsing, serialization format). These are identified when ALL of:

- Assertions ≤ 2
- Branches ≤ 4 (including table-driven branches ≤ 1)
- No mocks/patches
- Helper calls ≤ 1, no helper-hidden lines
- No temp resources or large literals
- Subject symbols ≤ 4 (distinct production functions/methods called)
- Single phase
- Line count ≤ 18

For API-contract tests, `scored_setup_depth` subtracts 2 (floor 0) and `scored_branch_penalty` subtracts 2 (floor 0). The `large-example` and `low-assertion-density` smells are suppressed.

## Thresholds

| Score Range | Label | Interpretation |
|-------------|-------|----------------|
| 0-5 | **Focused** | Clean, well-scoped test |
| 6-12 | **Normal** | Acceptable complexity |
| 13-20 | **Questionable** | Review for refactoring opportunities |
| 21+ | **Poor** | Likely a design problem — test should be split or restructured |

## Per-Language Metric Mapping

The metrics are language-agnostic concepts. Here's how they map to specific frameworks:

### Assertion Detection

| Framework | Assertion Patterns |
|-----------|--------------------|
| pytest | `assert`, `pytest.raises`, `pytest.warns`, `pytest.approx` |
| unittest | `self.assert*`, `self.fail` |
| Jest/Vitest | `expect(…).to*`, `expect(…).not.to*` |
| xUnit (.NET) | `Assert.*`, `Should*` (FluentAssertions), `Verify` (Moq) |
| Go testing | `t.Error*`, `t.Fatal*`, `t.Log` + manual checks, testify `assert.*`/`require.*` |
| Rust | `assert!`, `assert_eq!`, `assert_ne!`, `#[should_panic]` |
| Speclj | `should`, `should=`, `should-not`, `should-contain`, `should-throw` |

### Mock Detection

| Framework | Mock/Stub Patterns |
|-----------|--------------------|
| pytest | `monkeypatch.*`, `unittest.mock.patch`, `MagicMock`, `@mock.patch` |
| Jest/Vitest | `jest.fn()`, `jest.mock()`, `jest.spyOn()`, `vi.fn()`, `vi.mock()`, `vi.spyOn()` |
| xUnit (.NET) | `Mock<T>`, `Substitute.For<T>`, `A.Fake<T>` |
| Go | interface stubs (manual), `gomock`, `testify/mock` |
| Rust | `mockall`, manual trait impls in `#[cfg(test)]` |

### Branch Detection

Count these constructs when they appear inside test function bodies:

```
if, else if, elif, else, match, switch, case, when
for (non-parameterized), while, loop
try/catch/except (with branching — not bare try-finally cleanup)
ternary/conditional expressions
&& / || in non-assertion context
```

**Exclude:** `for` used in parameterized/table-driven test data iteration, `with` context managers for resource cleanup, `@pytest.mark.parametrize` (this is table-driven, scored separately).

### Table-Driven Detection

A test is table-driven when:
- It uses `@pytest.mark.parametrize`, `test.each`, `[Theory]`/`[InlineData]`, `#[test_case]`, or equivalent
- It iterates over a data collection and asserts per element
- It follows the pattern: define cases → loop → assert

Table-driven tests get favorable scoring: branches from case iteration count as `table_branches` (lower penalty) and `low-assertion-density` / `large-example` smells are suppressed.

## File-Level Rollups

For each test file, aggregate:

| Metric | Calculation |
|--------|-------------|
| `example_count` | Total test functions |
| `avg_scrap` | Mean SCRAP score across all tests |
| `max_scrap` | Highest individual SCRAP score |
| `branching_examples` | Count of tests with branch_count > 0 |
| `low_assertion_examples` | Tests with 0 or 1 assertions |
| `zero_assertion_examples` | Tests with 0 assertions |
| `with_redefs_examples` | Tests using mocks/patches |
| `helper_hidden_example_count` | Tests with helper_hidden_lines > 0 |
| `coverage_matrix_candidates` | Tests meeting coverage-matrix criteria (see `scrap-duplication.md`) |

## Block-Level Rollups

For each `describe`/`context`/test class:

| Metric | Calculation |
|--------|-------------|
| `example_count` | Tests in this block |
| `avg_scrap` | Mean SCRAP in block |
| `max_scrap` | Worst test in block |
| `worst_example` | Name and score of worst test |
| `extraction_pressure` | See `scrap-duplication.md` |

## Refactor Pressure Score

A weighted file-level composite that determines whether refactoring is warranted:

```
base = (1.2 × avg_scrap)
     + (0.6 × max_scrap)
     + (0.8 × effective_duplication_score)
     + (20  × low_assertion_ratio)
     + (15  × branching_ratio)
     + (15  × mocking_ratio)
     + (12  × helper_hidden_ratio)

pressure = max(0, size_factor × base - matrix_credit)
```

**Size factors** (dampen pressure for tiny files):

| Example Count | Factor |
|---------------|--------|
| 1 | 0.25 |
| 2 | 0.40 |
| 3-4 | 0.65 |
| 5+ | 1.0 |

**Pressure levels:**

| Score | Level |
|-------|-------|
| 55+ | **CRITICAL** |
| 35-54 | **HIGH** |
| 18-34 | **MEDIUM** |
| < 18 | **LOW** |
| (stable) | **STABLE** |

A file is **STABLE** when: max_scrap ≤ 12, effective_duplication ≤ 3, zero_assertion_ratio = 0, and low_assertion_ratio ≤ 0.35.

## Remediation Modes

Based on pressure analysis, SCRAP recommends one of three modes:

| Mode | When | What to Do |
|------|------|------------|
| **STABLE** | File meets stability criteria | Leave it alone unless explicitly requested |
| **LOCAL** | Pressure exists but is concentrated | Fix in place — strengthen assertions, shrink oversized tests, extract shared setup |
| **SPLIT** | Pressure is spread across multiple hotspots (high avg_scrap, high duplication, or many high-pressure blocks) | Split the file by responsibility before local cleanup |

**SPLIT triggers** (any one is sufficient when file is not STABLE):
- avg_scrap ≥ 10
- effective_duplication ≥ 20
- subject_repetition ≥ 12
- example_count ≥ 12 with ≥ 2 HIGH/CRITICAL pressure blocks
- max_scrap ≥ 35

## AI Actionability Classes

Explicit guidance for autonomous agents:

| Class | When | Agent Behavior |
|-------|------|----------------|
| **LEAVE_ALONE** | STABLE remediation mode | Don't modify unless user explicitly requests it |
| **AUTO_TABLE_DRIVE** | High coverage-matrix repetition, low max_scrap, low branching/mocking | Safe to consolidate repetitive low-complexity tests into parameterized/table-driven tests |
| **AUTO_REFACTOR** | LOCAL mode with actionable problems (weak assertions, duplication, oversized tests) | Safe for local improvements — focus on assertions, duplication, and test size |
| **MANUAL_SPLIT** | SPLIT remediation mode | Do not auto-refactor locally first. Split by responsibility before smaller cleanup. |
| **REVIEW_FIRST** | None of the above match cleanly | Not stable enough for unattended refactoring. Present findings and wait for user direction. |

## Recommendation Confidence

| Level | Meaning | Examples |
|-------|---------|---------|
| **HIGH** | Directly actionable, unambiguous problems | Zero-assertion tests, oversized tests, obvious coverage matrices |
| **MEDIUM** | Likely improvements, some judgment needed | Harmful duplication, heavy mocking, extraction opportunities |
| **LOW** | Broader design suggestions | File splitting by responsibility, strategy changes |

## Report Format

### Default (AI-focused guidance)

```
=== SCRAP Analysis ===

File: tests/test_order_processing.py
Pressure: 42.3 (HIGH)
Remediation: LOCAL
Actionability: AUTO_REFACTOR

Actions:
  [HIGH] Strengthen assertions in weak examples before structural cleanup.
  [HIGH] Split oversized examples into narrower examples.
  [MEDIUM] Extract shared setup where harmful duplication dominates.

Top Blocks:
  describe OrderProcessor  avg: 14.2  max: 28  pressure: HIGH
  describe PricingEngine   avg: 8.1   max: 15  pressure: MEDIUM

Worst Examples:
  1. OrderProcessor/handles complex multi-item discount   28
  2. PricingEngine/applies tiered pricing with overrides   15
  3. OrderProcessor/processes refund with partial return    14
```

### Per-Test Detail

```
  test: handles complex multi-item discount
    SCRAP: 28
    lines: 32
    assertions: 1
    branches: 3
    setup-depth: 4
    mocks: 5
    helper-calls: 2
    helper-hidden-lines: 12
    smells: low-assertion-density, high-mocking, large-example, helper-hidden-complexity
```

## Baseline and Comparison

### Creating a Baseline

Before refactoring, capture the current state:

```
SCRAP baseline for: tests/test_order_processing.py
  avg_scrap: 14.2
  max_scrap: 28
  example_count: 12
  pressure: 42.3 (HIGH)
  duplication: 8.5
  zero_assertion_examples: 1
```

Store as a sidecar JSON artifact (not source comments — scores are heuristic and version-dependent):

```json
{
  "version": 1,
  "path": "tests/test_order_processing.py",
  "content_hash": "abc123",
  "summary": {
    "avg_scrap": 14.2,
    "max_scrap": 28,
    "example_count": 12,
    "pressure_score": 42.3,
    "effective_duplication_score": 8.5,
    "zero_assertion_examples": 1,
    "low_assertion_examples": 4
  }
}
```

### Comparing Against Baseline

After refactoring, compare:

| Metric | Before | After | Delta |
|--------|--------|-------|-------|
| avg_scrap | 14.2 | 8.1 | -6.1 |
| max_scrap | 28 | 12 | -16 |
| pressure | 42.3 | 15.2 | -27.1 |

**Verdicts:**
- **Improved**: file_score dropped by ≥ 5, no regression in extraction_pressure or max_scrap
- **Worse**: extraction_pressure increased, or max_scrap increased, or file_score rose by ≥ 5
- **Mixed**: Some metrics improved, others regressed
- **Unchanged**: file_score delta is zero

**Watch for helper regression**: If helper_hidden_lines increased while other metrics improved, the complexity was hidden rather than eliminated.

## Integration with Mutation Testing

SCRAP and mutation testing are complementary:

| SCRAP Score | Mutation Score | Interpretation | Action |
|-------------|---------------|----------------|--------|
| Low (focused) | High (kills mutants) | Healthy test | Leave alone |
| Low (focused) | Low (misses mutants) | Clean but incomplete | Add edge case tests |
| High (poor) | High (kills mutants) | Effective but messy | Refactor structure |
| High (poor) | Low (misses mutants) | Worst case — complex AND weak | Priority remediation target |

Use the SCRAP × mutation matrix to prioritize: **high-SCRAP + low-mutation tests are the highest-value targets** for agent-driven improvement.

## Policy Configuration

All thresholds are centralized for tuning. Adjust based on project maturity:

```yaml
complexity:
  cap: 25.0          # Maximum complexity score (saturating curve ceiling)
  rise_rate: 0.18    # How fast complexity rises (higher = steeper curve)
  floor: 1.0         # Minimum complexity score

pressure:
  weights:
    avg_scrap: 1.2
    max_scrap: 0.6
    effective_duplication: 0.8
    low_assertion_ratio: 20
    branching_ratio: 15
    mocking_ratio: 15
    helper_hidden_ratio: 12
  levels:
    critical: 55
    high: 35
    medium: 18

actionability:
  matrix:
    min_case_matrix_repetition: 2
    max_scrap: 12
    max_branching_ratio: 0.15
    max_mocking_ratio: 0.2
  local:
    low_assertion_ratio: 0.4
    max_branching_ratio: 0.3
    max_mocking_ratio: 0.35
    max_scrap: 20
    avg_scrap: 12
  max_actions: 4

stability:
  max_scrap: 12
  max_duplication: 3
  max_low_assertion_ratio: 0.35
```

These defaults are calibrated from Uncle Bob's Clojure reference implementation and adapted for multi-language contexts. Tune `rise_rate` down (e.g., 0.12) for projects with inherently complex test setup (integration-heavy codebases), or up (e.g., 0.25) for projects that should have very lean unit tests.
