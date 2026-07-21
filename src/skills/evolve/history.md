# Evolution History

Historical, append-only run log from the legacy `/evolve` command era (predates `/skills:evolve` and the src/ layout); paths and command names are preserved as written.

## 2026-07-21

- **Score**: 45 → 88/100 (Good)
- **Iterations**: 4 of 5 (stopped: no remaining single-file P1/P2; multi-file gaps converted to recommendations)
- **Gaps**: 1 P1 + ~12 P2 + ~8 P3 detected; 19 single-file proposals applied
- **Proposals**: 19 applied (19 validated, 0 failed); `doc_lint` 0 findings throughout
- **Effectiveness**: audit domain load paths fixed (agent procedure); observability/logging field alignment; heuristic labeling on ungrounded numeric audit gates
- **Branch**: `evolve/2026-07-21`
- **Status**: pending review
- **No runs ledger** — `.agent-tools/runs/` absent; Tier 0 seeds skipped
- **Key changes**:
  - `workflow:audit` domain paths: `domains/*.md` (was `audit-*.md` / `skills/audit/` / `@audit/`)
  - Stale related skill `workflow-guide` → `workflow`; Rust advertised on code-patterns + CA frontmatter
  - Setup template paths; handoff `@swarm` worker-contract qualification; research-loop path disambiguation
  - Personify two-layer model + limits synced into `memory-primitives.md`
  - Parallel worktree cleanup → `/git:worktree-delete`
  - Logging required fields `service` + `environment`; QA frontmatter schema audit; mock/complexity/frontend/docs heuristics
  - Discoverability: `/swarm:test` and `qa:tools` family indexes
- **Recommendations (multi-file / judgment — not applied)**:
  - Planning-root SoT: refine/plan/product still hard-code `./planning/` vs preferred `.agent-tools/planning/` (`planning-root.md`)
  - Dual residence: parent workflow skill session-state schema vs execute skill session-state template
  - Product competitive-research protocol dual residence (parent vs `product:audit`)
  - Dual “Testing by Layer” ownership (code-patterns vs clean-architecture) — pick one authority + deference
  - Thin-routing extractions for fat write-time bodies in setup/brainstorm/roadmap (allowlisted setup remains)

## 2026-05-07

- **Score**: 93 → 99/100 (Excellent)
- **Iterations**: 1 of 5 (stopped: all P1/P2 gaps resolved or justifiably skipped)
- **Gaps**: 4 validated detected (P1: 0, P2: 1, P3: 3); 3 resolved, 1 skipped with justification
- **Proposals**: 3 applied (3 validated, 0 with caveats)
- **Effectiveness**: 0 checks run (all fixes were structural — sub-file indexing, terminology crosswalk, removal of misplaced doc; no agent behavior modified)
- **Branch**: evolve/2026-05-07
- **Status**: pending review
- **Detection noise**: 5 spurious findings rejected during validation (Tier 2a flagged visual-design as P1 scope gap — false; raw SQL ungrounded — false; mutation-testing unbacked — false; audit:code wrong logging path — false; TypeScript depth asymmetry — intentional). Documented to inform future Tier 2 reasoning standards.
- **Key changes**:
  - Indexed workflow-guide internal sub-files in SKILL.md References section (covered both newly-added `references/memory-primitives.md` and existing `references/conversation-analysis.md` discoverability gap)
  - Added L1/L2/L3 crosswalk table to memory-primitives.md clarifying compound's audit-hierarchy shorthand vs the four CLAUDE.md scopes
  - Removed misplaced `clean-architecture/references/agent-native-architecture.md` (347 lines on agent-as-first-class-user product design — unrelated to clean-architecture's layer-pattern scope; only inbound link was the sub-files index)
- **Skipped with justification**:
  - F4 (P3): `audit/domains/docs.md:36` ADR directory check has no skill grounding. Skipped because ADR is industry-standard infrastructure (Michael Nygard 2011); the audit only checks directory presence, like checking for `CONTRIBUTING.md` or `LICENSE`. Defining ADR conventions in workflow-guide would be make-work without active opinions to capture.
- **Compound observations**:
  - Score plateau confirmed: 95 → 95 across runs 3 and 4. Marginal returns now require new content (skill additions), not gap detection.
  - Tracking discipline gap caught: runs 1 and 2 had stale "pending review" status despite being merged 2026-03-21 (commits d809a40, 170960e). Updated below.
  - Scenario drift: `tests/scenarios/scrap-scoring/` exists on disk but is not listed in `.claude/commands/evolve.md` "Current Scenarios" table. Recommended for next evolve to evolve.md itself.
  - Most run-4 gaps trace to the new `memory-primitives.md` addition not being fully integrated when committed (c9eb179, this morning) — confirms that adding a sub-file should also update the parent SKILL.md index.

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
- **Status**: merged (commit 170960e)
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
- **Status**: merged (commit d809a40)
- **Key changes**:
  - Fixed implementation layer ordering contradiction (workflow-guide vs clean-architecture)
  - Eliminated all 18 stale `workflow:audit-*` references across 12 files
  - Fixed broken `spec` skill reference in code-patterns
  - Added `name` frontmatter to all 5 git commands
  - Added Related Skills sections to 4 skills (visual-design, qa, use-browser, workflow-guide)
  - Updated README to reflect unified audit + product command landscape
  - Replaced 6 stale audit subsections in workflow-guide with unified audit section
