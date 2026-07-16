## Session #N Complete

### What Was Done

- [Detailed list of accomplishments]

### Key Decisions Made

- [Decision 1]: [Rationale]
- [Decision 2]: [Rationale]

### Current State

- Branch: `feat/ISSUE-123` or `fix/ISSUE-123`
- Worktree: `<path>` (if using --worktree, otherwise omit)
- Tests: [passing/failing]
- Progress: [X%]

### Recommended Next Steps

1. **Next Priority**: [specific task]
2. **Consider**: [upcoming decision point]
3. **Watch For**: [potential blockers]

### Files Modified

- `path/to/file1.py` - [what changed]
- `path/to/file2.py` - [what changed]

### To Resume

```bash
/workflow:execute ./planning/[project]/
# Or with this summary:
/workflow:execute "[paste this summary for context]"
```

### Worktree Status (if using --worktree)

**DO NOT clean up worktrees during session handoff.** Another session may still be using its worktree. Cleanup is always a separate, user-initiated action after all parallel sessions complete.

Document the session's worktree for reference:

```markdown
**Worktree**: `<worktree-path>`
**Branch**: `<branch-name>`
```

**EnterWorktree exit prompt**: Respect your agent's worktree exit prompt behavior (see @git worktree skills). In parallel workflows, prefer keeping the worktree until after merging.

**User-initiated merge and cleanup** (after ALL parallel sessions complete):

```bash
# 1. Navigate to the main repository root
cd <main-repo-root>

# 2. Merge the worktree branch
git checkout main
git merge <branch-name>

# 3. Run full test suite after merge
<project-specific test command>

# 4. Verify no other worktrees are still active
git worktree list

# 5. Remove ONLY your own worktrees, ONLY after merging
git worktree remove <worktree-path>   # see @git (worktree-delete)
git worktree prune
```

**Safety rules**:
- Never remove a worktree while your shell CWD is inside it — the shell will break irrecoverably
- Only remove worktrees you created — never clean up another session's worktree
- Always check `git worktree list` first to verify no sessions are still active
