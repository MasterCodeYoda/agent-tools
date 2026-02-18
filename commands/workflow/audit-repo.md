---
name: workflow:audit-repo
description: Audit repository readiness for autonomous AI agent coding — CI/CD, review automation, risk management, agent docs, security posture
argument-hint: "['.', directory path, or '--focus ci|security|agent|factory']"
---

# Repository Readiness Audit

Examine repository infrastructure for CI/CD health, review automation, risk management, agent documentation, dependency management, security posture, and incident memory. Produce prioritized, actionable findings.

## User Input

```text
$ARGUMENTS
```

## Input Detection

Parse input to determine audit scope:

| Input Pattern | Scope | Action |
|---|---|---|
| `.` or empty | Current repo | Full readiness audit |
| Directory path | Target repo | Audit the specified repository |
| `--focus ci` | CI/CD only | CI/CD pipeline and testing infrastructure |
| `--focus security` | Security only | Security posture and dependency management |
| `--focus agent` | Agent readiness | Agent docs, CLAUDE.md, AGENTS.md quality |
| `--focus factory` | Factory alignment | Code Factory 10-point methodology check |
| `--recent 7d` | Recent changes | Audit repo config files modified in last N days |
| `--diff main` | Changed files | Audit config files changed vs. specified branch |

## Auto-Detection Phase

Before analysis, detect the repository's setup:

```
1. Detect CI/CD platform (GitHub Actions, GitLab CI, CircleCI, Jenkins, Buildkite)
2. Detect branch protection configuration
3. Detect testing infrastructure (test runner, coverage tools, mutation testing)
4. Detect code review setup (CODEOWNERS, required reviewers, review bots)
5. Detect agent documentation (CLAUDE.md, AGENTS.md, MCP configs)
6. Detect dependency management (lock files, Dependabot/Renovate, audit tools)
7. Detect security tooling (secret scanning, SAST, pre-commit hooks)
8. Detect documentation infrastructure (README quality, ADRs, contributing guide)
```

## Scope Gate

Based on auto-detection, determine audit scope:

- **Single repo**: Run all tiers automatically
- **Monorepo** (multiple CI configs): Run Tier 1 on all; prompt before Tier 2/3
- **Org-wide** (multiple repos): Require explicit scoping

## Three-Tier Analysis

### Tier 1 — Static Analysis (always runs)

Spawn 4 parallel agents that examine repository configuration:

**ci-pipeline-analyst**:
- CI workflow files exist and are valid YAML
- Workflows triggered on pull requests (not just push)
- Gate ordering: lint → build → test → deploy (no skipping)
- Required status checks configured in branch protection
- Build, test, and lint steps all present
- SHA pinning on third-party actions (not `@main` or `@v1`)
- Caching configured for dependencies
- Matrix strategy for multiple OS/version testing (P3)
- Workflow DRY-ness (reusable workflows or composite actions)
- Timeout limits set on jobs

**repo-config-analyst**:
- Branch protection enabled on default branch
- Force push disabled on protected branches
- Required reviews configured (minimum 1)
- CODEOWNERS file present and covers critical paths
- PR template exists with checklist structure
- Issue templates configured
- Merge strategy configured (squash/rebase/merge — consistent)
- Stale branch cleanup (automated or documented policy)
- `.gitignore` comprehensive for project type

**agent-readiness-analyst**:
- CLAUDE.md exists and contains actionable guidance
- AGENTS.md or agent configuration documented
- README has quickstart, architecture overview, and development setup
- Architecture documentation exists (diagrams, decision records)
- ADR directory present with at least initial decisions
- MCP configuration (`mcp.json` or `.mcp/`) documented if applicable
- CONTRIBUTING.md or equivalent exists
- Skill/command definitions present (if using agent-tools pattern)
- Onboarding time estimate (can an agent start contributing from docs alone?)

**dependency-security-analyst**:
- Lock file present and committed (package-lock.json, yarn.lock, Cargo.lock, etc.)
- `.gitignore` excludes secrets, env files, credentials
- Pre-commit hooks configured (husky, pre-commit, lefthook)
- Secret scanning configuration (GitHub secret scanning, gitleaks, detect-secrets)
- No secrets in recent git history (scan last 50 commits)
- SECURITY.md or security policy exists
- Dependency pinning strategy (exact versions vs ranges)

### Tier 2 — Dynamic Analysis (runs if `gh` CLI available)

Spawn 2 parallel agents:

**ci-health-runner**:
- Query branch protection API via `gh api` for actual enforcement status
- Check last 10 CI runs for reliability (pass rate, flakiness)
- Verify Dependabot or Renovate is active (open PRs or recent merges)
- Check if secret scanning is enabled via GitHub API
- Verify required status checks list matches actual CI job names
- Check if GitHub Advanced Security features are enabled

**test-infra-runner**:
- Verify test runner is functional (dry-run or `--list` mode)
- Check if coverage configuration exists and thresholds are set
- Verify coverage reporting is integrated into CI
- Check for test parallelization configuration
- Detect browser test infrastructure (if frontend project)
- Verify mutation testing setup (if configured)

### Tier 3 — Heuristic Analysis (AI judgment)

Spawn 3 parallel agents:

**factory-readiness-reviewer** — Code Factory 10-point alignment:
1. CI runs all tests on every PR
2. Coverage tool enforces minimum threshold
3. AI reviewer bot on every PR
4. One author can merge without extra approval (with CI gates)
5. Failed CI → agent gets feedback and retries ("one loop")
6. Mutation testing or equivalent quality gate
7. No manual QA gate in the deploy pipeline
8. Deployment is automated (merge → deploy)
9. Monitoring and alerting catch production issues
10. Agent can write AND review code autonomously

Assess each point: Met / Partially Met / Not Met / Not Applicable
Evaluate "SHA discipline maturity" — are dependencies and actions pinned to immutable references?

**agent-context-quality-reviewer**:
- Can an agent onboard from CLAUDE.md alone? (complete, accurate, actionable)
- Are there tribal knowledge gaps? (undocumented conventions, implicit standards)
- Is the development workflow documented end-to-end? (setup → test → deploy)
- Are code patterns documented or enforced? (linters, formatters, templates)
- Is the testing philosophy documented? (what to test, how, coverage expectations)
- Are there agent-specific anti-patterns? (manual steps, GUI-only workflows, undocumented environment setup)

**maturity-model-reviewer**:
- Synthesize all findings into overall maturity assessment
- Benchmark comparison:
  - Typical OSS project
  - Production SaaS
  - Agent-optimized repository
- Identify top 3 quick wins (highest impact, lowest effort)
- Identify top 3 strategic investments (high impact, higher effort)
- Generate prioritized remediation plan with effort estimates (hours/days)

## Output: Prioritized Report

Present findings using the following structure:

```markdown
## Repository Readiness Audit Complete

**Scope**: [repository path]
**CI Platform**: [detected platform]
**Branch Protection**: [enabled/disabled/partial]
**Agent Documentation**: [present/partial/missing]
**Tiers Run**: [1, 2, 3] or [1 only]

  ============================================
  ||     READINESS SCORE: [N]/100           ||
  ||     Grade: [Letter] — [Label]          ||
  ============================================

### Category Scores

| Category | Score | Grade | Bar |
|----------|-------|-------|-----|
| CI/CD Pipeline Health (20%) | [N]/100 | [A-F] | [████████░░] |
| Testing Infrastructure (15%) | [N]/100 | [A-F] | [██████░░░░] |
| Code Review Automation (10%) | [N]/100 | [A-F] | [████░░░░░░] |
| Risk Management & Merge Policy (15%) | [N]/100 | [A-F] | [████████░░] |
| Agent & Documentation Infrastructure (20%) | [N]/100 | [A-F] | [██████████] |
| Dependency Management (8%) | [N]/100 | [A-F] | [████████░░] |
| Security Posture (10%) | [N]/100 | [A-F] | [██████░░░░] |
| Incident Memory & Harness Gap (2%) | [N]/100 | [A-F] | [████░░░░░░] |

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

### Health Summary

| Metric | Value | Status |
|--------|-------|--------|
| CI/CD pipeline | [functional/partial/missing] | [ok/warning/critical] |
| Branch protection | [enforced/partial/none] | [ok/warning/critical] |
| Required reviews | [N reviewers] | [ok/warning/critical] |
| Test infrastructure | [configured/partial/missing] | [ok/warning/critical] |
| Coverage thresholds | [enforced/set/missing] | [ok/warning/critical] |
| Agent documentation | [complete/partial/missing] | [ok/warning/critical] |
| Secret scanning | [active/configured/missing] | [ok/warning/critical] |
| Dependency management | [automated/manual/none] | [ok/warning/critical] |

### Findings

#### P1 — Critical (Security / CI Gaps / Missing Protection)
[Missing branch protection, secrets in history, no CI, missing auth on deploy — these are structural risks]

#### P2 — Important (Automation / Documentation Gaps)
[Missing CODEOWNERS, no coverage thresholds, incomplete agent docs, manual deployment steps]

#### P3 — Suggestions (Maturity Improvements)
[Action pinning, matrix testing, ADRs, mutation testing, stale branch cleanup]

### Quick Wins

| Action | Impact | Effort | Category |
|--------|--------|--------|----------|
| [highest-impact, lowest-effort action] | High | < 1 hour | [category] |
| [second action] | High | < 2 hours | [category] |
| [third action] | Medium | < 4 hours | [category] |

### Code Factory Alignment

| # | Point | Status | Notes |
|---|-------|--------|-------|
| 1 | CI runs all tests on every PR | [Met/Partial/Not Met] | |
| 2 | Coverage tool enforces minimum | [Met/Partial/Not Met] | |
| 3 | AI reviewer on every PR | [Met/Partial/Not Met] | |
| 4 | Single author can merge (with gates) | [Met/Partial/Not Met] | |
| 5 | Failed CI → agent retries | [Met/Partial/Not Met] | |
| 6 | Mutation testing or equivalent | [Met/Partial/Not Met] | |
| 7 | No manual QA gate | [Met/Partial/Not Met] | |
| 8 | Automated deployment | [Met/Partial/Not Met] | |
| 9 | Monitoring catches production issues | [Met/Partial/Not Met] | |
| 10 | Agent writes AND reviews autonomously | [Met/Partial/Not Met] | |

**Factory Score: [N]/10 points met**

### Benchmark Comparison

| Dimension | This Repo | Typical OSS | Production SaaS | Agent-Optimized |
|-----------|-----------|-------------|-----------------|-----------------|
| CI/CD | [score] | 40-60 | 70-85 | 90+ |
| Testing | [score] | 30-50 | 65-80 | 85+ |
| Review Automation | [score] | 20-40 | 60-75 | 90+ |
| Agent Readiness | [score] | 10-20 | 30-50 | 85+ |
| Security | [score] | 30-50 | 70-85 | 85+ |

### Positive Observations
[Well-configured areas, strong patterns, mature practices]

### Recommended Actions
1. [Highest-impact fix — usually P1 items]
2. [Second priority]
3. [Strategic investment recommendation]
```

## Scoring Methodology

### Per-Check Scoring
- P1 check passed: 10 points
- P2 check passed: 6 points
- P3 check passed: 3 points
- Failed check: 0 points

### Category Scoring
Category score = (earned points / maximum possible points) × 100

### Overall Score
Weighted sum across categories using the weights in the Category Scores table.

### Grade Scale

| Grade | Score Range | Label |
|-------|-------------|-------|
| A | 90-100 | Agent-Ready |
| B | 80-89 | Production-Mature |
| C | 70-79 | Needs Work |
| D | 60-69 | Significant Gaps |
| F | 0-59 | Critical |

## Actionable Next Steps

After presenting the report, offer:

```markdown
## Next Steps

1. **Fix critical findings** — Address P1 items (security gaps, missing CI, unprotected branches)
2. **Implement quick wins** — Low-effort, high-impact improvements from the Quick Wins table
3. **Create follow-up tasks** — Track P2/P3 improvements
4. **Re-audit after fixes** — Run `/workflow:audit-repo` to verify progress
5. **Save report** — Export findings to `./planning/repo-audit-report.md`
6. **Run complementary audits** — `/workflow:audit-code`, `/workflow:audit-tests` for code-level findings
```

## Integration Points

### With /workflow:audit-code

audit-repo examines repository infrastructure; audit-code examines production code quality. They are complementary — repo infrastructure enables code quality enforcement.

### With /workflow:audit-tests

audit-repo checks that testing infrastructure exists and is configured; audit-tests evaluates the actual test quality and coverage.

### With /workflow:audit-docs

audit-repo checks that documentation infrastructure exists (README, CONTRIBUTING, ADRs); audit-docs evaluates documentation quality and accuracy.

### With /workflow:audit-frontend

audit-repo checks CI/CD and build pipeline health; audit-frontend examines frontend-specific code quality. Bundle analysis depends on functional CI.

### With /workflow:audit-api

audit-repo checks API documentation infrastructure; audit-api evaluates API design quality and security.

### With /workflow:execute

During execution, if a repo audit was recently run, reference its findings for infrastructure decisions.

### With /workflow:review

Review checks code changes. audit-repo ensures the review infrastructure (required reviews, CODEOWNERS, bots) is properly configured.

### With @code-patterns, @clean-architecture, @test-strategy

audit-repo verifies that the enforcement infrastructure exists for the standards defined in these skills.

## References

- [Code Factory: How to setup your repo so your agent can auto write and review 100% of your code](https://x.com/ryancarson/status/2023452909883609111) — Ryan Carson's 10-point methodology for agent-ready repositories (primary inspiration for this command)
- [Harness engineering: leveraging Codex in an agent-first world](https://openai.com/index/harness-engineering/) — OpenAI's complementary perspective on harness engineering
- [Compound Product](https://github.com/snarktank/compound-product) — Self-improving product system demonstrating the autonomous agent loop pattern
- [react-doctor](https://github.com/millionco/react-doctor) — Health scoring concept adapted from this React diagnostic CLI
