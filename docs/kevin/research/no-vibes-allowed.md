# Research: No Vibes Allowed — Advanced Context Engineering for Coding Agents

> **Supersession:** This is a **frozen talk capture** (what was said). For **current factory doctrine** when claims conflict with later talks or our decisions, use **[research-context-craft-lineage.md](./context-craft-lineage.md)**. Notable later revisions include: long-plan deep-read as primary leverage, ticket-contaminated research, and “read the plan not the code.” Process-IP that *did* land from this note (dumb zone, plan snippets, on-demand research, mid-phase compaction, visual fit) remains in agent-tools until deliberately changed.

**Date:** 2026-07-21  
**Source video:** [No Vibes Allowed: Solving Hard Problems in Complex Codebases — Dex Horthy, HumanLayer](https://www.youtube.com/watch?v=rmvDxxNubIg)  
**Event:** AI Engineer Code Summit (≈20 min)  
**Related write-up (same lineage):** [Getting AI to Work in Complex Codebases](https://github.com/humanlayer/advanced-context-engineering-for-coding-agents/blob/main/ace-fca.md)  
**Status:** Frozen talk capture. Captures the talk, maps it as of capture time, and records process-IP outcomes we chose to land then. **Not** the living doctrine SoT.

---

## Why this note exists

The talk is tightly aligned with the software-factory framing and with what agent-tools already encodes as `/workflow` + `/swarm`. It is not a new product idea — it is a **tactical manifesto for the shop floor**: how to keep agents out of the “dumb zone,” put human attention on high-leverage artifacts, and treat AI coding as an engineering craft rather than vibes.

This note is the durable capture of:

1. A comprehensive summary of the video’s claims and techniques  
2. How those map to **software-factory** direction and **agent-tools** process IP  
3. The specific process-IP additions we chose (dumb-zone norms, plan-snippet quality, on-demand research for nearly all work, mid-phase intentional compaction, visual-plan fit)

---

## Video summary

### Problem frame

- Large-scale developer productivity work (referenced “100k developers” study / Yegor talk lineage) shows AI often increases **rework and churn**: more code shipped, much of it reworking last week’s slop.  
- AI is strong on **greenfield / small** work; weak on **brownfield + complex** tasks.  
- Fatalism of “maybe someday when models are smarter” is the wrong lever. **Context engineering** is how you get more out of **today’s** models.

### Goals they optimized for

| Goal | Meaning |
|------|---------|
| Brownfield | Agents work in large, established codebases |
| Complex problems | Not only button colors and CRUD |
| No slop | Quality that passes expert review / merges cleanly |
| Mental alignment | Team still understands *how/why* the system is changing |
| High-leverage tokens | Spend context on work that multiplies output quality |

Team story: ~**2–3×** throughput after rewiring collaboration; team of three; ~**eight weeks** of uncomfortable process change; then “never going back.”

### Context as the only real lever

- Models are effectively **stateless** per turn: quality of output ≈ quality of the context window.  
- Optimize context for **correctness**, **completeness**, **size**, and **trajectory**.  
- **Trajectory:** a session of “agent errs → human yells → agent errs → yell” trains the next tokens toward more failure/apology loops.  
- Worst → least-worst pollution: **incorrect information** > **missing information** > **noise**.

### The “dumb zone”

- Rough guideline: quality degrades as utilization climbs; around **~40%** of a ~168k usable window is where diminishing returns often start (task- and model-dependent; some guidance cites **40–60%** as the work band).  
- Too many MCPs / giant tool JSON dumps can force *all* work into the dumb zone.  
- Geoff Huntley-style constraint: **more of the window used → worse outcomes**, all else equal.

### Ladder of techniques

1. **Naive chat** — re-steer until context dies or you give up.  
2. **Fresh window + steered re-prompt** — restart when off track (especially apology loops).  
3. **Intentional compaction** — distill goal, approach, done so far, current failure into a markdown artifact; review it; start clean with that handoff.  
4. **Sub-agents for context control** — not roleplay (“frontend agent / backend agent”); fresh windows to **search and summarize**, returning compact findings so the parent stays clean.  
5. **Frequent intentional compaction** — design the **entire workflow** around context management (stay in the “smart zone”).

### Research → Plan → Implement (RPI)

| Phase | Compresses | Good artifact shape |
|-------|------------|---------------------|
| **Research** | Truth from the live codebase for *this* task | Files, flows, constraints — objective snapshot; throw away if wrong |
| **Plan** | Intent | Exact steps, file paths, **code snippets** of intended changes, verification after each step |
| **Implement** | Execution | Walk the plan; keep context low; re-compact status after phases |

What eats the window and must be compacted away: file search, flow understanding, edits, test/build logs, tool noise.

- Research is often discarded and redone with better steering.  
- Plan-with-research beat plan-without-research on hard brownfield work.  
- Implement is “boring” if the plan is good enough for a weak model.  
- Open prompts/system were widely forked after HN attention.

### Evidence and limits (from the talk)

- **BAML (~300k LOC Rust):** outsider + non-expert Rust → solid bugfix PR approved next morning.  
- **Harder day:** ~**35k LOC** (cancellation + WASM) in ~**7 hours** of deep human+agent work (some codegen/golden-file noise).  
- **Hard fail:** Hadoop-out of parquet-java — research not deep enough; whiteboard reset; domain expert likely required.  
- Systems races / weirdness still burn weeks sometimes — RPI is not magic.

### Mental models that matter

- **Don’t outsource the thinking.** AI amplifies thinking *or* the lack of it. No perfect prompt.  
- **“Spec-driven development” is semantically diffused** — the durable idea is **compaction + context engineering**, not the acronym.  
- **Onboarding agents (Memento metaphor):** without compressed truth, agents invent.  
- **Static progressive disclosure** (always-on mega-docs / layered AGENTS trees) rots; documentation **lies** more than code. Prefer **on-demand research** that compresses truth from the live codebase for the task at hand.  
- **Mental alignment** is the main job of review at scale: leaders can’t read every 1–2k LOC PR weekly; they *can* read strong plans. (Put the agent journey on the PR.)  
- **Leverage pyramid:**  
  - bad line of **code** → bad line of code  
  - bad line of **plan** → ~hundreds of bad lines of code  
  - bad line of **research** → whole effort pointed the wrong way  
  → put human attention on research and plans, not only final diffs.

### Dose by difficulty

- Trivial (button color) → just talk to the agent.  
- Small feature → light plan.  
- Multi-repo / medium → research then plan.  
- Hardest problems → more compaction; the ceiling rises with discipline.  
- Learn dose via **reps**; avoid tool-hopping across every coding CLI.

### Prediction / product

- Coding agents **commoditize**.  
- Hard part: **team + SDLC transformation** for ~99% AI-written code.  
- Org rift (seniors clean slop; mid/juniors over-adopt) needs top-down culture change.  
- HumanLayer’s **CodeLayer** is their tooling bet around this workflow.

---

## Mapping to software-factory

| Talk | This repo’s direction |
|------|------------------------|
| Process as craft; no vibes | **Software factory**, not chat harness |
| RPI + review leverage | Project: horizon → refine → plan → execute → review → finish → compound |
| Agents commoditize; workflow wins | Process IP lives in **agent-tools**; this repo is project/runtime framing |
| Channels into one system | Terminal / Slack / Linear / GitHub / CI are **channels** (see LangChain note) |
| Memory that compounds | Hermes/memory bet; compound as factory “soul” |
| Hybrid shell + coding workers | Hermes operator → Grok/Claude/OpenCode workers |
| Team org transformation | **Personal** throughput first; commercial optional |

**Gap before this research:** factory docs locked the *thesis* but did not yet capture Dex’s **context-budget doctrine** as process IP to push into agent-tools.

---

## Mapping to agent-tools (before → after intent)

### Already strong

| Talk | Existing process IP |
|------|---------------------|
| RPI-like line | `/workflow:refine` · `:plan` · `:execute` · `:review` · `:compound` |
| Dose by difficulty | Tracks: **micro** / **feature** / **research** |
| Human gates at leverage | Plan approval, roadmap gates, review evidence schema |
| Sub-agents / isolation | Swarm workers, explore tasks, worktrees |
| Session continuity | `session-state.md`, handoff package, runs ledger |
| Anti-theater | Soft-checks; process lessons → `/skills:evolve` only |
| On-demand knowledge | Skills + memory index-on-demand |

### Gaps we chose to close (process IP)

| Gap | Outcome |
|-----|---------|
| No explicit **dumb-zone** norms | Land in agent-tools `references/context-engineering.md` + execute/plan load points |
| Plans weak on **intended-change snippets** | Plan quality bar: concrete snippets / before-after shapes + per-step verification |
| Research only as a *track*, not as **default context craft** | **On-demand codebase research** artifact for nearly all work (not feature-only) |
| Compaction mostly at **session boundaries** | **Mid-phase intentional compaction** during execute (and when trajectory collapses) |
| Visual plan not explicitly tied to research/snippet quality | Visual surface **grounds** on research + reflects plan density (still presentation-only) |

**Naming discipline:** the built-in **research track** (decision/spike, conclusion-gated) is *not* the same as **on-demand codebase research** (compress live-code truth for the current unit). Both can coexist; conflating them blunts impact on context growth.

---

## Process-IP outcomes (locked for landing)

1. **Research note (this file)** — comprehensive summary + source link.  
2. **Dumb-zone norms** — stay roughly in the smart band; prefer fresh windows + compacted artifacts over stuffed threads.  
3. **Plan-snippet quality bar** — high-leverage plans include intended change shape (snippets / precise edit sites) and verification after steps.  
4. **On-demand research artifact — almost all work** — default context practice, not a feature-track exclusive. Dose scales (micro = short; hard = multi-pass); skip only true trivial cases.  
5. **Mid-phase intentional compaction** — first-class in execute (and continue-aware), not only handoff.  
6. **Visual plan fit** — still approval presentation only; must be grounded in codebase research and consistent with snippet-dense markdown plans so humans review the *same* high-leverage intent in a scannable surface.

Canonical skill landing: `~/Source/OMG/agent-tools` → `src/workflow/references/context-engineering.md` and wired plan/execute/tracks/visual docs.

---

## Timestamps (approximate, from source video)

| Time | Topic |
|------|--------|
| 00:00 | Intro / complex code & rework |
| 01:40 | Context engineering vs “wait for smarter models” |
| 02:53 | Advanced context engineering; naive vs restart |
| ~03:47 | Intentional compaction |
| ~05:55 | Dumb zone |
| ~06:35 | Sub-agents for context control |
| ~07:29 | Frequent intentional compaction; RPI |
| ~08:30 | BAML / brownfield practice |
| ~09:40 | Limits (parquet-java); don’t outsource thinking |
| ~10:20 | Spec-driven semantic diffusion |
| ~12:00 | Onboarding / progressive disclosure / on-demand research |
| ~14:42 | Planning as compression of intent; mental alignment |
| ~17:12 | Leverage pyramid; dose by difficulty |
| ~18:39 | RPI acronym caution; harness engineering |
| ~19:09 | What’s next: SDLC / culture; CodeLayer |

---

## Related in this repo

| Note | Path |
|------|------|
| Handoff / product direction | [handoff.md](../handoff.md) |
| LangChain software factory article | [research-langchain-software-factory.md](./langchain-software-factory.md) |
| Process IP waves 1–3 | [process-ip-wave1.md](./process-ip-wave1.md) · [wave2](./process-ip-wave2.md) · [wave3](./process-ip-wave3.md) |

## External links

| Resource | URL |
|----------|-----|
| **Source video** | https://www.youtube.com/watch?v=rmvDxxNubIg |
| ACE write-up (HumanLayer) | https://github.com/humanlayer/advanced-context-engineering-for-coding-agents/blob/main/ace-fca.md |
| HumanLayer | https://www.humanlayer.dev/ |
| agent-tools process SoT | `~/Source/OMG/agent-tools` |

---

*End of research note. Process-IP edits land in agent-tools; this file is the factory-side research capture.*
