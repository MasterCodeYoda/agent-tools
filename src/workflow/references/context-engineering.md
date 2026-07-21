# Context engineering (coding agents)

**Load when:** planning, executing, continuing a multi-session unit, designing research
artifacts, reviewing plan quality, or when context feels noisy/stale/apology-looped.
Inspired by frequent intentional compaction / RPI practice (HumanLayer “No Vibes Allowed”
lineage) — adapted to this family’s tracks, gates, and artifacts.

**Goal:** keep the agent in the **smart zone** so today’s models can do hard work in real
codebases without slop. The only durable lever per turn is the **quality of the context
window** (correctness, completeness, size, trajectory).

## Two different “research” words

| Term | Meaning | Artifact / path |
|------|---------|-----------------|
| **Research track** | Built-in *work track*: success = decision or scored experiment | Frame → evidence → conclusion (`references/tracks.md`, `research-loop.md`) |
| **On-demand codebase research** | Context craft: compress **live code truth** for *this unit* so plan/execute start clean | `codebase-research.md` under the unit (preferred) — see below |

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

Agents cannot always read a live token meter. Approximate triggers to compact **now**:

- Multiple full-file reads + failed fix attempts on the same area without progress  
- Apology / “you’re right” loops after repeated corrections  
- Mid-unit handoff, slice complete, or approach pivot  
- About to start a new phase (research → plan → implement → next slice) with a full window  

## On-demand codebase research (default)

### Why

Static progressive disclosure (mega `AGENTS.md`, layered always-load docs) **rots** and can
**lie**. The code is the ground truth. For each unit, **compress a snapshot** of the parts
that matter — then plan and implement against that snapshot, not against a polluted chat.

This is the primary control on **context growth**: research burns search tokens in a
disposable window; the parent (or next phase) loads a short, human-reviewed artifact.

### When (almost all work)

| Situation | Dose |
|-----------|------|
| Feature track / multi-file / ambiguous seams | **Full** codebase research → `codebase-research.md` before plan (or before execute if plan was skipped) |
| Micro / direct issue | **Light** research: still produce a short artifact or a “Codebase research (light)” block in session-state / issue notes — files, entry points, constraints |
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

## Goal of this research
[What decision or change this snapshot supports]

## Relevant files (with why)
| Path | Role | Notes (symbols / lines if known) |
|------|------|----------------------------------|
| … | … | … |

## How it works today
[Data/control flow for the slice that matters — objective]

## Constraints & conventions
[Patterns to match; tests to extend; “do not break X”]

## Hypotheses / open questions
[Only if still uncertain — mark confidence]

## What we are *not* changing
[Out of blast radius]

## Freshness
- Sourced from code at: [commit SHA or date]
- Discard if: [condition]
```

**Light dose** may collapse to: goal · 3–10 files · 5–15 lines of flow · constraints.

### Quality bar

- Ground claims in **read code**, not memory of other repos  
- Prefer **throwing out** a wrong research doc over patching lies in place for pages  
- Human (or peer) should be able to **spot a bad line of research** before plan/implement  
- Research is **not** the research-track conclusion; it is context fuel  

## Plan-snippet quality bar

Plans compress **intent**. A plan that only lists vague tasks forces the implementer model
to re-discover the codebase (context growth + slop risk).

**Required for substantial plans** (and strongly preferred for anything multi-file):

1. **Edit sites** — concrete paths (and symbols/regions when known).  
2. **Intended-change shape** — short **code snippets** or precise before→after descriptions
   of the non-obvious edits (not every line of the final PR — the *shape* of the change).  
3. **Verification after steps** — what command/test/manual check proves each phase.  
4. **Link to research** — `codebase-research.md` (or light block) cited; plan must not
   invent modules that research did not establish.  
5. **Sweet spot** — long enough for reliable execution, short enough for a human to review
   in one sitting. Prefer density over essay.

Leverage reminder: a bad line of **plan** → many bad lines of code; a bad line of
**research** → the whole unit pointed wrong. Put human attention here.

Template support: @workflow (`planning/templates.md`) › Implementation Plan — **Research
grounding** + **Intended changes (snippets)**.

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
  plan + latest compaction + research artifact — **not** the full failed chat.  
- Continue / execute resume paths should treat the latest compaction as high-priority
  steering.  
- If approach is wrong: stop → re-plan (`/workflow:plan`) with updated research; do not
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
2. **Reflect plan density** — if the markdown plan has intended-change snippets and
   verification steps, the HTML should surface the same edit sites and phase checks (tables
   / callouts), not a vague overview that hides weak planning.  
3. **Same intent, two surfaces** — revise markdown first, then rewrite HTML (existing rule).  
4. **Human leverage** — visual is for scanning architecture + files + risks so the human
   spends approval attention like plan review, not like reading 2k LOC later.  
5. **Skip still OK** — non-substantial / policy `never` / write failure; never block the
   gate. Skipped visual does **not** skip codebase research or snippet quality on the
   markdown plan.

## Dose summary

```text
trivial one-liner     → skip research (reason) · chat or micro execute
micro                 → light codebase research · issue-as-plan · quick review
feature / hard        → full codebase research · snippet-dense plan · phase compact
research track        → decision evidence; add codebase research when code-shaped
any track, dumb zone  → intentional compaction → fresh window
```

## Related

| Topic | Path |
|-------|------|
| Tracks (feature / micro / research) | `references/tracks.md` |
| Plan skill | `planning/SKILL.md` |
| Plan templates | `planning/templates.md` |
| Execute skill | `execution/SKILL.md` |
| Direct issue (micro) | `execution/references/direct-issue-execution.md` |
| Visual approval | `planning/references/visual-approval.md` |
| Memory loading | `references/memory-primitives.md` |
| Process payload | `references/process-payload.md` |

Factory research capture: software-factory `docs/research-no-vibes-allowed.md`
(source video: https://www.youtube.com/watch?v=rmvDxxNubIg).
