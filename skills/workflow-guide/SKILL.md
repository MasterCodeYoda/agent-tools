---
name: workflow-guide
description: Comprehensive guidance for the workflow command set - planning, execution, review, and knowledge capture following vertical slicing and Clean Architecture principles.
---

# Workflow Guide

This skill provides extended guidance for the `/workflow:*` command set. Commands reference specific sections when additional context is needed.

## Philosophy

### Core Tenets

1. **Do what works, don't overcomplicate** - Simple processes that get results beat complex frameworks
2. **Work spans multiple sessions** - Structure for continuity without loss of fidelity
3. **Speed + quality + attention to detail wins** - Fast execution with high standards
4. **Knowledge compounds** - Each solved problem makes future work easier
5. **User approves before action** - Plans require explicit user approval before saving or executing

### Vertical Slicing

Build features end-to-end, not layer-by-layer.

**Traditional (Horizontal) Approach** - Avoid:
```
1. Build all domain entities
2. Build all repositories
3. Build all use cases
4. Build all API endpoints
5. Build UI
6. Integrate and test
```

**Vertical Slicing Approach** - Preferred:
```
1. Pick highest priority user story
2. Build ONLY what's needed for that story through ALL layers
3. Deploy it
4. Pick next story, repeat
```

### Why Vertical Slicing Works

- **Faster Time to Value** - Deploy features as they're ready
- **Reduced Risk** - Small slices are testable
- **Better Feedback** - Users see progress immediately
- **Easier Integration** - Continuous, not big-bang
- **Clear Progress** - Working features, not "90% complete" layers

### Bottom-Up Implementation

While we plan **top-down** (user story → layers), we implement **bottom-up**:

1. **Domain Layer First** - Pure business logic, no dependencies
2. **Application Layer** - Use cases, orchestration (depends on domain abstractions)
3. **Infrastructure Layer** - Data access, external services (implements application interfaces)
4. **Framework Layer** - API endpoints, UI

This order follows the dependency rule: each layer depends only on layers inside it. Infrastructure implements the interfaces that Application defines.

Testing integrates naturally with bottom-up implementation: write tests for each layer as you build it upward. See @test-strategy for strategy selection.

## The Ten Commands

### /workflow:refine
**Purpose**: Discover and refine requirements through conversation

**Outputs**:
- `./planning/<project>/requirements.md` - Problem, solution, user stories, requirements
- PM issue (optional) - Linear or Jira issue creation

**When to use**: When starting from a vague idea, unclear requirements, or needing stakeholder alignment before planning

### /workflow:plan
**Purpose**: Create implementation plans from requirements

**Outputs**:
- `./planning/<project>/implementation-plan.md` - How to build it
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
- Documentation (@workflow-guide)
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
**Purpose**: Capture knowledge from solved problems

**Creates**: `docs/solutions/<category>/<slug>.md`

**When to use**: After solving non-trivial problems

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
│   ├── requirements.md          # What we're building (from /workflow:refine)
│   ├── implementation-plan.md   # How we're building it (from /workflow:plan)
│   ├── session-state.md         # Multi-session tracking (from /workflow:plan)
│   └── technical-decisions.md   # Key decisions (optional)
└── archive/                     # Completed work
```

### Session State Schema

```yaml
---
project: [name]
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

### When to Use

- An epic has 2+ independent stories/slices that don't modify the same files
- You want multiple Claude sessions to execute different slices simultaneously
- The planning phase has identified parallel execution groups (see epic planning template)

### When NOT to Use

- Stories have sequential dependencies (Story 2 builds on Story 1's code)
- Stories modify the same files (merge conflicts are likely)
- The project is small enough that serial execution is fast enough
- You're working on a single story or bug fix

### Prerequisites

1. **Planning docs must be in the worktree** — either use `/workflow:plan --worktree` (which commits docs into the worktree automatically) or manually commit `./planning/` before running `/workflow:execute --worktree`
2. **Parallel groups identified** — the implementation plan should indicate which stories can run concurrently
3. **No shared file modifications** — stories in the same parallel group must touch different files

### Parallel Execution Workflow

```
1. Plan the epic:  /workflow:plan --worktree <epic>
                   (or /workflow:plan <epic>, then commit docs manually)
2. Start parallel sessions (each in its own terminal):
   Session A: /workflow:execute ./planning/<project>/   (detects existing worktree from plan)
   Session B: /workflow:execute --worktree ./planning/<project>/   (creates new worktree)
3. Each session works in its own worktree with its own branch
4. Sessions complete — each handoff documents its worktree path and branch
5. USER merges one branch at a time (after ALL sessions complete):
   cd <main-repo-root>
   git checkout main
   git merge feat/<slice-a-key>    # Run full test suite
   git merge feat/<slice-b-key>    # Run full test suite again
6. USER cleans up worktrees (only after all merges succeed):
   git worktree list               # Verify no sessions are still active
   git worktree remove .claude/worktrees/<name-a>
   git worktree remove .claude/worktrees/<name-b>
   git worktree prune
```

### Branch Naming for Parallel Work

Each worktree gets its own branch following the standard naming convention:
- `<type>/<issue-key>` (e.g., `feat/LIN-101`, `feat/LIN-102`)
- The `--worktree` flag auto-creates and renames the branch to match

### Merge Strategy

Merge branches **one at a time**, running the full test suite after each merge. This isolates merge conflicts to a single branch and makes failures easy to attribute.

### Worktree Safety Rules

These rules prevent data loss in multi-session parallel workflows:

1. **Sessions never remove worktrees** — Handoff documents the worktree path but does NOT delete it. Cleanup is always a separate, user-initiated action.
2. **Only remove worktrees you created** — Never clean up another session's worktree.
3. **Check `git worktree list` before removal** — Verify no other worktrees are still active.
4. **Never remove a worktree while CWD is inside it** — The shell will break irrecoverably.
5. **EnterWorktree exit prompt** — When Claude Code asks "keep or remove?" on session exit, **always choose "keep"** in parallel workflows. Remove only manually after merging.
6. **Session-state tracks ownership** — The `worktree:` field in `session-state.md` records which worktree belongs to each session.

## Common Pitfalls

### Over-Engineering the First Slice

**Wrong**: Building everything a feature might need
```python
class Task:
    def __init__(self, title, description, status, priority,
                 assignee, labels, attachments, comments, ...):
```

**Right**: Building only what the current story needs
```python
class Task:
    def __init__(self, title, description):
```

### Building Horizontal Infrastructure

**Wrong**: All repository methods upfront
```python
class TaskRepository:
    def create(self, task): ...
    def update(self, task): ...
    def delete(self, task_id): ...
    def find_by_status(self, status): ...
```

**Right**: Only what current story needs
```python
class TaskRepository:
    def create(self, task): ...
```

### Premature Abstraction

**Wrong**: Complex inheritance before patterns emerge
```python
class BaseEntity: ...
class AuditableEntity(BaseEntity): ...
class Task(AuditableEntity): ...
```

**Right**: Simple, direct implementation
```python
@dataclass
class Task:
    id: str
    title: str
```

### Skipping Quality Gates

**Wrong**: Moving to next task with failing tests
**Right**: Fix failures immediately, maintain green builds

### 80% Done Syndrome

**Wrong**: Moving to next feature before current is complete
**Right**: Ship complete features, then move on

## Extended Guidance

For detailed templates and patterns, reference these sections:

### Planning Phase
- `planning/templates.md` - Vertical slice, quick, epic, spike, bug fix templates
- `planning/task-breakdown.md` - Task breakdown patterns and estimation

### Implementation Phase
- `implementation/quality-checkpoints.md` - Per-layer quality gates
- `implementation/dependency-establishment.md` - Worktree dependency cache restoration
- `@test-strategy` - Testing strategy, TDD, property-based testing, contracts, and test quality
- `implementation/logging.md` - Structured logging standards, required fields, context propagation

### PM Integration
- `planning/pm-integration.md` - Linear, Jira, and manual workflow guides

### Examples
- `examples/planning-example.md` - Complete planning walkthrough

## Related Skills

- **clean-architecture**: Authoritative for layer definitions and dependency direction. Workflow commands implement clean-architecture patterns via vertical slicing; defer to clean-architecture for what belongs in each layer.
- **code-patterns**: Language-specific implementation patterns used during `/workflow:execute`
- **test-strategy**: Testing methodology integrated into execution and review workflows
- **audit**: Unified audit consumes workflow-guide for documentation domain criteria

## Key Principles Summary

| Principle | Application |
|-----------|-------------|
| Vertical slicing | Build by story, not by layer |
| Bottom-up implementation | Domain → Application → Infrastructure → Framework |
| Required vs. Out of Scope | All planned tasks required; future ideas in Out of Scope |
| User approval gates | Plans require explicit approval before saving or executing |
| Session continuity | Session state as source of truth |
| Knowledge compounding | Document solutions for future reference |
| Quality built in | Tests and checks as you go |
| Testing strategy | Select approach per situation, verify behavior |
| Ship complete work | Finish features before moving on |

## Remember

- **YAGNI** - Build only what the current story needs
- **Ship Early** - Deploy as soon as the slice works
- **Refactor Continuously** - Clean up as patterns emerge
- **Stay Vertical** - Resist building horizontal layers
- **Test Behavior** - Verify what code does, not how it does it
- **Compound Knowledge** - Each problem solved helps future work

## References

### Knowledge Compounding

The concept of "compounding" AI assistance—capturing solutions so each problem solved makes future work easier—is adapted from:

- **"How to Use AI to Do Practical Stuff: A New Guide"** by Ethan Mollick, Every.to
  https://every.to/chain-of-thought/how-to-use-ai-to-do-practical-stuff-a-new-guide

This idea drives the `/workflow:compound` command: systematically documenting solutions creates a knowledge base that accumulates value over time, making the AI assistant increasingly effective for your specific codebase and patterns.
