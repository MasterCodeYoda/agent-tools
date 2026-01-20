---
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*)
description: Create a git commit
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider user input before proceeding, if not empty. The user may provide additional context about 
the outstanding changes, or may indicate which specific changes should be included.

If the user does not provide any input, commit all pending changes.

## Context

- Optional user input: `$ARGUMENTS`
- Current git status: !`git status`
- Current git diff (staged and unstaged changes): !`git diff HEAD`
- Current branch: !`git branch --show-current`
- Recent commits: !`git log --oneline -10`

## Your task

Based on the above changes, create a single git commit.

You have the capability to call multiple tools in a single response. Stage and create the commit using a single message.
Do not use any other tools or do anything else. Do not send any other text or messages besides these tool calls.

Always follow Conventional Commits standard when formatting the commit message, and include a high-quality description
without being overly verbose.

### Issue Key Handling

- **Extract Issue Key(s)**: Parse the user input for issue keys (pattern: `[A-Z]+-[0-9]+`, e.g., `PRJ-1470`)
- **Include in Commit**: If an issue key is found, include it in the commit message:
  - Subject line: `type(scope): description ISSUE-KEY`
  - Or body: Include reference to the issue in the body, e.g., `Closes ISSUE-KEY`
- **Multiple Keys**: If multiple issue keys are provided, include the primary one in the subject line
- **No Key Provided**: If no issue key is found in user input, proceed without one
