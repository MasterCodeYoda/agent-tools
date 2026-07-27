# Product surface — software factory agent

**Date:** 2026-07-21; **host/control plane 2026-07-24**  
**Status:** **Locked product surface** (process + UX contract). Host default **Hermes** (Kevin v1); stack remains pluggable under lean A.  
**Audience:** Future sessions implementing Kevin. Prefer this file over shell-out hybrid sketches.

**Related:** [handoff.md](./handoff.md) · [kevin-v1.md](./kevin-v1.md) · [research/context-craft-lineage.md](./research/context-craft-lineage.md) · agent-tools process SoT

---

## One-line definition

**`agent` in a repo: a long-lived project agent with a fresh conversation each invocation, shipped factory process, hierarchical multi-model routing, Grok-style tool approvals, and git-backed disk as memory — our control plane, one surface.**

---

## What it is

A **project-bound coding agent**. The product *is* the agent — not a dashboard over other coding apps.

| Concern | Ownership |
|---------|-----------|
| **Process / control plane** | agent-tools (`/workflow`, `/swarm`, memory, PM dialect) — **SoT** |
| **Product surface** | This agent: entry, chrome, model hierarchy, config overlays, tool approvals, observation |
| **Models** | Multi-provider; subscriptions / API keys / SDKs as needed |
| **Tool loop** | In-process (or in *our* runtime stack) — learn patterns from OpenCode, Grok Build, LangChain Deep Agents, etc. |
| **Artifacts** | Lens on project disk (git-backed) |

Personal ROI justifies the work. Commercial release is optional and not the design driver (“slim odds” = low likelihood *we* pursue GTM, not a viability claim).

---

## What it is not

- Multiplexer / shell-out to Claude Code, Grok Build, OpenCode, etc. as **apps** where work happens  
- Multi-project IDE shell (project picker, leave-project navigation)  
- A second process dialect (no QRSPI rename, no parallel phase table)  
- Immortal single conversation as system of record  
- PM-first product that happens to call coders  

Use ecosystem **models**, **auth/subscription paths**, and **SDKs when required** (e.g. Claude). Borrow **harness patterns**. Do not make foreign TUIs/CLIs the execution home.

---

## Entry and binding

| Decision | Detail |
|----------|--------|
| **Entry** | Run `agent` **from inside the project directory**. Cwd *is* the project. |
| **Primary object** | The **project** — ambient, always. Units, phases, models, capacity are views *inside* that project. |
| **Navigation** | No in-app list of projects; no product concept of “leave project.” Multiple repos ⇒ multiple OS processes / directories. |
| **Agent lifetime** | **One long-lived project agent** (identity, config, disk posture bound to that root). |
| **Conversation lifetime** | **Every invocation = a new conversation.** Not one long-running chat. |

### Continuity vs conversation

| Concern | Mechanism |
|---------|-----------|
| Agent / project identity | Long-lived; bound to project root |
| Chat / context window | Fresh each invocation |
| Work continuity | Disk: planning root, session-state, runs ledger, compound memory, conventions |
| Process fidelity | Skills + system-prompt binding + overlay injection policy |
| Model choice | Hierarchical config; changeable at **turn boundaries** within a conversation; re-resolved each invocation from hierarchy |

Aligns with context-craft hygiene: artifacts are memory; polluted threads are not.

---

## Core shape

```text
$ cd ~/Source/foo && agent

  Project agent (long-lived binding to this disk root)
    ├── New conversation every invocation
    ├── Continuity: lens on disk (git-backed)
    ├── Control plane: shipped agent-tools skills (SoT)
    ├── Config: hierarchical models + harness-managed overlays
    ├── Tools: in-process; Grok-style approval tiers
    └── Chrome: phase · model map · capacity · yield/stuck
```

Later: same agent core over Slack / Telegram / other channels — **transport only**. Communication mechanism may change; **process does not**.

---

## Standing chrome (always visible)

- **Phase** (project posture / control-plane state)  
- **Model map** (effective hierarchy resolution for this run/turn)  
- **Capacity** (subscription / API spend awareness + **usage windows** where available)  
- **Yield / stuck** (last signal from runs / project diagnostics)  

### Operator control plane (v1)

A launchable dashboard (or equivalent) for the **factory** host instance — not a second project-disk SoT:

| Capability | Required |
|------------|----------|
| Model hierarchy config | Orchestrate / execute / aux (and defaults) |
| Subscription / provider attachment | Which pools the factory agent uses |
| Usage metrics | Tokens/cost/sessions for factory scope |
| Usage windows | Remaining allowance / reset / rate limits per attached plan (best available; provider gaps honest) |

Prefer host-native admin surfaces as substrate; product owns factory policy, config-as-code sync, and gaps. See [ADR-001](./decisions/001-hermes-provisional-factory-host.md).

---

## Multi-model policy

**Hierarchical configuration**, not a single static role→model map.

Sketch (outer → inner wins unless policy says otherwise):

```text
product defaults
  → user global
    → project
      → phase / track
        → this-run / this-turn override
```

- Models may change at **any turn boundary**.  
- Differentiator as models commoditize: **routing + policy + observability**, not a single default model.

---

## Configuration plane

### Starting position on gates

- **Human / process gates:** skill-enforced (same semantics as today).  
- **Harness flex:** system prompts; policy on which project overlays skills may inject (today: `personify.md`, `conventions.md`, etc.).  
- **Productization direction:** move overlay *authoring and binding* into harness-managed surfaces that still write **disk artifacts skills understand** — not a second secret process language.

### Harness-managed surfaces — first-wave priority

1. Model hierarchy  
2. Conventions  
3. Personify  
4. PM auth / connectivity  
5. Capacity / spend visibility  

### Artifacts

**Lens on disk.** Planning, runs, memory, conventions live in the project tree. Git supplies versioning, review, and recovery. UI is not a second system of truth that must sync.

---

## Process pack

| Decision | Detail |
|----------|--------|
| **SoT** | agent-tools remains process source of truth |
| **Distribution** | **Ship** the process pack (or published process-payload slice) with the product |
| **Updates** | Optional later: auto-pull from repo; **lean ship** for v1 |
| **Non-goal** | Dual-maintaining a second full process corpus inside the product |

---

## Tools and permissions

- Full **tool calling** in this agent (stack supplies mechanics).  
- **Grok-style approval tiers** as the user-visible permission model.  
- Skills enforce **process** gates; harness enforces **tool** gates.  
- Stack evaluation should study how OpenCode, Grok Build, LangChain Deep Agents (and peers) handle tool loops, streaming, sessions, and permissions — as **implementation references**, not as apps to shell into.

---

## v1 non-goals

- Slack / Telegram / multi-channel until TUI proves multi-model + shared ledger  
- Commercial packaging pressure  
- Second process dialect  
- Multi-project navigation inside the app  
- Shell-out architecture to foreign coding agent apps  

---

## Evolution law

> Communication mechanism may change (TUI → chat channels).  
> Process does not.  
> Project binding and disk SoT do not.

---

## Jobs the surface owns

1. Operator home for the control plane (continue / claim / phase / swarm posture).  
2. Multi-model workflow (hierarchical routing, turn-boundary switches).  
3. Project-level continuity across models (one runs ledger, planning dialect, compound/memory view).  
4. Configuration plane that skills already understand (overlays, auth, PM, merge policy).  
5. Consistent UX/behavior regardless of model.  
6. Capacity / spend awareness for personal ops.  
7. Channel-ready core with TUI as first console.

---

## Stack stance (open)

Product surface is **locked**; implementation stack is **not**.

**Default host:** Hermes — [decisions/001-hermes-provisional-factory-host.md](./decisions/001-hermes-provisional-factory-host.md).  
Historical landscape: [research/stack-evaluation.md](./research/stack-evaluation.md). Host remains pluggable under lean A.

**Evaluate stacks against this surface**, not the reverse. Especially:

| Surface requirement | Stack must support |
|---------------------|-------------------|
| Project-cwd entry | Clear project root binding |
| Fresh conversation / invocation | Session model that does not force immortal threads |
| Disk lens | No mandatory opaque DB as SoT for planning/runs |
| Shipped skills pack | Skill/tool loading compatible with agent-tools (or clean adapter) |
| Hierarchical multi-model | Provider flexibility + runtime model switch |
| Grok-style tool approvals | Permission tiers or equivalent |
| Future channels | Headless / gateway path without forking process |

Historical note: early handoff favored “Hermes + shell coding CLIs.” **That hybrid is superseded for product architecture.** Hermes (or any stack) may still win as **runtime under this surface**; workers-as-foreign-apps is out.

---

## Supersedes (when conflicting)

| Older claim | Current surface |
|-------------|-----------------|
| Primary investment = greenfield Rust Grok-Build clone | Not required; stack open; product is the agent surface |
| Architecture = orchestrator that shells out to Grok/Claude/OpenCode **apps** | Own the agent + tool loop; use their **models/SDKs/patterns** |
| Hermes is only a candidate | Hermes is **default host** for Kevin v1; still pluggable under lean A |
| Immortal chat / episode thread as primary memory | Fresh conversation each invocation; disk is continuity |

---

## Related

| Doc | Role |
|-----|------|
| [handoff.md](./handoff.md) | Session orientation |
| [kevin-v1.md](./kevin-v1.md) | v1 destination + residual DoD |
| [decisions/001-hermes-provisional-factory-host.md](./decisions/001-hermes-provisional-factory-host.md) | Host + Kevin locks |
| [research/context-craft-lineage.md](./research/context-craft-lineage.md) | Process craft doctrine |
| [research/README.md](./research/README.md) | Research archive index |

---

*Product surface lock. Update when surface decisions change.*
