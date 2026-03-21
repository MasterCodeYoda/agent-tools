---
name: workflow:audit
description: Unified project audit — orchestrates domain-specific agents across code, tests, API, frontend, docs, repo infrastructure, and QA coverage into a single deduplicated report
argument-hint: "['.' or directory] [--focus code|tests|api|frontend|docs|repo|qa] [--depth quick|standard|deep]"
---

# Project Audit

A single entry point for comprehensive project assessment. Auto-detects what the project contains, dispatches domain-specific agent teams in parallel, deduplicates cross-domain findings, and produces one unified health report.

This is `/workflow:review` at project scope — not targeted at a changeset, but at the full codebase.

## User Input

```text
$ARGUMENTS
```

## Input Detection

| Input Pattern | Scope | Action |
|---|---|---|
| `.` or empty | Current project | Full audit across all detected domains |
| Directory path | Target directory | Audit within scope |
| `--focus code` | Single domain | Run only code quality agents |
| `--focus tests` | Single domain | Run only test quality agents |
| `--focus api` | Single domain | Run only API design agents |
| `--focus frontend` | Single domain | Run only frontend quality agents |
| `--focus docs` | Single domain | Run only documentation agents |
| `--focus repo` | Single domain | Run only repo infrastructure agents |
| `--focus qa` | Single domain | Run only QA coverage agents |
| `--focus code,tests,api` | Multiple domains | Comma-separated domain list |
| `--depth quick` | Shallow | Tier 1 only across all domains |
| `--depth standard` | Normal | Tier 1 + Tier 2 (default) |
| `--depth deep` | Thorough | All tiers including heuristic analysis |
| `--diff main` | Changed scope | Only audit files changed vs. branch |
| `--recent 7d` | Recent scope | Only audit files modified in last N days |

`--focus` and `--depth` combine: `--focus code,tests --depth deep` is valid.

## Auto-Detection Phase

Before dispatching agents, discover the project's shape. This determines which domains are relevant.

```
1. Languages and frameworks (Python/FastAPI, TypeScript/React, C#/.NET, Rust/Tauri, etc.)
2. API surface (REST endpoints, OpenAPI specs, GraphQL schemas, gRPC protos)
3. Frontend presence (React/Vue/Angular components, pages, CSS/styling)
4. Test infrastructure (test framework, test files, coverage tools, mutation tools)
5. Documentation (README, docs/, planning/, inline doc patterns, doc tooling)
6. CI/CD and repo infrastructure (GitHub Actions, branch protection, CODEOWNERS)
7. QA artifacts (NL specs in sentinel/, Playwright config, generated test files)
8. Project size (file counts per domain for scope gating)
```

## Domain Selection

Based on auto-detection, activate relevant domains:

| Domain | Activates When | Defers To |
|--------|---------------|-----------|
| **Code Quality** | Production source files detected | `audit-code.md` agents |
| **Test Quality** | Test files detected | `audit-tests.md` agents |
| **API Design** | API endpoints or spec files detected | `audit-api.md` agents |
| **Frontend Quality** | Frontend components detected | `audit-frontend.md` agents |
| **Documentation** | README or docs/ detected | `audit-docs.md` agents |
| **Repo Infrastructure** | Git repo detected (always) | `audit-repo.md` agents |
| **QA Coverage** | Any production code detected | QA agents (defined below) |

If `--focus` is set, only activate the specified domains regardless of detection.

Report which domains were activated and which were skipped (with reason).

## Scope Gate

Aggregate file counts across active domains:

- **Small** (< 100 total files): All tiers across all domains
- **Medium** (100-500 files): Tier 1 all domains; prompt before Tier 2/3
- **Large** (500+ files): Require `--focus` scoping or `--depth quick`

## Agent Reasoning Standards

All agents across all domains must follow:

- **Cite evidence.** Every finding must reference specific `file:line`. No finding without a concrete citation.
- **Check the opposite hypothesis.** Before reporting P1/P2, consider: "Could this be intentional?" Check for framework behavior, design decisions, or documented conventions.
- **Tag your domain.** Every finding must include its domain tag (code, tests, api, frontend, docs, repo, qa) for deduplication.
- **Flag cross-domain connections.** If a finding relates to another domain, note it: "Related: API endpoint also has no input validation (api domain)."

## Domain Agent Teams

### Code Quality Domain

References: @code-patterns, @clean-architecture

Agents (from `audit-code.md`):
- **pattern-compliance-analyst**: Naming, type safety, error handling, idioms
- **dependency-direction-checker**: Layer boundaries, dependency rule, SOLID
- **observability-readiness-analyst**: Structured logging, required fields
- **data-access-pattern-checker**: Repository patterns, queries, transactions

### Test Quality Domain

References: @test-strategy

Agents (from `audit-tests.md`):
- **assertion-analyst**: Assertion-free tests, weak assertions, tautological patterns
- **mock-boundary-checker**: Internal collaborator mocking, boundary identification

### API Design Domain

References: @clean-architecture, @code-patterns

Agents (from `audit-api.md`):
- **api-convention-checker**: Resource naming, HTTP semantics, error format, pagination
- **api-security-analyst**: OWASP API Top 10, auth, rate limiting, input validation
- **api-contract-completeness-checker**: Schema validation, breaking changes

### Frontend Quality Domain

References: @code-patterns, @visual-design

Agents (from `audit-frontend.md`):
- **accessibility-scanner**: WCAG 2.2, color contrast, form labels, keyboard nav
- **component-architecture-reviewer**: God components, prop drilling, composition
- **state-and-data-flow-reviewer**: State duplication, re-render patterns, context stacking

### Documentation Domain

References: @workflow-guide

Agents (from `audit-docs.md`):
- **structure-validator**: Missing docs, broken links, heading hierarchy, empty stubs
- **inline-doc-checker**: Public API doc coverage, parameter documentation
- **code-doc-alignment-checker**: Stale examples, parameter mismatches, dead links

### Repo Infrastructure Domain

Agents (from `audit-repo.md`):
- **ci-pipeline-analyst**: CI workflows, gate ordering, status checks
- **repo-config-analyst**: Branch protection, CODEOWNERS, PR templates
- **agent-readiness-analyst**: AGENTS.md, CLAUDE.md, onboarding docs

### QA Coverage Domain (NEW)

References: @qa, @test-strategy

This domain fills the gap — no prior standalone audit covered E2E/NL test scenario quality.

**qa-spec-coverage-analyst**:
- Check for NL test spec directory (sentinel/, specs/, e2e-specs/)
- Count NL specs vs. critical user flows visible in the codebase
- Flag key user journeys with no corresponding NL spec:
  - Authentication flows (login, register, password reset)
  - Core CRUD operations for primary entities
  - Payment/checkout flows (if applicable)
  - Onboarding/setup flows
- Assess spec quality: Are specs behavioral (user-centric) or implementation-coupled?
- Check for spec staleness: do specs reference UI elements/flows that no longer exist?

**qa-test-generation-analyst**:
- Check for generated Playwright test files corresponding to NL specs
- Flag specs with no generated tests (the spec exists but was never run through the Planner/Generator)
- Flag generated tests that appear stale (generated test references selectors/routes that no longer exist)
- Check Playwright configuration: is it set up and functional?
- Assess test isolation: do generated tests have proper setup/teardown?

**qa-drift-detector**:
- Cross-reference NL specs against current app routes/components
- Flag behavioral drift: spec describes flow X, but app now works differently
- Flag coverage gaps: new features added to app with no corresponding spec
- Flag orphaned specs: specs for features that were removed
- Check last spec update dates vs. last app code changes in same area

## Orchestration

### Dispatch

1. Activate domain teams based on auto-detection
2. Within each domain, apply the depth filter:
   - `quick`: Tier 1 agents only
   - `standard`: Tier 1 + Tier 2 agents
   - `deep`: Tier 1 + Tier 2 + Tier 3 agents
3. Spawn all domain agents in parallel (domains are independent)
4. Collect findings from all agents

### Deduplication

After all agents report, the orchestrator deduplicates cross-domain findings:

**Same file, overlapping concern** → Merge into one finding:
- Example: `api.py:L25` flagged by both `api-security-analyst` (no input validation) AND `pattern-compliance-analyst` (missing type safety) → One P1 finding: "Endpoint lacks input validation and type safety" tagged `[code, api]`

**Same root cause, different symptoms** → Group under root cause:
- Example: Missing auth middleware flagged as P1 by `api-security-analyst` AND missing branch protection flagged by `repo-config-analyst` → Group: "Authentication infrastructure gaps" with sub-findings

**Complementary findings** → Cross-reference without merging:
- Example: `audit-tests` finds low coverage on domain layer AND `audit-code` finds untested domain logic → Keep both, add cross-reference: "See also: [test-quality] finding #T3"

### Deduplication Rules

1. If two findings reference the **same file and line range** (within 10 lines), merge them
2. Merged findings take the **highest severity** from any contributing agent
3. Merged findings list **all contributing domains** as tags
4. If findings from different domains describe the **same root cause** but in different files, group them under a root cause heading
5. Cross-domain references use format: `[domain] #ID`

### Weighting

Adjust domain importance based on project shape:

| Project Type | Upweighted | Downweighted |
|---|---|---|
| Backend API | Code, API, Tests | Frontend |
| Frontend SPA | Frontend, Tests | API (if no backend) |
| Full-stack | All equal | — |
| Library/SDK | Code, Tests, Docs | Frontend, Repo |
| CLI tool | Code, Tests, Docs | Frontend, API |

Weighting affects the unified health score, not individual findings.

## Output

```markdown
## Project Audit Complete

**Project**: [name/path]
**Domains Active**: [list of activated domains]
**Domains Skipped**: [list with reasons — "Frontend: no component files detected"]
**Depth**: [quick/standard/deep]
**Agents Run**: [N] across [N] domains
**Findings**: [N] total after deduplication (from [M] raw findings)

### Unified Health Score

| Domain | Weight | Score | Grade |
|--------|--------|-------|-------|
| Code Quality | [N%] | [N]/100 | [A-F] |
| Test Quality | [N%] | [N]/100 | [A-F] |
| API Design | [N%] | [N]/100 | [A-F] |
| Frontend Quality | [N%] | [N]/100 | [A-F] |
| Documentation | [N%] | [N]/100 | [A-F] |
| Repo Infrastructure | [N%] | [N]/100 | [A-F] |
| QA Coverage | [N%] | [N]/100 | [A-F] |
| **Overall** | | **[N]/100** | **[A-F]** |

### Findings

#### P1 — Critical
[Merged, deduplicated findings with domain tags]
Each finding: `[domain tags] file:line — description — evidence — recommendation`

#### P2 — Important
[Same format]

#### P3 — Suggestions
[Same format]

### Cross-Domain Insights

[Patterns that span multiple domains — the unique value of unified auditing]
- "Authentication is consistently weak: no auth middleware (api), no auth tests (tests), no security docs (docs), no branch protection requiring reviews (repo)"
- "Domain layer is undertested: low coverage (tests), anemic models (code), no NL specs for core domain flows (qa)"

### Positive Observations
[Strong areas across domains]

### Recommended Actions

Priority-ordered, combining the most impactful fixes across all domains:
1. [Highest-impact action — often a P1 that spans domains]
2. [Second priority]
3. [Third priority]

### Domain Deep-Dives

For detailed findings in any domain, run focused mode:
- `/workflow:audit --focus code` — Full code quality report
- `/workflow:audit --focus tests` — Full test quality report
- [etc.]
```

## Integration Points

### With /workflow:review

Review examines changes (diffs/PRs). Audit examines the full codebase state. They complement: review catches issues in new code, audit catches issues in existing code.

### With /workflow:execute

Reference audit findings during execution — if the area being worked on has known issues, address them.

### With /workflow:compound

When audit reveals recurring patterns worth documenting, offer compound. Cross-domain insights are particularly valuable for compounding.

### With /workflow:plan

Audit findings inform planning — P1 items become candidates for the next planning cycle.

### With focused audit commands

The individual `audit-code.md`, `audit-tests.md`, etc. serve as domain definitions. They define the agents, their skill references, and their check criteria. The unified audit orchestrates them; `--focus` routes to them for domain-specific depth.

### With /evolve

Evolve ensures the skills that back audit agents are complete and consistent. When the unified audit consistently misses issues, evolve identifies which skill gap explains it.

## References

- [react-doctor](https://github.com/millionco/react-doctor) — Health scoring concept
- Individual domain commands: `audit-code.md`, `audit-tests.md`, `audit-api.md`, `audit-frontend.md`, `audit-docs.md`, `audit-repo.md`
