# Worktree enter / create for execute

Load when `--worktree` is set or `session-state.md` records a `worktree:` path.
Also see @git (worktree-create / worktree-delete) and @workflow (`execution/dependency-establishment.md`, `references/parallel-worktrees.md`).

### 1.25. Detect Existing Worktree (from session-state)

Before creating a new worktree, check if one already exists from a prior `/workflow:plan --worktree` run:

1. **Read `session-state.md`** for a `worktree:` field
2. If `worktree:` has a path, verify the worktree still exists:
   ```bash
   git worktree list  # Look for the recorded path
   ```
3. **If worktree exists and `WORKTREE_MODE=false`**: Inform the user that an existing worktree was detected. Capture `REPO_ROOT` before leaving the source repo (`REPO_ROOT=$(git rev-parse --show-toplevel)`), then change working directory to the worktree path (`cd <worktree-path>`). **Establish dependencies if missing** — if `node_modules/` or the expected venv directory does not already exist, follow @workflow (dependency establishment) to restore them. Skip step 1.5 — no new worktree needed.
4. **If worktree exists and `WORKTREE_MODE=true`**: This is caught by flag validation (the "worktree already recorded" error in §Flag Extraction).
5. **If worktree recorded but missing** (e.g., user manually deleted it): Warn the user that the recorded worktree was not found. Fall through to step 1.5 if `WORKTREE_MODE=true`, or continue without a worktree if `WORKTREE_MODE=false`.

### 1.5. Enter Worktree (if `WORKTREE_MODE=true` and no existing worktree detected in step 1.25)

If the `--worktree` flag was set during Flag Extraction and no existing worktree was found, create an isolated worktree before loading session state.

**Derive worktree name** from the input:
- Planning directory `./planning/my-project/` → worktree name `my-project`
- Issue key `LIN-123` → worktree name `lin-123`
- Plan file `./planning/auth-feature.md` → worktree name `auth-feature`

**Capture `REPO_ROOT`** before entering the worktree (once inside, `git rev-parse --show-toplevel` returns the worktree root):

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
```

**Create worktree**:

```
Use the agent's worktree creation mechanism (see @git (worktree-create))
```

This creates a worktree using the agent's worktree naming convention (see @git (worktree-create) for agent-specific path details) and switches CWD to it.

**Worktree exit prompt**: Respect your agent's worktree exit prompt behavior (see @git (worktree-create) and @git (worktree-delete)). In parallel workflows, prefer keeping the worktree until after merging. Worktree removal is a user-initiated action after all sessions complete and branches are merged. See Worktree Safety Rules in @workflow (`references/parallel-worktrees.md`).

**Rename branch** to match naming convention:

The worktree creation mechanism (see @git (worktree-create)) may auto-generate a branch name. Rename it immediately to follow the standard naming convention:

```bash
# Determine the correct branch name using Branch Naming Convention from @workflow
# Example: feat/LIN-123 or feat/my-project
git branch -m <type>/<identifier>
```

**Establish dependencies** — follow @workflow (dependency establishment) to restore `node_modules/` and/or Python deps. `REPO_ROOT` was captured above; CWD is inside the worktree. Warn on failure, never block.

**Validate planning docs exist in worktree**:

```bash
# Planning docs must have been committed to appear in the worktree
ls ./planning/ 2>/dev/null
```

If planning docs are missing, error with:
```
ERROR: Planning documents not found in worktree.
Worktrees branch from HEAD, so planning docs must be committed before using --worktree.

Fix: commit your planning docs first, then retry:
  git add ./planning/<project>/
  git commit -m "docs: add planning for <project>"
  /workflow:execute --worktree ./planning/<project>/
```

**Record worktree state**: Set `WORKTREE_PATH` to the current working directory for later use in session state and handoff.

