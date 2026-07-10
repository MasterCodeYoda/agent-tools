---
name: docs-as-code-needs-code-grade-gates
description: when documents are the executable product (skills, prompts, specs), gate them like code — reference linter + golden characterization tests in CI beat manual audits
type: pattern
applicability: project
related:
  - tools/doc_lint.py
  - tests/publisher/
  - .github/workflows/ci.yml
promoted_at: null
source_harness: claude
---

In this repo the product *is* markdown that agents execute literally: a dead `@`-reference,
a stale command name, or a corrupted published file is a runtime bug, not a docs nit. Manual
review — even a thorough multi-agent audit — misses whole failure classes here: a three-agent
documentation audit missed two shipped publisher bugs (published MARKUP.md at half length;
`skills/import` truncated on all non-claude agents) that golden-file characterization tests
plus an adversarial code review surfaced immediately.

**Why:** Mechanical failure classes need mechanical gates. Self-editing loops
(`/skills:evolve`, sweeps, refactors) regenerate reference rot unless an invariant blocks it.

**How to apply:**

1. **Reference linter** (`tools/doc_lint.py`) validates links, `@skill` refs, command names,
   and intra-skill paths against the real tree — runs in CI; keep the allowlist commented and
   file-scoped.
2. **Golden characterization tests** (`tests/publisher/`) pin transformation-pipeline output
   byte-for-byte per agent; regenerate goldens only for intentional changes, and eyeball the
   diff.
3. When adding a new doc-transformation behavior or reference style, extend the fixture tree
   in the same change — an untested behavior class is where the next shipped corruption lives.
4. Before trusting "the docs are clean," run the gates, not another read-through.
5. **Know each gate's blind spots.** The doc linter scans only `*.md` — the D2 sweep missed
   `/swarm:init` surviving in harness *Python* (emitted to operators) and a scenario `.yml`,
   with stale test assertions locking the defect in green. After a rename sweep, grep the
   whole repo for the old token, not just the file types your gate covers.
