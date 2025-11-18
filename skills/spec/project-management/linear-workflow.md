# Linear Workflow Integration

This guide provides specific instructions for integrating vertical slicing with Linear.app.

## Linear Overview

Linear is a modern issue tracking tool designed for software development teams, with a focus on speed and keyboard-driven workflows.

## Issue Structure in Linear

### Issue Identifier Format
```
LIN-123
├─ LIN: Team identifier
└─ 123: Sequential issue number
```

### Issue Components
- **Title**: Brief description
- **Description**: Detailed requirements (Markdown)
- **Status**: Workflow state
- **Priority**: 0 (Urgent) to 4 (Low)
- **Estimate**: Points or time
- **Labels**: Categorization
- **Project**: Feature grouping
- **Cycle**: Sprint/iteration

## Vertical Slicing with Linear

### Step 1: Issue Analysis

When starting a vertical slice with a Linear issue:

```markdown
## Linear Issue: LIN-123
**Title**: [Issue title from Linear]
**Status**: Backlog → In Progress
**Priority**: [P0-P4]
**Estimate**: [Points/Time]

### Description
[Copy key requirements from Linear]

### Acceptance Criteria
- [ ] Criteria from Linear
- [ ] Additional criteria identified
```

### Step 2: Planning Documentation

Create planning document and reference in Linear:

```markdown
# LIN-123: Implementation Plan

## Vertical Slice
[Your vertical slice plan]

## Link in Linear
Add comment: "Implementation plan created: [link to doc]"
```

### Step 3: Status Management

#### Linear Status Workflow

| Status | When to Use | Actions |
|--------|------------|---------|
| **Backlog** | Not started | Review requirements |
| **Todo** | Ready to start | Assigned, planned |
| **In Progress** | Actively working | Update daily |
| **In Review** | Code complete | PR created |
| **Done** | Deployed | Close issue |
| **Canceled** | Won't do | Document reason |

#### Transition Commands

Using MCP tools (if available):
```javascript
// Move to In Progress
mcp__linear__updateIssue(issueId: "LIN-123", status: "in_progress")

// Add progress comment
mcp__linear__createComment(issueId: "LIN-123", body: "Completed domain layer")

// Move to In Review
mcp__linear__updateIssue(issueId: "LIN-123", status: "in_review")
```

Manual updates:
1. Open Linear (Cmd+K → issue number)
2. Press 'S' for status
3. Select new status
4. Add comment with update

### Step 4: Commit Integration

#### Commit Message Format

```bash
# Feature commit
git commit -m "feat(tasks): implement create task endpoint [LIN-123]

- Add Task domain entity
- Implement CreateTaskUseCase
- Add POST /tasks endpoint
- Include test coverage

Closes: LIN-123"

# Fix commit
git commit -m "fix(tasks): resolve validation error [LIN-123]

Fixes validation issue in task creation

Related: LIN-123"
```

#### Automatic Linking

Linear automatically links commits when:
- Issue ID in commit message
- PR title contains issue ID
- Branch name contains issue ID

### Step 5: Pull Request Integration

#### PR Title Format
```
[LIN-123] Implement task creation vertical slice
```

#### PR Description Template
```markdown
## Summary
Implements vertical slice for task creation feature.

## Linear Issue
Closes LIN-123

## Changes
- Domain: Task entity with validation
- Application: CreateTaskUseCase
- Infrastructure: TaskRepository
- API: POST /tasks endpoint

## Testing
- Unit tests: ✅
- Integration tests: ✅
- E2E tests: ✅

## Checklist
- [ ] Tests passing
- [ ] Documentation updated
- [ ] Linear issue updated
```

### Step 6: Time Tracking

#### Update Estimates

```markdown
## Time Tracking for LIN-123
Original Estimate: 4 points (8 hours)
Actual Time: 6 hours

Breakdown:
- Planning: 1 hour
- Domain Layer: 1 hour
- Infrastructure: 1.5 hours
- Application: 1 hour
- API Layer: 1 hour
- Testing: 0.5 hours
```

Add to Linear:
1. Open issue
2. Click estimate field
3. Update with actual
4. Add comment explaining variance

### Step 7: Completion

#### Closing Checklist
```markdown
## Completion of LIN-123
- [x] All acceptance criteria met
- [x] Tests passing
- [x] Code reviewed
- [x] Deployed to production
- [x] Linear updated to Done
- [x] Time tracked
- [x] Lessons learned documented
```

## Linear-Specific Features

### Cycles (Sprints)

```markdown
## Cycle Integration
**Current Cycle**: Week 45 (Nov 4-10)
**Cycle Goal**: Complete user management

Vertical Slices This Cycle:
1. LIN-123: Create user (Day 1-2)
2. LIN-124: Update user (Day 2-3)
3. LIN-125: Delete user (Day 3-4)
4. LIN-126: List users (Day 4-5)
```

### Projects

Group related vertical slices:

```markdown
## Project: User Management
**Goal**: Complete user CRUD operations

Vertical Slices:
- LIN-123: Create user ✅
- LIN-124: Update user 🔄
- LIN-125: Delete user ⏳
- LIN-126: List users ⏳
- LIN-127: Search users ⏳
```

### Labels

Use labels to categorize:

| Label | Use Case |
|-------|----------|
| `vertical-slice` | Mark VS work |
| `domain` | Domain layer work |
| `infrastructure` | Infrastructure work |
| `api` | API endpoints |
| `bug` | Bug fixes |
| `tech-debt` | Refactoring |

### Dependencies

Link related issues:

```markdown
## Dependencies for LIN-125 (Delete user)
**Blocks**: LIN-128 (Bulk delete)
**Blocked by**: LIN-123 (Create user)
**Related**: LIN-126 (List users)
```

In Linear:
1. Open issue
2. Click "Add dependency"
3. Select relationship type
4. Choose related issue

## Linear Keyboard Shortcuts

Useful shortcuts for vertical slicing workflow:

| Shortcut | Action |
|----------|--------|
| `C` | Create new issue |
| `S` | Change status |
| `P` | Set priority |
| `E` | Edit estimate |
| `L` | Add labels |
| `⌘+K` | Quick search |
| `G then I` | Go to inbox |
| `G then M` | Go to my issues |

## Linear API Integration

For advanced automation:

```javascript
// Fetch issue details
const issue = await linearClient.issue("LIN-123");

// Update with vertical slice info
await issue.update({
  description: issue.description + "\n\n## Vertical Slice Plan\n...",
  labels: ["vertical-slice"],
  state: "in_progress"
});

// Add planning document
await issue.addComment({
  body: "Planning complete: [Link to plan]"
});
```

## Linear Templates

Create issue templates for vertical slices:

```markdown
# Vertical Slice Template

## User Story
As a [user], I want [capability] so that [benefit].

## Acceptance Criteria
- [ ]
- [ ]
- [ ]

## Vertical Slice Checklist
- [ ] Domain layer defined
- [ ] Use cases identified
- [ ] Infrastructure needs clear
- [ ] API endpoints specified
- [ ] Test strategy defined

## Estimates
- Planning: [time]
- Implementation: [time]
- Testing: [time]
```

## Tips for Linear + Vertical Slicing

1. **Use Linear Views**: Create a view for current vertical slices
2. **Track Progress**: Update status after each layer
3. **Link Everything**: PRs, commits, docs all reference Linear ID
4. **Time Boxing**: Use Linear cycles to timebox slices
5. **Batch Updates**: Update multiple related issues together

## Common Linear Patterns

### Pattern 1: Epic to Slices
```
Epic: User Management
├─ LIN-123: Create user (Slice 1)
├─ LIN-124: View user (Slice 2)
├─ LIN-125: Update user (Slice 3)
└─ LIN-126: Delete user (Slice 4)
```

### Pattern 2: Story Points
```
1 point = Simple slice (2-4 hours)
2 points = Standard slice (4-8 hours)
3 points = Complex slice (1-2 days)
5 points = Too big, split it!
```

### Pattern 3: Status Automation
Set up Linear automations:
- Auto-move to "In Review" when PR created
- Auto-close when PR merged
- Auto-archive after 2 weeks done

## Reporting with Linear

Track vertical slicing metrics:

```markdown
## Cycle Metrics
- Slices Planned: 5
- Slices Completed: 4
- Average Slice Time: 6 hours
- Velocity: 12 points

## Quality Metrics
- Bugs per Slice: 0.2
- Rework Required: 5%
- Test Coverage: 85%
```

## Remember

- Linear is keyboard-first, learn the shortcuts
- Keep issues focused on single vertical slices
- Update status as you complete each layer
- Use Linear's speed to maintain momentum
- Link everything for complete traceability