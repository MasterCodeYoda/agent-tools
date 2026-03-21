# QA Coverage Domain

Agents and criteria for auditing end-to-end test coverage — NL spec completeness, Playwright test generation health, and spec-to-app drift detection.

Consumed by `/workflow:audit` orchestrator. Use `--focus qa` for this domain only.

References: @qa, @test-strategy

## Auto-Detection

```
1. Check for NL test spec directories (sentinel/, specs/, e2e-specs/, tests/e2e/)
2. Check for Playwright configuration (playwright.config.ts/js)
3. Check for generated test files alongside or referencing NL specs
4. Detect primary user flows from routes/pages/components
5. Count specs vs. estimated critical flows
```

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
