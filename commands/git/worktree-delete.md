---
allowed-tools: Bash(git worktree:*), Bash(git branch:*), Bash(git rev-parse:*), Bash(git log:*), Bash(git merge-base:*), Bash(ls:*), Bash(pwd:*)
description: Delete a git worktree with merge safety checks
argument-hint: "<name-or-path> [--force] [--keep-branch]"
---

## CRITICAL: Git Command Rules

**NEVER use `git -C <path>` in any git command.** The session is already active in the correct working directory. Always use plain `git` commands (e.g., `git status`, `git worktree list`). This rule is absolute and has no exceptions. Violating this rule will produce incorrect results.

**NEVER change CWD.** Do not use `cd` at any point during this command. All operations must run from the current working directory.

## User Input

```text
$ARGUMENTS
```

## Argument Parsing

Parse the following from `$ARGUMENTS`:

| Argument | Syntax | Required |
|----------|--------|----------|
| **Worktree identifier** | Bare name or path | No — if absent, list worktrees and ask |
| **Force** | `--force` | No |
| **Keep branch** | `--keep-branch` | No |

### Resolving the worktree identifier

- **Bare name** (no `/` characters): Resolve to `<REPO_ROOT>/.claude/worktrees/<name>/`
- **Path** (contains `/`): Use the path directly
- **No identifier**: List worktrees with `git worktree list` and ask the user which to remove

## Phase 1 — Validate

### 1.1 Resolve repo root

```bash
git rev-parse --show-toplevel
```

Store as `REPO_ROOT`.

### 1.2 Worktree exists

Run `git worktree list` and verify the resolved path appears in the output. If not, error: "No worktree found at '<path>'."

### 1.3 CWD is not inside the target worktree

Run `pwd` and verify the current working directory is NOT inside the target worktree path. If it is, error: "You are currently inside this worktree. Navigate to the main repo root first before deleting it."

### 1.4 Merge verification (unless `--force`)

Skip this section if `--force` was provided.

1. **Parse the branch name** from `git worktree list` output. The format is:
   ```
   <path>  <sha> [<branch>]
   ```
   Extract the branch name (strip the `refs/heads/` prefix if present).

2. **Check for unmerged commits**:
   ```bash
   git log main..<branch> --oneline
   ```

3. **If unmerged commits exist**: Display the commits to the user, warn that this work has not been merged, and **stop**. Offer three options:
   - Merge the branch first (user action)
   - Force remove with `--force`
   - Cancel

Do NOT proceed with removal if unmerged work is detected.

## Phase 2 — Remove

### 2.1 Remove the worktree

```bash
git worktree remove <path>
```

### 2.2 Prune stale worktree references

```bash
git worktree prune
```

### 2.3 Branch cleanup

Unless `--keep-branch` was provided:

1. Tell the user which branch was associated with the worktree
2. Ask whether they want to delete the branch
3. If yes, use **safe delete** (not force delete):
   ```bash
   git branch -d <branch>
   ```
   This will fail if the branch has unmerged changes — an intentional safety net.

## Output

Confirm the following to the user:

- **Worktree removed**: `<path>`
- **Branch status**: Deleted or kept (with branch name)
- **Current directory**: Unchanged (still at original CWD)
