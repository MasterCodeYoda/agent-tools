# Documentation Domain

Agents and criteria for auditing documentation quality — READMEs, inline docs, API docs, planning docs, architecture docs.

Consumed by `/workflow:audit` orchestrator. Use `--focus docs` for this domain only.

## User Input

```text
$ARGUMENTS
```

## Input Detection

Parse input to determine audit scope:

| Input Pattern | Scope | Action |
|---|---|---|
| `./docs/` or `./documentation/` | Directory | Audit all documentation in directory |
| `./src/` or `./lib/` | Code path | Audit inline docs, docstrings, comments |
| `README.md` or `*.md` | File/glob | Audit matching files |
| `all` or empty | Full project | Auto-detect docs, audit everything (prompt if large) |
| `--type api` | API docs | Audit OpenAPI/Swagger/GraphQL schemas |
| `--type planning` | Planning docs | Audit `./planning/*/` files |
| `--type inline` | Code docs | Audit docstrings, JSDoc, XML comments |
| `--recent 7d` | Recent changes | Audit files modified in last N days |
| `--diff main` | Changed files | Audit files changed vs. specified branch |

## Auto-Detection Phase (Exhaustive Discovery)

**Discovery mandate**: Complete ALL steps below before reporting any findings. Use multiple search strategies for each step. You have a dedicated 1M token context window; use it for thoroughness, not sampling. See the orchestrator's Exhaustive Discovery Protocol for general principles.

### Step 1: Discover ALL documentation locations
- Search for ALL doc directories: `docs/`, `documentation/`, `wiki/`, `planning/`, `guides/`
- Search for ALL doc site apps (Docusaurus, Astro/Starlight, MkDocs, Sphinx) — monorepos may have multiple doc sites (user-facing, technical, API)
- Check for ADR directories (`docs/ADR/`, `adr/`, `decisions/`)
- Find ALL markdown/mdx files across the entire repo

### Step 2: Detect code documentation patterns
- Detect per-language doc patterns: `///` (Rust), `/** */` (JSDoc), `"""` (Python docstrings), `///` (C# XML)
- Sample doc coverage across multiple directories, not just one
- Check for doc generation tooling (rustdoc, typedoc, sphinx)

### Step 3: Count and classify
- Count doc files per location using glob
- Classify: README, contributing, architecture, API, inline, planning, solution docs
- Check for doc tooling configs and build steps in CI

## Scope Gate

Based on auto-detection, prompt user for scope confirmation:

- **Small** (< 20 doc files): Run all tiers automatically
- **Medium** (20-100 doc files): Run Tier 1 on all; prompt before Tier 2/3
- **Large** (100+ doc files): Require explicit scoping or run Tier 1 sampling

## Agent Reasoning Standards

Follow all standards from the orchestrator's Agent Reasoning Standards (cite evidence, check opposite hypothesis, verify absence claims, complete discovery before findings, use full 1M context budget, tag domain, flag cross-domain connections). Additionally:

- **Check for doc generation tooling.** Before reporting missing docs, check if docs are auto-generated from code (rustdoc, typedoc, sphinx) or hosted elsewhere.

## Three-Tier Analysis

### Tier 1 — Presence & Structure (always runs)

Spawn 2 parallel agents:

**structure-validator** — References @workflow-guide (`planning/templates.md`, quality checkpoints):
- Missing expected docs (README per module, CONTRIBUTING, CHANGELOG)
- Frontmatter validation (YAML format, required fields)
- Section completeness (expected sections present)
- Heading hierarchy (proper nesting)
- Broken internal links (relative paths, anchor references)
- Empty or stub files

**inline-doc-checker** — References @clean-architecture (`templates/architecture-review.md`):
- Public API documentation coverage (functions/classes without docs)
- Documentation format compliance per language
- Parameter and return value documentation completeness
- Exception/error documentation
- Example code presence for complex APIs

### Tier 2 — Accuracy & Freshness (cross-reference)

Spawn 2 parallel agents:

**code-doc-alignment-checker**:
- Stale examples (code that won't compile/run)
- Parameter mismatch (documented params don't match signatures)
- Dead external links
- Configuration drift (documented config doesn't match actual)
- Version discrepancies

**planning-doc-verifier** — If `./planning/` exists:
- Requirements vs. implementation alignment
- Session state accuracy
- Issue key validity
- Checklist completeness vs. actual status

### Tier 3 — Quality & Completeness (AI judgment)

Spawn 2 parallel agents:

**clarity-analyst**:
- Jargon without explanation
- Missing context (assumes unstated knowledge)
- Ambiguous instructions
- Incomplete examples
- Inconsistent terminology

**gap-finder**:
- Missing edge case documentation
- Undocumented design decisions
- Missing troubleshooting guides
- Incomplete API coverage
- Missing getting-started guide for new contributors

## Output: Prioritized Report

Present findings using the same P1/P2/P3 structure as `/workflow:review`:

```markdown
## Documentation Audit Complete

**Scope**: [directory/files audited]
**Doc Files**: [N] files
**Doc Types**: [README, API, inline, planning, architecture]
**Tooling**: [detected doc tools]
**Tiers Run**: [1, 2, 3] or [1 only]

### Health Summary

| Metric | Value | Status |
|--------|-------|--------|
| Expected docs present | X/Y | [ok/warning/critical] |
| Frontmatter validation | [pass/issues] | [ok/warning] |
| Broken links | N | [ok/warning/critical] |
| Public API doc coverage | X% | [ok/warning/critical] |
| Stale examples | N | [ok/warning/critical] |
| Code-doc alignment | [aligned/drift] | [ok/warning/critical] |

### Health Score

Calculate from findings:
- Start at 100
- Each P1: -12 points
- Each P2: -4 points
- Each P3: -1 point
- Floor: 0

| Score Range | Label |
|-------------|-------|
| 90-100 | Excellent |
| 75-89 | Good |
| 60-74 | Fair |
| 40-59 | Needs Work |
| 0-39 | Critical |

**Score: [N]/100 — [Label]**

### Findings

#### P1 — Critical (Docs That Mislead)
[Stale examples, wrong signatures, outdated config — these actively cause confusion]

#### P2 — Important (Docs That Under-Serve)
[Missing docs, incomplete coverage, broken links, missing getting-started guide]

#### P3 — Suggestions (Clarity Improvements)
[Jargon, ambiguity, missing context, inconsistent terminology]

### Positive Observations
[Well-documented areas, good patterns found, comprehensive sections]

### Recommended Actions
1. [Highest-impact fix — usually P1 items]
2. [Second priority]
3. [Tool recommendation if doc tooling not configured]
```

## Actionable Next Steps

After presenting the report, offer:

```markdown
## Next Steps

1. **Fix critical findings** — Address P1 items (misleading docs cause real damage)
2. **Create follow-up tasks** — Track P2/P3 improvements
3. **Re-audit after fixes** — Run `/workflow:audit --focus docs [same scope]` to verify
4. **Install doc tooling** — [if not configured: recommend tools for project]
5. **Save report** — Export findings to `./planning/docs-audit-report.md`
```

## Integration Points

### With /workflow:execute

During execution, remind to update documentation when changing code that has associated docs.

### With /workflow:compound

Validate compound solution output quality — ensure documented solutions are clear and complete.

### With /workflow:refine and /workflow:plan

Validate requirements and plan structure against documentation standards.

### With /workflow:audit --focus repo

audit-docs evaluates documentation quality and accuracy; audit-repo checks that documentation infrastructure exists (README, CONTRIBUTING, ADRs, agent docs).

### With @clean-architecture

Architecture review documentation standards inform what docs should exist and how they should be structured.

## References

- [react-doctor](https://github.com/millionco/react-doctor) — Health scoring concept adapted from this React diagnostic CLI
