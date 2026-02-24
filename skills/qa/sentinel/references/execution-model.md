# Execution Model

Sentinel does not execute tests. It authors NL specs (discover) and checks for drift (audit). Execution is handled entirely by the Playwright Test Agents pipeline.

## Pipeline

```
NL specs (specs/*.md)
        ↓
    Planner
        ↓
   test plan
        ↓
   Generator
        ↓
 .spec.ts files (tests/*.spec.ts)
        ↓
npx playwright test
        ↓
  test results + HTML report (playwright-report/)
        ↓
    Healer (on failure)
        ↓
  fixed .spec.ts files
```

### Planner

Reads NL spec files and produces a structured test plan. The Planner consumes only the markdown body — Overview, Preconditions, Scenarios, Test Data. It ignores YAML frontmatter entirely (frontmatter is sentinel metadata, not test instructions).

The Planner outputs a test plan describing: what pages to navigate to, what actions to perform, what assertions to make, and what fixtures are needed.

### Generator

Converts the Planner's test plan into `.spec.ts` files using Playwright's API. Generated files live in the configured test directory (default: `tests/`). Generated tests import shared fixtures from the seed spec referenced in the NL spec's `seed` frontmatter field.

### npx playwright test

Standard Playwright test runner. Executes `.spec.ts` files against the running application. Playwright handles:
- Test isolation and ordering
- Screenshot capture (on failure by default)
- Trace recording
- Video capture
- HTML report generation (`playwright-report/`)

All evidence capture is configured in `playwright.config.ts`, not in sentinel config.

### Healer

When tests fail due to selector changes or assertion drift, the Healer analyzes failures and fixes `.spec.ts` files. The Healer repairs test code — it does not update NL specs.

If the app's behavior has fundamentally changed (not just a selector rename), the NL spec itself needs updating. That is an audit concern, not a Healer concern.

## Sentinel's Role

- **Before execution**: `discover` authors NL specs that the Planner will consume
- **After execution**: `audit` reads Playwright's output and compares it against NL spec expectations
- **Not during execution**: Sentinel is not in the execution loop — it hands off to the Playwright pipeline and waits

## Seed Spec

Each NL spec references a `seed` file in its frontmatter (e.g., `seed: tests/seed.spec.ts`). The seed contains project-specific fixtures:

- Bridge shim injection (for apps using IPC, e.g., Tauri)
- Auth setup (login state, test user credentials)
- Base URL configuration
- Any shared `beforeAll` / `afterAll` hooks

Generated tests import from the seed, keeping project-specific setup out of the NL specs themselves. The `setup` command generates an initial seed file with placeholder fixtures.

## On-Demand vs CI

The Playwright pipeline runs in both modes:

- **On-demand**: Developer runs `npx playwright test` locally after the Generator produces `.spec.ts` files
- **CI**: GitHub Actions or similar runs `npx playwright test` on every PR against generated test files checked into the repo
- **Sentinel audit**: Can be run after either mode to compare NL spec expectations against Playwright's HTML report

Generated `.spec.ts` files should be committed to the repo. The Planner and Generator are run when NL specs change; the test runner executes committed test files on every CI run.
