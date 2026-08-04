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

Mutation testing was often **uneconomical to own** — not impossible to compute, but too slow for full-repo daily use and too tedious for humans to triage survivors. AI agents change the **analysis and kill-loop** economics when scope stays incremental:

- **Automated execution**: Agents run mutation tools incrementally on changed/domain files, not the full codebase
- **Survivor analysis**: Agents read surviving mutant diffs, classify them (real gap vs. equivalent), and explain the untested behavior
- **Test generation**: Agents write minimal tests that kill surviving mutants, then re-run to confirm
- **Equivalent mutant filtering**: Agents apply heuristics to skip mutations with no observable behavior change

**Unlock ≠ always-run.** Agents do not shrink wall-clock for full-suite mutation, do not replace tool install, and must not invent kill tests that are tautological. Soft gate: domain/changed files when a tool is present; sabotage when not; never block merges solely on score theater or demand full-repo mutation on every PR.

### The Mutation-Kill Loop

```
1. Run mutation tool on changed/targeted files (domain-first; timebox the session)
2. Parse results → identify survivors
3. For each survivor (cap analysis effort — prioritize domain/high-risk lines):
   a. Read the mutant diff
   b. Classify: equivalent (skip) or real gap (act)
   c. If real gap: identify the untested behavior
   d. Write a minimal test that kills the mutant (strong assertions — no tautologies)
   e. Re-apply THAT mutant and confirm the new test fails; then restore
4. Re-run to confirm all new tests kill their targets
5. Report final mutation score + evidence (files mutated, survivors remaining, skips)
```

**No tool path:** do not skip quality verification. Use sabotage on 3–5 critical domain paths (see `test-quality.md`) and record which paths were sabotaged and whether tests caught them. Recommend tool setup as a follow-up, not as a substitute for this slice’s evidence.

**Audit ranking rule:** reason-trace is enough for bulk P2/P3 candidate lists. Before ranking a finding **P1**, “fail-open”, or “survives the whole suite,” **apply** the mutant once, run the focused suite, record the result, revert. Static “would survive” is not evidence at that severity.

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

- **During `/work:execute`**: When domain/pure-logic files changed — incremental mutate if tool present; otherwise sabotage (see execute `quality-checkpoints.md` › Domain verification path). Not every task if no domain in the diff.
- **During `/work:audit --focus tests`**: On the targeted scope (directory or file glob), tool path or sabotage fallback
- **In CI** (optional, project-chosen): incremental mutate on domain/critical paths only — report score/survivors as signal. Do **not** treat mutation score as a universal merge breaker; prefer process evidence (execute DoD) + review P2 over score theater. Never full-repo mutation as a default required check.

## Mutation Score Thresholds

These severities apply **only when mutation was run** on in-scope files. Missing tool → use sabotage evidence (execute DoD); do not invent a score. No full-repo run just to “have a number.”

**Severity SoT:** `test-quality.md` › Advanced-technique severity (process evidence vs review/audit severity vs optional CI). This table is the layer target guide; do not invent harder gates here.

Apply thresholds appropriate to each architectural layer:

| Layer | Target | Below Target | Rationale |
|-------|--------|-------------|-----------|
| Domain | 80%+ | P2 if 60–79% or real survivors unaddressed; **P1** if under 60% *and* survivors look real on critical domain (else P2) | Business logic correctness is critical — score alone is not automatic P1 |
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

## False kills (tests that pass under the mutant)

A test can look correct and still **not discriminate** the fault. Treat a “kill” as unproven until the suite fails under the applied mutant.

### Default-set / full-mask no-op

Production merges a narrow flag set into a **default that already contains those flags**. Dropping the merge is a no-op at the default, so a test that only exercises the default path stays green under the mutant.

```text
// production (intent: always include PHONE when searching)
search_fields = DEFAULT_FIELDS | PHONE_FIELDS

// mutant under test: drop the OR
search_fields = DEFAULT_FIELDS

// false-kill test setup (looks related, does not discriminate)
fields = DEFAULT_FIELDS          // already includes PHONE
result = search(query, fields)
assert result includes phone_match

// why it stays green: DEFAULT_FIELDS already has PHONE_FIELDS bits;
// removing "| PHONE_FIELDS" changes nothing on this path
```

**Discriminating setup:** drive a deliberately **narrow** mask that would miss the behavior unless the production merge runs.

```text
// kill test: start from a mask that does NOT already include PHONE
fields = NAME_ONLY               // subset of DEFAULT_FIELDS, no phone bits
// production path must still OR PHONE_FIELDS for this search mode
result = search(query, fields)   // or assert the composed mask contains PHONE
assert composed_mask has PHONE_BITS
// under mutant (no OR): assertion fails → real kill
```

### Other false-kill shapes (check these before trusting reason-trace)

| Shape | Why the suite stays green |
|-------|---------------------------|
| Asserting only on a field the mutant never touches | Wrong observable |
| Using a fixture whose “valid” state already satisfies every disjunct | Dropping one disjunct is equivalent for that fixture |
| Matching a superset / “contains any of” when the bug is which member was set | Assertion too loose |
| Integration double always returns success | Mutant in real code path never runs |

**Rule:** after authoring a kill test, apply the mutant, run the focused test, require failure, restore. No exception for audit remediation or execute DoD.

## Agent-Driven Survivor Analysis Workflow

Step-by-step protocol for agents analyzing surviving mutants:

### 1. Read the Surviving Mutant Diff

Examine what the mutation tool (or sabotage edit) changed. Example:

```text
// original
if order.total > THRESHOLD:
    apply_discount(order)

// mutant (boundary)
if order.total >= THRESHOLD:
    apply_discount(order)
```

### 2. Classify: Equivalent or Real Gap?

Ask: "Is there any input where `>` and `>=` produce different results at THRESHOLD?"

Yes — when `order.total == THRESHOLD`. With `>`, no discount. With `>=`, discount applied. Real gap.

### 3. Identify the Untested Behavior

The boundary `total == THRESHOLD` is not tested. Existing tests likely cover below-threshold (no discount) and well-above (discount), but miss the exact boundary.

### 4. Write a Minimal Killing Test

```text
test discount_not_applied_at_exact_threshold:
  order = create_order(total = 100)
  process_order(order)
  assert order.discount == 0   // boundary: 100 is NOT above threshold
```

### 5. Confirm the Kill Under the Applied Mutant

Do not stop at “new test is green on clean code.”

```text
1. Apply the boundary mutant (tool apply, or temporary edit: > becomes >=)
2. Run only the new test (or its small focus set)
3. Require: FAIL under mutant
4. Restore production code
5. Require: PASS on clean code
```

If step 3 is still green, the test is a **false kill** — strengthen the fixture/assertion (see False kills above), do not report Killed.

### 6. Report

```text
Survivor: order.pricing (boundary: > → >=)
Classification: Real gap — boundary condition at threshold value
Fix: discount_not_applied_at_exact_threshold
Evidence: 1 failed under applied mutant; green after restore
Result: Killed
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
