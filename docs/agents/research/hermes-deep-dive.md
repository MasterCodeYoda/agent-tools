# Deep investigation: Hermes Agent as factory foundation

**Date:** 2026-07-21  
**Status:** Contender deep-dive (not ADR). Scores under Hybrid weights still provisional.  
**Why this doc:** Hermes leads Hybrid ranking (~91). This is a **build-on investigation**: packaging, multi-channel, coding host, surface fit, policy work, risks, adoption path.  
**Related:** [product-surface.md](../product-surface.md) · [research-stack-paper-map.md](./stack-paper-map.md) · agent-tools process-payload

**Primary sources:** Hermes docs (architecture, skills, security, memory, configuration, quickstart, Slack).

---

## 1. Executive read

Hermes is a **full agent OS** (Nous Research, MIT): one `AIAgent` core serving CLI/TUI, messaging gateway (20+ platforms), ACP editors, cron, batch. It ships **coding-class tools**, **agentskills-compatible process packaging**, **once/session/always approvals**, and **multi-provider models**. That maps unusually well to Hybrid goals: **packaging (W1) + multi-channel (W2) + coding host (W3)**.

It is **not** a blank coding kernel. Defaults include **persistent memory**, **background self-improvement**, and **agent-created skills**. Those are features for a personal assistant product and **policy liabilities** for a software factory with **project disk as SoT** and **process-IP that must not silently mutate**.

**Viability conclusion (investigation, not decision):**  
Hermes is a **strong customize-into-factory path** if you treat it as the host OS and impose a **factory profile** (blank skills baseline, external process pack, write approvals, memory discipline, project bind). It is a **weak path** if you expect zero product gravity or “thin harness only.”

---

## 2. What Hermes actually is (architecture)

### 2.1 One core, many entry points

```text
CLI / TUI ──┐
Gateway ────┼──► AIAgent (run_agent.py)
ACP ────────┤      prompt builder · provider resolve · tool dispatch
Cron ───────┤      compression · session DB
Batch/API ──┘
                 │
                 ├── tools/ (70+ tools, ~28 toolsets)
                 ├── skills (agentskills + hub)
                 ├── memory (MEMORY.md / USER.md + optional providers)
                 └── terminal backends (local | docker | ssh | modal | daytona | singularity)
```

**Design principle that matters for us:** *platform-agnostic core* — Slack and CLI run the same agent loop. That is exactly “communication changes; process does not.”

Docs: [Architecture](https://hermes-agent.nousresearch.com/docs/developer-guide/architecture).

### 2.2 Tool surface (coding-host fitness)

Documented tool families include:

| Family | Capability |
|--------|------------|
| File | `read_file`, `write_file`, `patch`, `search_files` |
| Terminal | Orchestrated shell; 6 backends; process registry |
| Browser / web | Search, extract, browser automation |
| Code execution | Sandboxed `execute_code` |
| Delegation | Subagents / parallel workstreams |
| MCP | Dynamic MCP tool servers |
| Skills | list / view / manage (with gates) |

This is **sufficient host surface for agent-tools-class skills** — unlike a bare skill loader. Per-platform toolsets (`hermes tools`) and `agent.disabled_toolsets` let a **Slack factory bot** run a narrower tool matrix than local CLI.

### 2.3 Profiles (unit of “factory vs personal”)

Profiles isolate **config, memory, skills, sessions, gateway PID**. Docs recommend **not** using a personal profile for Slack team bots.

For us:

| Profile | Purpose |
|---------|---------|
| `factory` (or product name) | Process pack, project disk, strict approvals, Slack |
| optional `personal` | Default Hermes learning/memory if wanted |

This is the natural isolation boundary for team vs personal use.

---

## 3. Mapping to locked product surface

| Surface requirement | Hermes support | Factory customization |
|---------------------|----------------|----------------------|
| Project-bound agent | CWD + AGENTS.md / HERMES.md / CLAUDE.md; progressive subdir AGENTS.md; `terminal.cwd` for gateway | Convention: always launch from project root; AGENTS.md carries project posture; docker mount cwd when sandboxed |
| Fresh conversation each invocation | Possible via `/new`, new session, cron “fresh agent”; **default is long-lived sessions** | Policy: factory CLI entry wraps “new session per invoke” *or* treat session as window only; project state never lives only in transcript |
| Disk lens SoT | File tools write anywhere allowed; planning/runs can live on repo disk | **Enforce** agent-tools layout under project `.agent-tools/`; forbid treating MEMORY.md/session DB as project |
| Multi-model hierarchy | `/model`, multi-provider, fallbacks, auxiliary models (compression/review) | Build hierarchy as config + skills (“orchestrate vs execute model”); not fully first-class product→phase→turn map out of the box |
| Grok-style approvals | **once / session / always / deny**; smart/manual/off; hardline blocklist; `approvals.deny` | Set `approvals.mode: manual` or smart; never YOLO for factory; document allowlist hygiene |
| Ship process pack | External skill dirs, hub taps, bundles, blank slate / opt-out, write_approval | See §4 — this is the strongest Hermes fit |
| TUI first | `hermes` / `hermes --tui` | Skin/SOUL for factory operator; chrome (phase/model/capacity) may need plugin/UI later |
| Channels later | **Gateway first-class** including Slack Socket Mode | Dedicated factory profile + allowlists + channel skill bindings |
| Own product identity | Medium — Hermes brand/OS | Profile + SOUL + optional public rename later; process pack is *your* IP |

---

## 4. Process-IP packaging (W1 deep)

### 4.1 Mechanisms (docs)

| Mechanism | Use for factory |
|-----------|-----------------|
| **agentskills `SKILL.md`** | Portable process units |
| **`skills.external_dirs`** | Point at published agent-tools export / monorepo skills tree **without** copying into Hermes home as SoT |
| **Hub taps** | `hermes skills tap add org/factory-skills` for team install |
| **Bundles** | YAML grouping e.g. `/factory-continue` → continue + runs + personify |
| **Blank slate / opt-out** | `hermes setup` Blank Slate; `hermes skills opt-out`; install `--no-skills` — avoid bundled ML/ops skill pollution |
| **`skills.write_approval: true`** | Stage every `skill_manage` write — process IP not silently patched |
| **Slash commands** | Every skill → `/skill-name` on CLI **and** Slack |
| **Local precedence** | Local `~/.hermes/skills` overrides external same-name skill |

### 4.2 Recommended packaging architecture

```text
agent-tools (SoT, git)
    │  publish / export
    ▼
process-pack (agentskills tree)  ──► private git repo or hub tap
    │
    ├── hermes skills.external_dirs: [path or clone]
    │     OR hermes skills tap add + install
    │
    └── bundles/*.yaml  (operator shortcuts)

Project repo (Spectral, Wildwood, …)
    ├── AGENTS.md          (project posture; hermes loads)
    ├── .agent-tools/      (planning, runs, memory — project disk)
    └── (no second process dialect)
```

**Critical rule:** Hermes home skills for **adapter/glue only**; **agent-tools remains process SoT**. External dir should be a **checkout or published artifact of agent-tools**, not a fork of phase tables.

### 4.3 Agent-tools impedance

| agent-tools reality | Hermes adaptation |
|---------------------|-------------------|
| Dense SKILL.md + progressive `@` references | Map to SKILL.md + `references/`; progressive skill_view |
| Host tools assumed (bash, read, edit, …) | Present via toolsets — enable file + terminal (+ MCP Linear/GitHub) |
| Continue / claim / never invent NEXT | Encode in skill text + AGENTS.md refuse list; not Hermes-enforced SM |
| Runs ledger on disk | Skill instructs append to `.agent-tools/runs/`; hermes does not provide factory ledger natively |
| Personify / conventions overlays | SOUL.md (global identity) + project AGENTS.md + optional skill config |

**Honest gap:** Hermes will not *mechanically* enforce continue’s hard state machine. Fidelity remains **skill + operator discipline + future soft-checks**, same as other hosts—better tools, not magic gates.

### 4.4 Team replication story

| Audience | Install path |
|----------|--------------|
| You | Factory profile + external pack + project AGENTS.md |
| Teammate local | Same profile template (dotfiles / script) + pack checkout |
| Team Slack | Dedicated profile + gateway service + allowlists + channel skill bindings |
| Org control | [Managed scope](https://hermes-agent.nousresearch.com/docs/user-guide/managed-scope) for pinned config if needed |

This is closer to a **product distribution model** than OpenCode “install skills” alone.

---

## 5. Multi-channel / Slack (W2 deep)

### 5.1 Gateway model

- Same AIAgent as CLI  
- Socket Mode Slack — **no public URL** required  
- Full slash commands on Slack (regenerable manifest)  
- Approvals via buttons or `!approve` / `!deny` in threads  
- Per-platform toolsets — narrow tools for team bot  

### 5.2 Factory-relevant Slack controls

| Control | Factory use |
|---------|-------------|
| `SLACK_ALLOWED_USERS` / channel allowlists | Hard boundary |
| Dedicated **profile** for Slack | Isolate memory/skills/secrets from personal CLI |
| `channel_skill_bindings` | Auto-load factory continue / status skills per channel |
| `channel_prompts` | Channel-specific tone (ops vs engineering) |
| `group_sessions_per_user` | Default true — isolate contexts in shared channels |
| `hermes tools` per platform | Slack: fewer destructive tools; CLI: full set |
| Docker/ssh terminal backend on gateway host | Sandbox team bot away from operator laptop secrets |

### 5.3 Autonomy realism

Hermes supports **cron**, **goals**, long-running gateway. Factory “autonomous continue” still needs:

- Named claimable units on disk or PM  
- Human gates for plan/merge where process requires  
- Approvals for dangerous shell  

**Do not expect** “Slack mentions Hermes → fully unattended ship” without process gates. Expect: **drive continue, report, ask approvals, update project disk**.

---

## 6. Multi-model (W4)

| Capability | Notes |
|------------|-------|
| Broad providers | OpenRouter, Anthropic, OpenAI/Codex, xAI, Gemini, local, many others |
| Mid-session `/model` | Operator switch (CLI and gateway) |
| Fallbacks | Provider resilience |
| Auxiliary models | Compression, background review on cheaper models |

**Hierarchy (product → project → phase → turn):** not a single first-class config tree. Achievable via:

- Profile defaults  
- Project AGENTS.md / skill instructions (“use execute model for implement”)  
- `/model` at turn boundaries  
- Possible future config layer you maintain  

Good enough for Hybrid W4 (scored 5); not zero work for your exact hierarchy UX.

---

## 7. Approvals & security (W5)

| Feature | Factory stance |
|---------|----------------|
| once / session / always / deny | Map to Grok tiers |
| `approvals.mode: smart \| manual \| off` | Prefer **manual** or smart; never off for factory |
| Hardline blocklist | Always on (even YOLO) |
| `approvals.deny` globs | Factory-specific bans (e.g. force-push) |
| File write denylist | Protects secrets; pair with project disk paths |
| `HERMES_WRITE_SAFE_ROOT` | Optional sandbox root—careful not to block Hermes home + project |
| Docker backend | Recommended for gateway production |
| Context file injection scan | Protects AGENTS.md loading |

**CLI approval prompt:** once | session | always | deny — aligns with product surface.

---

## 8. Memory & continuity (W6 tension — deepest risk)

### 8.1 What Hermes wants

| Layer | Behavior |
|-------|----------|
| MEMORY.md / USER.md | Injected every session; agent writes proactively |
| Background review | Post-turn may save memory / patch skills |
| session_search | FTS over all past sessions |
| Optional providers | Honcho, Mem0, etc. |

### 8.2 What factory wants

| Layer | Behavior |
|-------|----------|
| planning / session-state / runs | Git-backed project |
| Compound memory | `.agent-tools/memory/` via process |
| Chat | Ephemeral window |
| Process IP | agent-tools only via evolve |

### 8.3 Mitigations (documented knobs)

```yaml
# Factory profile sketch — validate against current schema on install
memory:
  memory_enabled: false          # or true with write_approval only
  user_profile_enabled: false
  write_approval: true

skills:
  write_approval: true
  external_dirs:
    - ${FACTORY_PROCESS_PACK}/skills
  # opt-out bundled skills via setup / hermes skills opt-out

agent:
  disabled_toolsets: []          # optionally disable memory toolset
  # max_turns etc. as needed

approvals:
  mode: manual                   # or smart
  # deny: [...]

terminal:
  backend: docker                # for gateway / team
  # docker_mount_cwd_to_workspace: true when intentional
```

Also: **Blank Slate** setup disables memory capture and skills by default—strong starting point for factory profile.

### 8.4 Residual risk

Even with memory off:

- Session DB still stores conversations (searchable)  
- Compression/summarization may drop project detail if not on disk  
- Users can re-enable learning features  

**Acceptable if** AGENTS.md + skills scream “disk is SoT” and factory profile is the only profile used for product work.

---

## 9. Hybrid score stress-test (Hermes cells)

| Criterion | Prior score | Investigation update | Keep? |
|-----------|-------------|----------------------|-------|
| W1 Packaging | 5 | External dirs, taps, bundles, blank slate, write_approval, slash everywhere | **5** |
| W2 Multi-channel | 5 | Slack Socket Mode, skill bindings, per-platform tools, multi-workspace | **5** |
| W3 Coding host | 5 | Full toolsets; docker isolation | **5** |
| W4 Multi-model | 5 | Broad providers + /model; hierarchy is policy not product | **4–5** (hold 5 if hierarchy-via-skill acceptable) |
| W5 Approvals | 5 | once/session/always/deny + hardline | **5** |
| W6 Disk/project | 3 | Doable; defaults fight; Blank Slate + policy | **3** (or 4 after proven factory profile) |
| W7 Leverage | 3 | Huge surface; monorepo + learning loop tax | **3** |
| W8 Ownability | 3 | Profile/SOUL help; still Hermes OS | **3** |
| W9 TUI | 3 | Capable, not best-in-class coding TUI | **3** |
| W10 Maturity | 4 | Active, large docs, rapid updates; complexity | **4** |

**Weighted total remains ~91** unless W4 drops to 4 → **~88.8** (still #1 under Hybrid).

---

## 10. Risks & non-goals

| Risk | Severity | Mitigation |
|------|----------|------------|
| Process fidelity without hard SM | High product | Skills + continue discipline; evolve from thrash; optional later enforcement tooling |
| Memory/learning pollution | High | Factory Blank Slate; write_approval; disable memory toolset |
| Dual process maintenance | High | External pack from agent-tools only; no Hermes-local skill forks of workflow |
| Monorepo / update churn | Medium | Prefer config/skills/plugins; avoid deep fork; pin updates |
| Nous Portal / tool gateway gravity | Low–Med | Optional; BYOK providers fine |
| Slack bot safety | High | Dedicated profile, allowlists, docker, narrow tools |
| Identity (“Hermes” not your brand) | Low personal | SOUL + private rename later |

**Non-goals for Hermes path:** reimplementing coding tools; dual phase tables; using Hermes bundled skills as process SoT.

---

## 11. Adoption path (summary)

| Phase | Name | Falsifies if… |
|-------|------|----------------|
| **H0** | Paper | — done (this doc) |
| **H1** | Factory profile bootstrap | Local host cannot run process pack + tools + project disk |
| **H2** | Packaging realism | Cannot replicate install for “future you” / teammate |
| **H3** | Slack factory bot | Channel cannot drive process safely with project updates |
| **H4** | Multi-model hierarchy policy | Model routing too painful for daily use |
| **H5** | Decision gate | Overall policy load unacceptable → Eve/pi |

**Horizon map (claimable units):** [roadmap.md](../../.agent-tools/planning/roadmap.md)  
**Runnable detail for H1–H5:** [hermes-factory-runbook.md](../runbooks/hermes-factory.md)

---

## 12. Hermes vs Eve (why investigate Hermes first)

| Dimension | Hermes edge | Eve edge |
|-----------|-------------|----------|
| Packaging maturity | Hub, taps, external dirs, bundles, write_approval | Agent directory as unit; younger |
| Slack | Deep Socket Mode + skill bindings | First-class channels |
| Coding host age | Large tool matrix, multi-backend terminal | Sandbox-first, framework-shaped |
| Memory fight | Heavier defaults | Durable sessions different fight |
| Maturity | Larger product surface, more docs | Beta, Vercel orbit |
| Hybrid score | ~91 | ~80 |

Hermes-first investigation is justified by Hybrid ranking; Eve remains **#2 fallback** if H1–H3 fail or Vercel-shaped product becomes preferable.

---

## 13. Bottom line

1. **Hermes can host the factory product surface** as a customized OS: coding tools, multi-model, approvals, TUI, Slack, process packaging.  
2. **The work is policy + packaging**, not reinventing tools: factory profile, external process pack from agent-tools, write approvals, memory off/gated, project project disk.  
3. **Hard remaining risk:** process **enforcement** (continue SM) stays skill-level; memory/session culture must be actively suppressed.  
4. **Next concrete step:** Phase H1 factory profile bootstrap on one real product repo—not a toy fixture, not full pack migration yet.

---

## Key links

| Topic | URL |
|-------|-----|
| Docs home | https://hermes-agent.nousresearch.com/docs/ |
| Architecture | …/developer-guide/architecture |
| Skills | …/user-guide/features/skills |
| Memory | …/user-guide/features/memory |
| Security | …/user-guide/security |
| Configuration | …/user-guide/configuration |
| Quickstart / Blank Slate | …/getting-started/quickstart |
| Slack | …/user-guide/messaging/slack |
| GitHub | https://github.com/NousResearch/hermes-agent |
