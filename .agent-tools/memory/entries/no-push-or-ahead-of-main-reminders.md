---
name: no-push-or-ahead-of-main-reminders
description: Don't prompt about pushing or report how far ahead of origin/main the local branch is
type: process
applicability: project
related: []
promoted_at: "2026-07-08T22:29:35Z"
source_harness: claude
---

Do **not** remind the user to push, offer to push, or report how many commits ahead of `origin/main` the local branch is. They manage remote state without prompting.

**Why:** Push/ahead status is noise; the user tracks it themselves.

**How to apply:** After commits/merges, report what was done locally and stop. Push only when explicitly asked. Omit "you're N commits ahead of origin" status lines entirely.
