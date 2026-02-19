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
2. **Infrastructure Layer** - Data access, external services
3. **Application Layer** - Use cases, orchestration
4. **Framework Layer** - API endpoints, UI

This order ensures each layer depends only on layers below it.

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

**When to use**: Implementing planned work

### /workflow:review
**Purpose**: Flexible code review

**Supports**:
- PR reviews (`/workflow:review #123`)
- Git ranges (`/workflow:review main..HEAD`)
- Files (`/workflow:review ./src/auth/`)
- Uncommitted (`/workflow:review changes`)

**When to use**: Before merging or deploying

### /workflow:audit-tests
**Purpose**: Audit existing test suites for quality, anti-patterns, and coverage gaps

**Key features**:
- Three-tier analysis (static, dynamic, heuristic)
- Prioritized findings (P1/P2/P3)
- Auto-detects test framework and quality tools
- References @test-strategy skill criteria

**When to use**: Onboarding to a codebase, after AI-generated test push, periodic health check

### /workflow:audit-code
**Purpose**: Audit existing production code for quality, architecture, and production readiness

**Key features**:
- Three-tier analysis (static, dynamic, heuristic)
- Prioritized findings (P1/P2/P3)
- Auto-detects language, architecture style, and quality tools
- References @code-patterns, @clean-architecture, @logging criteria

**When to use**: Onboarding to a codebase, periodic health check, pre-release quality gate

### /workflow:audit-docs
**Purpose**: Audit documentation quality — presence, accuracy, completeness, and clarity

**Key features**:
- Three-tier analysis (presence, accuracy, quality)
- Prioritized findings (P1/P2/P3)
- Auto-detects documentation types and tooling
- Cross-references docs against code for staleness

**When to use**: Onboarding to a codebase, after major refactoring, periodic health check

### /workflow:audit-api
**Purpose**: Audit API surface design — conventions, schema quality, security, and consistency

**Key features**:
- Three-tier analysis (spec linting, security, design quality)
- Prioritized findings (P1/P2/P3)
- Auto-detects API type (REST/GraphQL) and spec files
- References OWASP API Security Top 10, Zalando/Microsoft guidelines

**When to use**: Onboarding to a codebase, API review before public release, periodic health check

### /workflow:audit-frontend
**Purpose**: Audit frontend code for accessibility, performance, component architecture, and security

**Key features**:
- Three-tier analysis (static, build-dependent, heuristic)
- Prioritized findings (P1/P2/P3)
- Auto-detects framework, styling, state management, and build tools
- Measures Core Web Vitals and WCAG 2.2 compliance

**When to use**: Onboarding to a codebase, pre-release quality gate, periodic health check

### /workflow:audit-repo
**Purpose**: Audit repository readiness for autonomous AI agent coding

**Key features**:
- Three-tier analysis (static, dynamic, heuristic)
- Prioritized findings (P1/P2/P3)
- Code Factory 10-point alignment assessment
- Checks CI/CD, review automation, risk management, agent docs, security posture
- Visual report card with 0-100 readiness score and letter grade

**When to use**: Onboarding to a codebase, setting up agent workflows, periodic infrastructure health check

### /workflow:compound
**Purpose**: Capture knowledge from solved problems

**Creates**: `docs/solutions/<category>/<slug>.md`

**When to use**: After solving non-trivial problems

## Priority System

### P1 - Must Have
Essential for feature completion. Without these, it doesn't work.

- Core domain logic
- Primary use case
- Essential persistence
- Main user interface
- Critical path tests

### P2 - Should Have
Improves quality but not strictly necessary for initial deployment.

- Comprehensive validation
- Detailed error messages
- Performance optimizations
- Extended test coverage
- Logging and monitoring

### P3 - Nice to Have
Can be deferred to future iterations.

- Advanced UI features
- Analytics integration
- Detailed documentation
- Performance metrics
- Extended customization

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
---
## Current Focus
[What's being worked on]

## Last Session Summary
[Handoff context]

## Session History
[Append-only log]
```

### Branch Naming Convention

Use a consistent `<type>/<identifier>` pattern for branch names:

| Type | With Issue Key | Without Issue Key |
|------|----------------|-------------------|
| Bug fix | `fix/INK-123` | `fix/login-validation` |
| Feature | `feat/INK-124` | `feat/user-dashboard` |

**Guidelines**:
- Prefer issue keys when available—they link branches to tracking systems
- Use lowercase with hyphens for descriptions
- Keep descriptions short (2-4 words)

### Handoff Protocol

At session boundaries:
1. Update session state with progress
2. Commit work with clear message
3. Offer compound documentation
4. Generate detailed handoff summary

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
- `planning/task-breakdown.md` - P1/P2/P3 breakdown patterns and estimation

### Implementation Phase
- `implementation/quality-checkpoints.md` - Per-layer quality gates
- `@test-strategy` - Testing strategy, TDD, property-based testing, contracts, and test quality

### PM Integration
- `planning/pm-integration.md` - Linear, Jira, and manual workflow guides

### Examples
- `examples/planning-example.md` - Complete planning walkthrough

## Key Principles Summary

| Principle | Application |
|-----------|-------------|
| Vertical slicing | Build by story, not by layer |
| Bottom-up implementation | Domain → Infrastructure → Application → Framework |
| P1/P2/P3 prioritization | Must have → Should have → Nice to have |
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
