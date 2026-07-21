# Context engineering (coding agents)

**Load when:** refining, planning, executing, continuing a multi-session unit, designing
research or design artifacts, reviewing plan quality, or when context feels
noisy/stale/apology-looped. Lineage: HumanLayer context craft (RPI → QRSPI corrections) —
adapted to this family’s tracks, gates, and artifacts. Factory doctrine:
software-factory `docs/research-context-craft-lineage.md`.

**Goal:** keep the agent in the **smart zone** so today’s models can do hard work in real
codebases without slop. The only durable lever per turn is the **quality of the context
window** (correctness, completeness, size, **instruction count**, trajectory).

## Two different “research” words

| Term | Meaning | Artifact / path |
|------|---------|-----------------|
| **Research track** | Built-in *work track*: success = decision or scored experiment | Frame → evidence → conclusion (`references/tracks.md`, `research-loop.md`) |
| **On-demand codebase research** | Context craft: compress **live code truth** for *this unit* so refine/plan/execute start clean | `codebase-research.md` under the unit (preferred) — see below |

Do **not** treat “micro / no research track” as “skip codebase research.” Codebase research
is the default context practice for **almost all work**; dose scales, skip is rare.

## Dumb-zone norms

Rough band (Claude-class ~168k usable windows; adjust per model):

| Band | Guidance |
|------|----------|
| **Smart zone** (~0–40% utilization) | Prefer to do planning, hard reasoning, and delicate edits here |
| **Work band** (~40–60%) | Acceptable for well-scoped implement steps with a strong plan; watch for drift |
| **Dumb zone** (≳60%, or any heavy MCP/tool-noise session) | **Stop and compact** — do not “push through” with more search/edits |

Hard norms:

1. **Incorrect context is worse than empty context.** Throw out bad research; restart with
   steering rather than arguing for pages.
2. **Trajectory hygiene.** If the window is a chain of failures + corrections + apologies,
   compact and open a **fresh** window — do not keep yelling in-thread.
3. **Tool noise is context debt.** Prefer focused reads over dumping large JSON/MCP payloads
   into the parent window. Use sub-agents/tasks to search; return **structured digests**.
4. **Sub-agents are for context control**, not role theater (no mandatory “frontend agent /
   backend agent / QA agent” cosplay). Parent keeps the compact truth; children burn tokens
   on exploration.
5. **Audit / one-shot discovery is an exception** when the skill explicitly grants a large
   dedicated window for exhaustive search — still return compact findings to the host.
6. **Instruction budget.** Frontier models only follow on the order of ~150–200 instructions
   with good consistency (number moves with models). Mega-prompts and stuffed skill loads
   **silently skip** high-leverage steps. Prefer **control flow outside the prompt** (phase
   skills, hard gates, thin load points) over one blob that “mentions” every step.

Agents cannot always read a live token meter. Approximate triggers to compact **now**:

- Multiple full-file reads + failed fix attempts on the same area without progress  
- Apology / “you’re right” loops after repeated corrections  
- Mid-unit handoff, slice complete, or approach pivot  
- About to start a new phase (research → design → structure → implement → next slice) with a full window  

### Progressive disclosure (skill fidelity)

`/workflow` exists so correct behavior is the **default** without magic phrases. That only
holds if high-leverage steps are **hard stops or separate thin loads**, not buried prose in
a mega-skill the model half-attends. When extending process IP: prefer small references
loaded at the right phase; do not grow parent skills into 85-instruction monoliths.

## On-demand codebase research (default)

### Why

Static progressive disclosure (mega `AGENTS.md`, layered always-load docs) **rots** and can
**lie**. The code is the ground truth. For each unit, **compress a snapshot** of the parts
that matter — then design, plan, and implement against that snapshot, not against a polluted
chat.

This is the primary control on **context growth**: research burns search tokens in a
disposable window; the parent (or next phase) loads a short, human-reviewed artifact.

### Questions-first, then ticket-hidden facts

**Good research is facts.** If you paste the full ticket / “here’s what we’re building” into
the research window, the model forms **opinions** about the solution instead of mapping how
the code works today.

| Step | Window / load | Content |
|------|---------------|---------|
| **1. Questions** | May see the ticket | Detangle into **technical inquiries** that force relevant seams (endpoints, flows, workers, types) — not a solution brief |
| **2. Research** | Prefer **fresh** window; **hide or quarantine solution intent** | Answer the questions with **objective** “how it works today”; no implementation plan, no chosen design |
| **3. Converge** | Refine (primary) or plan re-verify | Facts ⨯ ticket/ACs → grounded requirements and/or technical design |

**Ticket-hidden rule:** the research artifact must not read as a disguised plan. Goal of
research may name the *area* under study without locking product decisions.

### When (almost all work)

| Situation | Dose |
|-----------|------|
| Feature track / multi-file / ambiguous seams | **Full** codebase research → `codebase-research.md` during **refine** when requirements are open, else before plan (or before execute if plan was skipped) |
| Micro / direct issue | **Light** research: short artifact or “Codebase research (light)” block — files, entry points, constraints |
| Research **track** (decision) | Decision evidence **plus** codebase research when the decision depends on how the system works today |
| Pure typo / one-line / docs-only with known path | **Skip** with an explicit one-liner: `codebase research: skipped — <reason>` |

User can always force full research (`research this first`, `deep research`).

### Artifact location

Prefer under the unit’s planning directory (resolved planning root):

```text
<planning-root>/<unit>/codebase-research.md
```

If micro has no shell yet, write a minimal unit dir **or** put a short light block in
session-state / continue notes — do not silently skip.

### Artifact shape (full)

```markdown
# Codebase research: [unit / issue]

## Research questions
[Technical inquiries that drove this pass — not the solution brief]

## Relevant files (with why)
| Path | Role | Notes (symbols / lines if known) |
|------|------|----------------------------------|
| … | … | … |

## How it works today
[Data/control flow for the slice that matters — **objective facts only**]

## Constraints & conventions
[Patterns observed; tests to extend; “do not break X” — still descriptive]

## Hypotheses / open questions
[Only if still uncertain — mark confidence; no chosen implementation]

## What we are *not* changing
[Out of blast radius — factual scope of the map]

## Freshness
- Sourced from code at: [commit SHA or date]
- Discard if: [condition]
```

**Light dose** may collapse to: questions · 3–10 files · 5–15 lines of flow · constraints.

### Quality bar

- Ground claims in **read code**, not memory of other repos  
- Prefer **throwing out** a wrong research doc over patching lies in place for pages  
- Human (or peer) should be able to **spot a bad line of research** before design/plan  
- Research is **not** the research-track conclusion; it is context fuel  
- Research is **not** technical design; design is the next converge step  

### Converge (facts ⨯ ticket)

After research, **do not** treat the ticket as still ungrounded:

- **Refine (primary):** fold research into requirements and technical design — ACs may change
  when code falsifies assumptions.  
- **Plan:** re-verify research freshness; re-run if branch moved; if design-invalidating
  facts appear after requirements freeze → **stop and offer re-enter refine**, do not silently
  rewrite ACs in the plan.

## Technical design discussion (refine-primary)

**Not** `/workflow:brainstorm` (concept: *what/why* seed). Brainstorm stays optional and
upstream. Technical design is **how this change sits in this codebase** after facts exist.

### When

| Situation | Dose |
|-----------|------|
| Feature / hard / multi-seam / new contracts | **Full** `design-discussion.md` during refine (default) |
| Small but non-trivial feature with clear ACs | **Light** design block in requirements or short design file |
| Micro / typo / known one-path fix | **Skip** with reason — no ceremony |
| Plan finds design missing on a feature unit | Confirm or produce design **before** structure/tactical plan; prefer pointing user to refine if ACs must change |

### Artifact

```text
<planning-root>/<unit>/design-discussion.md
```

Shape (full):

```markdown
# Design discussion: [unit]

## Current state
[From research — how it works today for this blast radius]

## Desired end state
[What success looks like in the system — still product-grounded]

## Patterns found (accept / reject)
| Pattern / location | Verdict | Notes |
|--------------------|---------|-------|
| … | accept / reject / supersede | … |

## Resolved decisions
- …

## Open questions
- [ ] … — recommended default: …

## Requirements impact
[ACs or scope changes implied by technical reality — must land in requirements/PM]

## Freshness
- Grounded in research at: [path + commit]
```

**Brain surgery:** force the agent to surface wrong patterns and open questions **before**
structure and tactics. Human (or code owner) can deep-read this short artifact (~1–3 screens).

## Plan segmentation (do not weaken)

Plans are **not** one undifferentiated wall. For substantial work, the executable plan
**must** segment:

```text
1. Design confirm (link design-discussion + research; stop if design must change)
2. Structure outline — vertical phases + verification checkpoints (human deep-read)
3. Tactical intended changes — snippets / edit sites (agent fuel; human spot-check)
4. Breakdown tasks / DoD
```

### Structure outline quality bar

- **Vertical** phase order (testable checkpoints), not horizontal “all DB then all API then FE”
  unless deliverable-partition mode genuinely requires deliverable completeness  
- Per phase: what lands, how to **verify** before the next phase  
- Signatures / types / seam shape where that is the high-leverage correction surface  
- Sweet spot: ~pages of structure scannable in one sitting — not a second novel  

### Tactical plan quality bar (snippets)

1. **Edit sites** — concrete paths (and symbols/regions when known).  
2. **Intended-change shape** — short **code snippets** or precise before→after for
   non-obvious edits.  
3. **Verification after steps** — command/test/manual check.  
4. **Link to research + design** — must not invent modules research/design did not establish.  
5. Density over essay — reliable for a weaker implementer; **spot-check** for humans.

**Leverage (updated):** a bad line of **research** → whole unit pointed wrong; a bad line of
**design/structure** → hundreds of bad lines of code; a bad line of **tactical plan** → bad
edits. Put human attention on research, design, and structure; own the **code** at review
with dose-scaled pattern/seam reading (human guidance — see below).

Template support: @workflow (`planning/templates.md`) › Implementation Plan — **Research
grounding**, **Design**, **Structure outline**, **Intended changes (snippets)**.

### Anti-race / fidelity

Do **not** jump straight to a finished multi-page plan body without structure (and design
confirm when required). Interactive options/outline are **defaults of the skill**, not
optional magic words the user must recite. Micro track may skip structure by classification,
not by silent omission on a feature unit.

## Mid-phase intentional compaction

Do **not** wait only for session handoff. Compact **during** execute when triggers fire.

### What to write

Update **both** when possible:

1. **`session-state.md`** — Current Focus, Last Session Summary, and an append-only
   **Intentional Compaction** subsection (or replace the latest snapshot).  
2. **`implementation-plan.md`** — checkboxes + a short **Status after phase N** note when
   approach/status diverged from the written plan.

Minimum snapshot fields:

```markdown
## Intentional Compaction — [timestamp]

- **Goal (unchanged / revised):** …
- **Approach:** …
- **Done so far:** …
- **Current failure or next step:** …
- **Key files:** …
- **Tests / verification last green:** …
- **Do not re-open:** [dead ends]
```

### After compacting

- Prefer a **fresh context window** (new session / clear thread) loaded with:
  design + structure + plan + latest compaction + research — **not** the full failed chat.  
- Continue / execute resume paths should treat the latest compaction as high-priority
  steering.  
- If approach is wrong: stop → re-plan or re-enter refine when ACs/design break; do not
  “patch vibes” in the dumb zone.

### When mid-phase compaction is mandatory

- Slice / sub-issue complete and more units remain  
- Failed approach after 2+ serious attempts  
- User correction that changes trajectory  
- Context trigger list above  

### When it is optional

- Single remaining trivial task with green tests and clean trajectory  

## Visual plan fit

Visual plan (`visual-plan.html`) remains **approval presentation only** — executable SoT is
still `implementation-plan.md` (@workflow `planning/references/visual-approval.md`).

Context-engineering constraints on the visual surface:

1. **Ground in research** — architecture, file map, and contracts come from
   `codebase-research.md` (or light research), not invention. Label inference.  
2. **Surface segmentation** — design decisions / rejected patterns; **structure** (vertical
   phases + verification); then tactical intended-change density — not one mushy overview.  
3. **Same intent, two surfaces** — revise markdown first, then rewrite HTML (existing rule).  
4. **Human leverage** — visual is for scanning design + structure + files so approval matches
   the high-leverage read, not a substitute for owning the PR later.  
5. **Skip still OK** — non-substantial / policy `never` / write failure; never block the
   gate. Skipped visual does **not** skip research, design (when required), structure, or
   snippet quality on the markdown plan.

## Code ownership (human guidance; system eases)

Not a robotic “read N% of LOC” rule in the skills. Craft standard for production you own:

| Always | Pattern / seam | Dose-scaled | Never |
|--------|----------------|-------------|-------|
| Own intent, blast radius, rollback | Read for pattern match / prefactor / feedback into design | Track + risk (`quick` / `standard` / `deep`) | Blind-merge and hope |

System job: better design/structure surfaces, risk-scaled review, less surprise volume so the
human read is **shorter and higher-signal**. Review skill remains **code-centric**; green
tests ≠ reviewed.

## Dose summary

```text
trivial one-liner     → skip research (reason) · chat or micro execute
micro                 → light research · issue-as-plan · quick review · no design/structure ceremony
feature               → questions + ticket-hidden research → design in refine → structure + tactical plan → execute → review
hard / multi-seam     → fuller design/structure · vertical checkpoints · re-enter refine if design falsifies ACs
research track        → decision evidence; add codebase research when code-shaped
any track, dumb zone  → intentional compaction → fresh window
```

## Related

| Topic | Path |
|-------|------|
| Tracks (feature / micro / research) | `references/tracks.md` |
| Refine skill | `refine/SKILL.md` |
| Design discussion template | `refine/templates/design-discussion.md` |
| Plan skill | `planning/SKILL.md` |
| Plan templates | `planning/templates.md` |
| Execute skill | `execution/SKILL.md` |
| Direct issue (micro) | `execution/references/direct-issue-execution.md` |
| Visual approval | `planning/references/visual-approval.md` |
| Memory loading | `references/memory-primitives.md` |
| Process payload | `references/process-payload.md` |

Factory living doctrine: software-factory `docs/research-context-craft-lineage.md`
(sources: https://www.youtube.com/watch?v=rmvDxxNubIg ,
https://www.youtube.com/watch?v=YwZR6tc7qYg).
