# Coverage Model

Sentinel tracks coverage by comparing NL spec scenarios against generated `.spec.ts` test files. Coverage answers: "How many of my specified scenarios have corresponding generated tests?"

## Coverage Levels

### Scenario-Level

Each numbered scenario in an NL spec is either:

| Status | Meaning |
|--------|---------|
| **Covered** | A corresponding test exists in a `.spec.ts` file |
| **Uncovered** | No matching test found in any `.spec.ts` file |

### Spec-Level

Coverage for a single NL spec:

```
spec_coverage = covered_scenarios / total_scenarios
```

A spec is considered:
- **Fully covered** — all scenarios have corresponding tests
- **Partially covered** — some scenarios covered, others uncovered
- **Uncovered** — no corresponding test file exists

### Area-Level

Aggregated across all NL specs sharing the same `area` frontmatter field:

```
area_coverage = sum(covered_scenarios across area specs) / sum(total_scenarios across area specs)
```

## Matching NL Specs to Tests

Sentinel matches NL spec scenarios to `.spec.ts` tests by:

1. **Naming convention**: NL spec `workspace-create.md` → `workspace-create.spec.ts`
2. **Test name content**: Numbered scenario titles should appear in `test()` description strings within the generated spec
3. **Partial matching**: A test that covers multiple scenarios counts as covered for each

If no `.spec.ts` file matches a given NL spec by naming convention, all scenarios in that spec are uncovered.

## Drift Detection

Drift occurs when NL specs, generated tests, and app behavior diverge. Sentinel's `audit` command detects three categories of drift:

### Spec → Test Drift

- **Uncovered specs**: NL spec scenarios with no generated test — the Planner/Generator have not been run against this spec, or the spec was added after the last generation pass
- **Orphaned tests**: `.spec.ts` tests with no corresponding NL spec — a spec was deleted or renamed without removing the generated test

### Test → App Drift

- **Failing tests**: Tests that fail against the current app — detected by reading Playwright's HTML report
- **App regression**: App behavior changed, tests correctly detect the regression (test is right, app is wrong)
- **Spec staleness**: NL spec describes old behavior, tests are correct for new behavior (spec needs updating)

Sentinel does not automatically distinguish app regressions from spec staleness — that judgment requires a human reviewer. The audit report surfaces the failing tests and flags them for review.

## Execution Artifacts

Playwright produces execution artifacts natively. Sentinel reads these during audit but does not produce or manage them.

| Artifact | Location | Format | Produced by |
|----------|----------|--------|-------------|
| HTML report | `playwright-report/` | HTML | `npx playwright test` |
| Test results | `test-results/` | Directories per test | `npx playwright test` |
| Screenshots | `test-results/<test>/` | PNG | Playwright (on failure by default) |
| Traces | `test-results/<test>/` | ZIP | Playwright (on retry by default) |
| Video | `test-results/<test>/` | WebM | Playwright (configurable) |

Evidence capture settings are in `playwright.config.ts`, not in sentinel config.

## Audit Report

The `audit` command produces a structured markdown report with:

- **Coverage summary** — overall percentage + breakdown by area
- **Uncovered NL spec scenarios** — listed by spec and scenario number, with recommendation to run Generator
- **Orphaned tests** — `.spec.ts` files with no corresponding NL spec, with recommendation to delete or create a spec
- **Failing tests** — tests that failed in the most recent Playwright run, categorized by likely drift type
- **Recommendations** — which specs need Generator, which tests need Healer, which specs need manual review

### Example Audit Report Structure

```markdown
# Sentinel Audit Report — 2026-02-23

## Coverage Summary

| Area | Covered | Total | Coverage |
|------|---------|-------|----------|
| workspace-management | 8 | 10 | 80% |
| auth | 6 | 6 | 100% |
| editor | 3 | 12 | 25% |
| **Overall** | **17** | **28** | **61%** |

## Uncovered Scenarios

These NL spec scenarios have no corresponding generated test. Run the Generator against these specs.

- `editor-block-types.md` — scenarios 4–12 (Generator not yet run)
- `workspace-management-rename.md` — scenario 3 (partial generation)

## Orphaned Tests

These `.spec.ts` files have no corresponding NL spec.

- `tests/workspace-settings-old.spec.ts` — NL spec was deleted, test remains

## Failing Tests

Tests that failed in the most recent Playwright run. Review to determine if this is an app regression or spec staleness.

| Test File | Test Name | Likely Cause |
|-----------|-----------|--------------|
| workspace-create.spec.ts | "Attempt empty name" | Selector change — run Healer |
| auth-login.spec.ts | "Magic link flow" | App behavior changed — review spec |
```
