---
name: git:worktree-create
user-invocable: true
allowed-tools: Bash(git worktree:*), Bash(git branch:*), Bash(git rev-parse:*), Bash(git log:*), Bash(git status:*), Bash(ls:*), Bash(pwd:*), Bash(cd:*), Bash(cp:*), Bash(pnpm:*), Bash(npm:*), Bash(bun:*), Bash(yarn:*), Bash(uv:*), Bash(poetry:*), Bash(pipenv:*), Bash(pip:*)
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

4. **No name collision** — Check that the target worktree path does not already exist.

<!-- agent:include claude -->
Check that `<REPO_ROOT>/.claude/worktrees/<name>/` does not already exist. If it does, error: "A worktree named '<name>' already exists."
<!-- /agent:include claude -->

<!-- agent:include grok -->

Check that `<REPO_ROOT>/.grok/worktrees/<name>/` does not already exist. If it does, error: "A worktree named '<name>' already exists."

<!-- /agent:include grok -->

<!-- agent:include factory -->

Check that `<REPO_ROOT>/.factory/worktrees/<name>/` does not already exist. If it does, error: "A worktree named '<name>' already exists."

<!-- /agent:include factory -->

<!-- agent:include codex -->

Check that `<REPO_ROOT>/.codex/worktrees/<name>/` does not already exist. If it does, error: "A worktree named '<name>' already exists."

<!-- /agent:include codex -->

5. **Branch name not in use** — Check:
   ```bash
   git branch --list <type>/<name>
   ```
   If the branch already exists, error: "Branch '<type>/<name>' already exists."

### 1.3 Create the worktree

```bash
git worktree add -b <type>/<name> <TARGET_WORKTREE_PATH> <base-ref>
```

<!-- agent:include claude -->
Use `<REPO_ROOT>/.claude/worktrees/<name>` as the target path.
<!-- /agent:include claude -->

<!-- agent:include grok -->

Use `<REPO_ROOT>/.grok/worktrees/<name>` as the target path.

<!-- /agent:include grok -->

<!-- agent:include factory -->

Use `<REPO_ROOT>/.factory/worktrees/<name>` as the target path.

<!-- /agent:include factory -->

<!-- agent:include codex -->

Use `<REPO_ROOT>/.codex/worktrees/<name>` as the target path.

<!-- /agent:include codex -->

If `--branch` was provided, use that as the full branch name instead of `<type>/<name>`.

## Phase 2 — Enter the worktree

Switch the session's working directory into the new worktree:

```bash
cd <TARGET_WORKTREE_PATH>
```

<!-- agent:include claude -->
Use `<REPO_ROOT>/.claude/worktrees/<name>` as the path.
<!-- /agent:include claude -->

<!-- agent:include grok -->

Use `<REPO_ROOT>/.grok/worktrees/<name>` as the path.

<!-- /agent:include grok -->

<!-- agent:include factory -->

Use `<REPO_ROOT>/.factory/worktrees/<name>` as the path.

<!-- /agent:include factory -->

<!-- agent:include codex -->

Use `<REPO_ROOT>/.codex/worktrees/<name>` as the path.

<!-- /agent:include codex -->

This is the same pattern used by @workflow (execution) for entering existing worktrees. It switches the Bash working directory for subsequent commands without disrupting other sessions.

**Do not use any agent-specific "enter worktree" tool** that auto-creates from HEAD — always use explicit `git worktree` commands so you can control the base ref and target directory (see the agent blocks above for the correct path pattern).

## Phase 3 — Establish Dependencies

Restore project dependencies so the worktree is ready to work immediately. Follow the procedure in @workflow (dependency establishment):

1. **Detect tooling** from lock files in the worktree root (Node.js and Python ecosystems)
2. **Copy dependency caches** from `$REPO_ROOT` (Node.js only, non-pnpm — uses COW clones where available)
3. **Run sync command** for each detected ecosystem

`REPO_ROOT` was already captured in Phase 1.1. Dependency establishment must never block worktree entry — warn on failure and continue.

## Output

Confirm the following to the user:

- **Worktree name**: `<name>`
- **Path**: The agent-specific worktree directory (see the blocks above for the exact path pattern per agent)
- **Branch**: `<type>/<name>` (or the `--branch` override)
- **Base ref**: `<base-ref>`
- **Status**: Session CWD is now inside the worktree, ready to work.
