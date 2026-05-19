---
name: git
description: Family of focused, safe git skills for conventional commits, push + PR flows, and worktree-based parallel development. All skills enforce strict rules around git command usage.
user-invocable: true
---

# Git Skills

A coordinated set of skills for everyday git work that prioritize safety, conventional practices, and the ability to work on multiple independent changes without interference.

## Critical Shared Rules

**NEVER use `git -C <path>`** in any git command. The session is already active in the correct working directory. Always use plain `git` commands.

All skills in this family follow this rule strictly.

## Available Commands

| Command                  | Purpose |
|--------------------------|---------|
| `/git:commit`            | Create a clean conventional commit with live diff review |
| `/git:commit-push`       | Commit + push in a single safe flow |
| `/git:commit-pr`         | Commit, push, and open a pull request |
| `/git:worktree-create`   | Create an isolated git worktree and enter it for parallel work |
| `/git:worktree-delete`   | Safely delete a worktree with merge-safety checks |

## When to Use This Family

- You need to make a commit and want help writing a good message while reviewing changes.
- You want to push changes or open a PR with proper checks.
- You need to work on a feature/fix without disturbing your current branch (worktrees).
- You need to clean up old worktrees safely.

Each sub-skill contains the detailed procedures, argument hints, and safety checks.

See the individual skills for full instructions and examples.