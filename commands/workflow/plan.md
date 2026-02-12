---
name: workflow:plan
description: Create implementation plans from requirements
argument-hint: "[requirements.md path, work item ID (LIN-123, PROJ-456), or feature description]"
---

# Implementation Planning

Transform requirements into actionable implementation plans with task breakdowns and technical decisions.

**Note**: For discovering and refining requirements, use `/workflow:refine` first. This command expects clear
requirements as input.

## User Input

```text
$ARGUMENTS
```

**If input is empty**, check for existing requirements:

1. Look for `./planning/*/requirements.md` files
2. If found, list them and ask which to plan
3. If not found, ask: "What would you like to plan? Provide a requirements.md path, work item ID, or describe the
   feature."

## Input Detection

Parse input to determine source type:

| Pattern                                | Source Type         | Action                                                       |
|----------------------------------------|---------------------|--------------------------------------------------------------|
| `./planning/<project>/requirements.md` | Requirements doc    | Load requirements, create implementation plan                |
| `./planning/<project>/`                | Planning directory  | Load requirements.md from directory                          |
| `LIN-[0-9]+`                           | Linear issue        | Fetch via Issue Retrieval Strategy — treat as requirements    |
| `[A-Z]+-[0-9]+`                        | Jira ticket         | Fetch via Issue Retrieval Strategy — treat as requirements    |
| `http(s)://`                           | URL                 | Fetch via Issue Retrieval Strategy if PM URL, else WebFetch — treat as requirements |
| Directory path                         | Existing plan       | Load and review                                              |
| Text                                   | Feature description | Use directly (suggest /workflow:refine for complex features) |

**For text input**: If the description is vague or complex, suggest: "This sounds like it might benefit from
requirements discovery. Would you like to run `/workflow:refine` first to clarify requirements?"

## Context Gathering

### 1. Auto-Detect Project Context

```bash
# Check for existing planning
ls ./planning/ 2>/dev/null

# Get project name from git or directory
basename $(git rev-parse --show-toplevel 2>/dev/null || pwd)

# Check for PM tool configuration
cat .claude/settings.json 2>/dev/null | grep project_management
```

### 2. Research Phase

Run parallel exploration using sub-agents to understand context:

**Codebase Analysis** (Task: Explore):

- Identify existing patterns
- Find similar implementations
- Map architectural structure
- Note conventions and standards

**Requirements Analysis**:

- Parse work item details
- Extract acceptance criteria
- Identify stakeholders
- Note constraints and dependencies

**Technical Research** (if needed):

- Framework documentation
- Best practices
- Security considerations
- Performance implications

## Load Requirements

### From requirements.md

If input is a requirements.md path or planning directory:

1. Read the requirements document
2. Extract key information:
    - Problem statement / overview
    - User stories
    - Must-have vs nice-to-have requirements
    - Success criteria
    - Related issue IDs

### From Work Item

If input is a Linear or Jira issue:

1. Fetch issue details using the Issue Retrieval Strategy from @workflow-guide (PM integration)
2. Extract requirements from title, description, and acceptance criteria
3. Note the issue ID for linking

### Review with User

Present requirements summary and ask:

1. "Do these requirements look complete for planning?"
2. "Any clarifications needed before creating the implementation plan?"
3. "Should we run `/workflow:refine` first to clarify requirements?"

Proceed to implementation planning once requirements are confirmed.

## Implementation Plan

For task breakdown patterns, reference @workflow-guide (task breakdown patterns)

### Create Implementation Plan

Generate `./planning/<project>/implementation-plan.md`:

```markdown
# Implementation Plan: [Feature Title]

## Approach

[High-level approach description]
[Key architectural decisions]
[Why this approach was chosen]

## Vertical Slice Breakdown

### Slice 1: [Core Functionality]

**Issue**: [ISSUE-ID]
**Commit Point**: After all layers complete for this slice
**PM Update**: Mark [ISSUE-ID] as Done

#### Domain Layer

- [ ] [Entity/model with specific fields]
- [ ] [Validation rules]
- [ ] [Business logic]

#### Application Layer

- [ ] [Use case implementation]
- [ ] [Request/Response DTOs]

#### Infrastructure Layer

- [ ] [Repository methods needed]
- [ ] [External service integrations]
- [ ] [Database changes]

#### Framework Layer

- [ ] [API endpoints or UI components]
- [ ] [Input validation]

#### Slice Completion

- [ ] Tests passing
- [ ] Code committed with issue reference
- [ ] PM tool updated (issue → Done)

### Slice 2: [Enhancement] (if applicable)

[Same structure - include Issue, Commit Point, PM Update, and Slice Completion]

## Task Breakdown

### P1 - Must Have (Required for completion)

- [ ] [Task 1] - [brief description]
- [ ] [Task 2] - [brief description]
- [ ] [Task 3] - [brief description]

### P2 - Should Have (Quality improvements)

- [ ] [Task 1] - [brief description]
- [ ] [Task 2] - [brief description]

### P3 - Nice to Have (Future enhancements)

- [ ] [Task 1] - [brief description]
- [ ] [Task 2] - [brief description]

## Technical Decisions

### [Decision 1]

- **Context**: [Why this decision matters]
- **Options**: [Alternatives considered]
- **Decision**: [What we chose]
- **Rationale**: [Why]

### [Decision 2]

[Same format]

## Testing Strategy

- **Approach**: [TDD recommended — see @tdd for methodology]
- **Unit Tests**: [Approach for domain/use case testing]
- **Integration Tests**: [Approach for infrastructure testing]
- **E2E Tests**: [Approach for complete flow testing]

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| [Risk 1] | Low/Med/High | Low/Med/High | [Strategy] |

## Implementation Order

1. [First task/slice] - [Why first]
2. [Second task/slice] - [Dependencies]
3. [Continue...]

## Definition of Done

### Per Slice/Story

- [ ] All layers implemented for this slice
- [ ] Tests passing for this slice
- [ ] Code committed with issue reference
- [ ] PM tool updated (issue → Done)

### Per Feature (Epic)

- [ ] All slices complete (using above checklist per slice)
- [ ] All P1 tasks complete
- [ ] Code reviewed
- [ ] Documentation updated
- [ ] Deployed to staging
```

### Initialize Session State

Create `./planning/<project>/session-state.md`:

```yaml
---
project: [project-name]
session_count: 0
status: planned
progress:
  total_tasks: [count from plan]
  completed: 0
  percent: 0%
current_layer: not_started
branch: <type>/<issue-key or description>
created: [timestamp]
---

## Status
Planning complete. Ready to begin implementation.

## Next Steps
1. Review implementation plan
2. Run `/workflow:execute ./planning/[project]/`
3. Begin with first P1 task

## Session History
[Empty - will be populated during execution]
```

## PM Tool Integration

For PM-specific workflows, reference @workflow-guide (PM integration)

### Update Work Item (if applicable)

Based on detected PM tool:

**Linear**:

```bash
# If Linear MCP available
mcp__linear__updateIssue(issueId, {status: "In Progress"})
mcp__linear__createComment(issueId, "Planning complete. Implementation plan created.")
```

**Jira**:

```bash
# If Jira MCP available
mcp__jira__transitionIssue(issueKey, "In Progress")
mcp__jira__addComment(issueKey, "Planning complete.")
```

**Manual**:

```markdown
Update your tracking system:

- Status: Planning -> In Progress
- Add link to: ./planning/[project]/
```

## Post-Planning Options

Present options to user:

```markdown
## Planning Complete

**Requirements**: `./planning/[project]/requirements.md` (input)

**Created**:

- `./planning/[project]/implementation-plan.md`
- `./planning/[project]/session-state.md`

**What's next?**

1. **Start Implementation** - Run `/workflow:execute ./planning/[project]/`
2. **Review Plan** - Open plan files for review
3. **Refine Plan** - Make changes to implementation plan
4. **Create Branch** - `git checkout -b feat/ISSUE-123` (or `fix/ISSUE-123` for bugs)
```

## Execution Handoff

**CRITICAL**: When the user approves the plan and wants to begin implementation immediately, you MUST follow the
`/workflow:execute` protocol. This ensures proper session tracking, quality gates, and commit discipline.

### Handoff Protocol

1. **Invoke `/workflow:execute`** with the planning directory:
   ```
   /workflow:execute ./planning/[project]/
   ```

2. **If continuing in the same conversation**, follow these steps from `/workflow:execute`:

   a. **Display Session Context** (execute.md §Context Review):
      ```markdown
      ## Session Context
      **Project**: [project-name]
      **Session**: #1 of work
      **Progress**: 0/[Y] tasks (0% complete)
      **Current Focus**: [first P1 task]
      ```

   b. **Initialize TodoWrite** with tasks from implementation-plan.md

   c. **Follow the Execution Loop** (execute.md §Execution Loop):
    - Mark task in_progress in TodoWrite
    - Look for existing patterns
    - Implement following conventions
    - Write tests
    - Run tests
    - Mark task completed in TodoWrite
    - Update plan checkbox
    - Check for slice completion → commit with issue reference

   d. **Quality Gates** (execute.md §Quality Gates):
    - Implementation matches plan requirements
    - Tests pass for new functionality
    - No linting/type errors introduced
    - Code follows existing patterns
    - Changes are focused and atomic

   e. **Story/Slice Completion** (execute.md §Story/Slice Completion):
    - Commit with message: `feat(scope): description (ISSUE-ID)`
    - Update PM tool (mark story Done)
    - Move to next story

### Why This Matters

- **Session state becomes source of truth** for multi-session continuity
- **TodoWrite integration** enables clear task tracking
- **Quality gates** prevent regressions
- **Commit-per-slice** discipline ensures incremental progress visibility
- **PM tool updates** show real progress to stakeholders

## Key Principles

### Separate What from How

- Requirements document the "what" and "why"
- Implementation plan documents the "how"
- Clear separation enables better stakeholder communication

### Vertical Slicing

- Plan complete features, not layers
- Each slice delivers user value
- Enables incremental delivery

### Realistic Scope

- P1 tasks are must-haves
- P2 tasks improve quality
- P3 tasks can be deferred
- Don't over-plan; elaborate as you learn

### Enable Execution

- Plans should be actionable
- Tasks should be specific and testable
- Session state enables continuity

## Quality Checklist

Before completing planning:

- [ ] Requirements are clear and testable
- [ ] Acceptance criteria are specific
- [ ] Scope boundaries are explicit
- [ ] Implementation approach is documented
- [ ] Tasks are broken down with priorities
- [ ] Risks are identified
- [ ] Session state is initialized
- [ ] Ready to execute with `/workflow:execute`
