# Research loop (built-in research track)

Use when the unit’s success is a **decision or scored experiment**, not shipped product code by
default. Full classification: @workflow `references/tracks.md`.

**Not the same as on-demand codebase research.** Codebase research (`codebase-research.md`)
compresses live-code truth for almost any unit (feature, micro, or this track when
code-shaped). This file is the **decision/spike** loop only. Context craft:
@workflow `references/context-engineering.md`.

## States

```text
framed → evidence → conclusion → compound → done
```

### 1. Framed

- Question in one sentence
- Success = decision or scored experiment (not “merged feature”)
- Time box (e.g. one session or 1–2 weeks)

### 2. Evidence

- Notes: `docs/research/<slug>.md` (preferred durable) and/or planning unit notes
- Optional spike branch / install / dogfood — out of product scope unless adopted later

### 3. Conclusion (user-gated)

- Adopt / reject / hybrid / defer
- Write durable conclusion under `docs/research/` or project handoff
- Open follow-on **feature** issues only if adopt

### 4. Compound

- Capture reusable criteria, or `compound: none — <reason>`

### 5. Done

**Not-done** (refuse done) if: no conclusion, open questions that block the decision, or
exploring status. **Done** is a judgment call once not-done signals are clear — user would not
reopen without new external evidence.

## Code spikes

If commits land, run review on the spike; conclusion doc remains primary deliverable.
