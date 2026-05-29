---
last_updated: 2026-05-28
---
# Workflow Conventions

## PM Integration
None. The backlog is the local file `backlog.md` (file mode).

## Branching
One branch per backlog item: `feat/<item-key>` (e.g. `feat/CTM-2`).

## Commits
Conventional commits, present tense. Reference the item key.

## Merge Policy
Merge to `main` locally with `--no-ff`. Full `pytest -q` must pass after each merge. Never
push to a remote.

## Review
Each item is reviewed before merge; reviewers check the item's ACs and the shared integration
invariants.

## Release
N/A.

## Documentation
Update `seed/README.md` only if behavior materially changes; otherwise no docs required.
