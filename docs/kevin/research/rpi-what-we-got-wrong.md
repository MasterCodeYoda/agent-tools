# Research: Everything We Got Wrong About Research-Plan-Implement

> **Supersession:** This is a **frozen talk capture** (what was said). For **current factory doctrine**, use **[research-context-craft-lineage.md](./context-craft-lineage.md)**. That synthesis absorbs this talk’s corrections (QRSPI shape, ticket-hidden research, design/structure leverage, code ownership nuance) and our process decisions (refine-primary technical design, segmentation, anti-magic-words as validation, etc.). Candidate lists below are historical discussion residue; treat the synthesis “Process-IP intent” as the decision rollup.

**Date:** 2026-07-21  
**Source video:** [Everything We Got Wrong About Research-Plan-Implement — Dexter Horthy, HumanLayer](https://www.youtube.com/watch?v=YwZR6tc7qYg)  
**Event:** Coding Agents Conference / MLOps.community keynote, Computer History Museum lineage (published ~Mar 24, 2026; ~27 min incl. Q&A)  
**Predecessor note:** [research-no-vibes-allowed.md](./no-vibes-allowed.md) (same speaker; RPI + context engineering introduction)  
**Living doctrine:** [research-context-craft-lineage.md](./context-craft-lineage.md)  
**Status:** Frozen talk capture. Captures the talk and early mapping; **not** the living doctrine SoT. Agent-tools landings still require explicit action beyond this capture.

---

## Why this note exists

The prior Dex talk sold **Research → Plan → Implement (RPI)** as the shop-floor answer for brownfield quality. This talk is the **post-adoption postmortem**: thousands of engineers used the open prompts; experts thrived; many teams did not. Dex reverses several of his own earlier claims (especially “read the plan, not the code”) and replaces the three-phase mega-prompt with a **finer workflow** (Questions / Research / Design / Structure / Plan / Worktree / Implement / PR), nicknamed **CRISPY** / **QRSPI**.

This note is the durable capture of:

1. A comprehensive summary of the video’s claims, failures, and replacement shape  
2. Continuity and tension with **No Vibes Allowed**  
3. How those map to **software-factory** direction and **agent-tools** process IP  
4. Process-IP **candidates** as discussed at capture time (see living synthesis for decision rollup)

---

## Video summary

### Setup and frame

- RPI spread widely after HN / open prompts (~“10k people” internal use claim: startups → enterprise).  
- Origin pain still holds (Igor / productivity studies): AI often buys **volume + rework**; strong on **low-complexity greenfield**, weak on **high-complexity brownfield**.  
- This talk is **not** “RPI is great”; it is **what broke when RPI hit real teams**.

### What they still claim as right

| Principle | Meaning |
|-----------|---------|
| **No magic prompt** | Silver-bullet system text is not the fix |
| **Do not outsource the thinking** | Engineer remains in the loop; AI amplifies thinking *or* its absence |
| **Seek leverage** | Prefer work that multiplies correctness without reading everything after the fact |
| **Objective research** | Compress **facts** about how code works today; discourage implementation opinions in research |

### Failure modes of RPI at scale

#### 1. Bad research (ticket contamination)

- Skilled engineers **detangle the ticket into questions** that force the agent to touch the right seams.  
- Most users paste the **whole ticket** into research → model invents **opinions** about the build instead of **facts**.  
- Good research = all facts; “here’s what I’m building” biases the window.

#### 2. Bad plans + the magic-words trap

- Planning lived in a **monolithic skill/prompt (~85+ instructions)** with buried interactive steps: present design options, get structure feedback, *then* write the plan.  
- When it worked: Q&A → phase outline → user reorders/adds tests → **only then** plan file.  
- For ~**50%+** of people (or when the model was “feeling dumb”), the agent **skipped alignment** and dumped a finished plan with all decisions made.  
- “Secret handshake”: *“Work back and forth with me starting with your open questions and outline before writing the plan.”*  
- Dex’s judgment: **if the tool needs magic words, the tool is broken** — not a user training problem.

#### 3. Instruction budget

- Cites work (Kyle / arXiv lineage): frontier models follow ~**150–200 instructions** with good consistency; beyond that, half-attention and dice rolls.  
- 85-instruction plan skill + system prompt + tools + MCP → silent skip of the high-leverage steps.  
- Ties back to **12 Factor Agents**: **do not use prompts for control flow** — classify, then smaller focused prompts with fewer actions. They preached micro-agents/workflows, then shipped a mega-prompt for Claude Code; this rebuild is **drinking their own Kool-Aid**.

#### 4. Plan-reading illusion (major reversal)

- Prior stage advice: read plans so leaders stay aligned without reading every PR.  
- Reality after months: **~1k-line plan ≈ ~1k-line code (±10%)**; plans have **surprises**; implementation **drifts** from plan → humans re-read both.  
- That is **not leverage**.  
- **New advice: don’t deep-read the long plan; please read the code** for production systems people get paged on.  
- Tried “don’t read code” for ~6 months → had to rip/replace large parts of a system.  
- OSS vibe projects (Beads-scale, OpenClaw-style “I know the structure but not every line”) are **different stakes** than regulated / paid production SaaS.  
- **2026 = year of no more slop**; craft vs slop; mid on pure agent-swarm / “gas town” speed without quality ownership.  
- Target **~2–3×** with near-human quality, not 10× throwaway.

### Replacement workflow (QRSPI / CRISPY)

Literal stages named in the talk:

```text
Questions → Research → Design → Structure (outline) → Plan → Worktree → Implement → PR
```

Acronym soup: full letter string is awkward; they brand the subset as **CRISPY** / community **QRSPI**. Treat the **shape** as durable, not the marketing name.

| Stage | Job | Context craft |
|-------|-----|----------------|
| **Questions** | Turn ticket into technical inquiries that force relevant seams | Own window; human/engineer skill matters |
| **Research** | Objective map of how code works **today** | **Fresh window; hide the ticket** so the model cannot form build opinions |
| **Design discussion** | Shared understanding: current state, desired end state, patterns to follow, resolved decisions, open questions | ~**200-line** markdown; **brain surgery** before code — force the agent to surface what it’s wrong about |
| **Structure outline** | “How we get there”: phase order, signatures/types shape, **how to test along the way** | ~**2 pages**; C **header-file** analogy vs plan-as-implementation |
| **Plan** | Tactical change list for the implementer agent | **Spot-check** after design/structure alignment; same template as old RPI plan, lower human deep-read duty |
| **Worktree** | Organize work hierarchy from vertical slices | Isolation / task tree (talk light on detail) |
| **Implement** | Write code (not the focus of this talk) | Prefer small models for implement + smarter spot-check (from related interview materials) |
| **PR** | Human reads and **owns** the code | Deep review lives **here**, not on the 8-page plan |

### Vertical plans vs horizontal plans

- Models **love horizontal plans**: all DB → all services → all API → all FE → then discover nothing works.  
- **Cannot fully prompt/eval that away**; **structure outline** is the practical fix.  
- **Vertical plans**: mock API → wire FE → mock services → migration → integrate — **checkpoints** after each 200–400 LOC block.  
- Same total code; much earlier falsification.

### Leverage pyramid (updated)

| Artifact | Approx. size | Human job |
|----------|--------------|-----------|
| Design discussion | ~200 lines | **Deep** alignment; reject bad patterns; answer open questions; optional co-founder/code-owner review |
| Structure outline | ~2 pages | Confirm phase order + verification checkpoints; force verticality |
| Plan | ~pages (old RPI) | **Spot-check** for agent tacticians |
| Code / PR | ~plan size | **Read and own** — production non-negotiable |

Team leverage: short design/structure docs are what you send the **code owner** *before* attachment to a working branch. Architecture-review energy moves earlier; code review becomes “yep, that’s what we agreed.”

### Time math (pre-AI vs AI-coding-only vs AI-alignment)

- 2-day feature: coding was often only 2–4 hours of the cycle.  
- Claude-only shipping: coding → ~20 minutes, **still** a multi-day feature (align, review, multi-repo, verify).  
- AI on **planning + alignment** shortens the non-coding majority *and* shortens rework in review.

### Dumb zone (updated nuance in Q&A)

- Still teaches **under ~40%** / rethink at **~60%** for people without intuition.  
- Heavy users (60 hrs/week, 6–9 months): “dumb zone” is less useful as a fixed rule — sometimes stay under 30%, sometimes push 60% by task complexity and instruction-vs-info mix.  
- Prefer **static artifacts** (research, design, structure, plan) over built-in autocompact quality for resume.

### What he did not have time for

- Implement-side harness detail  
- Testing / verification (points at Drew Brignac talk)  
- Adoption cost of **3 → ~7 stages** (“I thought we were making this easier”)  
- Measuring productivity impact  
- Platform-team prompt consolidation without regressions  
- Product: IDE that orchestrates the workflow (CodeLayer / HumanLayer productization) — optional, not required to get the value

### Q&A highlights

| Question | Answer gist |
|----------|-------------|
| Is “always read the code” scalable? | Binary-searching how much to read; 2–3× with reading still beats 10× slop; prior “don’t read” will age poorly for production |
| Software factory / never read either side | Formal verification / TLA++ rabbit hole maybe someday; does **not** endorse “spec only, code as assembly, never read” for people shipping now |
| Dumb zone still true with autocompact? | YMMV by expertise; teach 40/60 defaults; static assets beat relying on compact quality |

---

## Continuity with “No Vibes Allowed”

| Carried forward | Revised / sharpened |
|-----------------|---------------------|
| Context quality = only lever per turn | Instruction **count** is a first-class budget, not only token % |
| Dumb zone / sub-agents / intentional compaction | Static multi-artifact resume > autocompact as default story |
| Objective research; don’t outsource thinking | **Hide ticket** during research; separate **Questions** window |
| RPI as compression pipeline | RPI mega-prompt **failed at team scale**; split into QRSPI stages |
| Human attention on high-leverage artifacts | **Which** artifact: short **design/structure**, not long **plan**; **code** still owned |
| Mental alignment via plans | Mental alignment via **design discussion + structure**; plan is tactical |
| Dose by difficulty | Unchanged spirit; more stages for hard work, not cargo-cult ceremony for typos |

---

## Mapping to software-factory

| Talk | This repo’s direction |
|------|------------------------|
| Process as craft; no slop | **Software factory**, not chat harness |
| RPI → finer production line | Project: horizon → refine → plan → execute → review → finish → compound |
| Agents commoditize; harness + control flow win | Process IP in **agent-tools**; this repo is project/runtime framing |
| Human still owns production code | Review/integrate gates are load-bearing, not optional theater |
| Skeptical of “never read code/spec factory” | Factory is **disciplined loop + channels**, not hands-off codegen |
| Static artifacts over ephemeral chat | Handoff / session-state / runs ledger / compound memory bet |
| 2–3× with craft > 10× rework | Personal throughput first; commercial optional |

**Gap before this research:** factory docs + Wave 1–3 + No Vibes note locked RPI-like craft and context-engineering IP, but did **not** yet capture Dex’s **post-RPI corrections**: ticket-hidden research, design/structure as primary human gates, plan demoted to tactical, code-read as production norm, instruction-budget splitting of mega-skills, anti-magic-words defaults.

---

## Mapping to agent-tools (already strong vs gaps)

### Already strong

| Talk idea | Existing process IP |
|-----------|---------------------|
| RPI-like line | `/workflow:refine` · `:plan` · `:execute` · `:review` · `:compound` (+ continue/swarm) |
| Objective codebase research | `codebase-research.md` + context-engineering norms (post–No Vibes) |
| Vertical slices | Default decomposition mode; anti layer-by-layer doctrine |
| Human gates | Plan approval; roadmap gates; review evidence before integrate |
| Worktrees | Plan/execute `--worktree`; swarm isolation |
| Sub-agents for context | Explore/Task patterns; swarm workers |
| Static resume artifacts | `session-state.md`, plan, handoff package, runs ledger |
| Code review exists | `/workflow:review` is **code**-centric; green tests ≠ reviewed |
| Dose by difficulty | Tracks: **micro** / **feature** / **research** |
| Mid-phase compaction | Intentional compaction in context-engineering |
| Pattern of control flow over vibes | Tracks + continue state machine + gates (not one mega freeform agent) |

### Gaps / tensions (candidates only)

| Gap | Why it matters | Candidate direction |
|-----|----------------|---------------------|
| **Ticket contamination of research** | Research may still see full ticket/requirements → opinions | Explicit **facts-only** research brief; optional **Questions** pass that rewrites the ticket into technical questions; research window **must not** restate the solution intent as gospel |
| **No first-class Design discussion artifact** | Human deep-read still defaults to long `implementation-plan.md` (+ visual HTML) | Add short **`design-discussion.md`** (~1–3 screens): current/end state, patterns found (accept/reject), decisions, open questions — **gate before** full plan for feature/hard work |
| **No Structure outline distinct from plan** | Verticality and checkpoints can bury in a long plan | Add **`structure-outline.md`** (or a hard top section of plan): phase order, signatures/types shape, per-phase verification — human deep-reads **this**, plan becomes agent tactical |
| **Plan still primary approval surface** | Conflicts with Dex’s “spot-check plan, own code” | Split gates: **approve design/structure** (high human) → **spot-check plan** → **execute** → **review code (mandatory)**; visual plan should prefer design/structure density, not only task lists |
| **Magic-words risk in plan skill** | Large plan skill + “present for approval” can still skip interactive design options if the model races to a full plan | Default path **requires** open questions / options / outline **before** drafting full plan body (no user phrase required); micro track may skip by classification, not by omission |
| **Instruction budget of mega-skills** | workflow plan/execute/continue skills are large; silent skip is the failure mode Dex hit | Prefer **phase sub-skills / thin load points** with small instruction sets; parent orchestrates control flow (already partially true via references — lean further) |
| **“Read the plan not the code” residue** | No Vibes note + leverage pyramid still push leaders toward plan review | Update doctrine: **short design/structure** for mental alignment; **code** for production ownership; long plan is implementer fuel |
| **Pattern “brain surgery”** | Agents follow wrong legacy patterns | Design stage must list candidate patterns from research with human accept/reject before implement |
| **Adoption ceremony (3→7)** | Risk of cargo-culting full QRSPI for micro work | Map stages onto existing **tracks**: micro ≈ light research + issue-as-plan + code review; feature/hard ≈ full QRSPI-shaped artifacts |

**Naming discipline:** do **not** rename `/workflow` to QRSPI/CRISPY. Absorb the **mechanics** into artifacts + gates; keep agent-tools vocabulary (refine/plan/execute/review) unless a deliberate branding pass later.

---

## Process-IP candidates (for user gate — not landed)

Proposed set, ordered by leverage:

1. **Research note (this file)** — comprehensive summary + source link.  
2. **Ticket-hidden / questions-first research craft** — in `context-engineering.md` (+ plan load): Questions pass optional-but-default for feature; Research artifact is facts-only; hide or heavily quarantine solution intent during research.  
3. **Design discussion artifact + gate** — short human-owned alignment doc before full plan for feature/hard units.  
4. **Structure outline (vertical phases + verification)** — intermediate artifact or mandatory plan section; human deep-reads structure; plan is tactical.  
5. **Anti-magic-words planning path** — interactive options/outline **by default** before plan body; micro skips via track, not silent race.  
6. **Review doctrine update** — production: read/own code; design/structure for early human/team alignment; demote long-plan deep-read as primary leverage.  
7. **Instruction-budget hygiene** — document and gradually split mega-skill control flow; prefer thin phase prompts.  
8. **Visual plan fit v2** — ground visual surface on design + structure (and research), not only long implementation-plan prose.

**Out of scope unless asked:** rebranding workflow skills to QRSPI; implementing HumanLayer’s IDE; formal verification / no-human-read factory.

Canonical skill landing (if approved): `~/Source/OMG/agent-tools` — primarily `src/workflow/references/context-engineering.md`, plan/refine/review load points, templates, and possibly new artifact templates under planning.

---

## Timestamps (approximate, from source video)

| Time | Topic |
|------|--------|
| 00:00 | Host intro |
| 00:57 | Dex intro; RPI adoption |
| 01:29 | Productivity / rework / greenfield vs brownfield |
| 02:02 | “Everything we got wrong”; read code; no long plans; no slop |
| 02:46 | What they got right: no magic prompt; don’t outsource thinking; leverage |
| 03:05 | Audience poll: research / plan / magic words |
| 03:44 | Expert vs team adoption gap |
| 04:03 | Bad research; objective compression; ticket → opinions |
| 05:22 | Bad plans; 85-instruction monolith; interactive ideal path |
| 06:33 | ~50% skip alignment; magic words embarrassment |
| 07:35 | Instruction budget (~150–200) |
| 08:16 | Plan-reading failure; 1k plan ≈ 1k code |
| 09:01 | New advice: read the code; reverse prior talk |
| 09:32 | OSS vs production stakes; no more slop; mid on pure swarms |
| 11:02 | Fixes: better research / plans / leverage |
| 11:15 | Hide ticket; questions window then research window |
| 11:48 | 12-factor; context engineering; dumb zone; MCP instruction bloat |
| 13:12 | Control flow not prompts; split mega-prompt |
| 13:54 | QRSPI stages; <40 instructions each |
| 14:56 | Design discussion ~200 lines; brain surgery; patterns |
| 16:35 | Structure outline; vertical vs horizontal plans |
| 19:04 | Plan as tactical; design/structure for team alignment |
| 20:22 | Time savings on alignment, not only codegen |
| 21:20 | Full pipeline; CRISPY branding |
| 21:43 | Open problems: adoption, metrics, platform skills |
| 22:43 | Product / hiring / events |
| 23:22 | Q&A: reading code scalability |
| 24:14 | Q&A: software factory / never-read |
| 25:17 | Q&A: dumb zone + autocompact |

---

## Related in this repo

| Note | Path |
|------|------|
| Prior Dex talk (RPI intro / context engineering) | [research-no-vibes-allowed.md](./no-vibes-allowed.md) |
| Handoff / product direction | [handoff.md](../handoff.md) |
| LangChain software factory article | [research-langchain-software-factory.md](./langchain-software-factory.md) |
| Process IP waves 1–3 | [process-ip-wave1.md](./process-ip-wave1.md) · [wave2](./process-ip-wave2.md) · [wave3](./process-ip-wave3.md) |

## External links

| Resource | URL |
|----------|-----|
| **Source video** | https://www.youtube.com/watch?v=YwZR6tc7qYg |
| Prior talk (No Vibes) | https://www.youtube.com/watch?v=rmvDxxNubIg |
| ACE write-up (HumanLayer; RPI lineage) | https://github.com/humanlayer/advanced-context-engineering-for-coding-agents/blob/main/ace-fca.md |
| HumanLayer | https://www.humanlayer.dev/ |
| 12 Factor Agents | https://hlyr.dev/12fa |
| Community transcript capture | https://github.com/shanraisshan/claude-code-best-practice/blob/main/videos/claude-dex-mlops-community-24-mar-26.md |
| agent-tools process SoT | `~/Source/OMG/agent-tools` |

---

*End of research note. Process-IP edits land in agent-tools only after explicit approval; this file is the factory-side research capture.*
