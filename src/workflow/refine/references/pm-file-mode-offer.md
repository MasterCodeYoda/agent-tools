# PM issue creation offer (file mode only)

Load after saving `requirements.md` when optionally offering tracking-issue creation.
For MCP field mappings and issue update shapes, prefer @workflow (`planning/pm-integration.md`).

## PM Tool Integration (file mode only)

**Skip this section entirely in PM mode** — the issue was already created/updated above.

In file mode, optionally offer issue creation after saving `requirements.md`:

### Detect PM Configuration

```bash
# Check for PM tool configuration
cat .claude/settings.json 2>/dev/null | grep -A10 project_management

# Check for available MCP tools
# Linear: mcp__linear__createIssue
# Jira: mcp__jira__createIssue
```

### Offer Issue Creation

If PM tool is configured or available:

```markdown
## Create Tracking Issue?

Requirements are ready. Would you like to create a tracking issue?

1. **Yes - Create issue** in [Linear/Jira]
2. **No - Just save requirements** (create issue later)
3. **Link existing issue** - provide issue ID
```

### Linear Issue Creation

If Linear MCP available:

```bash
mcp__linear__createIssue({
  title: "[Feature Title]",
  description: "[Problem statement + proposed solution summary]",
  teamId: "[from config or ask]"
})
```

Update requirements.md with issue ID:

```markdown
## Related

- Issue: LIN-[new-id]
```

### Jira Issue Creation

If Jira MCP available:

```bash
mcp__jira__createIssue({
  projectKey: "[from config or ask]",
  summary: "[Feature Title]",
  description: "[Problem statement + proposed solution summary]",
  issueType: "Story"
})
```

Update requirements.md with issue key:

```markdown
## Related

- Issue: [PROJ-new-id]
```

### Manual Tracking

If no PM integration:

```markdown
## Manual Tracking

Requirements saved to: `./planning/[project]/requirements.md`

To track this work:

1. Create an issue in your tracking system
2. Update the "Related" section with the issue ID
3. Run `/workflow:plan` when ready to create implementation plan
```

