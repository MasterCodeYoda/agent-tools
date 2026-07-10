---
name: workflow:brainstorm
description: Explore a single fuzzy idea into a framed concept ready for refinement — collaborative HITL diverge, user-gated converge
argument-hint: "[optional: a rough idea, problem, or 'what if' to explore]"
user-invocable: true
---

# Concept Brainstorming

Turn **one** loose, fuzzy idea into a crisp, framed concept that `/workflow:refine` can take into
structured requirements. Brainstorm decides **what we're building and why** for a **single unit**;
refine decides the **exact requirements**.

**Shared invariant:** no durable path decision (`Chosen Direction`, `Status: Explored`) without an
**explicit user selection turn**. Draft options; the user commits.

## User Input

```text
$ARGUMENTS
```

## When to Use This Skill

Use brainstorm when **one** idea is still fuzzy:

- You can't yet state the problem as a single sentence.
- You're at "what if we…" or "I have a vague sense we need X."
- Several directions are possible and you haven't chosen one.

**Skip it** and go straight to `/workflow:refine` when you can already state the problem and a
rough direction — refine's Phase 1–2 will explore from there. Brainstorm exists for the step
*before* that, not as a mandatory gate.

### Altitude check (entry) — refuse multi-unit work

If the input is a **multi-unit program** (multiple independent workstreams, portfolio sequencing,
"shape the roadmap," initiative decomposition), **do not** run this skill as a portfolio workshop.

**Stop and offer only** (do not auto-invoke):

- Concept still fuzzy at program scale → user should run `/workflow:brainstorm` only if they first
  narrow to **one** concept; otherwise go to `/workflow:roadmap` (roadmap owns destination framing
  for multi-unit horizons).
- Direction clear enough to name streams/order → `/workflow:roadmap`.

Multi-stream English is not "one big concept." One feature with multiple ACs is still single-unit
and belongs here or in refine.

## Input Interpretation

| Input Pattern | Interpretation |
|---------------|----------------|
| Empty | Prompt for the rough idea |
| `continue` | Resume `./planning/*/brainstorm.md` with `Status: Exploring` (re-present directions; do **not** auto-converge) |
| Text | Use as the seed idea and begin exploring |

**If input is empty**, ask: "What's the rough idea? It's fine if it's half-formed — a problem,
a 'what if', or just a direction you're curious about."

**When exploring**, use the `AskUserQuestion` tool if available; otherwise ask one question (or a
small interrelated group) at a time and wait for the answer before continuing.

## The Brainstorming Protocol

### Gates (hard)

| Gate | Rule |
|------|------|
| **Diverge-complete** | Present ≥3 framings that pass the structural test (below). Then **hard stop**. |
| **Forbidden until user converges** | Writing `Chosen Direction`; `Status: Explored`; offering `/workflow:refine` as done; collapsing to one option; same-turn recommendation |
| **Converge** | User selects, rejects, ranks, merges, or explicitly asks which you prefer — **later turn** |
| **Recommend** | Only after user selects/ranks/rejects **or** explicitly asks "which do you prefer?" Never in the same turn as first options presentation |
| **Write Explored** | Only after converge; record `converged_by: user` |

User may **waive** fewer than three options ("only two real frames") — record the waiver.

### Structural options test

Each framing must differ on **at least two** of: problem owner, job-to-be-done, primary constraint,
success metric, non-goal set. Each must include a **kill criterion that would not kill the other
options**. Same solution in three outfits → fail the gate; stay in diverge / `Exploring`.

### Steps

1. **Frame the fuzz.** Capture the raw idea in the user's words. Surface the itch: who feels the
   pain, why it matters now, what triggered the thought. Don't solve yet.
2. **Diverge.** Generate options that pass the structural test. Expand lightly: compelling + kill
   (one or two lines each).
3. **Present the field and STOP.** Write or update `brainstorm.md` as `Status: Exploring` with
   directions only — **no** `Chosen Direction`, **no** seed as final. Wait for the user.
4. **Converge (user turn).** Pick, merge, or re-open diverge. Optional recommendation only under
   the recommend rule above.
5. **Pressure-test (optional).** If the chosen direction is a big or hard-to-reverse bet, run
   **Pass 1 (Blind-Spot)** of the Critic Pass — see @workflow (`references/critic-pass.md`).
   Skip for low-stakes ideas.
6. **Crystallize the seed.** One paragraph: problem, who it's for, chosen direction, why, what is
   deliberately *not* decided. Then write `Status: Explored` with Chosen + seed.

<!-- agent:include claude,grok -->
If the `superpowers:brainstorming` skill is available, you may borrow **one-question-at-a-time**
discipline for diverge only. **Do not** run its design-doc, user-review-spec, or writing-plans path —
return here for gates, artifact, and handoff. If it is not installed, use this protocol directly.
<!-- /agent:include claude,grok -->

## Output Artifact

Determine the project name from the git repository or working directory (the same basis
`/workflow:refine` uses), create `./planning/<project>/` if needed.

### While exploring (required shape)

```markdown
# Brainstorm: [working title]

Status: Exploring

## The Itch

[What problem or itch this addresses, who feels it, why now.]

## Directions Considered

- **[Direction A]** — [compelling] / kill: [criterion that wouldn't kill B/C]
- **[Direction B]** — …
- **[Direction C]** — …

## Deliberately Undecided

[Scope left open — optional at this stage]

## Notes

[Optional: user waiver of option count, open threads]
```

**Do not** include `## Chosen Direction` or a final `## Seed Concept` while `Status: Exploring`.

### After user converges

```markdown
# Brainstorm: [working title]

Status: Explored
converged_by: user

## Seed Concept

[One paragraph: the problem, who it's for, the chosen direction, why, and what is deliberately
left undecided.]

## The Itch

[…]

## Directions Considered

[…]

## Chosen Direction

[The direction to carry into refinement, and why it won.]

## Deliberately Undecided

[Scope and solution choices intentionally left open for refine/plan to resolve.]

## Open Questions for Refinement

- [ ] [Question to answer during refinement]
```

This artifact is local-file only. PM-system framing begins at `/workflow:refine`, not here.

## Handoff to Refine

Only after `Status: Explored`: "Concept framed and saved to `planning/<project>/brainstorm.md`.
Run `/workflow:refine` to turn this seed into structured requirements."

## Key Principles

- **Diverge before you converge** — and **stop** so the user actually converges.
- **Single-concept only** — multi-unit horizons belong to `/workflow:roadmap`.
- **Decide what and why, not how** — no ACs, stories, or task breakdown.
- **A seed, not a spec** — one sharp paragraph is the deliverable.
- **Signal, not ceremony** — if the idea is already clear, say so and send the user to refine.
- **Offer, don't chain-invoke** roadmap or refine until the user asks or the Explored handoff applies.
