# QA Coverage Domain

Agents and criteria for auditing end-to-end test coverage — NL spec completeness, Playwright test generation health, and spec-to-app drift detection.

Consumed by `/workflow:audit` orchestrator. Use `--focus qa` for this domain only.

References: @qa, @test-strategy

## Auto-Detection (Exhaustive Discovery)

**Discovery mandate**: Complete ALL steps below before reporting any findings. Use multiple search strategies for each step — a single search returning empty is not proof of absence. You have a dedicated 1M token context window; use it for thoroughness, not sampling. See the orchestrator's Exhaustive Discovery Protocol for general principles.

### Step 1: Discover ALL E2E and spec infrastructure
- Search for ALL Playwright/Cypress configs across the entire repo (not just root): `playwright.config.*`, `cypress.config.*`
- Search for NL spec directories using multiple patterns: `sentinel/`, `specs/`, `e2e-specs/`, `tests/e2e/`, `tests/specs/`, `*.nl.md`, `*.nl.spec`
- **Read EACH config file completely** — note which test directories and file patterns each covers
- Check for multiple E2E setups (desktop app vs. web app may have separate configs)

### Step 2: Locate ALL E2E test files
- **Strategy A (glob)**: Search for `*.spec.ts`, `*.spec.tsx`, `*.e2e.ts` across ALL app directories
- **Strategy B (content)**: Search for Playwright/Cypress markers: `test.describe`, `test(`, `cy.`, `page.goto`
- **Cross-reference**: If strategies yield different file sets, investigate the discrepancy

### Step 3: Map E2E coverage to features
- Read ALL spec files (not a sample) to build a complete coverage map
- Cross-reference against routes, pages, and critical user flows in the app
- When claiming a flow is "untested," verify by searching spec files for relevant keywords (feature name, route, component)

### Step 4: Cross-check CI execution
- Read CI workflow files to determine if E2E tests run in CI or are local-only
- Flag test infrastructure that exists but never executes in CI

## Agent Reasoning Standards

Follow all standards from the orchestrator's Agent Reasoning Standards (cite evidence, check opposite hypothesis, verify absence claims, complete discovery before findings, use full 1M context budget, tag domain, flag cross-domain connections). Additionally:

- **Check ALL spec files before claiming a flow is untested.** Search spec files for feature keywords, route names, and component names — coverage may exist in a spec named differently than expected.

## Scope Gate

- **Small** (< 10 NL specs or < 20 routes): All agents automatically
- **Medium** (10-50 specs): All agents, sample coverage analysis
- **Large** (50+ specs): Prompt before full drift analysis

## Three-Tier Analysis

### Tier 1 — Spec Presence (always runs)

**qa-spec-coverage-analyst**:
- Check for NL test spec directory existence and structure
- Count NL specs vs. critical user flows visible in the codebase
- Flag key user journeys with no corresponding NL spec:
  - Authentication flows (login, register, password reset)
  - Core CRUD operations for primary entities
  - Payment/checkout flows (if applicable)
  - Onboarding/setup flows
  - Error/edge case flows (404, unauthorized, validation errors)
- Assess spec quality: Are specs behavioral (user-centric actions and assertions) or implementation-coupled (CSS selectors, internal state)?
- Check for spec staleness: do specs reference UI elements, routes, or flows that no longer exist?
- Severity: P1 for critical flows with no spec, P2 for secondary flows, P3 for spec quality issues

### Tier 2 — Test Generation Health (runs if Playwright config detected)

**qa-test-generation-analyst**:
- Check for generated Playwright test files corresponding to each NL spec
- Flag specs with no generated tests (spec exists but was never run through the Planner/Generator)
- Flag generated tests that appear stale:
  - Test references selectors or routes that no longer exist in the app
  - Test imports modules that have been renamed or removed
  - Test was generated before significant app changes (check file dates vs. app file dates)
- Check Playwright configuration: is it set up and functional?
- Assess test isolation: do generated tests have proper setup/teardown?
- Check for test interdependencies (tests that depend on execution order)
- Severity: P2 for specs with no generated tests, P2 for stale generated tests, P3 for isolation issues

### Tier 3 — Behavioral Drift (AI judgment)

**qa-drift-detector**:
- Cross-reference NL specs against current app routes, components, and API endpoints
- Flag behavioral drift: spec describes flow X, but app now implements it differently
  - Changed form fields, new required inputs, removed steps
  - Different navigation paths, renamed routes
  - Modified success/error states
- Flag coverage gaps: new features added to app with no corresponding spec
  - New routes with no spec
  - New components with user-facing interactions and no spec
  - New API endpoints with no integration spec
- Flag orphaned specs: specs for features that were removed from the app
- Check last spec update dates vs. last app code changes in the same area
- Severity: P2 for behavioral drift (spec exists but is wrong), P2 for coverage gaps on significant features, P3 for orphaned specs

## Output (Domain-Specific)

When run via `--focus qa`:

```markdown
### QA Coverage Summary

| Metric | Value | Status |
|--------|-------|--------|
| NL specs present | [N] specs | [ok/warning/critical] |
| Critical flows covered | [N]/[M] | [ok/warning/critical] |
| Specs with generated tests | [N]/[M] | [ok/warning/critical] |
| Stale specs | [N] | [ok/warning] |
| Stale generated tests | [N] | [ok/warning] |
| Behavioral drift detected | [N] | [ok/warning/critical] |
| Orphaned specs | [N] | [ok/warning] |
| Coverage gaps (new features) | [N] | [ok/warning/critical] |
```

## Integration Points

### With /qa:discover

If spec coverage is low, recommend running `/qa:discover` to author NL specs for uncovered flows.

### With /qa:audit

The qa:audit command performs live drift detection by actually running tests. This domain performs static drift analysis by reading specs and app code. They complement — static analysis catches obvious mismatches, live execution catches behavioral regressions.

### With @test-strategy

The spec quality assessment draws on test-strategy's principles: behavioral vs. implementation-coupled tests, assertion quality, and single-behavior focus.
