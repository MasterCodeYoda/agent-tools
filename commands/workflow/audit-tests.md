---
name: workflow:audit-tests
description: Audit an existing test suite for quality, anti-patterns, and coverage gaps using the @test-strategy skill framework
argument-hint: "[directory path, file glob, or 'all']"
---

# Test Suite Audit

Examine an existing test suite against @test-strategy principles and produce prioritized, actionable findings.

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

## Auto-Detection Phase

Before analysis, detect the project's testing setup:

```
1. Detect test framework (pytest, jest/vitest, xUnit, JUnit, Go testing)
2. Locate test files (convention-based: *_test.py, *.test.ts, *.spec.ts, *Tests.cs)
3. Locate corresponding production code files
4. Count test files and estimate suite size
5. Check for available quality tools:
   - Coverage: pytest-cov, c8/istanbul, coverlet, JaCoCo
   - Mutation: mutmut, Stryker, Stryker.NET, PIT, cargo-mutants
```

## Scope Gate

Based on auto-detection, prompt user for scope confirmation:

- **Small suite** (< 20 test files): Run all tiers automatically
- **Medium suite** (20-100 test files): Run Tier 1 on all; prompt before Tier 2/3
- **Large suite** (100+ test files): Require explicit scoping or run Tier 1 sampling with recommendations

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

**mock-boundary-checker** — References @test-strategy (`references/mocking-and-contracts.md`):
- Internal collaborator mocking (same-system classes mocked instead of using real)
- Boundary identification (which mocks are at real boundaries vs. internal)
- Mock-to-real ratio (flag files with > 50% mocked dependencies)
- Fake vs. mock usage (recommend fakes for repositories, mocks only for side effects)
- Dependency injection patterns (flag `new` inside functions being tested)

### Tier 2 — Dynamic Analysis (auto-detect: runs if tools found, suite is manageable)

**coverage-analyst** — References @test-strategy (`references/test-quality.md`):
- Run test suite with coverage
- Measure against layer-appropriate floors:
  - Domain: 85%, Application: 75%, Infrastructure: 60%, Framework: 50%
- Identify uncovered paths (not just percentages — which functions/branches)
- Flag coverage without verification (high coverage + weak assertions)

**mutation-scout** — Conditional on tooling:
- **If mutation tool detected**: Run on changed/targeted files, report mutation score
- **If no mutation tool**: Perform AI-driven sabotage test:
  1. Identify 3-5 critical code paths in production code
  2. For each: describe a specific mutation (change `>` to `>=`, remove null check, etc.)
  3. Assess whether existing tests would catch it
  4. Report which mutations would survive

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
| Mutation score | X% | [if available] |
| Mock boundary violations | N | [ok/warning] |

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
3. **Re-audit after fixes** — Run `/workflow:audit-tests [same scope]` to verify
4. **Install quality tools** — [if mutation testing not available: recommend tool for language]
5. **Save report** — Export findings to `./planning/test-audit-report.md`
```

## Integration Points

### With /workflow:execute

During execution, if an audit was recently run, reference its findings for the area being worked on.

### With /workflow:compound

If audit reveals a recurring pattern worth documenting, offer compound.

### With @test-strategy

All agent prompts reference specific sections of the @test-strategy skill as their criteria source. This command is the active counterpart to the skill's passive guidance.
