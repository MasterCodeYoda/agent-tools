---
name: workflow:refine
description: Discover and refine requirements through guided conversation
argument-hint: "[optional: initial feature idea or problem description]"
---

# Requirements Discovery and Refinement

Transform ideas into clear requirements through guided conversation.

## User Input

```text
$ARGUMENTS
```

## Input Interpretation

Parse input to determine discovery mode:

| Input Pattern                          | Interpretation                       |
|----------------------------------------|--------------------------------------|
| Empty                                  | Prompt for initial description       |
| `./planning/<project>/requirements.md` | Refine existing requirements         |
| `continue`                             | Resume in-progress refinement        |
| Text                                   | Start discovery with initial context |

**If input is empty**, ask: "What feature or problem would you like to explore? Describe the idea, user need, or problem
you're trying to solve."

**If path to existing requirements.md**, load and review for refinement.

**If `continue`**, check for `./planning/*/requirements.md` with `Status: Draft` and resume.

**When conducting problem discovery**, use the `AskUserQuestion` tool, if available, to guide the user through the
information gathering process. If such a tool is not available, ask the user questions one at a time, or in small groups
of questions that are interrelated, waiting for their answer after each question before proceeding. Ask followup
questions when necessary.

## Phase 1: Problem Discovery

### Understand the Problem Space

Ask clarifying questions to understand:

1. **Who has this problem?**
    - Who are the users affected?
    - What's their role or context?

2. **What's happening now?**
    - How do users currently handle this?
    - What's painful or inefficient?

3. **What triggers the need?**
    - When does this problem occur?
    - What situations make it worse?

4. **What's the impact?**
    - What happens if this isn't solved?
    - How much time/effort is wasted?

### Capture Problem Statement

Synthesize a clear problem statement:

```markdown
## Problem Statement

[User type] experiences [problem] when [context/trigger].
Currently, they [workaround], which results in [negative outcome].
```

Confirm with user: "Does this capture the core problem?"

## Phase 2: Solution Exploration

### Explore Potential Approaches

Discuss possible solutions:

1. **What would ideal look like?**
    - If constraints didn't exist, what would you build?

2. **What's the minimum viable solution?**
    - What's the smallest change that would help?

3. **What similar solutions exist?**
    - Are there patterns we can follow?
    - What have others done?

4. **What constraints exist?**
    - Technical limitations?
    - Time or resource constraints?
    - Organizational considerations?

### Capture Proposed Solution

```markdown
## Proposed Solution

[High-level approach description]

### Why This Approach

- [Reason 1]
- [Reason 2]

### Alternatives Considered

- [Alternative 1]: [Why not chosen]
- [Alternative 2]: [Why not chosen]
```

Confirm: "Does this approach feel right for solving the problem?"

## Phase 3: User Stories

### Extract Key User Needs

For each distinct user need, create a user story:

```markdown
## User Stories

### Core Stories (Must Have)

- As a [user], I want [capability] so that [benefit]
- As a [user], I want [capability] so that [benefit]

### Supporting Stories (Nice to Have)

- As a [user], I want [capability] so that [benefit]
```

Ask:

- "Are there other user types who would use this?"
- "What's the most important story - the one that defines success?"

## Phase 4: Requirements Organization

### Separate Must-Have from Nice-to-Have

```markdown
## Key Requirements

### Must Have

- [Essential requirement] - [why essential]
- [Essential requirement] - [why essential]

### Nice to Have

- [Optional enhancement] - [value it adds]
- [Optional enhancement] - [value it adds]

### Out of Scope

- [Explicitly excluded] - [why excluded]
```

Ask:

- "If we could only ship one thing, what would it be?"
- "What can we explicitly defer to a future iteration?"

## Phase 5: Success Criteria

### Define Measurable Outcomes

```markdown
## Success Criteria

### Functional

- [ ] [Specific testable criterion]
- [ ] [Specific testable criterion]

### Quality

- [ ] [Performance/reliability criterion]
- [ ] [User experience criterion]

### Business (if applicable)

- [Measurable business outcome]
```

Ask:

- "How will we know this is working?"
- "What would make this a success vs. just 'done'?"

## Phase 6: Capture Open Questions

### Document Unknowns

```markdown
## Open Questions

- [ ] [Question needing stakeholder input]
- [ ] [Technical uncertainty to resolve]
- [ ] [Decision to be made later]
```

Ask: "What questions do we still need to answer before or during implementation?"

## Write Requirements Document

### Determine Project Name

```bash
# Get project name from git or directory
basename $(git rev-parse --show-toplevel 2>/dev/null || pwd)
```

Or ask user if unclear: "What should we call this project/feature?"

### Create Planning Directory

```bash
mkdir -p ./planning/<project>/
```

### Generate requirements.md

Write `./planning/<project>/requirements.md`:

```markdown
# [Feature Title]

## Problem Statement

[Who has this problem and what happens - from Phase 1]

## Proposed Solution

[High-level approach - from Phase 2]

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

## Open Questions

- [ ] [Unresolved items needing input]

## Success Criteria

- [ ] [Measurable outcome]

## Related

- Issue: [ISSUE-ID or "Not created"]
- Implementation Plan: [Link when created]

---
Created: [timestamp]
Status: Draft
```

## PM Tool Integration

### Detect PM Configuration

```bash
# Check for PM tool configuration
cat .claude/settings.json 2>/dev/null | grep -A2 project_management

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

## Completion

Present summary to user:

```markdown
## Requirements Complete

Created: `./planning/[project]/requirements.md`
Issue: [ISSUE-ID or "Not created"]
Status: Ready for Planning

### Summary

**Problem**: [one-line problem statement]
**Solution**: [one-line approach]
**Core Stories**: [count]
**Must-Have Requirements**: [count]

### What's Next?

1. **Create implementation plan** - `/workflow:plan ./planning/[project]/requirements.md`
2. **Review requirements** - Open requirements.md for review
3. **Refine further** - `/workflow:refine ./planning/[project]/requirements.md`
4. **Share for feedback** - Send requirements to stakeholders
```

## Key Principles

### Discovery Over Documentation

- Focus on understanding the problem
- Documentation captures understanding, not drives it
- Questions are more valuable than assumptions

### Conversation Is the Tool

- Guide through questions, not templates
- Adapt based on user responses
- Skip phases that aren't relevant

### Minimum Viable Requirements

- Capture enough to start planning
- Don't over-specify details that will emerge during implementation
- Mark unknowns as open questions

### Separate Concerns

- Requirements define "what" and "why"
- Planning (next step) defines "how"
- This command focuses on requirements only
