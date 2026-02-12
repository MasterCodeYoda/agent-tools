---
allowed-tools: Bash(git checkout --branch:*), Bash(git add:*), Bash(git status:*), Bash(git push:*), Bash(git commit:*), Bash(gh pr create:*)
description: Commit and push
---

## CRITICAL: Git Command Rules

**NEVER use `git -C <path>` in any git command.** The session is already active in the correct working directory. Always use plain `git` commands (e.g., `git status`, `git add`, `git commit`, `git push`). This rule is absolute and has no exceptions. Violating this rule will produce incorrect results.

## Your task

1. Evalute user input, establish context, and commit changes by following all instructions in `commit.md` (or `git-commit.md` in flat command structures)
2. Push the commit to origin
3. You have the capability to call multiple tools in a single response. You MUST do all of the above in a single
   message. Do not use any other tools or do anything else. Do not send any other text or messages besides these tool
   calls.
