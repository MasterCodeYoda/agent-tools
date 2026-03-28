# Evolution History

Score trend and run log for `/evolve` command iterations.

## 2026-03-28

- **Score**: 71 → 95/100 (Excellent)
- **Iterations**: 2 of 5 (stopped: all P2s addressed, then P3s resolved collaboratively)
- **Gaps**: 14 detected (P1: 0, P2: 5, P3: 9), 13 resolved (1 P3 intentionally skipped)
- **Proposals**: 15 applied (15 validated, 0 with caveats) + 2 scenario updates
- **Effectiveness**: 0 checks run (coverage/consistency/terminology fixes)
- **Branch**: evolve/2026-03-28
- **Status**: merged
- **Key changes**:
  - Eliminated remaining "Port Interfaces" terminology in layer-patterns.md and decision-tree.md
  - Added strategy-fit assessment to test audit behavior-coverage-reviewer
  - Added error message quality check to code audit production-readiness-scout
  - Added design token consistency checklist to visual-design skill (grounds frontend audit)
  - Added API spec-to-implementation cross-validation (docs + api domains)
  - Added structured concurrency patterns to TypeScript guide (Promise combinators, AbortController, anti-patterns)
  - Documented layer boundary enforcement variation by language in clean-architecture
  - Clarified E2E testing boundary between test-strategy and qa skills
  - Updated weak-test-suite scenario: +1 planted issue (WTS-08, strategy-fit violation)
  - Updated visual-design-violations scenario: +1 planted issue (VDV-09, design token drift)
  - Cross-referenced layer-specific testing in test-strategy Related Skills
  - Clarified test-strategy deference scope in clean-architecture and code-patterns
  - Explicit sub-file path in review command quality checkpoints reference
  - Specified clean-architecture deference scope in workflow-guide
- **Skipped**: C1-09 (product:audit @clean-architecture link) — intentional domain separation
- **Note**: LP3 (mutation testing setup commands) verified as already addressed in mutation-testing.md. Score plateau reached — only intentional skips remain.

## 2026-03-21 (run 2)

- **Score**: 48 → 88/100 (Good)
- **Iterations**: 3 evolve iterations + 5 recommendation implementations
- **Gaps**: 17 detected (P1: 1, P2: 8, P3: 8), all addressed
- **Proposals**: 16 applied (16 validated, 0 with caveats)
- **Effectiveness**: 0 checks run (structural/reference/content fixes)
- **Branch**: evolve/2026-03-21-b
- **Status**: pending review
- **Key changes**:
  - Fixed broken @planning skill reference in workflow:execute
  - Added argument-hint frontmatter to 3 git commands (commit, commit-pr, commit-push)
  - Resolved repository interface placement contradiction in layer-patterns.md
  - Added "When to Use This Skill" section to qa skill
  - Renamed visual-design heading to match skill convention
  - Added visual-design to code-patterns Related Skills (bidirectional)
  - Strengthened mocking boundary attribution in audit tests domain
  - Grounded 2 unanchored frontend audit agents with skill references
  - Replaced port/adapter terminology with "service abstractions" across test-strategy
  - Aligned core-concepts.md layer naming to ecosystem convention
  - Removed empty TS validators dir, documented idiomatic TS approach in SKILL.md
  - Expanded C# guide: domain events, aggregate roots, Result pattern (+343 lines)
  - Created C# examples.md: complete Task Management feature across all layers (+558 lines)

## 2026-03-21 (run 1)

- **Score**: 0 → 72/100 (Fair)
- **Iterations**: 4 of 5 (stopped: remaining gaps are P2 missing sections and P3 terminology)
- **Gaps**: 68 detected, 38 addressed
- **Proposals**: 10 applied (10 validated, 0 with caveats)
- **Effectiveness**: 0 checks run (structural cleanup iteration — no skill guidance changes affecting detection)
- **Branch**: evolve/2026-03-21
- **Status**: pending review
- **Key changes**:
  - Fixed implementation layer ordering contradiction (workflow-guide vs clean-architecture)
  - Eliminated all 18 stale `workflow:audit-*` references across 12 files
  - Fixed broken `spec` skill reference in code-patterns
  - Added `name` frontmatter to all 5 git commands
  - Added Related Skills sections to 4 skills (visual-design, qa, use-browser, workflow-guide)
  - Updated README to reflect unified audit + product command landscape
  - Replaced 6 stale audit subsections in workflow-guide with unified audit section
