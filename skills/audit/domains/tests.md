# Test Quality Domain

Agents and criteria for auditing test suites against @test-strategy principles.

Consumed by `/workflow:audit` orchestrator. Use `--focus tests` for this domain only.

## User Input

```text
$ARGUMENTS
```

## Input Detection

Parse input to determine audit scope:

| Input Pattern | Scope | Action |
|---|---|---|
| `./tests/` or `./test/` | Directory | Audit all test files in directory |
| `./src/domain/` | Production code path | Find and audit associated test files |
| `*.test.ts` or `*_test.py` | File glob | Audit matching files |
| `all` or empty | Full suite | Auto-detect test framework, audit everything (prompt if large) |
| `--layer domain` | Architectural layer | Audit tests for that layer (requires `@clean-architecture` context) |
| `--recent 7d` | Recent changes | Audit files modified in last N days |
| `--diff main` | Changed files | Audit files changed vs. specified branch |

## Auto-Detection Phase (Exhaustive Discovery)

**Discovery mandate**: Complete ALL steps below before reporting any findings. Use multiple search strategies for each step — a single search returning empty is not proof of absence. You have a dedicated 1M token context window; use it for thoroughness, not sampling. See the orchestrator's Exhaustive Discovery Protocol for general principles.

### Step 1: Discover ALL test frameworks and configs
- Search for ALL test config files across the entire repo: `vitest.config.*`, `jest.config.*`, `playwright.config.*`, `.mocharc.*`, `pytest.ini`, `pyproject.toml`, `Cargo.toml [dev-dependencies]`
- **Read EACH config file completely** — note which file patterns and directories each covers
- Check for multiple configs (monorepos often have per-app configs AND root configs — finding one is not enough)
- Check `package.json` test scripts in every workspace package
- Check CI workflow files for test execution commands (reveals which configs actually run in CI vs. local-only)

### Step 2: Locate ALL test files using multiple strategies
- **Strategy A (glob)**: Search for test file patterns: `*.test.ts`, `*.test.tsx`, `*.spec.ts`, `*.spec.tsx`, `*_test.rs`, `*_test.py`, `*Tests.cs`, `*_test.go`
- **Strategy B (content)**: Search for test markers: `#[test]`, `#[cfg(test)]`, `#[tokio::test]`, `describe(`, `it(`, `test(`, `[Fact]`, `[Test]`, `def test_`
- **Strategy C (directories)**: Check ALL directories named `tests/`, `test/`, `__tests__/`, `specs/`, `e2e/`
- **Cross-reference**: If strategies A and B yield different counts, investigate. Discrepancies reveal missed test locations.

### Step 3: Map test layers
For each distinct test layer found (unit, integration, E2E, contract, property-based), record: location, framework, file count, function count, what it tests, how it runs (which CI step, or local-only).

### Step 4: Verify quality tool presence
- Coverage: Search for coverage configs AND CI coverage steps
- Mutation: Search for mutation testing configs AND actual usage in test code
- Property-based: Search for `proptest!`, `prop_assert`, `@given`, `hypothesis`, `quickcheck` in actual test code (not just Cargo.toml/package.json dependencies)

### Step 5: Cross-check CI execution
- Read CI workflow files to determine which test layers execute in CI vs. local-only
- Flag any test configs that exist but aren't referenced by any CI step

## Scope Gate

Based on auto-detection, prompt user for scope confirmation:

- **Small suite** (< 20 test files): Run all tiers automatically
- **Medium suite** (20-100 test files): Run Tier 1 on all; prompt before Tier 2/3
- **Large suite** (100+ test files): Require explicit scoping or run Tier 1 sampling with recommendations

## Agent Reasoning Standards

Follow all standards from the orchestrator's Agent Reasoning Standards (cite evidence, check opposite hypothesis, verify absence claims, complete discovery before findings, use full 1M context budget, tag domain, flag cross-domain connections). Additionally:

- **Check test helpers and fixtures.** Before reporting a gap, look for shared test infrastructure (helpers, builders, fixtures) that might satisfy the concern from a different location than expected.

## Three-Tier Analysis

### Tier 1 — Static Analysis (always runs)

Spawn 2 parallel agents that read test files:

**assertion-analyst** — References @test-strategy (`references/test-quality.md`, `references/test-design.md`):
- Assertion-free tests (no `assert`/`expect`/`should` statements)
- Weak assertions (truthiness-only: `assert result`, `expect(x).toBeTruthy()`)
- Computed expected values (`assert double(5) == 5 * 2` instead of `== 10`)
- Tautological patterns (test assertion mirrors production logic)
- Assertion strength scoring (level 0-5 per test, flag level 0-2)
- Test naming quality (behavioral spec vs. method name)
- Single-behavior-per-test compliance
- Static guarantee duplication (tests that verify type correctness, nullability, exhaustive matching, or lint rules already enforced by the compiler/linter)
- Arrange-Act-Assert structure clarity

**mock-boundary-checker** — References @test-strategy (`references/mocking-and-contracts.md`). Core principle: mock at architectural **service abstraction boundaries** only (repository, gateway, event publisher), never internal collaborators:
- Internal collaborator mocking (same-system classes mocked instead of using real)
- Boundary identification (which mocks are at real architectural ports vs. internal classes)
- Mock-to-real ratio (flag files with > 50% mocked dependencies)
- Fake vs. mock usage (recommend fakes for repositories, mocks only for side effects)
- Dependency injection patterns (flag `new` inside functions being tested)

### Tier 2 — Dynamic Analysis (auto-detect: runs if tools found, suite is manageable)

**coverage-analyst** — References @test-strategy (`references/test-quality.md`):
- Run test suite with coverage
- Measure against layer-appropriate floors:
  - Domain: 85%, Application: 75%, Framework: 50%
  - Infrastructure (internal — sqlite, import, agent-core, task-runner, json, image): 60% floor
  - Infrastructure (external — supabase, onnx, llm, cloud providers): No floor; report coverage but do not penalize.
    These are better tested via integration/E2E tests, not unit tests.
- Identify uncovered paths (not just percentages — which functions/branches)
- Flag coverage without verification (high coverage + weak assertions)

**mutation-scout** — References @test-strategy (`references/mutation-testing.md`, `references/test-quality.md`):

**If mutation tool detected** (mutmut, Stryker, cargo-mutants, Stryker.NET):
1. Run incrementally on changed/targeted files only (not full codebase)
2. Parse results to identify surviving mutants
3. For each survivor:
   - Classify: equivalent mutant (no observable behavior change) vs. real gap
   - If real gap: identify the untested behavior and suggest a specific test
4. Identify redundant tests (P3): tests that kill no unique mutants — they are either redundant with other tests, assertion-free, or testing compiler-enforced properties. Flag as candidates for deletion or rewriting with stronger assertions.
5. Report mutation score with layer-appropriate interpretation:
   - Domain 80%+: Excellent | 60-79%: Gaps exist (P2) | <60%: Significant issues (P1)
   - Application 70%+: Good | 50-69%: Gaps exist (P2) | <50%: Flag for review
   - Infrastructure (internal): 60%+ Good | 40-59%: Gaps (P2) | <40%: Flag for review
   - Infrastructure (external): skip entirely — mutation testing external service wrappers has near-zero value
   - Framework: skip, unless non-trivial validation/parsing logic exists — run targeted mutations on those files

**If no mutation tool detected**:
1. Perform AI-driven sabotage test on 3-5 critical code paths:
   - Identify the most important business logic in scope
   - For each: describe a specific mutation (boundary change, removed guard, negated condition, altered return value)
   - Trace existing tests to assess whether they would catch it (cite specific test files and assertions)
   - Report which mutations would survive with confidence level
2. Recommend the appropriate mutation testing tool for the detected language (see @test-strategy `references/mutation-testing.md`)
3. Provide the one-line setup command

### Tier 3 — Heuristic Analysis (AI judgment)

**behavior-coverage-reviewer** — References @test-strategy (SKILL.md philosophy + `references/test-design.md`):
- Read test + production code side-by-side for the scoped area
- Identify behaviors tested vs. behaviors present
- Flag missing edge cases (empty inputs, boundary values, error paths)
- Assess refactoring resilience ("would renaming a private method break tests?")
- Evaluate "Would this test catch a subtle bug introduced by someone else?"
- Static guarantee waste ("are tests spending effort verifying properties the type system or linter already enforce?")
- Suggest strategy improvements (e.g., "this parser would benefit from property-based testing")

## Output: Prioritized Report

Present findings using the same P1/P2/P3 structure as `/workflow:review`:

```markdown
## Test Suite Audit Complete

**Scope**: [directory/files audited]
**Test Files**: [N] files, [M] tests
**Framework**: [detected framework]
**Tiers Run**: [1, 2, 3] or [1 only]

### Health Summary

| Metric | Value | Status |
|--------|-------|--------|
| Tests passing | Y/N | [pass/fail] |
| Assertion-free tests | N | [ok/warning/critical] |
| Weak assertions (level 0-2) | N | [ok/warning] |
| Coverage (domain) | X% | [above/below 85% floor] |
| Mutation score | X% | [if available: domain 80%+/app 70%+/framework validation if applicable] |
| Mock boundary violations | N | [ok/warning] |

### Health Score

Calculate per-layer scores, then weight by test viability:

**Per-layer scoring** (start at 100, apply finding penalties):
- Each P1: -15 points
- Each P2: -5 points
- Each P3: -1 point
- Floor: 0

**Layer weights** (reflect testing viability and value):

| Layer | Weight | Rationale |
|-------|--------|-----------|
| Domain | 0.35 | Pure logic, highest test value, most testable |
| Application | 0.30 | Use cases with mocked boundaries, high value |
| Frameworks | 0.15 | Controllers, CLI handlers, Tauri glue — validation/transport, moderate-to-low unit-test viability |
| Infrastructure (internal) | 0.15 | SQLite, local I/O — testable with fixtures |
| Infrastructure (external) | 0.05 | Network services (Supabase, ONNX, LLM) — low unit-test viability |

**Composite score** = Σ(layer_score × layer_weight)

Infrastructure split: classify crates as "internal" (sqlite, import, agent-core, task-runner, json, image)
vs "external" (supabase, onnx, llm) based on whether they wrap network services.

| Score Range | Label |
|-------------|-------|
| 90-100 | Excellent |
| 75-89 | Good |
| 60-74 | Fair |
| 40-59 | Needs Work |
| 0-39 | Critical |

**Score: [N]/100 — [Label]**

### Findings

#### P1 — Critical (Tests That Don't Test)
[Assertion-free tests, tautological tests — these create false confidence]

#### P2 — Important (Tests That Under-Test)
[Weak assertions, static guarantee duplication, boundary mocking violations, missing edge cases]

#### P3 — Suggestions (Tests That Could Be Better)
[Naming improvements, strategy recommendations, structural suggestions]

### Positive Observations
[Well-written tests, good patterns found, strong areas]

### Recommended Actions
1. [Highest-impact fix — usually P1 items]
2. [Second priority]
3. [Tool recommendation if mutation testing not available]
```

## Actionable Next Steps

After presenting the report, offer:

```markdown
## Next Steps

1. **Fix critical findings** — Address P1 items (assertion-free and tautological tests)
2. **Create follow-up tasks** — Track P2/P3 improvements
3. **Re-audit after fixes** — Run `/workflow:audit --focus tests [same scope]` to verify
4. **Install quality tools** — [if mutation testing not available: recommend tool for language]
5. **Save report** — Export findings to `./planning/test-audit-report.md`
```

## Integration Points

### With /workflow:execute

During execution, if an audit was recently run, reference its findings for the area being worked on.

### With /workflow:compound

If audit reveals a recurring pattern worth documenting, offer compound.

### With /workflow:audit --focus repo

audit-tests evaluates test quality and coverage; audit-repo checks that testing infrastructure exists and is properly configured in CI.

### With @test-strategy

All agent prompts reference specific sections of the @test-strategy skill as their criteria source. This command is the active counterpart to the skill's passive guidance.

## References

- [react-doctor](https://github.com/millionco/react-doctor) — Health scoring concept adapted from this React diagnostic CLI
