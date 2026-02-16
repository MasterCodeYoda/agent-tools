---
name: workflow:audit-docs
description: Audit documentation quality — READMEs, inline docs, API docs, planning docs, architecture docs
argument-hint: "[directory path, file glob, or 'all']"
---

# Documentation Audit

Examine existing documentation for presence, accuracy, completeness, and clarity. Produce prioritized, actionable findings.

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

## Auto-Detection Phase

Before analysis, detect the project's documentation setup:

```
1. Detect documentation structure (root docs, doc directories, planning dirs, solution docs)
2. Detect code documentation patterns per language (docstrings, JSDoc, XML comments, doc comments)
3. Detect API documentation (OpenAPI, GraphQL schemas)
4. Count documentation files
5. Check for doc tooling (MkDocs, Docusaurus, Sphinx, rustdoc)
```

## Scope Gate

Based on auto-detection, prompt user for scope confirmation:

- **Small** (< 20 doc files): Run all tiers automatically
- **Medium** (20-100 doc files): Run Tier 1 on all; prompt before Tier 2/3
- **Large** (100+ doc files): Require explicit scoping or run Tier 1 sampling

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
3. **Re-audit after fixes** — Run `/workflow:audit-docs [same scope]` to verify
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

### With @clean-architecture

Architecture review documentation standards inform what docs should exist and how they should be structured.
