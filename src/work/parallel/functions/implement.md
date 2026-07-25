# Function: implement

**Kind:** phase packet (maps to `/work:execute`)

## Procedure

Enter the item's worktree (`cd` to the path in the dispatch). Run `/work:execute` against
the plan for this item. If the dispatch includes a `fix_list` from a prior review, address
those items first.

## Scope

- Implement only what the plan (and any `fix_list`) requires.
- Keep commits on the item branch inside the worktree.
- Do not merge to main. Do not start review yourself.
- Report commits, files_changed, and test_status.

## Valid statuses

`DONE` · `DONE_WITH_CONCERNS` · `NEEDS_CONTEXT` · `BLOCKED`
