---
name: specs-go-in-planning
description: Working specs go in planning root; durable designs promote to docs/design/ before committed citation
type: process
applicability: project
related:
  - docs/design/README.md
  - .agent-tools/planning/
promoted_at: "2026-07-08T22:29:35Z"
source_harness: claude
---

In this repo, in-progress design specs and planning docs live under the **planning root**
(preferred `.agent-tools/planning/`, e.g. `.agent-tools/planning/<area>/*-design.md`),
**not** the superpowers brainstorming default `docs/superpowers/specs/`.

The planning root is **transient** — largely gitignored, pruneable by `/work:maintain` —
so **committed files must never cite planning paths** as durable SoT (the doc-integrity
linter enforces this in CI). A design worth keeping after the work ships is promoted to
`docs/design/` (rewritten for a reader, not a work log) before being cited.

**Why:** The swarm skill and test-harness README once cited `planning/swarm/*.md` as their
"authoritative design"; the files were purged and every pointer dangled for months.

**How to apply:** Write working specs under the planning root (`<area>/`). When
brainstorming/writing-plans skills default to `docs/superpowers/specs/`, override to the
planning root. At work completion, either let the spec be pruned (skills/READMEs are the
authority) or promote it to `docs/design/` — never leave a committed reference into planning.
