---
name: qa-sentinel
description: Spec-driven QA testing — structured markdown specs ARE the tests, executed by Claude via Chrome DevTools MCP browser control
---

# Sentinel: Spec-Driven QA Testing

Sentinel is a QA harness where structured markdown specs are the tests. There is no intermediate test code layer — Claude reads the specs, drives a browser via Chrome DevTools MCP, judges outcomes against expected results, and records evidence. Designed for on-demand pre-release validation, not CI.

## When to Use

- Pre-release validation of a web application
- Regression testing after significant UI or feature changes
- UAT (user acceptance testing) driven by structured scenarios
- Validating that critical user flows still work as expected
- Building a coverage baseline for a new or untested area of the app

## Core Concept: Specs Are the Tests

Traditional test automation requires writing test code (Selenium scripts, Playwright tests, Cypress specs). Sentinel eliminates that layer entirely:

1. **You write specs** — structured markdown files describing features, scenarios, and expected results
2. **Claude executes them** — reading each scenario, driving the browser, and judging whether the outcome matches
3. **Results are recorded** — pass/fail per scenario with evidence (screenshots, DOM snapshots)

No test code to maintain. No selectors to keep in sync. Claude adapts to UI changes the same way a human tester would — by understanding intent, not matching brittle selectors.

## Command Set

Sentinel operates through four commands, typically run in sequence:

### `qa-sentinel:setup`
Initialize Sentinel in a project. Creates the directory structure, config file, and a sample spec.

### `qa-sentinel:discover`
Scan the specs directory, parse all spec files, build the dependency graph, and report coverage status. Shows which specs exist, which have been run, and which have never been tested.

### `qa-sentinel:run`
Execute specs against the running application. Resolves dependency order, drives the browser through each scenario, captures evidence, and writes run files with results.

### `qa-sentinel:report`
Generate a coverage and regression report from run data. Shows pass/fail rates by area, flags regressions (scenarios that previously passed but now fail), and identifies never-tested specs.

## References

- `references/spec-format.md` — Spec file structure, frontmatter fields, scenario format, examples
- `references/coverage-model.md` — Coverage tracking, run files, regression detection
- `references/execution-model.md` — How browser execution works, dependency resolution, self-healing
- `references/evidence-guide.md` — Screenshot and evidence capture conventions

## Templates

- `templates/spec-template.md` — Blank spec with all sections and placeholder guidance
- `templates/config-template.yaml` — Configuration file with all options documented
