---
allowed-tools: Bash(git worktree:*), Bash(git branch:*), Bash(git rev-parse:*), Bash(git log:*), Bash(git status:*), Bash(ls:*), Bash(pwd:*), Bash(cd:*)
description: Create a git worktree and enter it for immediate work
argument-hint: "[name] [from <ref>] [--type feat|fix|chore] [--branch <name>]"
---

## CRITICAL: Git Command Rules

**NEVER use `git -C <path>` in any git command.** The session is already active in the correct working directory. Always use plain `git` commands (e.g., `git status`, `git worktree add`). This rule is absolute and has no exceptions. Violating this rule will produce incorrect results.

## User Input

```text
$ARGUMENTS
```

## Argument Parsing

Parse the following from `$ARGUMENTS` (all optional):

| Argument | Syntax | Default |
|----------|--------|---------|
| **Name** | Bare word or phrase (no prefix) | Generate a random `<adjective>-<noun>` pair (e.g., `swift-falcon`, `bright-otter`) |
| **Base ref** | `from <ref>` | `main` |
| **Branch type** | `--type <type>` | `feat` |
| **Branch name override** | `--branch <full-name>` | Auto-generated as `<type>/<name>` |

If any argument is ambiguous or unclear, **stop and ask the user** before proceeding.

## Phase 1 — Validate & Create

### 1.1 Resolve repo root

```bash
git rev-parse --show-toplevel
```

Store this as `REPO_ROOT`.

### 1.2 Validations

Run these checks in order. **Stop with a clear error** if any fail:

1. **Not inside a worktree** — Compare `git rev-parse --show-toplevel` with `git rev-parse --git-common-dir`. If `--git-common-dir` is NOT `.git` (i.e., it points to another repo's `.git` directory), you are inside a worktree. Error: "You are already inside a worktree. Navigate to the main repo root first."

2. **Current branch check** — Run `git branch --show-current`. If the current branch is NOT `main` and no explicit `from <ref>` was provided by the user, inform the user they are not on `main` and confirm they want the worktree created from `main` (the default). If ambiguous, stop and ask.

3. **Base ref exists** — Verify the base ref resolves:
   ```bash
   git rev-parse --verify <base-ref>
   ```
   If it fails, error: "Base ref '<base-ref>' does not exist."

4. **No name collision** — Check that `<REPO_ROOT>/.claude/worktrees/<name>/` does not already exist. If it does, error: "A worktree named '<name>' already exists."

5. **Branch name not in use** — Check:
   ```bash
   git branch --list <type>/<name>
   ```
   If the branch already exists, error: "Branch '<type>/<name>' already exists."

### 1.3 Create the worktree

```bash
git worktree add -b <type>/<name> <REPO_ROOT>/.claude/worktrees/<name> <base-ref>
```

If `--branch` was provided, use that as the full branch name instead of `<type>/<name>`.

## Phase 2 — Enter the worktree

Switch the session's working directory into the new worktree:

```bash
cd <REPO_ROOT>/.claude/worktrees/<name>
```

This is the same pattern used by `workflow/execute.md` for entering existing worktrees. It switches the Bash working directory for subsequent commands without disrupting other sessions.

**Do NOT use `EnterWorktree()`** — that tool creates a new worktree from HEAD and cannot target a specific base ref or enter an existing worktree.

## Output

Confirm the following to the user:

- **Worktree name**: `<name>`
- **Path**: `<REPO_ROOT>/.claude/worktrees/<name>/`
- **Branch**: `<type>/<name>` (or the `--branch` override)
- **Base ref**: `<base-ref>`
- **Status**: Session CWD is now inside the worktree, ready to work.
