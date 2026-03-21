---
name: qa
description: QA skills for testing workflows — visual inspection tools and NL spec authoring for Playwright Test Agents
---

# QA Skills

Quality assurance workflows: NL spec-driven e2e testing with Playwright Test Agents, and visual inspection tools.

## Sentinel: NL Spec Authoring & Audit

Sentinel is a thin layer over Playwright Test Agents. Claude authors structured Natural Language (NL) specs describing what to test. Playwright's Planner and Generator agents convert those specs into `.spec.ts` test files, and `npx playwright test` executes them deterministically. Sentinel's role is authoring (discover) and maintenance (audit) — not execution.

### Pipeline

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

### NL Spec Format

NL specs are the contract between Sentinel (authoring) and Playwright (execution). They use YAML frontmatter for metadata and structured markdown that the Planner consumes.

See `references/spec-format.md` for the full format specification.

**Important**: Commit NL specs to version control. The audit workflow compares specs against generated tests — if specs aren't retained, audit cannot detect drift.

## Visual Inspection Tools

Tools for inspecting visual artifacts during QA workflows: video frame extraction, screenshot analysis, and visual regression documentation.

**Use when**: You need to analyze screen recordings, extract frames from videos, or build visual evidence for bug reports.

See `tools/SKILL.md` for tool documentation.

## Command Set

### `/qa:setup`
Initialize Sentinel in a project. Creates directory structure, config file, Playwright config, and seed test file.

### `/qa:discover`
Author NL specs by scanning the app, importing existing docs, or guided interactive conversation. Outputs structured markdown NL specs ready for Playwright's Planner.

### `/qa:audit`
Detect drift between NL specs, generated `.spec.ts` tests, and app behavior. Reports uncovered specs, orphaned tests, and behavioral regressions.

## Related Skills

- **test-strategy**: Testing methodology and strategy selection. **E2E boundary**: qa owns NL spec authoring and Playwright pipeline for E2E tests; test-strategy owns testing philosophy, strategy selection, and unit/integration test design. When deciding *what* E2E scenarios to write, consult qa. When deciding *how* to design test assertions and structure, consult test-strategy.
- **use-browser**: Browser automation tools used by qa:discover for app scanning
- **audit**: QA coverage domain (`domains/qa.md`) audits spec completeness and drift

## References

- `references/spec-format.md` — NL spec format: frontmatter fields, scenario structure, examples

## Templates

- `templates/spec-template.md` — Blank NL spec with all sections and guidance comments
