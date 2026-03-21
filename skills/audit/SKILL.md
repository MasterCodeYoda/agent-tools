---
name: audit
description: Domain definitions for the unified /workflow:audit command. Each domain file defines the agents, skill references, and check criteria for one aspect of project quality. Not invoked directly — consumed by the audit orchestrator.
---

# Audit Domains

This skill provides domain-specific agent definitions for the `/workflow:audit` command. Each domain file defines:

- Which agents to spawn
- Which skills they reference as criteria
- What specific checks each agent performs
- Expected finding types and severity levels

## When to Use This Skill

This skill is consumed by `/workflow:audit` automatically. You do not need to reference it directly. The audit orchestrator reads domain files to know which agents to dispatch.

## Domains

| Domain | File | Agents | Skill References |
|--------|------|--------|-----------------|
| Code Quality | `domains/code.md` | 4 agents | @code-patterns, @clean-architecture |
| Test Quality | `domains/tests.md` | 2 agents | @test-strategy |
| API Design | `domains/api.md` | 3-5 agents | @clean-architecture, @code-patterns |
| Frontend Quality | `domains/frontend.md` | 3-5 agents | @code-patterns, @visual-design |
| Documentation | `domains/docs.md` | 2-4 agents | @workflow-guide |
| Repo Infrastructure | `domains/repo.md` | 3-6 agents | @code-patterns, @clean-architecture, @test-strategy |
| QA Coverage | `domains/qa.md` | 3 agents | @qa, @test-strategy |

## Architecture

```
/workflow:audit (orchestrator command)
    ↓ reads @audit skill
    ↓ selects domains based on project auto-detection
    ↓ spawns agents defined in each domain file
    ↓ collects findings, deduplicates, produces unified report

domains/code.md ──→ pattern-compliance-analyst, dependency-direction-checker, ...
domains/tests.md ──→ assertion-analyst, mock-boundary-checker, ...
domains/api.md ──→ api-convention-checker, api-security-analyst, ...
domains/frontend.md ──→ accessibility-scanner, component-architecture-reviewer, ...
domains/docs.md ──→ structure-validator, inline-doc-checker, ...
domains/repo.md ──→ ci-pipeline-analyst, repo-config-analyst, ...
domains/qa.md ──→ qa-spec-coverage-analyst, qa-test-generation-analyst, ...
```

## Related Skills

- **code-patterns**: Language-specific criteria for code domain
- **clean-architecture**: Architectural criteria for code and API domains
- **test-strategy**: Testing criteria for test and QA domains
- **visual-design**: Design criteria for frontend domain
- **workflow-guide**: Documentation and workflow criteria
- **qa**: QA pipeline criteria for QA domain

## Commands

- `/workflow:audit` — The unified orchestrator that consumes these domain definitions
- `/workflow:audit --focus <domain>` — Runs a specific domain's agents only
