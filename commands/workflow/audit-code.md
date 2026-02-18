---
name: workflow:audit-code
description: Audit existing production code quality against @code-patterns, @clean-architecture, and @logging standards
argument-hint: "[directory path, file glob, or 'all']"
---

# Production Code Audit

Examine existing production code against @code-patterns, @clean-architecture, and @logging principles and produce prioritized, actionable findings.

## User Input

```text
$ARGUMENTS
```

## Input Detection

Parse input to determine audit scope:

| Input Pattern | Scope | Action |
|---|---|---|
| `./src/` or `./lib/` | Directory | Audit all production code in directory |
| `./tests/` or `./test/` | Test directory | Redirect to `/workflow:audit-tests` |
| `*.py` or `*.ts` | File glob | Audit matching files |
| `all` or empty | Full codebase | Auto-detect project structure, audit everything (prompt if large) |
| `--layer domain` | Architectural layer | Audit that layer (requires `@clean-architecture` context) |
| `--recent 7d` | Recent changes | Audit files modified in last N days |
| `--diff main` | Changed files | Audit files changed vs. specified branch |

## Auto-Detection Phase

Before analysis, detect the project's setup:

```
1. Detect primary language(s)
2. Detect architecture style (Clean Architecture, feature-based, traditional layers, flat)
3. Locate production code directories (exclude tests, node_modules, build artifacts)
4. Count source files and estimate LoC
5. Check for quality tools (mypy/ruff/bandit, ESLint/tsc, Roslyn, clippy)
6. Detect logging framework (structlog, winston, serilog, tracing)
```

## Scope Gate

Based on auto-detection, prompt user for scope confirmation:

- **Small** (< 50 files): Run all tiers automatically
- **Medium** (50-500 files): Run Tier 1 on all; prompt before Tier 2/3
- **Large** (500+ files): Require explicit scoping or run Tier 1 sampling

## Three-Tier Analysis

### Tier 1 — Static Analysis (always runs)

Spawn 4 parallel agents that read production code:

**pattern-compliance-analyst** — References @code-patterns (SKILL.md + language guides):
- Naming conventions per language
- Type safety compliance (strict mode, no `any`/`dynamic`)
- Error handling patterns (Result/Either, not exceptions for expected failures)
- Code organization (feature-based vs scattered)
- Language-specific idioms and framework best practices
- Anti-patterns per language (mutable shared state, god objects, string typing)

**dependency-direction-checker** — References @clean-architecture (SKILL.md + `references/layer-patterns.md`):
- Dependency Rule compliance (inward only)
- Layer boundary violations
- Anemic domain detection (entities with only getters/setters)
- Fat controller detection (business logic in framework layer)
- SOLID principle violations
- Entity/Value Object distinction
- Aggregate boundary enforcement

**observability-readiness-analyst** — References @logging (SKILL.md):
- Structured logging compliance (JSON, not string interpolation)
- Required field presence (timestamp, level, event, request_id/trace_id)
- Correct log level usage
- Sensitive data exposure in logs
- Context propagation across boundaries

**data-access-pattern-checker** — References @clean-architecture (`references/layer-patterns.md#infrastructure`):
- ORM/query builder usage patterns (raw SQL flagged unless justified)
- Repository pattern compliance (queries in infrastructure layer, not in controllers/use cases)
- Migration file hygiene (reversible migrations, no data-destructive operations without guards)
- Connection management (pooling configured, connections released, no leaked connections)
- Transaction boundary placement (transactions in application layer use cases, not scattered)
- Index coverage for query patterns (queries on unindexed columns)

### Tier 2 — Dynamic Analysis (auto-detect: runs if tools found)

Spawn 2 parallel agents:

**static-analyzer-runner** — Language-appropriate tooling:
- Python: mypy (strict), ruff, bandit
- TypeScript: tsc --noEmit, ESLint
- C#: Roslyn analyzers, dotnet format
- Rust: clippy, cargo-audit

**complexity-metrics-analyst**:
- Cyclomatic complexity per function (flag > 10)
- Function length (flag > 50 lines), class size (flag > 300 lines)
- Duplication detection
- Module coupling metrics
- Hot path identification (most-called functions via static call graph)
- Bundle/binary size analysis (if web project: webpack-bundle-analyzer; if compiled: binary size)
- Dependency weight analysis (heavy transitive dependencies)

### Tier 3 — Heuristic Analysis (AI judgment)

Spawn 4 parallel agents:

**architecture-health-reviewer** — References @clean-architecture (`templates/architecture-review.md`):
- Layer responsibility adherence across full codebase
- Cross-cutting concern placement
- Transaction boundary clarity
- N+1 queries, resource leaks, missing connection pooling
- Schema design quality (normalization issues, missing constraints, orphan tables)
- Data access layer isolation (no SQL in controllers, no ORM entities in API responses)

**production-readiness-scout** — References quality checkpoints (`skills/workflow-guide/implementation/quality-checkpoints.md`):
- Security: input validation, SQL injection prevention, auth/authz, secrets management
- Error handling: graceful degradation, exception boundaries
- Resilience: retry logic, circuit breakers, timeouts, idempotency
- Deployment: config externalized, health checks, graceful shutdown

**design-smell-detector** — AI-driven assessment:
- Long parameter lists, feature envy, primitive obsession, data clumps
- Naming quality and consistency
- Missing abstractions (repeated conditionals, hardcoded rules)
- Testability assessment (hard-coded dependencies, missing seams)

**performance-hotspot-detector** — AI-driven assessment:
- Algorithm complexity (nested loops, quadratic patterns on collections)
- Missing caching (repeated expensive computations, redundant API/DB calls)
- Resource utilization patterns (unbounded collections, missing pagination at data layer)
- Synchronous blocking in async contexts
- Memory patterns (large object retention, missing cleanup/disposal)
- Hot path optimization opportunities

## Output: Prioritized Report

Present findings using the same P1/P2/P3 structure as `/workflow:review`:

```markdown
## Code Audit Complete

**Scope**: [directory/files audited]
**Source Files**: [N] files, ~[M] LoC
**Language(s)**: [detected languages]
**Architecture**: [detected style]
**Tiers Run**: [1, 2, 3] or [1 only]

### Health Summary

| Metric | Value | Status |
|--------|-------|--------|
| Static analysis | [pass/issues] | [ok/warning/critical] |
| Layer violations | N | [ok/warning/critical] |
| Anemic domains | N | [ok/warning] |
| Type safety | [strict/partial/weak] | [ok/warning/critical] |
| Structured logging | [compliant/partial/missing] | [ok/warning/critical] |
| Cyclomatic complexity | [avg / max] | [ok/warning] |
| Security issues | N | [ok/warning/critical] |
| Data layer compliance | [pass/issues] | [ok/warning/critical] |
| Performance hotspots | N | [ok/warning] |
| Performance anti-patterns | N | [ok/warning] |

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

#### P1 — Critical (Architectural / Security Violations)
[Dependency rule violations, security vulnerabilities, missing auth — these are structural risks]

#### P2 — Important (Quality / Maintainability)
[Type safety gaps, anemic domains, missing structured logging, high complexity]

#### P3 — Suggestions (Improvements)
[Naming consistency, design smells, missing abstractions, testability improvements]

### Positive Observations
[Well-structured areas, good patterns found, strong areas of the codebase]

### Recommended Actions
1. [Highest-impact fix — usually P1 items]
2. [Second priority]
3. [Tool recommendation if static analysis not configured]
```

## Actionable Next Steps

After presenting the report, offer:

```markdown
## Next Steps

1. **Fix critical findings** — Address P1 items (architectural and security violations)
2. **Create follow-up tasks** — Track P2/P3 improvements
3. **Re-audit after fixes** — Run `/workflow:audit-code [same scope]` to verify
4. **Install quality tools** — [if static analysis not configured: recommend tools for language]
5. **Save report** — Export findings to `./planning/code-audit-report.md`
```

## Integration Points

### With /workflow:execute

During execution, if an audit was recently run, reference its findings for the area being worked on.

### With /workflow:review

Review examines changes (diffs/PRs). Audit-code examines the current codebase state regardless of when code was written.

### With /workflow:refine

If P1 architectural issues are found, use refine to design a refactoring approach.

### With /workflow:compound

If audit reveals a recurring anti-pattern fix worth documenting, offer compound.

### With /workflow:audit-repo

audit-code examines production code quality; audit-repo examines repository infrastructure (CI/CD, branch protection, agent docs). They are complementary — repo infrastructure enables code quality enforcement.

### With @code-patterns, @clean-architecture, @logging

All agent prompts reference specific sections of these skills as their criteria source. This command is the active counterpart to those skills' passive guidance.

## References

- [react-doctor](https://github.com/millionco/react-doctor) — Health scoring concept adapted from this React diagnostic CLI
