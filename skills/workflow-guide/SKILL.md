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

## The Four Commands

### /workflow:plan
**Purpose**: Transform features into actionable plans

**Outputs**:
- `./planning/<project>/requirements.md` - What and why
- `./planning/<project>/implementation-plan.md` - How
- `./planning/<project>/session-state.md` - Continuity tracking

**When to use**: Starting new features or projects

### /workflow:execute
**Purpose**: Session-based work with progress tracking

**Key features**:
- Session state persistence
- TodoWrite integration
- Quality checkpoints
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
│   ├── requirements.md          # What we're building
│   ├── implementation-plan.md   # How we're building it
│   ├── session-state.md         # Multi-session tracking
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
branch: [feature-branch]
---
## Current Focus
[What's being worked on]

## Last Session Summary
[Handoff context]

## Session History
[Append-only log]
```

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
| Session continuity | Session state as source of truth |
| Knowledge compounding | Document solutions for future reference |
| Quality built in | Tests and checks as you go |
| Ship complete work | Finish features before moving on |

## Remember

- **YAGNI** - Build only what the current story needs
- **Ship Early** - Deploy as soon as the slice works
- **Refactor Continuously** - Clean up as patterns emerge
- **Stay Vertical** - Resist building horizontal layers
- **Compound Knowledge** - Each problem solved helps future work
