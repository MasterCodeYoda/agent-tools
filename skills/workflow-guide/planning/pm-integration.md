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
      "tool": "linear",
      "linear": {
        "workspace": "my-team",
        "base_url": "https://linear.app/my-team/issue"
      },
      "jira": {
        "domain": "mycompany",
        "base_url": "https://mycompany.atlassian.net/browse"
      }
    }
  }
}
```

**URL Patterns**:
- Linear: `{base_url}/{key}` → `https://linear.app/my-team/issue/LIN-123`
- Jira: `{base_url}/{key}` → `https://mycompany.atlassian.net/browse/PROJ-456`

## Issue Retrieval Strategy

When a command needs to **read** issue details (title, description, status, acceptance criteria), use the following priority-ordered retrieval chain. Stop at the first method that succeeds.

### 1. Construct URL

If input is an issue key (not a full URL), build the URL from config:

```bash
# Read base_url from .claude/settings.json
cat .claude/settings.json 2>/dev/null | grep -A10 project_management
```

- Linear key → `{linear.base_url}/{key}`
- Jira key → `{jira.base_url}/{key}`
- Full URL input → use as-is

If no base_url is configured and no MCP tools are available, skip to step 6 (Manual).

### 2. CDP Browser (preferred)

Try connecting to an already-running Chrome instance via CDP. This preserves existing authentication sessions (SSO, cookies).

```bash
# Check for running Chrome with CDP
agent-browser connect 9222 2>/dev/null && echo "CDP connected" || echo "CDP unavailable"
```

If connected:

```bash
agent-browser open {issue_url}
agent-browser wait --load networkidle
agent-browser snapshot -c
```

Parse the compact snapshot text to extract:
- **Title**: Usually the first heading or prominent text element
- **Description**: Body/content area text
- **Status**: Status badge or label element
- **Acceptance criteria**: List items under criteria/requirements sections

If the snapshot shows a login page or auth wall, skip to step 4 (MCP tools).

### 3. Standalone Browser

If CDP is unavailable, try launching a standalone browser session:

```bash
agent-browser open {issue_url}
agent-browser wait --load networkidle
agent-browser snapshot -c
```

If the page requires authentication (login form detected in snapshot), skip to step 4 (MCP tools). Do not attempt to automate login flows for PM tools.

### 4. MCP Tools

Use MCP integrations if available:

```bash
# Linear
mcp__linear__getIssue(issueId: "{key}")

# Jira
mcp__jira__getIssue(issueKey: "{key}")
```

### 5. WebFetch

Last resort for known URLs when browser and MCP are both unavailable:

```bash
WebFetch(url: "{issue_url}", prompt: "Extract the issue title, description, status, and acceptance criteria")
```

Note: This typically fails for authenticated PM tools.

### 6. Manual

If all automated methods fail:

1. Ask the user to paste the issue content directly
2. Suggest configuring Chrome CDP or base URLs:
   ```
   To enable browser-based retrieval:
   1. Open Chrome with: /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --remote-debugging-port=9222
   2. Log into your PM tool
   3. Add base_url to .claude/settings.json (see Configuration above)
   ```

### Retrieval Strategy Notes

- **Write operations** (status updates, comments) still use MCP tools directly — this strategy is for **reads only**
- Browser retrieval gets richer context (rendered markdown, images, linked issues) than API calls
- CDP mode reuses your existing browser session, so it works with SSO/2FA without extra setup

## Linear Workflow

**Issue Format**: `LIN-123`

**Status Values**: Backlog → In Progress → In Review → Done

### During Planning
```bash
# Fetch issue details using Issue Retrieval Strategy (above)
# Prefer CDP browser → standalone browser → MCP → WebFetch → manual

# Update status (write operations use MCP directly)
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
# Fetch issue details using Issue Retrieval Strategy (above)
# Prefer CDP browser → standalone browser → MCP → WebFetch → manual

# Transition status (write operations use MCP directly)
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

If MCP integrations aren't available, issue retrieval can still work via the browser-based methods in the Issue Retrieval Strategy (above). To set this up:

1. **Configure base URLs** in `.claude/settings.json` (see Configuration section)
2. **Open Chrome with CDP** for authenticated access:
   ```bash
   /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
     --remote-debugging-port=9222 \
     --user-data-dir="$HOME/.chrome-agent-browser" &
   ```
3. **Log into your PM tool** in that Chrome instance
4. Issue retrieval will connect via CDP and read issue details from the rendered page

For **write operations** (status updates, comments) without MCP, provide manual instructions:

```markdown
## Manual Update Required

Update your tracking system:
- Status: Planning → In Progress
- Link planning docs: ./planning/[project]/
- Add implementation notes
```
