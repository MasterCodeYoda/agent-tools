---
name: workflow
description: Parent skill for the workflow family — brainstorming, refinement, planning, execution, review, audit, compound, and knowledge capture. Supports vertical-slice and deliverable-partition decomposition modes.
user-invocable: true
---

# Workflow

This is the parent skill for the `workflow` family. It contains high-level philosophy, decomposition guidance, and navigation to the functional areas below (brainstorm, planning, execution, audit, review, compound, and refine). The functional areas contain the detailed processes and artifacts.

## Commands in This Family

| Command | Purpose |
|---------|---------|
| `/workflow:setup` | Initialize/maintain the `planning/` docs and collaboratively define project-local conventions (tracks, gates, integration policy) |
| `/workflow:prune` | Sweep `planning/` for fully-completed work, verify against git + PM, and purge confirmed-complete dirs/meta files on approval |
| `/workflow:brainstorm` | Explore a fuzzy idea into a framed concept ready for refinement |
| `/workflow:refine` | Discover and refine requirements through guided conversation |
| `/workflow:plan` | Create detailed implementation plans from requirements |
| `/workflow:execute` | Run planned work with progress tracking, todos, and quality gates |
| `/workflow:review` | Flexible code review (PRs, ranges, files, or uncommitted changes) |
| `/workflow:audit` | Comprehensive multi-domain project audit |
| `/workflow:compound` | Capture durable knowledge from any work (solutions, patterns, decisions) and maintain knowledge compounding |
| `/workflow:continue` | Resume the next slice — orient from `planning/`, drive one slice through the full loop, stopping only at user-input gates |

See the individual sub-skills for full details, argument hints, and procedures.

## Philosophy

### Core Tenets

1. **Do what works, don't overcomplicate** - Simple processes that get results beat complex frameworks
2. **Work spans multiple sessions** - Structure for continuity without loss of fidelity
3. **Speed + quality + attention to detail wins** - Fast execution with high standards
4. **Knowledge compounds** - Each unit of work — a solved bug, a refactor, a feature pattern, a design decision — makes future work easier when its insight is captured
5. **User approves before action** - Plans require explicit user approval before saving or executing
6. **Artifacts state the current target, not their own history** - Decision records, domain docs, and acceptance criteria describe what is true/intended *now*. When a decision changes, re-derive the dependent artifacts from the new target — don't edit in place to preserve old structure (find-replace) or old history (supersession notes, tombstones, status fields). Git holds the past. Keep the rationale and rejected alternatives (they stop re-litigation); drop the change-narrative. See @workflow (`references/decision-records.md`)

### Decomposition Modes

How an epic decomposes into stories or sub-issues depends on the work's shape. Two modes:

**Vertical Slice** — build each story end-to-end through all layers and ship it before starting the next; every slice delivers an observable increment. Default for post-first-release feature work in deployed systems.

**Deliverable-Partition** — decompose the epic into the artifacts it must produce (validator, CI, hooks, contracts, ...), partitioning the parent acceptance criteria across sub-issues with verbatim AC ownership and an AC traceability matrix in the parent. For foundation / pre-first-release work and cross-cutting / large-effort work (contract-first shared-library changes, compliance roll-outs, framework migrations).

#### Mode Selection

Pick **vertical slice** when:

- The system has users (or simulated equivalents) observing value at each slice.
- Each story can ship independently and deliver an observable increment.
- The epic spans Domain → Framework cleanly and stories don't share files extensively.

Pick **deliverable-partition** when:

- No deployed surface yet (greenfield / pre-first-release).
- The epic produces multiple distinct artifacts (validator rules, CI steps, hooks, contracts) rather than user-facing increments.
- Vertical slicing would force "minimal X, full X later" boundaries that risk silently weakening parent ACs.
- The epic touches a shared library/contract that downstream consumers must adopt incrementally.
- Compliance, refactor, or framework-migration work spans the system without a natural user-story shape.

When in doubt, default to vertical slice for feature work and deliverable-partition for foundation, infrastructure, or cross-cutting work.

Full doctrine — when-and-how per mode, why each works where it does, verbatim AC inheritance and backlog resize, bottom-up implementation order within a slice, and anti-patterns with worked examples — lives in @workflow (`references/decomposition-modes.md`).

## Requirements Source Mode

A binary choice per workflow that determines where requirements live. See @workflow (`planning/pm-integration.md`) for detection logic and PM-specific field mappings.

### File Mode

`requirements.md` is created by `/workflow:refine` and consumed by plan/execute/review. PM issue creation is an optional add-on. Best for ad-hoc work, personal projects, or teams without PM tooling.

### PM Mode

The PM issue (Linear/Jira) is the source of truth for requirements. `/workflow:refine` writes requirements back to the issue directly — no `requirements.md` is created. `implementation-plan.md` and `session-state.md` are still created in `./planning/<project>/`. Best for teams where PM issues are the canonical location for requirements.

### Mode Detection

Mode is determined at the start of each workflow command:

1. **Explicit invocation**: Issue key → PM mode. File path → file mode.
2. **Project context**: AGENTS.md, CLAUDE.md, or `.claude/settings.json` indicating PM system → default PM mode for ambiguous input.
3. **Available MCP tools**: Linear/Jira MCP tools present → suggest PM mode.
4. **Fallback**: File mode.

The agent states its determination and lets the user course-correct.

## Project-Local Conventions

Some projects layer **local process on top of the generic workflow** — an extra work track, gates
beyond code review, or a specific integration policy. The generic `/workflow:*` skills can't infer
these, so they live as **data** in `planning/conventions.md`, authored and maintained by
`/workflow:setup`. Every phase honors them; nothing is hard-coded into a project-local command.

A project's `conventions.md` may declare:

- **Additional work tracks.** Beyond the default feature track
  (`brainstorm → refine → plan → execute → review → finish → compound`), a project may define a
  track that **overrides** the phase table for the units it governs — e.g. a research/discovery
  loop, a data-labeling cycle, or a release checklist — each following its own process doc and its
  own review-equivalent. `/workflow:continue` classifies each slice into its track before routing.
- **Project-specific gates.** Checks **additive to** the standard review gate (cross-cutting
  safety, regression/holdout adoption, schema/contract lockstep). Applied before a slice is done.
- **Integration / merge policy.** Local vs remote, merge style, banking/versioning, push policy
  (default: local-only; pushing and PRs are user-initiated).

When present, the top-level handoff (`planning/session-state.md`) can carry a durable **Project orientation**
pointer block. Per-item handoffs under `planning/<item>/` are the common case. Run `/workflow:setup`
to set up hygiene and record any real custom conventions (it will not create empty/default-only files).

## Functional Areas & Commands

### /workflow:setup
**Purpose**: Initialize/maintain project workflow scaffolding and capture project-local conventions

**Behavior**: Idempotent and non-destructive. Surveys existing `planning/` state, then collaborates with the user to record — in `planning/conventions.md` — the requirements-source mode, any **additional work tracks** (e.g. a discovery loop that overrides the default phase table), **project-specific gates** (additive to the review gate), and the **integration/merge policy**. Also ensures the top-level handoff carries a durable *Project orientation* pointer block. **Always** scaffolds `.agent-tools/memory/` and the AGENTS.md memory-link block when missing. Run anytime to refresh.

**Outputs**:
- `./planning/conventions.md` — only when the project has non-default tracks, gates, or policy (absent = use built-in defaults)
- Top-level `./planning/session-state.md` — only when a live cross-project handoff/pointer exists (optional; normal per-item state lives in `planning/<item>/session-state.md` and is created by plan/execute)
- `.agent-tools/memory/` — shared project memory scaffold (`MEMORY.md`, `state.yml`, `entries/`, `solutions/`)
- `AGENTS.md` memory-link block (`agent-tools:memory-link`)

**Boundary**: `planning/`-scoped for transient work and conventions; owns shared-memory scaffold under `.agent-tools/memory/`. Complementary to `/swarm:setup` (which owns the swarm charter and umbrella bootstrap).

**When to use**: Onboarding a project to `/workflow`, or whenever the project's tracks/gates/policy change

### /workflow:prune
**Purpose**: Reclaim `planning/` by purging fully-completed work — the corollary to `/workflow:setup`

**Behavior**: Conservative and confirmation-gated. Loads `conventions.md` to learn the project's status vocabulary, PM mode, and which files are **live orchestration**. Enumerates work-item dirs + loose `planning*` meta files, then verifies completion against **multiple signals** — terminal status, the referenced merge commit present on main, the PM issue Closed/Done (PM mode), not named as active/next in the handoff, and durable knowledge already migrated. Only **CONFIRMED-COMPLETE** items are proposed; anything done-but-unmigrated is flagged for `/workflow:compound` first. Presents a per-item evidence summary, requires explicit approval, then `git rm`s the approved items (recoverable via history).

**Outputs**: A removal summary; the approved deletions staged (committed only if the user asks).

**Protects**: Permanent structural files (`conventions.md`, `.gitkeep`, `.gitignore`), track process docs, and referenced archives — never proposed for deletion. The handoff (`session-state.md` / `SESSION-HANDOFF.md`), `session-state.md` files, and queue (`work-streams.md`) are protected only while active or incomplete; they are pruned once the associated work is classified CONFIRMED-COMPLETE (cross-project orchestration artifacts that eventually complete and remove, just like session-state).

**When to use**: Periodically as completed work accumulates, or at a milestone close (after durable knowledge is migrated to ADRs / Codex / runbooks / memory)

### /workflow:refine
**Purpose**: Discover and refine requirements through conversation

**Outputs** (depends on requirements source mode):
- **File mode**: `./planning/<project>/requirements.md` — problem, solution, user stories, requirements. PM issue creation offered as optional add-on.
- **PM mode**: PM issue updated with refined requirements directly. No `requirements.md` created. `./planning/<project>/` directory created for later use by plan.

**When to use**: When starting from a vague idea, unclear requirements, or needing stakeholder alignment before planning

### /workflow:plan
**Purpose**: Create implementation plans from requirements

**Outputs**:
- `./planning/<project>/implementation-plan.md` - How to build it. Opens with YAML
  frontmatter carrying `blocks` / `blocked_by` / `parallelizable_with` dependency metadata
  (sourced from `/workflow:refine` and confirmed during planning), which downstream
  orchestration (`/swarm`) uses to schedule parallel waves.
- `./planning/<project>/session-state.md` - Continuity tracking

**Flags**:
- `--worktree` — On approval, create an isolated git worktree, save planning docs inside it, and commit them. This prepares the worktree for `/workflow:execute` to detect automatically (no `--worktree` flag needed on execute).

**Approval gate**: Plans MUST be presented to the user for explicit approval before saving documents or starting
execution. After approval, the user chooses: save the plan only, or save and proceed to execution.

**When to use**: After requirements are clear (from `/workflow:refine` or existing documentation)

### /workflow:execute
**Purpose**: Session-based work with progress tracking

**Key features**:
- Session state persistence
- TodoWrite integration
- Quality checkpoints
- Completion verification before stopping
- Compound prompts at boundaries
- `--worktree` flag for parallel epic execution in isolated git worktrees (also available on `/workflow:plan`)

**When to use**: Implementing planned work

### /workflow:review
**Purpose**: Flexible code review

**Supports**:
- PR reviews (`/workflow:review #123`)
- Git ranges (`/workflow:review main..HEAD`)
- Files (`/workflow:review ./src/auth/`)
- Uncommitted (`/workflow:review changes`)

**When to use**: Before merging or deploying

### /workflow:audit
**Purpose**: Unified project audit — auto-detects project shape, dispatches domain-specific agent teams, deduplicates findings across domains

**Domains** (activated based on project auto-detection):
- Code quality (@code-patterns, @clean-architecture)
- Test quality (@test-strategy)
- API design (@clean-architecture)
- Frontend quality (@code-patterns, @visual-design)
- Documentation (@workflow)
- Repo infrastructure
- QA coverage (@qa)

**Key features**:
- Single entry point for comprehensive assessment
- Cross-domain deduplication (same root cause → one finding)
- Project-type-aware weighting (backend vs frontend vs full-stack)
- Depth control (`--depth quick|standard|deep`)
- Focus mode (`--focus code,tests`) for domain-specific depth
- Unified health score with per-domain breakdown

**When to use**: Onboarding to a codebase, periodic health check, pre-release quality gate

### /workflow:compound
**Purpose**: Capture durable knowledge from any engineering work — debugging solutions, refactors, features, design decisions, reusable patterns — and route each to its right home; maintain shared + harness-local memory quality

**Creates** (via deterministic gate):
- Debugging solution → `.agent-tools/memory/solutions/<category>/<slug>.md`
- Project-wide pattern/gotcha/lesson/process → `.agent-tools/memory/entries/<slug>.md` (+ `MEMORY.md` line)
- Architecture decision → `docs/decisions/` (optional lesson → entries)
- Or AGENTS.md / personify / harness-local when applicability is not project-shared

**Maintain** (`--maintain`): audit L1–L3, propose promote/retire (user approval); optional `--migrate-solutions` for legacy `docs/solutions/`

**When to use**: After any non-trivial work whose insight would save the next person (or the next you) real time — not only after fixing bugs; periodically for `--maintain`

### /workflow:continue
**Purpose**: Sequential orchestrator — resume the next slice of work and drive it through the full workflow loop

**Behavior**: Orients by scanning `planning/*/session-state.md`, picks **one** PM-defined value slice (or an explicitly named target), classifies its stage from disk, and routes it through refine → plan → execute → review → finish → compound — auto-advancing through phases that need no input and stopping only at genuine user-input gates (plan approval, review-findings triage, merge confirmation). **Review is a hard gate** (hygiene gates ≠ review; size does not skip). Ends every loop with a **required recap**; when code was produced, the recap must include **Review findings & disposition** from `/workflow:review` (method, counts, disposition, verdict). Autonomous merge refuses without valid evidence schema + that recap block. Tracks a light handoff on completion (compress/archive history, refresh the next-phase pointer).

**Flags**:
- `--worktree` — run the slice in an isolated worktree (new or existing match) so other, non-workflow sessions can run in parallel in the same repo. Defaults to the main workspace.

**Coexistence**: The sequential counterpart to `/swarm`. Keeps a separate state store (`planning/` only, never `.agent-tools/swarm/`); when a swarm run is active it warns and picks only items swarm isn't driving.

**When to use**: Resuming multi-session work — "pick up where I left off" — one slice at a time. For parallel backlog-scale execution, use `/swarm`.

## Task Planning

All tasks in an implementation plan are required. If a task is derived from acceptance criteria or is necessary for the feature to work, it belongs in the flat task list and must be completed before the work is considered done.

There are no priority tiers. Acceptance criteria are binary — met or not met.

### Out of Scope
Items genuinely not required by acceptance criteria but worth noting for future iterations belong in an "Out of Scope" section. This section is for ideas and enhancements, not for deferring planned work.

## Session Continuity

### Planning Directory Structure

```
./planning/
├── <project-name>/
│   ├── requirements.md          # File mode only (from /workflow:refine)
│   ├── implementation-plan.md   # Both modes (from /workflow:plan)
│   ├── session-state.md         # Both modes (from /workflow:plan)
│   └── technical-decisions.md   # Key decisions (optional)
└── archive/                     # Completed work
```

### Session State Schema

```yaml
---
project: [name]
requirements_source: [file|pm]
work_item: [ISSUE-ID]          # Set when PM issue is linked
pm_tool: [linear|jira|manual]  # Set when PM tool is detected
session_count: [N]
status: [planned|in_progress|complete]
progress:
  total_tasks: [X]
  completed: [Y]
  percent: [Z%]
current_layer: [domain|infrastructure|application|framework]
branch: <type>/<issue-key or description>
worktree: <path>  # Only set when using --worktree; absolute path to worktree directory
---
## Current Focus
[What's being worked on]

## Last Session Summary
[Handoff context]

## Session History
[Append-only log]
```

### Branch Naming Convention

**Rule**: All working branches MUST follow the `<type>/<identifier>` pattern exactly.

| Type | With Issue Key | Without Issue Key |
|------|----------------|-------------------|
| Bug fix | `fix/INK-123` | `fix/login-validation` |
| Feature | `feat/INK-124` | `feat/user-dashboard` |

**Rules**:
- When an issue key exists, use it as the ENTIRE identifier — do NOT append a description (e.g. `feat/INK-124`, never `feat/INK-124-user-dashboard` or `matt/INK-124-desc`)
- Without an issue key, use a short lowercase-hyphenated description (2-4 words max)
- No usernames, dates, or other prefixes in branch names

**Anti-patterns** (never do these):
- `matt/ink-123-some-description` — no username prefixes, no appended descriptions with issue keys
- `feature/INK-123-implement-user-dashboard` — too long, wrong type prefix
- `INK-123` — missing type prefix

### Handoff Protocol

At session boundaries:
1. Update session state with progress
2. Commit work with clear message
3. Offer compound documentation
4. Generate detailed handoff summary

## Parallel Execution with Worktrees

Use worktrees when an epic has 2+ independent slices that don't modify the same files and you want multiple sessions executing simultaneously. Don't use them for sequentially-dependent or shared-file slices, small projects, or a single story/bug fix.

The full workflow — prerequisites, per-session commands, branch naming, the one-branch-at-a-time merge strategy, and the Worktree Safety Rules — lives in @workflow (`references/parallel-worktrees.md`). See @git (worktree-create) and @git (worktree-delete) for agent-specific behavior, directory conventions, and commands.

## Common Pitfalls

- **Over-engineering the first slice** — building everything a feature might need instead of only what the current story needs.
- **Building horizontal infrastructure inside a vertical slice** — drifting into building all repository methods, service abstractions, or use-case shapes upfront. (Does not apply in deliverable-partition mode, where comprehensively building one deliverable to its owned AC subset is exactly the work.)
- **Premature abstraction** — complex inheritance before patterns emerge; keep implementations simple and direct.
- **Skipping quality gates** — fix failures immediately; maintain green builds.
- **80% done syndrome** — ship complete features before moving to the next.

Wrong/right examples for each pitfall: see @workflow (`references/decomposition-modes.md`).

## Extended Guidance

For detailed templates and patterns used by the functional areas, reference these sections:

### Decomposition & Parallelism
- `references/decomposition-modes.md` - Full decomposition doctrine: when/how per mode, AC inheritance and resize, anti-patterns
- `references/parallel-worktrees.md` - Parallel worktree workflow, merge strategy, worktree safety rules

### Planning Phase
- `planning/templates.md` - Vertical slice, quick, epic, spike, bug fix templates; implementation-plan document, session-state, and plan-time prompt templates
- `planning/task-breakdown.md` - Task breakdown patterns and estimation

### Implementation Phase
- `execution/quality-checkpoints.md` - Per-layer quality gates
- `execution/dependency-establishment.md` - Worktree dependency cache restoration
- `@test-strategy` - Testing strategy, TDD, property-based testing, contracts, and test quality
- `execution/logging.md` - Structured logging standards, required fields, context propagation

### PM Integration
- `planning/pm-integration.md` - Linear, Jira, and manual workflow guides

### Examples
- `references/planning-example.md` - Complete planning walkthrough

## Related Skills

- **clean-architecture**: Authoritative for layer definitions and dependency direction. The workflow functional areas follow clean-architecture patterns via vertical slicing.
- **code-patterns**: Language-specific implementation patterns used during execution.
- **test-strategy**: Testing methodology integrated into execution and review.
- **audit**: The audit functional area consumes documentation domain criteria from this skill.

## Key Principles Summary

| Principle | Application |
|-----------|-------------|
| Decomposition matches work shape | Vertical slice for feature work; deliverable-partition for foundation and cross-cutting work |
| Within vertical slices, build bottom-up | Domain → Application → Infrastructure → Framework per slice |
| Within deliverable-partition, partition then ship | Each sub-issue owns a verbatim slice of parent ACs; ship deliverables in dependency order |
| Required vs. Out of Scope | All planned tasks required; future ideas in Out of Scope |
| User approval gates | Plans require explicit approval before saving or executing |
| Session continuity | Session state as source of truth |
| Knowledge compounding | Document solutions for future reference |
| Quality built in | Tests and checks as you go |
| Testing strategy | Select approach per situation, verify behavior |
| Ship complete work | Finish slices/deliverables before moving on |

## Remember

- **YAGNI** — In vertical-slice mode, build only what the current story needs. In deliverable-partition mode, build the deliverable's owned AC subset comprehensively — no more, no less.
- **Ship Early** — Deploy slices as soon as they work; close sub-issues as soon as their deliverables ship.
- **Refactor Continuously** — Clean up as patterns emerge.
- **Stay in mode** — Don't drift into horizontal layer-building inside a vertical slice; don't pretend a foundation epic has user-facing slices.
- **Test Behavior** — Verify what code does, not how it does it.
- **Compound Knowledge** — Each problem solved helps future work.

## References

### Sub-files

This parent skill organizes supporting reference material used by the functional areas:

**Planning** — used by `/workflow:plan`, `/workflow:refine`:
- `planning/pm-integration.md` — PM-system integration patterns
- `planning/task-breakdown.md` — Decomposition guidance
- `planning/templates.md` — Plan and plan-time artifact templates

**Implementation** — used by `/workflow:execute`, `/workflow:review`, audit domains:
- `execution/dependency-establishment.md` — Dependency setup patterns
- `execution/logging.md` — Structured logging standards (consumed by `audit:code` observability-readiness-analyst)
- `execution/quality-checkpoints.md` — Quality gate patterns

**References** — used across multiple commands:
- `references/conversation-analysis.md` — Extracting signals from `~/.claude/` conversation history (used by `/skills:evolve`, `/workflow:compound`, `/workflow:audit`)
- `references/decomposition-modes.md` — Decomposition-mode doctrine: when/how per mode, AC inheritance and resize, anti-patterns (used by `/workflow:refine`, `/workflow:plan`, `/workflow:execute`)
- `references/memory-primitives.md` — memory levels (L1/L2/L3-shared/L3-local), harness primitives, `.agent-tools/memory/` (used by `/workflow:compound` and `--maintain`)
- `references/parallel-worktrees.md` — Parallel worktree execution workflow, merge strategy, safety rules (used by `/workflow:plan`, `/workflow:execute`)

**Examples**:
- `references/planning-example.md` — Worked planning example

### Knowledge Compounding

The concept of "compounding" AI assistance—capturing solutions so each problem solved makes future work easier—is adapted from:

- **"How to Use AI to Do Practical Stuff: A New Guide"** by Ethan Mollick, Every.to
  https://every.to/chain-of-thought/how-to-use-ai-to-do-practical-stuff-a-new-guide

This idea drives the compound functional area: systematically documenting solutions creates a knowledge base that accumulates value over time.
