---
name: specs-go-in-planning
description: Working specs go in transient planning/; durable designs promote to committed docs/design/ before anything committed cites them
type: process
applicability: project
related:
  - docs/design/README.md
promoted_at: "2026-07-08T22:29:35Z"
source_harness: claude
---

In this repo, in-progress design specs and planning docs live under `planning/` (e.g.
`planning/<area>/*-design.md`), **not** the superpowers brainstorming default
`docs/superpowers/specs/`.

The carve-out (added 2026-07-09): `planning/` is **transient** — gitignored, purgeable by
`/workflow:prune` — so **committed files must never cite planning/ paths** (the doc-integrity
linter enforces this in CI). A design worth keeping after the work ships is promoted to
`docs/design/` (rewritten for a reader, not a work log) before being cited.

**Why:** The swarm skill and test-harness README once cited `planning/swarm/*.md` as their
"authoritative design"; the files were purged and every pointer dangled for months.

**How to apply:** Write working specs to `planning/<area>/`. When brainstorming/writing-plans
skills default to `docs/superpowers/specs/`, override to `planning/<area>/`. At work
completion, either let the spec be pruned (skills/READMEs are the authority) or promote it to
`docs/design/` — never leave a committed reference pointing into `planning/`.
