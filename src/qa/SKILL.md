---
name: qa
description: QA skills for testing workflows — visual inspection tools and NL spec authoring for Playwright Test Agents
---

# QA Skills

Quality assurance workflows: NL spec-driven e2e testing with Playwright Test Agents, and visual inspection tools.

## When to Use This Skill

- **Testing web applications** — Setting up or running e2e test pipelines with Playwright Test Agents
- **Authoring NL test specs** — Creating structured natural language specifications that describe what to test
- **Auditing spec-to-test alignment** — Detecting drift between NL specs, generated tests, and actual app behavior
- **Visual inspection** — Using browser automation to visually verify UI behavior

## Sentinel: NL Spec Authoring & Audit

Sentinel is a thin layer over Playwright Test Agents. It provides authoring (discover) and maintenance (audit) capabilities for NL-driven testing. The actual test generation and execution are handled by Playwright's Planner, Generator, and Healer agents.

---

<!-- agent:include claude -->

**Current integration is primarily demonstrated with Claude Code as the NL spec author and auditor.**

### Pipeline (Claude-centric example)

```
discover (Claude)  →  Planner (Playwright)  →  Generator (Playwright)  →  npx playwright test  →  audit (Claude)
   ↓                      ↓                       ↓                          ↓                       ↓
 NL specs             test plan              .spec.ts files           test results + report     drift detection
 (specs/*.md)                                (tests/*.spec.ts)       (playwright-report/)      (audit report)
```

<!-- /agent:include claude -->

<!-- agent:include grok -->

### Grok Implementation

Grok can participate in the Sentinel / Playwright Test Agents workflow in two primary ways:

- **Directly as the model** driving the Planner, Generator, and/or Healer roles via the Playwright MCP server (typically through Grok Build, Cursor with a Grok backend, or a custom MCP client).
- **As a meta-tool** for authoring or refining high-quality NL specs before they are fed into the Playwright agent loop, or for reviewing and improving generated tests.

**Strengths**: Strong reasoning for planning complex flows and producing maintainable, well-structured test code (especially POM patterns).

**Limitations / Differences**:
- There is no native `--loop=grok` in `npx playwright init-agents`. Most teams use `--loop=vscode` (or omit the flag) while running Grok as the model.
- Generated tests often still benefit from the Playwright Healer for selector robustness.
- Best results usually come from giving Grok rich context (seed test + constants + style guidelines) and explicitly asking it to verify state after major steps.

<!-- /agent:include grok -->

<!-- agent:include factory -->

### Factory Droid Implementation

Factory Droid approaches NL-driven testing differently from the dedicated Playwright Planner/Generator/Healer loop. Instead of routing NL specs through Playwright’s specific agents, Factory tends to:

- Delegate testing responsibilities to specialized **Test Droids** (or Reliability Droids) as part of larger, orchestrated multi-agent workflows.
- Use `AGENTS.md`, persistent project memory (`.factory/memories.md`), and rules (`.factory/rules/`) to keep the Test Droid aligned with team standards and verification requirements.
- Treat NL spec authoring as one possible input among others (tickets, monitoring signals, existing tests, etc.) rather than the central hand-off artifact.

**Verification-oriented strengths**: Factory places heavy emphasis on guardrails, role boundaries, and auditable outcomes. Test Droids can be explicitly instructed to produce evidence, catch regressions, and maintain coverage as part of a broader engineering process.

**Workflow differences**: You are more likely to give a Test Droid an ongoing responsibility (“Maintain E2E coverage for checkout and report drift”) than to manually step through a Planner → Generator → Healer pipeline. The platform’s multi-agent nature and strong convention enforcement are the primary advantages.

<!-- /agent:include factory -->

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
