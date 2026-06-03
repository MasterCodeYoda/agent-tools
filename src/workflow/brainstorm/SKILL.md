---
name: workflow:brainstorm
description: Explore a fuzzy idea into a framed concept ready for refinement
argument-hint: "[optional: a rough idea, problem, or 'what if' to explore]"
user-invocable: true
---

# Concept Brainstorming

Turn a loose, fuzzy idea into a crisp, framed concept that `/workflow:refine` can take into
structured requirements. This is the divergent front of the pipeline: brainstorm decides **what
we're building and why**; refine decides the **exact requirements**.

## User Input

```text
$ARGUMENTS
```

## When to Use This Skill

Use brainstorm when the idea is still fuzzy:

- You can't yet state the problem as a single sentence.
- You're at "what if we…" or "I have a vague sense we need X."
- Several directions are possible and you haven't chosen one.

**Skip it** and go straight to `/workflow:refine` when you can already state the problem and a
rough direction — refine's Phase 1–2 will explore from there. Brainstorm exists for the step
*before* that, not as a mandatory gate. Like the rest of the family, it should add signal, not
ceremony.

## Input Interpretation

| Input Pattern | Interpretation |
|---------------|----------------|
| Empty | Prompt for the rough idea |
| `continue` | Resume an in-progress `./planning/*/brainstorm.md` (`Status: Exploring`) |
| Text | Use as the seed idea and begin exploring |

**If input is empty**, ask: "What's the rough idea? It's fine if it's half-formed — a problem,
a 'what if', or just a direction you're curious about."

**When exploring**, use the `AskUserQuestion` tool if available; otherwise ask one question (or a
small interrelated group) at a time and wait for the answer before continuing.

## The Brainstorming Protocol

This protocol is the engine and runs on every agent. Move from divergent to convergent — do not
narrow onto the first idea.

1. **Frame the fuzz.** Capture the raw idea in the user's words. Surface the itch behind it: who
   feels the pain, why it matters now, what triggered the thought. Don't solve yet.
2. **Diverge.** Generate at least three *genuinely different* framings or directions — not
   variations of one. Useful prompts: "If no constraints existed, what would this be?", "What's
   the adjacent problem next to this one?", "What's the inverse of the obvious approach?"
3. **Expand and challenge.** For each direction, name what makes it compelling and what would
   kill it. Keep this lightweight — a line or two each, not an analysis.
4. **Converge.** With the user, pick the direction worth refining (or merge two). State why it
   won over the others.
5. **Pressure-test (optional).** If the chosen direction is a big or hard-to-reverse bet, run
   **Pass 1 (Blind-Spot)** of the Critic Pass — see @workflow (`references/critic-pass.md`) — over
   the directions considered to surface what the exploration missed. Skip for low-stakes ideas.
6. **Crystallize the seed.** Write the one-paragraph seed concept: the problem, who it's for, the
   chosen direction, why, and what is deliberately *not* being decided yet. This paragraph is
   refine's input.

<!-- The divergent rounds (steps 1–4) can be delegated where a richer ideation skill exists; the protocol above is always the fallback. Availability of superpowers is not guaranteed even on these agents, so this stays conditional, never the engine. -->
<!-- agent:include claude,grok -->
If the `superpowers:brainstorming` skill is available, prefer invoking it to drive the divergent
rounds (steps 1–4), then return here to pressure-test and crystallize the seed into the artifact
below. If it is not installed, use the protocol above directly.
<!-- /agent:include claude,grok -->

## Output Artifact

Determine the project name from the git repository or working directory (the same basis
`/workflow:refine` uses), create `./planning/<project>/` if needed, and write the seed concept to
`./planning/<project>/brainstorm.md`:

```markdown
# Brainstorm: [working title]

Status: Explored

## Seed Concept

[One paragraph: the problem, who it's for, the chosen direction, why, and what is deliberately
left undecided.]

## The Itch

[What problem or itch this addresses, who feels it, why now.]

## Directions Considered

- [Direction A] — [what's compelling / what would kill it]
- [Direction B] — [what's compelling / what would kill it]
- [Direction C] — [what's compelling / what would kill it]

## Chosen Direction

[The direction to carry into refinement, and why it won.]

## Deliberately Undecided

[Scope and solution choices intentionally left open for refine/plan to resolve.]

## Open Questions for Refinement

- [ ] [Question to answer during refinement]
```

This artifact is local-file only. PM-system framing (issues, acceptance criteria) begins at
`/workflow:refine`, not here.

## Handoff to Refine

Close by offering the next step: "Concept framed and saved to `planning/<project>/brainstorm.md`.
Run `/workflow:refine` to turn this seed into structured requirements." Refine reads this file as
its starting context.

## Key Principles

- **Diverge before you converge.** Three real options beat one obvious one. The first idea is
  rarely the best framing.
- **Decide what and why, not how.** No acceptance criteria, no user stories, no task breakdown —
  those belong to refine and plan. Producing them here is scope creep.
- **A seed, not a spec.** One sharp paragraph is the deliverable. If it's getting long, you've
  drifted into refinement.
- **Signal, not ceremony.** If the idea is already clear, say so and send the user to refine.
