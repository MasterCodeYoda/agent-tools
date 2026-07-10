---
name: content-move-refactors-need-conservation-review
description: for doc/content extraction refactors, move verbatim with byte-diff discipline and review with an independent conservation lens plus an executability lens
type: pattern
applicability: project
related:
  - .agent-tools/memory/entries/docs-as-code-needs-code-grade-gates.md
promoted_at: null
source_harness: claude
---

The D3 context diet moved ~950 lines out of four SKILL.md files (31–42% reductions) with
zero content loss. The discipline that made that verifiable:

**Why:** "Move, don't rewrite" is checkable; "summarize while moving" isn't. Once content
is paraphrased in transit, nobody can prove nothing was dropped — and in a corpus agents
execute literally, a silently dropped gate or field list is a behavior change.

**How to apply:**

1. **Extraction rule:** passages move *verbatim* (heading-level lifts only). The extractor
   byte-diffs every moved passage against the original before deleting from source, and
   reports a moved-passage manifest (source lines → destination).
2. **Parallel extraction is safe on disjoint file sets**; forbid agents from running
   repo-wide gates mid-flight (siblings are dirty) — run gates centrally afterward.
3. **Review with two distinct lenses:** (a) *conservation* — independently re-derive the
   deleted-line set from git and grep destinations for it (deleted-but-unfound = P1 unless
   a declared dedupe); (b) *executability* — read the slimmed skill end-to-end as if
   executing it: gates/STOPs intact, field lists still inline, every pointer names a real
   file and section.
4. **Pointers must be namespaced** (`@family (path)`) — bare relative paths resolve
   differently (or not at all) across deployed layouts.
5. **What stays inline:** routing criteria, approval gates, artifact field lists — anything
   the agent needs *before* deciding to load the reference.

Companion lens for user-facing docs (from D5): review READMEs/walkthroughs by verifying
every factual claim against the actual script/skill behavior, not by proofreading.
