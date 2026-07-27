# Doctrine: Context craft — from RPI to QRSPI (living synthesis)

**Date:** 2026-07-21 (synthesis)  
**Status:** **Living source of truth** for factory-side doctrine drawn from the Dex Horthy / HumanLayer lineage. Prefer this file over individual talk captures when claims conflict.  
**Talk captures (frozen sources):**  
- [research-no-vibes-allowed.md](./no-vibes-allowed.md) — “No Vibes Allowed” (RPI + context engineering intro)  
- [research-rpi-what-we-got-wrong.md](./rpi-what-we-got-wrong.md) — “Everything We Got Wrong About RPI” (postmortem → QRSPI/CRISPY)  

**Process SoT for skills:** `~/Source/OMG/agent-tools` (`/workflow`, `/swarm`). This file is factory research doctrine, not a skill.

---

## Why this file exists

Two talks, same speaker, same shop-floor problem — with **revisions** between them (especially where human attention goes). Leaving both captures as equal peers produces conflicting guidance. This synthesis holds the **current** doctrine; talk notes preserve what was said when.

---

## Problem that does not change

- AI coding often buys **volume + rework** (churn on last week’s slop).  
- Strong on **low-complexity greenfield**; weak on **high-complexity brownfield** without discipline.  
- Waiting for “smarter models” is the wrong primary lever. **Context engineering** — correctness, completeness, size, trajectory of the window — is how you get more from **today’s** models.  
- **Do not outsource the thinking.** There is **no magic prompt**. AI amplifies thinking or the lack of it.

---

## Context craft (stable core)

### Dumb zone / smart zone

- Rough teaching defaults: prefer hard reasoning in roughly the **0–40%** utilization band; rethink / compact as you approach **~60%**.  
- Heavy daily users develop intuition; fixed percentages are training wheels, not physics.  
- **Incorrect context is worse than missing context.** Bad research → throw out and re-steer.  
- **Trajectory hygiene:** apology / correction loops → compact and open a **fresh** window.  
- **Tool / MCP noise** and **instruction bloat** both push work into the dumb zone.  
- **Sub-agents are for context control** (search + structured digest), not role theater.

### Intentional compaction

- Distill goal, approach, done, current failure / next step into a durable artifact; resume from that — not from a polluted thread.  
- Prefer **static multi-artifact** progress (research, design, structure, plan, session-state) over relying on harness autocompact quality.  
- Compact **mid-phase**, not only at session handoff.

### Instruction budget

- Models only follow on the order of **~150–200 instructions** with good consistency (number moves with models; the constraint remains).  
- Mega-prompts silently **skip** high-leverage steps.  
- **Control flow for control flow** — classify, then smaller focused stages — not one 85-instruction blob.  
- Our `/workflow` family (especially continue) exists to enshrine a working process as **repeatable system** rather than non-DRY magic phrases across projects. Anti-magic-words is **validation of the stack**, not a separate product initiative; remaining work is **fidelity** (hard gates + progressive disclosure so steps cannot be raced past).

---

## Research → alignment → structure → tactics → code

Dex’s marketed names (**RPI**, then **QRSPI** / **CRISPY**) are **lineage labels**. We do **not** rebrand `/workflow`. We map mechanics into our process.

### Pipeline (conceptual)

```text
Questions (from ticket)
    → Research (ticket-hidden facts about the live codebase)
    → Converge + technical design (facts ⨯ requirements; refine-primary)
    → Structure (vertical phases + verification checkpoints)
    → Tactical plan (agent fuel; human spot-check)
    → Implement (execute; worktrees when needed)
    → Review code (dose-scaled own + pattern/seam read)
```

### On-demand codebase research (almost all work)

- Compress **live code truth** for *this* unit — not static mega-docs as gospel.  
- **Questions-first:** detangle the ticket into technical inquiries that force the right seams.  
- **Ticket-hidden research window:** research artifact is **facts** (how it works today). Do not load solution intent as gospel in that window or you get **opinions**.  
- **Converge** research facts with ticket/ACs afterward — primarily in **`/workflow:refine`** when requirements are still open (grounded requirements). Plan re-verifies or re-runs research when code moved; it does not replace that converge.  
- Distinct from the **research track** (decision/spike unit). Naming discipline stays.

### Technical design discussion (refine-primary)

- **Not** the same as `/workflow:brainstorm` (concept: *what/why* seed). Brainstorm stays brainstorm.  
- **Technical design:** current state, desired end state, patterns found (accept/reject legacy), resolved decisions, open questions — ~short “brain surgery” surface so the agent shows what it’s wrong about **before** structure and tactics.  
- **Home:** primarily **`/workflow:refine`** for feature/hard work, so limitations can still change requirements.  
- **Dose:** skip for true micro/trivial; light or full for non-trivial seams.  
- **Antipattern guard:** no endless refine↔design thrash — after requirements freeze, design-invalidating discoveries **re-enter refine** explicitly; plan does not silently rewrite ACs.  
- Plan’s **first** job is confirm design + research still hold, then structure + tactics — not a full redesign by default.

### Structure outline (hard segmentation — do not weaken)

- **Where we’re going** (design) vs **how we get there** (structure) vs **exact edits** (tactical plan).  
- Structure: phase order, signatures/types shape, **vertical** slices, **verification after each phase**.  
- Models bias to **horizontal** plans (all DB → all API → all FE); structure is the practical counter.  
- Human deep-reads **structure** (and design); tactical plan is denser agent fuel and gets a **spot-check**.  
- Visual plan must **surface the same segmentation** (design decisions / rejected patterns, vertical phases + checkpoints, then tactical density) — not one mushy overview.

### Tactical plan

- Snippet-dense edit sites, verification steps, research/design grounding links.  
- Long enough for a weaker implementer model; short enough that humans aren’t doing literature review on it as the primary gate.

### Code ownership (human guidance; system eases it)

**Not** “never read code” and **not** “read every line always.”

| Always | Pattern / seam | Dose-scaled | Never (production you own) |
|--------|----------------|-------------|----------------------------|
| Own the change: intent, blast radius, rollback | Read for pattern match / prefactor signal / feedback into design | Track + risk (`quick` / `standard` / `deep`) | Blind-merge and hope the next model fixes it |

- Short design/structure remain **high leverage** for early alignment (including code-owner review before attachment).  
- Long tactical plans are **not** a substitute for owning the PR.  
- System goal: keep improving surfaces so the human element is **easier and higher-signal** — not a robotic “must read N% of LOC” rule in the skills.

### Target throughput

- Prefer **~2–3× with craft** over **10× slop** that becomes next week’s rework.  
- Skeptical of pure “never read either side” factory fantasies for production systems people get paged on.

---

## Mapping to software-factory

| Doctrine | Factory direction |
|----------|-------------------|
| Process as craft; no vibes | Software factory system, not chat harness |
| Control flow + stages | Horizon → refine → plan → execute → review → finish → compound (+ swarm when wave-shaped) |
| Agents commoditize; harness wins | Process IP in **agent-tools**; this repo is project/runtime framing |
| Channels | Terminal / Slack / Linear / GitHub / CI into one system |
| Static artifacts | Handoff, session-state, runs, compound memory |
| Human still owns production outcomes | Review/integrate load-bearing; system makes ownership easier |

---

## Mapping to agent-tools (intent)

### Already aligned (do not re-adopt under new names)

- Phase family + continue SM (anti-magic-words as **system**)  
- Tracks (micro / feature / research) — dose QRSPI-shaped work onto these  
- On-demand `codebase-research.md`, dumb-zone, plan snippets, mid-phase compaction (post–No Vibes landing)  
- Vertical-slice doctrine  
- Plan approval, visual plan (presentation), worktrees, code-centric review, progressive disclosure direction  

### Process-IP intent → Wave 4 (landed in agent-tools skill text)

1. **Ticket-hidden / questions-first research** + **converge with ticket in refine** (plan re-verifies).  
2. **Technical design discussion** primarily in **refine** (not rename brainstorm; not full redesign inside plan by default).  
3. **Hard structure segmentation** in plan (+ visual): design → structure (vertical + verification) → tactical — **do not weaken**.  
4. Anti-magic-words = **validation** of workflow; fidelity via gates + instruction-budget hygiene.  
5. Read-code = **human guidance** + system makes pattern/seam ownership easier.  
6–8. Further progressive disclosure; visual plan v2 for segmentation; map into existing paradigm/tracks.

**Landing note:** [process-ip-wave4.md](./process-ip-wave4.md). Publish via agent-tools `./setup.sh`. No QRSPI rename.

---

## Superseded claims (do not apply from talk captures alone)

| Older claim (talk lineage) | Current doctrine |
|----------------------------|------------------|
| Deep-read the long plan instead of the code (primary leverage) | Deep-read **design + structure**; **spot-check** tactical plan; **own** the code at dose-scaled depth |
| “Don’t read the code” for production you own | Invalid for this factory’s craft standard |
| RPI as a single mega-prompt pipeline | Split stages; instruction budget; control flow outside the prompt |
| Research may include full “what we’re building” as the research prompt | **Hide ticket** during facts research; converge afterward |
| Magic words to force interactive planning | Defaults and hard gates; if a step needs a secret phrase, the skill is under-structured |
| Sub-agents as persona theater | Context firewalls only |
| Always-on progressive mega-docs as truth | On-demand codebase research; docs can lie |

---

## Dose by difficulty (factory / agent-tools tracks)

| Dose | Shape |
|------|--------|
| Trivial / micro | Light or skip research (reason); issue-as-plan; quick review; no full design/structure ceremony |
| Feature | Questions + ticket-hidden research → design in refine → structure + tactical plan → execute → review |
| Hard / multi-seam | More compaction; fuller design/structure; vertical checkpoints; re-enter refine if design falsifies ACs |
| Research track | Decision/evidence path; add codebase research when code-shaped |

---

## Source videos

| Talk | URL |
|------|-----|
| No Vibes Allowed | https://www.youtube.com/watch?v=rmvDxxNubIg |
| Everything We Got Wrong About RPI | https://www.youtube.com/watch?v=YwZR6tc7qYg |
| ACE write-up (RPI lineage) | https://github.com/humanlayer/advanced-context-engineering-for-coding-agents/blob/main/ace-fca.md |

---

## Related

| Doc | Role |
|-----|------|
| [product-surface.md](../product-surface.md) | **Locked product surface** (agent UX / multi-model / disk continuity) |
| [handoff.md](../handoff.md) | Research history / next actions |
| [research-langchain-software-factory.md](./langchain-software-factory.md) | External “software factory” framing |
| Process IP waves 1–4 | Process landings in agent-tools |
| Process IP wave 5 (GumClaw ops) | Landed in agent-tools 2026-07-23 — [process-ip-wave5.md](./process-ip-wave5.md) |
| Talk capture: No Vibes | Frozen source |
| Talk capture: RPI wrong | Frozen source |

---

*Living doctrine. Update this file when the lineage revises again; leave talk captures as historical sources with supersession banners.*
