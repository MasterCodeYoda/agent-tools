# Direct issue execution

Load from `/workflow:execute` when running simple work from an issue key without full planning docs.

For simple tasks that don't require detailed planning documents, execute directly from an issue tracker item.

### When to Use Direct Execution

- Bug fixes with clear reproduction steps
- Small enhancements with well-defined scope
- Tasks where the issue description IS the plan
- Quick iterations where planning overhead isn't justified

### Direct Execution Flow

```
1. Fetch issue details using the Issue Retrieval Strategy from @workflow (PM integration)
2. Extract:
   - Title → task subject
   - Description → requirements
   - Acceptance criteria (if present) → quality gates
3. Create minimal session state (in-memory or temporary)
4. Display issue context to user:
      ```markdown
      ## Direct Execution: [ISSUE-ID]
      **Title**: [issue title]
      **Description**: [issue description]
      **Status**: [current status]
      ```
5. Confirm with user before proceeding
6. Execute using standard Execution Loop (below)
7. On completion:
    - Commit with issue reference
    - Update issue status to Done
    - Offer to create planning docs if scope expanded

```

For detailed retrieval strategy (browser-first with MCP fallback), reference @workflow (PM integration).

### Escalation to Full Planning

If during direct execution the task proves more complex than expected:

1. Pause execution
2. Suggest running `/workflow:plan [ISSUE-ID]`
3. Create proper planning documents
4. Resume with full session tracking

