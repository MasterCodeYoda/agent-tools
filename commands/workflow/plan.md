---
name: workflow:plan
description: Requirements gathering and implementation planning for features
argument-hint: "[feature description, work item ID (LIN-123, PROJ-456), or URL]"
---

# Requirements and Implementation Planning

Transform feature descriptions into structured planning documents with clear requirements, implementation plans, and task breakdowns.

## User Input

```text
$ARGUMENTS
```

**If input is empty**, ask: "What feature would you like to plan? Describe the functionality, provide a work item ID, or share a URL."

## Input Detection

Parse input to determine source type:

| Pattern | Source Type | Action |
|---------|-------------|--------|
| `LIN-[0-9]+` | Linear issue | Fetch via Linear MCP or API |
| `[A-Z]+-[0-9]+` | Jira ticket | Fetch via Jira MCP or API |
| `http(s)://` | URL | Fetch and parse content |
| Directory path | Existing plan | Load and review |
| Text | Feature description | Use directly |

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

Run parallel exploration to understand context:

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

## Requirements Document

For detailed planning templates, reference @workflow-guide (planning templates)

### Create Requirements Document

Generate `./planning/<project>/requirements.md`:

```markdown
# [Feature Title]

## Overview
[One paragraph description of what we're building and why]

## User Story
As a [user type], I want [capability] so that [benefit].

## Acceptance Criteria
- [ ] Criterion 1 - [specific, testable requirement]
- [ ] Criterion 2 - [specific, testable requirement]
- [ ] Criterion 3 - [specific, testable requirement]

## Scope

### In Scope
- [What IS included]
- [Functionality we ARE building]

### Out of Scope
- [What is NOT included]
- [Explicitly deferred items]

## Constraints
- [Technical constraints]
- [Business constraints]
- [Timeline constraints]

## Dependencies
- [External dependencies]
- [Internal dependencies]
- [Blockers]

## Success Metrics
- [How we measure success]
- [KPIs if applicable]

## References
- Work Item: [ID and link]
- Related: [Links to related items]
- Documentation: [Relevant docs]
```

### Review with User

Present requirements summary and ask:
1. "Does this capture the requirements correctly?"
2. "Any acceptance criteria to add or modify?"
3. "Anything explicitly out of scope?"

Refine based on feedback before proceeding to implementation planning.

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
branch: [suggested branch name]
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

Created:
- `./planning/[project]/requirements.md`
- `./planning/[project]/implementation-plan.md`
- `./planning/[project]/session-state.md`

**What's next?**
1. **Start Implementation** - Run `/workflow:execute ./planning/[project]/`
2. **Review Plan** - Open plan files for review
3. **Refine** - Make changes to plan
4. **Create Branch** - `git checkout -b [suggested-branch]`
```

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
