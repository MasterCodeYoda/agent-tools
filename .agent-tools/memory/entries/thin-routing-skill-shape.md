---
name: thin-routing-skill-shape
description: skills stay thin control planes; catalogs/templates go to references/templates; doc_lint shape rules + shape allowlist catch re-inflation
type: pattern
applicability: project
related:
  - src/skills/references/thin-routing.md
  - tools/doc_lint.py
  - tools/doc-lint-allowlist.txt
promoted_at: null
source_harness: null
---

Corpus layout norm: **thin routing, thick modular libraries, selective loading**. `SKILL.md`
owns when/order/gates/mandatory loads — not API man pages, write-time artifact shells, or
essays that already live under `references/`. Dual residence (skill re-teaches a ref) is a bug.
Hard gates must **never** be demoted to optional-only docs.

**Why:** Fat always-on skills tax every invocation. Extractions without a checkable bar re-inflate.
Honor-system-only norms rot; objective metrics + allowlist let the horizon thin skills over time
without failing CI on pre-extraction debt.

**How to apply:**

1. **Read the norm** before restructuring skills: `src/skills/references/thin-routing.md`
   (also linked from `@skills` and `/skills:evolve` Tier-1).
2. **Move, don’t delete** — templates → `templates/`; catalogs → `references/`; keep control
   plane in `SKILL.md`. Conservation-review content moves.
3. **doc_lint shape rules** (class `shape`):
   - `skill-bloat-no-siblings` — ≥300 lines and zero other `.md` under the skill dir
   - `skill-high-fence-ratio` — ≥200 lines and fenced-code ratio ≥0.35
4. **Allowlist** pre-extraction fat skills with `shape <glob>` in
   `tools/doc-lint-allowlist.txt`. **Remove** the entry when that skill is modularized.
5. **Tests** live in `tests/doclint/test_doc_lint.py` — add fixtures when changing thresholds
   or allowlist shape semantics.
