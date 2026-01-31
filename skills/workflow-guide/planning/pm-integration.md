# Project Management Integration

The workflow commands work with any tracking system: Linear, Jira, or manual.

## Issue Creation (from /workflow:refine)

When requirements are complete, `/workflow:refine` can create a tracking issue.

### Linear Issue Creation

```bash
mcp__linear__createIssue({
  title: "[Feature Title from requirements]",
  description: "[Problem statement + proposed solution summary]",
  teamId: "[from config or prompt user]"
})
```

**Field Mapping**:
| Requirements.md Section | Linear Field |
|------------------------|--------------|
| Feature Title | `title` |
| Problem Statement | `description` (first paragraph) |
| Proposed Solution | `description` (second paragraph) |
| Must Have requirements | `description` (bullet list) |
| Success Criteria | `description` (acceptance criteria) |

### Jira Issue Creation

```bash
mcp__jira__createIssue({
  projectKey: "[from config or prompt user]",
  summary: "[Feature Title from requirements]",
  description: "[Problem statement + proposed solution]",
  issueType: "Story"  // or "Task", "Bug" based on context
})
```

**Field Mapping**:
| Requirements.md Section | Jira Field |
|------------------------|------------|
| Feature Title | `summary` |
| Problem Statement + Solution | `description` |
| User Stories | `description` (formatted as list) |
| Success Criteria | `description` (acceptance criteria section) |

### After Issue Creation

Update `requirements.md` with the new issue ID:

```markdown
## Related
- Issue: [NEW-ISSUE-ID]
- Implementation Plan: [Link when created]
```

## Auto-Detection

Commands detect your PM tool from:
1. Work item ID format in input
2. `.claude/settings.json` configuration
3. MCP tools available

### ID Format Detection

| Pattern | Tool |
|---------|------|
| `LIN-123` | Linear |
| `ABC-123` | Jira (project key varies) |
| Other | Manual |

### Configuration (Optional)

Store preference in `.claude/settings.json`:

```json
{
  "preferences": {
    "project_management": {
      "tool": "linear"
    }
  }
}
```

## Linear Workflow

**Issue Format**: `LIN-123`

**Status Values**: Backlog → In Progress → In Review → Done

### During Planning
```bash
# Fetch issue details (if MCP available)
mcp__linear__getIssue(issueId: "LIN-123")

# Update status
mcp__linear__updateIssue(issueId, {state: "In Progress"})

# Add comment
mcp__linear__createComment(issueId, "Planning complete.")
```

### During Implementation
- Reference in commits: `feat: description [LIN-123]`
- Update status at milestones
- Add progress comments

### Commit Format
```bash
git commit -m "feat(area): implement feature [LIN-123]"
```

## Jira Workflow

**Issue Format**: `PROJ-456` (project key varies)

**Status Values**: To Do → In Progress → In Review → Done

### During Planning
```bash
# Fetch issue (if MCP available)
mcp__jira__getIssue(issueKey: "PROJ-456")

# Transition status
mcp__jira__transitionIssue(issueKey, "In Progress")

# Add comment
mcp__jira__addComment(issueKey, "Planning complete.")
```

### During Implementation
- Reference in commits: `feat: description [PROJ-456]`
- Log work if tracking time
- Update through workflow states

### Commit Format
```bash
git commit -m "feat(area): implement feature [PROJ-456]"
```

## Manual Workflow

For teams using other tools or no formal tracking.

### During Planning
1. Document work item ID and description
2. Create planning docs in `./planning/`
3. Update your tracking system manually

### During Implementation
1. Reference work item in commits
2. Update status in your system
3. Document completion

### Commit Format
```bash
git commit -m "feat(area): implement feature [TASK-ID]"
```

## Integration Points

### In Planning Documents

```markdown
# Implementation Plan

**Work Item**: LIN-123
**Status**: Planning → In Progress
**Link**: https://linear.app/team/issue/LIN-123
```

### In Session State

```yaml
---
project: feature-name
work_item: LIN-123
pm_tool: linear
---
```

### In Commits

Always include work item ID:
```
feat(auth): implement user registration [LIN-123]

- Add User domain entity
- Implement RegisterUserUseCase
- Create POST /register endpoint

Closes: LIN-123
```

## Best Practices

1. **Configure Once** - Set PM tool at project start
2. **Consistent References** - Always include work item IDs
3. **Regular Updates** - Update status at milestones
4. **Link Artifacts** - Connect plans, PRs, and deployments

## Without MCP Tools

If MCP integrations aren't available:

**Linear**: Use the Linear app/web interface
**Jira**: Use the Jira interface
**Both**: Commands will provide instructions for manual updates

```markdown
## Manual Update Required

Update your tracking system:
- Status: Planning → In Progress
- Link planning docs: ./planning/[project]/
- Add implementation notes
```
