# Project Management Integration Guide

This guide explains how to integrate vertical slicing workflow with your project management tools.

## Overview

The vertical slicing skill supports three modes of project management integration:

1. **Linear** - For teams using Linear.app
2. **Jira** - For teams using Atlassian Jira
3. **Manual** - For teams using other tools or preferring manual tracking

## Initial Configuration

### First-Time Setup

When you first use the vertical slicing skill in a project, you'll be prompted to configure your project management preference:

```
No project management tool configured for this project.
Which tool are you using?

1. Linear (for issues like LIN-123)
2. Jira (for tickets like PROJ-456)
3. Manual/Other (default)

Your choice will be saved to .claude/settings.json
```

### Configuration File

Settings are stored in `.claude/settings.json`:

```json
{
  "version": "1.0",
  "preferences": {
    "project_management": {
      "tool": "manual",  // "linear", "jira", or "manual"
      "update_on_commit": true,
      "include_time_tracking": false,
      "default_status_transitions": true
    }
  }
}
```

### Changing Configuration

To switch tools mid-project:

1. Edit `.claude/settings.json`
2. Change the `tool` value
3. Save the file
4. Next execution will use new settings

## Integration Points

### 1. Planning Phase

When starting a vertical slice:

```markdown
## Work Item Reference
Tool: [Linear/Jira/Manual]
ID: [LIN-123 / PROJ-456 / CUSTOM-789]
URL: [Link to work item]
Status: Planning → In Progress
```

### 2. Implementation Phase

During development:

- Reference work item in commits
- Update status as you progress
- Add comments with achievements
- Log time if tracking

### 3. Completion Phase

When finishing:

- Update status to Done/Resolved
- Link to deployed code
- Add completion notes
- Close related items

## Tool-Specific Features

### Linear Integration

| Feature | How to Use |
|---------|------------|
| Issue Reference | Use format `LIN-123` |
| Status Updates | Backlog → In Progress → In Review → Done |
| Linking | Add PR/commit links in comments |
| Time Tracking | Update estimate vs actual |

### Jira Integration

| Feature | How to Use |
|---------|------------|
| Ticket Reference | Use format `PROJ-456` |
| Status Transitions | Follow configured workflow |
| Work Logs | Add time entries |
| Attachments | Upload planning docs |

### Manual Mode

| Feature | How to Use |
|---------|------------|
| Reference Format | Use your tool's format |
| Status Updates | Follow your process |
| Documentation | Store in project |
| Linking | Manual cross-reference |

## MCP Tool Support (Optional)

If MCP tools are available, the skill can use them for automation:

### Linear MCP Tools
- `mcp__linear__getIssue` - Fetch issue details
- `mcp__linear__updateIssue` - Update status
- `mcp__linear__createComment` - Add progress notes
- `mcp__linear__createIssueLink` - Link to code

### Jira MCP Tools
- `mcp__jira__getIssue` - Fetch ticket details
- `mcp__jira__transitionIssue` - Change status
- `mcp__jira__addComment` - Add updates
- `mcp__jira__logWork` - Track time

### Using MCP Tools

When available, the skill will:
1. Fetch work item details automatically
2. Update status without manual steps
3. Add comments programmatically
4. Link artifacts automatically

## Commit Message Integration

### Format for All Tools

```bash
# With work item reference
git commit -m "feat(area): implement feature [WORK-ID]

- Detail 1
- Detail 2

Implements: WORK-ID"
```

### Examples

```bash
# Linear
git commit -m "feat(tasks): add create task endpoint [LIN-123]"

# Jira
git commit -m "fix(auth): resolve login timeout [PROJ-456]"

# Manual
git commit -m "refactor(db): optimize queries [TASK-789]"
```

## Status Workflow Mapping

### Linear Status Flow
```
Backlog
   ↓
In Progress (start work)
   ↓
In Review (code complete)
   ↓
Done (deployed)
```

### Jira Status Flow
```
To Do
   ↓
In Progress (start work)
   ↓
Code Review (PR created)
   ↓
Testing (tests passing)
   ↓
Done (deployed)
```

### Manual Status Flow
```
[Your Status 1]
   ↓
[Your Status 2]
   ↓
[Your Status 3]
   ↓
[Complete Status]
```

## Best Practices

### 1. Consistent References
- Always include work item IDs
- Use consistent format
- Reference in commits, PRs, and docs

### 2. Regular Updates
- Update status when starting
- Add progress comments
- Close when complete

### 3. Link Everything
- Planning documents
- Pull requests
- Deployed commits
- Related items

### 4. Time Tracking (if used)
- Log actual effort
- Update estimates
- Note blockers

## Troubleshooting

### Issue: Configuration Not Found
**Solution**: Run the skill and follow the setup prompt

### Issue: Wrong Tool Configured
**Solution**: Edit `.claude/settings.json` directly

### Issue: MCP Tools Not Working
**Solution**: Skill will fall back to manual instructions

### Issue: Status Not Updating
**Solution**: Check tool permissions and connectivity

## Multi-Project Setup

For different tools per project:

```json
// Project A: .claude/settings.json
{
  "preferences": {
    "project_management": {
      "tool": "linear"
    }
  }
}

// Project B: .claude/settings.json
{
  "preferences": {
    "project_management": {
      "tool": "jira"
    }
  }
}
```

## Migration from Commands

If you were using `/spec.plan` and `/spec.implement` commands:

1. The functionality is now in this skill
2. Configuration is compatible
3. Workflow remains similar
4. Benefits include:
   - Better tool flexibility
   - Cleaner integration
   - More comprehensive guidance

## Manual Mode Benefits

Even without tool integration, manual mode provides:

- Structured planning templates
- Consistent workflow
- Clear documentation
- Team alignment
- Progress tracking

## Future Enhancements

Potential future integrations:
- GitHub Issues
- GitLab Issues
- Azure DevOps
- Trello
- Asana
- Monday.com

Request new integrations through feedback channels.