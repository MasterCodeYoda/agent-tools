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

Each domain's agents, skill references, tiered analysis, and check criteria are defined in the @audit skill under `domains/`. The orchestrator reads these definitions to know what to dispatch.

| Domain | Definition | Agents | Skill References |
|--------|-----------|--------|-----------------|
| Code Quality | `@audit/domains/code.md` | 4 | @code-patterns, @clean-architecture |
| Test Quality | `@audit/domains/tests.md` | 2 | @test-strategy |
| API Design | `@audit/domains/api.md` | 3-5 | @clean-architecture, @code-patterns |
| Frontend Quality | `@audit/domains/frontend.md` | 3-5 | @code-patterns, @visual-design |
| Documentation | `@audit/domains/docs.md` | 2-4 | @workflow-guide |
| Repo Infrastructure | `@audit/domains/repo.md` | 3-6 | @code-patterns, @clean-architecture, @test-strategy |
| QA Coverage | `@audit/domains/qa.md` | 3 | @qa, @test-strategy |

For each active domain: read its domain definition file, spawn the agents defined there at the appropriate depth tier, collect findings tagged with the domain name.

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

### With @audit skill (domain definitions)

Domain definitions live in `skills/audit/domains/`. Each file defines the agents, skill references, and check criteria for one domain. The orchestrator reads them; `--focus <domain>` routes to the specific domain definition for focused depth.

### With /evolve

Evolve ensures the skills that back audit agents are complete and consistent. When the unified audit consistently misses issues, evolve identifies which skill gap explains it.

## References

- [react-doctor](https://github.com/millionco/react-doctor) — Health scoring concept
- Domain definitions: `skills/audit/domains/{code,tests,api,frontend,docs,repo,qa}.md`
