---
name: qa-sentinel
description: Thin authoring and auditing layer over Playwright Test Agents — Claude writes NL specs, Playwright generates and runs tests
---

# Sentinel: NL Spec Authoring & Audit Layer

Sentinel is a thin layer over Playwright Test Agents. Claude authors structured Natural Language (NL) specs describing what to test. Playwright's Planner and Generator agents convert those specs into `.spec.ts` test files, and `npx playwright test` executes them deterministically. Sentinel's role is authoring (discover) and maintenance (audit) — not execution.

## Pipeline

```
discover (Claude)  →  Planner (Playwright)  →  Generator (Playwright)  →  npx playwright test  →  audit (Claude)
   ↓                      ↓                       ↓                          ↓                       ↓
 NL specs             test plan              .spec.ts files           test results + report     drift detection
 (specs/*.md)                                (tests/*.spec.ts)       (playwright-report/)      (audit report)
```

### What Sentinel Does
- **Discover**: Author NL specs by scanning the app, importing docs, or guided conversation
- **Audit**: Detect drift between NL specs, generated tests, and actual app behavior

### What Playwright Test Agents Do
- **Planner**: Read NL specs and produce a test plan
- **Generator**: Convert the test plan into `.spec.ts` files
- **Healer**: Fix broken selectors/assertions in `.spec.ts` files when tests fail
- **Executor**: `npx playwright test` runs the generated tests

### What Sentinel Does NOT Do
- Execute tests (Playwright does this)
- Manage evidence/screenshots (Playwright captures via `playwright.config.ts`)
- Generate reports (Playwright HTML reporter handles this)
- Fix broken selectors (Healer does this)

## When to Use

- **Before** generating tests: Run `discover` to create NL specs for your features
- **After** test runs: Run `audit` to check for drift between specs, tests, and app behavior
- **Setup**: Run `setup` to initialize the project structure and configuration

## Command Set

### `qa-sentinel:setup`
Initialize Sentinel in a project. Creates directory structure, config file, Playwright config, and seed test file.

### `qa-sentinel:discover`
Author NL specs by scanning the app, importing existing docs, or guided interactive conversation. Outputs structured markdown NL specs ready for Playwright's Planner.

### `qa-sentinel:audit`
Detect drift between NL specs, generated `.spec.ts` tests, and app behavior. Reports uncovered specs, orphaned tests, and behavioral regressions.

## NL Spec Format

NL specs are the contract between sentinel (authoring) and Playwright (execution). They use YAML frontmatter for sentinel metadata and structured markdown that the Planner consumes.

See `references/spec-format.md` for the full format specification.

## References

- `references/spec-format.md` — NL spec format: frontmatter fields, scenario structure, examples
- `references/execution-model.md` — Playwright pipeline: Planner → Generator → test → Healer
- `references/coverage-model.md` — Audit coverage model: NL specs vs generated tests
- `references/evidence-guide.md` — Evidence capture: Playwright-native screenshots, traces, video

## Templates

- `templates/spec-template.md` — Blank NL spec with all sections and guidance comments
- `templates/config-template.yaml` — Configuration file with Playwright and spec directory settings
