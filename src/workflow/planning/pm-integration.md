# Project Management Integration

The workflow commands work with any tracking system: Linear, Jira, or manual.

## Issue Creation (from /workflow:refine, file mode)

When requirements are complete in file mode, `/workflow:refine` can optionally create a tracking issue.

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

### After Issue Creation (file mode only)

Update `requirements.md` with the new issue ID:

```markdown
## Related
- Issue: [NEW-ISSUE-ID]
- Implementation Plan: [Link when created]
```

## Issue Update (from /workflow:refine, PM mode)

When refining in PM mode, write refined requirements directly back to the PM issue. The issue is the source of truth — no `requirements.md` is created.

### Linear Issue Update

```bash
mcp__linear__updateIssue({
  id: "[issue-id]",
  description: "[Full refined description — structured markdown]"
})
```

**Description Structure** (written as markdown to the issue description field):

```markdown
## Problem Statement

[Who has this problem and what happens — from Phase 1]

## Proposed Solution

[High-level approach — from Phase 2]

### Why This Approach
- [Reason 1]
- [Reason 2]

### Alternatives Considered
- [Alternative 1]: [Why not chosen]

## User Stories

### Core Stories
- As a [user], I want [capability] so that [benefit]

### Supporting Stories
- As a [user], I want [capability] so that [benefit]

## Key Requirements

### Must Have
- [Essential requirement]

### Nice to Have
- [Optional requirement]

### Out of Scope
- [Explicitly excluded]

## Acceptance Criteria

- [ ] [Specific testable criterion]
- [ ] [Specific testable criterion]

## Open Questions

- [ ] [Unresolved items needing input]
```

**Field Mapping (Update)**:

| Refinement Output | Linear Field |
|---|---|
| Full structured description | `description` |
| Feature Title | `title` (update if refined) |

### Jira Issue Update

```bash
mcp__jira__updateIssue({
  issueKey: "[PROJ-123]",
  description: "[Full refined description — structured markdown]",
  summary: "[Feature Title — update if refined]"
})
```

Use the same description structure as Linear above. Jira renders markdown in description fields.

### Creating a New Issue (PM mode)

If refining a new idea (no existing issue), create the issue first, then populate:

1. Create the issue using the Issue Creation mappings above
2. Record the new issue ID
3. Use the issue ID for all subsequent workflow commands

## Requirements Source Mode

### Overview

A binary choice per workflow that determines where requirements live:

- **File mode**: `requirements.md` is created by `/workflow:refine` and consumed by plan/execute/review. PM issue creation is an optional add-on. Best for ad-hoc work, personal projects, or teams without PM tooling.
- **PM mode**: The PM issue (Linear/Jira) is the source of truth for requirements. `/workflow:refine` writes requirements back to the issue directly — no `requirements.md` is created. `implementation-plan.md` and `session-state.md` are still created in `./planning/<project>/`. Best for teams where PM issues are the canonical location for requirements.

### Mode Detection

Determine the requirements source at the start of each workflow command, in priority order:

1. **Explicit invocation**: Issue key in input (e.g., `LIN-123`, `PROJ-456`) → PM mode. File path in input (e.g., `./planning/.../requirements.md`) → file mode.
2. **Project context**: Check AGENTS.md, CLAUDE.md, and `.claude/settings.json` for indicators that a PM system is in use. If found and invocation is ambiguous (empty input or plain text), default to PM mode.
3. **Available MCP tools**: If Linear or Jira MCP tools are available and no project context contradicts, suggest PM mode as default.
4. **Fallback**: File mode.

**Communicate the determination**: State the chosen mode and reason to the user. Allow course correction:
> "I'll use PM mode for this — your project indicates Linear is in use. Say 'use file mode' if you'd prefer to work with a local requirements.md instead."

### Session State Propagation

Record `requirements_source` in `session-state.md` so downstream commands (plan, execute, review) inherit the mode without re-detecting:

```yaml
---
project: [name]
requirements_source: [file|pm]
work_item: [ISSUE-ID]
pm_tool: [linear|jira|manual]
---
```

When a downstream command finds `requirements_source` in session state, it uses that mode directly. When no session state exists, the command runs its own mode detection.

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

### 2. Chrome DevTools MCP (preferred)

Use the Chrome DevTools MCP tools to navigate to the issue page. These connect to the user's running Chrome via autoConnect, preserving existing authentication sessions (SSO, cookies).

```
mcp__chrome-devtools__navigate_page(url: "{issue_url}")
mcp__chrome-devtools__wait_for(text: "issue title or key indicator")
mcp__chrome-devtools__take_snapshot
```

Parse the snapshot to extract:
- **Title**: Usually the first heading or prominent text element
- **Description**: Body/content area text
- **Status**: Status badge or label element
- **Acceptance criteria**: List items under criteria/requirements sections

If the snapshot shows a login page or auth wall, skip to step 4 (MCP tools).

### 3. Standalone Browser (fallback)

If Chrome DevTools MCP is unavailable, try launching a standalone agent-browser session:

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
2. Suggest enabling browser-based retrieval:
   ```
   To enable browser-based retrieval:
   1. In Chrome, navigate to chrome://inspect#remote-debugging and enable it
   2. Log into your PM tool in Chrome
   3. Add base_url to .claude/settings.json (see Configuration above)
   Chrome DevTools MCP will auto-discover your running Chrome.
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
requirements_source: pm
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
2. **Enable remote debugging** in Chrome:
   - Navigate to `chrome://inspect#remote-debugging` and enable it (one-time setup)
   - Chrome DevTools MCP autoConnect will discover your running Chrome automatically
3. **Fallback — port-based CDP** for sandboxed/Docker environments:
   ```bash
   /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
     --remote-debugging-port=9222 &
   ```
4. **Log into your PM tool** in Chrome
5. Issue retrieval will use Chrome DevTools MCP or agent-browser to read issue details from the rendered page

For **write operations** (status updates, comments) without MCP, provide manual instructions:

```markdown
## Manual Update Required

Update your tracking system:
- Status: Planning → In Progress
- Link planning docs: ./planning/[project]/
- Add implementation notes
```
