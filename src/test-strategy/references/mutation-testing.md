# Mutation Testing

Comprehensive guide to mutation testing tools, configuration, and agent-driven workflows.

## Core Concepts

Mutation testing measures test quality by injecting small faults (mutants) into production code and checking whether tests detect them.

### Mutation Operators

| Operator | Example | What It Tests |
|----------|---------|---------------|
| Boundary | `>` → `>=` | Off-by-one errors |
| Negation | `if (x)` → `if (!x)` | Condition logic |
| Removal | `applyDiscount()` → *(deleted)* | Side effect verification |
| Return value | `return total` → `return 0` | Output assertions |
| Arithmetic | `a + b` → `a - b` | Calculation correctness |

### Terminology

- **Killed**: Tests detected the mutant (at least one test failed) — good
- **Survived**: All tests still passed despite the mutation — gap in test suite
- **Equivalent mutant**: Mutation that produces identical observable behavior (not a real gap)
- **Mutation score**: `killed / (total - equivalent)` — the percentage of real faults your tests catch

### Theoretical Foundation

Two hypotheses underpin why mutation testing works:

1. **Competent programmer hypothesis**: Real bugs are small deviations from correct code — exactly what mutation operators produce.
2. **Coupling effect**: Tests that catch simple faults (single mutations) also tend to catch complex faults (multiple simultaneous errors).

## The AI Agent Advantage

Mutation testing was historically impractical — too slow to run, too tedious to analyze. AI agents change this:

- **Automated execution**: Agents run mutation tools incrementally on changed files, not the full codebase
- **Survivor analysis**: Agents read surviving mutant diffs, classify them (real gap vs. equivalent), and explain the untested behavior
- **Test generation**: Agents write minimal tests that kill surviving mutants, then re-run to confirm
- **Equivalent mutant filtering**: Agents apply heuristics to skip mutations with no observable behavior change

### The Mutation-Kill Loop

```
1. Run mutation tool on changed/targeted files
2. Parse results → identify survivors
3. For each survivor:
   a. Read the mutant diff
   b. Classify: equivalent (skip) or real gap (act)
   c. If real gap: identify the untested behavior
   d. Write a minimal test that kills the mutant
4. Re-run to confirm all new tests kill their targets
5. Report final mutation score
```

## Tool Configuration by Language

### Python — mutmut

**Installation:**
```bash
pip install mutmut
```

**Configuration** (`pyproject.toml`):
```toml
[tool.mutmut]
paths_to_mutate = "src/"
tests_dir = "tests/"
runner = "python -m pytest -x --tb=short"
```

**CLI usage:**
```bash
# Full run
mutmut run

# Incremental — only mutate changed files
mutmut run --paths-to-mutate=src/domain/order.py,src/domain/pricing.py

# View results
mutmut results

# Inspect a specific survivor
mutmut show <id>

# Apply a mutant to see it in context
mutmut apply <id>
```

**Skip a line** (for intentionally untestable code):
```python
x = default_value  # pragma: no mutate
```

**Agent parsing**: `mutmut results` outputs lines like `Survived: src/domain/order.py:42` — parse these to locate survivors.

### TypeScript/JavaScript — Stryker (StrykerJS)

**Installation:**
```bash
npm install --save-dev @stryker-mutator/core
npx stryker init  # interactive setup
```

**Configuration** (`stryker.config.mjs`):
```javascript
export default {
  mutate: ['src/**/*.ts', '!src/**/*.test.ts', '!src/**/*.spec.ts'],
  testRunner: 'vitest',  // or 'jest', 'mocha'
  checkers: ['typescript'],
  plugins: [
    '@stryker-mutator/typescript-checker',
    '@stryker-mutator/vitest-runner'
  ],
  reporters: ['clear-text', 'json', 'html'],
  thresholds: { high: 80, low: 60, break: null },
  incremental: true,
  incrementalFile: '.stryker-incremental.json'
};
```

**CLI usage:**
```bash
# Full run
npx stryker run

# Incremental — only mutate specific files
npx stryker run --mutate 'src/domain/**/*.ts'
```

**Agent parsing**: Use the JSON reporter — output file contains structured survivor data with file, line, and mutator type.

**TypeScript checker**: The `@stryker-mutator/typescript-checker` filters out type-invalid mutants before running tests, significantly reducing runtime.

### Rust — cargo-mutants

**Installation:**
```bash
cargo install cargo-mutants
```

**CLI usage:**
```bash
# Full run
cargo mutants

# Incremental — specific files
cargo mutants --file src/domain/order.rs --file src/domain/pricing.rs

# Exclude test files and generated code
cargo mutants --exclude '*/tests/*' --exclude '*/generated/*'

# With nextest (faster parallel execution)
cargo mutants -- --test-tool nextest
```

**Output format**: Results categorize mutants as `missed` (survived), `caught` (killed), or `unviable` (compile error — equivalent to type-invalid).

### C# / .NET — Stryker.NET

**Installation:**
```bash
dotnet tool install -g dotnet-stryker
```

**Configuration** (`stryker-config.json`):
```json
{
  "stryker-config": {
    "project": "MyProject.csproj",
    "test-projects": ["MyProject.Tests.csproj"],
    "reporters": ["cleartext", "json", "html", "dashboard"],
    "thresholds": { "high": 80, "low": 60, "break": null },
    "mutate": ["!**/obj/**", "!**/bin/**"]
  }
}
```

**CLI usage:**
```bash
# Run from test project directory
dotnet stryker

# Filter to specific files
dotnet stryker --mutate "src/Domain/**/*.cs"
```

## Incremental Mutation Testing

Running mutation testing on the full codebase is slow. Always run incrementally in agent workflows:

### Git Diff Integration

```bash
# Get changed files relative to main
git diff --name-only main -- '*.py' '*.ts' '*.rs' '*.cs'

# Feed to mutation tool
# Python
mutmut run --paths-to-mutate=$(git diff --name-only main -- '*.py' | tr '\n' ',')

# TypeScript
npx stryker run --mutate $(git diff --name-only main -- '*.ts' | sed "s/^/'/" | sed "s/$/'/" | tr '\n' ',')

# Rust
cargo mutants $(git diff --name-only main -- '*.rs' | sed 's/^/--file /')
```

### When to Run

- **During `/workflow:execute`**: On each vertical slice, mutate the domain files you changed
- **During `/workflow:audit --focus tests`**: On the targeted scope (directory or file glob)
- **In CI**: As a PR gate on domain/critical paths only — not infrastructure or framework layers

## Mutation Score Thresholds

Apply thresholds appropriate to each architectural layer:

| Layer | Target | Below Target | Rationale |
|-------|--------|-------------|-----------|
| Domain | 80%+ | P2 if 60-79%, P1 if <60% | Business logic correctness is critical |
| Application | 70%+ | P2 if 50-69%, flag below 50% | Orchestration conditionals (retry logic, failure handling, workflow branching) carry real bug risk |
| Infrastructure | Skip | N/A | Integration tests cover differently; mutations are often equivalent |
| Framework | Skip (with exceptions) | N/A | Thin layer; E2E tests provide the real signal. See note below |

**Don't chase 100%.** Equivalent mutants make 100% impossible without false effort. 80%+ on domain logic is transformative.

**Framework layer exception:** If your framework layer contains non-trivial input validation, request parsing, or response mapping logic, run targeted mutation testing on those specific files. A surviving mutation in a validation rule means your API tests aren't checking rejection cases. This applies to the validation logic itself, not to thin controller delegation code.

## Equivalent Mutant Identification

Not every surviving mutant represents a test gap. Some mutations produce identical observable behavior.

### Common Equivalent Patterns

| Pattern | Example | Why It's Equivalent |
|---------|---------|-------------------|
| No-op arithmetic | `x + 0` → `x - 0` | Both return `x` |
| Identity multiplication | `x * 1` → `x / 1` | Both return `x` |
| Dead code | Mutating code after an early return | Code never executes |
| Redundant condition | `if (x > 0 && x > 0)` → mutating one side | Other side still guards |
| Logging-only code | Mutating a log message string | No behavioral change |

### Agent Heuristic

When analyzing a surviving mutant, ask:

> "Does this mutation change any **observable behavior** — return values, side effects, state changes, or error conditions?"

- If **no** → equivalent mutant. Skip it, optionally annotate with `pragma: no mutate` or equivalent.
- If **yes** → real gap. Proceed to write a killing test.
- If **uncertain** → investigate. Trace the mutated code path to its observable outputs.

## Agent-Driven Survivor Analysis Workflow

Step-by-step protocol for agents analyzing surviving mutants:

### 1. Read the Surviving Mutant Diff

Examine what the mutation tool changed. Example:

```diff
- if (order.total > 100):
+ if (order.total >= 100):
    applyDiscount(order)
```

### 2. Classify: Equivalent or Real Gap?

Ask: "Is there any input where `> 100` and `>= 100` produce different results?"

Yes — when `order.total == 100`. With `>`, no discount. With `>=`, discount applied. This is a real gap.

### 3. Identify the Untested Behavior

The boundary condition `total == 100` is not tested. Existing tests likely cover `total = 50` (no discount) and `total = 200` (discount), but miss the exact boundary.

### 4. Write a Minimal Killing Test

```python
def test_discount_not_applied_at_exact_threshold():
    order = create_order(total=100)
    process_order(order)
    assert order.discount == 0  # boundary: 100 is NOT above threshold
```

### 5. Re-Run to Confirm the Kill

```bash
mutmut run --paths-to-mutate=src/domain/order.py
# Verify: the boundary mutant is now killed
```

### 6. Report

```
Survivor: src/domain/order.py:42 (boundary: > → >=)
Classification: Real gap — boundary condition at threshold value
Fix: Added test_discount_not_applied_at_exact_threshold
Result: Killed ✓
```

## Redundant Test Identification

Mutation testing doesn't just find missing tests — it identifies tests that contribute nothing. In large suites, this is often the higher-value finding.

### What "Redundant" Means

A test is redundant if removing it changes no mutation scores. This happens when:

- **No assertions**: The test executes code but never verifies outcomes — it kills zero mutants
- **Duplicate coverage**: Another test already kills every mutant this test kills
- **Static guarantee testing**: The test verifies properties the type system or linter already enforce — mutations to those properties produce compile errors, not surviving mutants
- **Tautological assertions**: The test's expected value is computed the same way as the production code — it kills no mutants because the mutation affects both identically

### Agent Workflow for Test Reduction

```
1. Run mutation tool and collect per-test kill counts
2. Identify tests that kill 0 unique mutants → deletion candidates
3. For each candidate, verify it's not an integration/E2E test
   (those serve wiring purposes not captured by mutation scores)
4. Classify:
   - Kill 0 mutants + no assertions → P2: delete or rewrite
   - Kill 0 mutants + assertions exist → P3: likely redundant with another test
   - Kills only mutants also killed by other tests → P3: safe to remove if suite is large
5. Report total potential reduction: "N of M tests kill no unique mutants"
```

### Caveats

- **Don't delete integration or E2E tests** based on mutation scores — they verify wiring between components, which mutation testing (focused on single-file mutations) doesn't measure
- **Don't mass-delete** — work module by module, re-running mutations after each round to confirm scores hold
- **Redundancy is contextual** — if test A and test B both kill the same mutant, only one is redundant. Choose the one with the clearer name and better documentation value

## Getting Started

If mutation testing is new to your project:

1. **Start small**: Pick one module with solid existing tests (high coverage, good assertions)
2. **Install the tool** for your language (see Tool Configuration above)
3. **Run on that module only**: Don't start with the full codebase
4. **Analyze survivors**: Use the Agent-Driven Survivor Analysis workflow above
5. **Write killing tests**: Focus on the real gaps, skip equivalent mutants
6. **Iterate**: Expand to more modules as the practice becomes natural

### What Mutation Testing Reveals That Coverage Doesn't

Coverage says "this line ran during tests." Mutation testing says "if this line had a bug, your tests would catch it." The gap between these two statements is where bugs hide:

- Tests that execute code but don't assert on its output
- Tests with assertions too weak to detect subtle changes
- Missing boundary condition tests
- Missing negative/error path tests

Combine coverage floors (find untested code) with mutation scores (verify tested code is actually verified) for a complete picture of test quality.
