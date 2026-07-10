---
name: git:commit-pr
user-invocable: true
allowed-tools: Bash(git checkout -b:*), Bash(git add:*), Bash(git status:*), Bash(git commit:*), Bash(git diff:*), Bash(git branch:*), Bash(git log:*), Bash(git push:*), Bash(gh pr create:*)
description: Commit, push, and open a PR
argument-hint: "[optional context about changes and PR details]"
---

## CRITICAL: Git Command Rules

**NEVER use `git -C <path>` in any git command.** The session is already active in the correct working directory. Always use plain `git` commands (e.g., `git status`, `git add`, `git commit`, `git push`). This rule is absolute and has no exceptions. Violating this rule will produce incorrect results.

## Your task

1. Create a new branch if on main
2. Evaluate user input, establish context, and commit changes by following all instructions in `commit/SKILL.md` (or the flattened `git-commit` skill in flat command structures)
3. Push the branch to origin
4. Create a pull request using `gh pr create`
5. You have the capability to call multiple tools in a single response. You MUST do all of the above in a single
   message. Do not use any other tools or do anything else. Do not send any other text or messages besides these tool
   calls.
