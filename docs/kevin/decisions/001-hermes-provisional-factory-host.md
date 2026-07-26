# ADR 001 — Hermes as factory host (Kevin / lean A)

**Status:** Accepted (adopt)  
**Date:** 2026-07-22 (provisional); **amended 2026-07-24** (build adopt + Kevin v1 locks)  
**Deciders:** Matt Overlund  
**Supersedes:** Informal Hybrid ranking as decision proxy; provisional-only residual posture  
**Related:** [product-surface.md](../product-surface.md) · [kevin-v1.md](../kevin-v1.md) · [hermes-deep-dive](../research/hermes-deep-dive.md) · [hermes-factory runbook](../runbooks/hermes-factory.md) · [pi-swap](../research/pi-swap-vs-hermes.md) · [process-ip-wave5](../research/process-ip-wave5.md)

---

## Context

We already have the software factory **process** in **agent-tools** (prescriptive process, flexible project conventions). The product problem is hosting and automating that control plane so that:

1. Human backlog priority and midstream redirection remain load-bearing.  
2. Automation applies **judgment over the workflow system** — continues when disk guards are green, escalates on a channel when not.  
3. Agent-level conventions can differ from project conventions (e.g. always-PR automation vs local-merge human defaults) **without** a second process dialect.  
4. Personality (personify-class intent) binds to host identity without making the host the product SoT.

**Evidence to date**

| Gate | Outcome |
|------|---------|
| H1–H4 dogfood | PASS — factory profile, process pack export, Slack packaging, multi-model knobs |
| Pre-H5 collab | Lean **(A)** locked |
| J1 judgment vertical | PASS — isolation, always-PR overlay, review evidence, E-MERGE, disk resume (operator-as-controller) |
| J1-bis automated wake | Substrate researched; live wake not yet executed |
| Process IP Wave 5 | Landed in agent-tools (approval boundaries, pre-wake, dated rules, escalate receipts) |
| Coding-loop parity | **PASS (2026-07-24)** — KEVN-6: 3/3 hermes -p kevin tracers (bug/multi-file/recovery) on SF project worktree within ±1 band of Grok Build baseline (Sonnet-class). Evidence: `docs/evidence/kevin-coding-confidence/scorecard.md`. Caveat: project docs/scripts class, not large Spectral-app residual. |
| Stack re-research | **Closed** — pursue Hermes for Kevin v1 without further host bake-offs as blockers |

**Product name / tracking:** Linear team **Kevin** (key **KEVN**); project holds full v1 epic set. Repo directory may remain `software-factory` until rename.

---

## Decision

### 1. Product spine (lean A) — non-negotiable

| Layer | Owner |
|-------|--------|
| Process dialect / claim / gates / continue SM | **agent-tools** (SoT) |
| Project continuity | Project **disk** (`.agent-tools/`, git) |
| Judgment-preserving automation + **operator control plane** | **Product we build/own** (controller + console) |
| Coding tools, multi-model, channel transport, tool approvals | **Host runtime** (pluggable; default Hermes) |

We are **not** building “a Hermes multi-instance product that happens to load agent-tools” (lean B). Hermes capabilities (profiles, gateway, cron, dashboard) are **host substrate** the product may use or wrap.

### 2. Hermes is the **default host** (adopt)

- Default runtime for Kevin v1: Hermes profile **`kevin`** (not named “factory”), managed process skills under `~/.hermes/`, approvals floor, memory off / write_approval, project bind.  
- **Naming:** Do **not** use **factory** for Kevin’s Hermes profile, publish agent, or skill install path. agent-tools already uses **`factory`** for the separate **Factory coding agent** (`~/.factory`). Kevin installs into **hermes** paths only.  
- Historical dogfood used `hermes -p factory`; migrate to **`kevin`** under config-as-code (KEVN-2).  
- **Not** eternal product OS — host remains replaceable if judgment, isolation, coding-parity, or control-plane tax becomes unacceptable (pi/Eve/OpenCode remain documented fallbacks).  
- No further host **research** as a gate; pivots only via written failure notes + epic outcome (e.g. coding-parity fail paths).

### 3. Coding path: **direct** on Hermes (not shell-out)

- Hermes (or successor host) runs the **in-process tool loop** with configured models/subscriptions.  
- **Do not** architect the product as Hermes shelling out to Claude Code / Grok / OpenCode as the execution home.  
- Narrow use of CLIs as *tools* (e.g. `gh`) is fine; foreign coding **apps** as session hosts are not.  
- **Coding-loop confidence** is an explicit **v1 gate** (tracer bullets on real product repos; pass ≈ equitable band vs daily harnesses). Fail paths: tune host → pivot host → shell-out only as last resort with product-surface reopen.

### 4. Models and subscriptions

- Multi-model hierarchy (orchestrate / execute / aux + turn overrides).  
- Use operator-configured subscriptions / pools (including Claude Code path already dogfooded).  
- Differentiator: routing + policy + observability, not a single model brand.

### 5. Config-as-code

- Hermes profile **`kevin`**, model map, approvals, skills path, automation policy, SOUL bind targets — **versioned in this repo** under `hermes/`.  
- Secrets out of git. Apply path documented. Dashboard must not become the only SoT.

### 6. Operator control plane (v1 requirement)

Operator-launched dashboard (or equivalent UX) for the **Kevin Hermes** instance:

| Capability | Required |
|------------|----------|
| Launch path | Documented command/URL, **kevin**-profile scoped |
| Model configuration | Hierarchy / defaults for Kevin agent(s) |
| Subscription / provider attachment | Which credential sources Kevin uses |
| Usage metrics | Tokens/cost/sessions attributable to Kevin/Hermes profile |
| **Usage windows** | Remaining allowance / reset / rate-limit state per attached plan — best available per provider; Claude subscription windows called out as hard; may land as adapter or deep-link if API insufficient |

Prefer Hermes web dashboard / desktop as **substrate**; product owns Kevin policy, config-as-code sync, and provider gaps. UI is not project-disk SoT.

### 7. Channels, wake, judgment (v1 in scope)

All of the following are **in Kevin v1** (epics on the same Linear project), not “research residuals forever”:

| Area | Intent |
|------|--------|
| Unattended wake | Gateway + cron + pre-wake + isolated worktree; claimable-only; no re-drive; no dirty primary; no remote pollution |
| Live Slack | Transport only; same process; Socket Mode / allowlists / escalate delivery |
| Auth packaging | Teammate-installable / non-snowflake secrets story |
| Judgment automation | Operator-as-controller until wake PASSes; then disk-gated continue \| escalate \| idle |
| Merge overlay | Human project defaults (e.g. local-merge) vs automation always-PR — one dialect |

### 8. Process pack distribution (locked 2026-07-24; **amended 2026-07-26** monorepo / Docker primary)

Same class of pipe as other coding agents that consume agent-tools — **not** a Kevin-only export ceremony for laptop agents. **Kevin primary instance is containerized.**

| Rule | Detail |
|------|--------|
| **SoT** | agent-tools (`src/` → publish → `dist/hermes`). No SKILL body fork under live profile homes. |
| **Agent name** | Publish/install target is **`hermes`**, not `factory`. (`factory` remains Factory coding agent → `~/.factory`.) |
| **Laptop / multi-agent** | `./setup.sh` → managed install under `~/.hermes/skills/` (symlink model). Same class as Claude/Grok. |
| **Kevin primary (Docker)** | Image **`kevin-hermes`**: CI/build runs publish, **copies `dist/hermes`** into the image (`/opt/kevin/skills`). Never bake raw `src/`. Profile distribution under `hermes/profile/`. |
| **Kevin profile bind** | Profile **`kevin`** loads managed skills via `external_dirs` (host path or `/opt/kevin/skills` in image). |
| **Updates (laptop)** | Pull agent-tools → re-run `./setup.sh`. |
| **Updates (primary)** | Pull new image (`:main` / `:sha-…`) and recreate container. See [002-kevin-hermes-image-versioning.md](./002-kevin-hermes-image-versioning.md). |
| **Missing skills** | Fail **loudly**. **No** silent `git pull` + setup on Hermes gateway start or unattended wake. |
| **Process content** | Wave 5 ops discipline remains in force once installed / baked. |

**Monorepo (2026-07-26):** Kevin host packaging lives in this repository (`hermes/`, `docs/kevin/`). The separate software-factory repo is retired after migration.

### 9. Personality and conventions

- Portable personify-class intent remains product concern.  
- Host identity (Hermes SOUL on profile **kevin**) = **binding when on Hermes**, not second personality SoT.  
- One process dialect; automation overlays via profile/config/controller.

---

## Kevin v1 destination (horizon)

> **Kevin** is a Hermes-hosted software factory: config-as-code in-repo, process pack wired, operator control plane for models/subscriptions/usage (including windows), deployable/repeatable bring-up, coding-loop confidence gate, unattended wake, Slack transport, and auth packaging — under lean A. Host remains replaceable.

---

## What is still *not* decided here

- Commercial GTM / public brand beyond informal Kevin.  
- Exact control-plane UI implementation (wrap Hermes dashboard vs custom).  
- Full multi-role fleet topology.  
- Whether project chrome (phase/yield) ships in the same control-plane MVP slice or immediately after.

---

## Evidence summary (unchanged dogfood)

| Gate | Outcome | Notes |
|------|---------|-------|
| H1 factory profile | PASS | Blank slate, external pack, real product repo |
| H2 process pack | PASS | Export from agent-tools; no SKILL edits |
| H3 Slack | PASS (reframed) | Packaging; live ops = v1 epic |
| H4 model hierarchy | PASS | Policy + knobs; control plane elevates this |
| Pre-H5 collab | Converged | Lean A |
| J1 judgment vertical | PASS | Operator controller on Spectral worktree |
| J1-bis automated wake | **MVP path (2026-07-24)** | KEVN-7 runbook + kevin-pre-wake; live gateway tick residual |
| Wave 5 process IP | Landed | agent-tools + factory re-export |
| Coding-loop parity | **PASS (repo class)** | KEVN-6 scorecard; large-app residual optional |

---

## Consequences

### Positive

- Clear build path: cleanup → Linear Kevin → epics → roadmap → drive.  
- Host research closed; energy on product spine + deployable factory.  
- Coding risk and control plane are **named** work, not hidden assumptions.  
- Pivot path still cheap if coding-parity or host tax fails.

### Negative / costs

- Hermes policy load (memory off, write_approval, blank skills, deny floor).  
- Process SM still skill-enforced until controller hardens.  
- Control plane + multi-provider usage windows are real product surface.  
- Hermes gravity can re-assert if kevin-profile discipline slips.

### Actions (build sequence)

1. Foundation cleanup (product repo + docs) — done.  
2. Linear team **Kevin (KEVN)** + v1 project + epics — done.  
3. Roadmap active; drive **KEVN-2** onward.  
4. agent-tools: add **hermes** publish/install target in `setup.sh` (KEVN-3).  
5. Default dogfood: `hermes -p kevin` + managed `~/.hermes/skills` (migrate off legacy `factory` profile).

---

## Alternatives considered

| Option | Why not |
|--------|---------|
| Shell-out to coding CLIs as architecture | Contradicts product surface; dual loop / dual SoT; only last-resort fail path |
| Hermes as eternal product OS | Contradicts lean A |
| Delay adopt until coding parity proven | Blocks packaging/control-plane work; gate is in-v1 not pre-decision |
| Pivot to pi/Eve/OpenCode before build | No host falsifier yet; packaging path works; swap analysis is advisory ([pi-swap](../research/pi-swap-vs-hermes.md)) |
| Greenfield own loop first | Highest cost; process already exists |
| Primary pack path = Kevin `export-process-pack` + Source-relative `external_dirs` | Extra ceremony; diverges from Claude/Grok install model; use only as secondary artifact |
| Reuse agent-tools **factory** install for Hermes | Collides with Factory coding agent (`~/.factory`); Kevin uses **hermes** paths only |
| Silent pull+setup on Hermes start / cron | Non-deterministic; unsafe for unattended wake — setup is explicit |

---

## Revision

- **2026-07-22** — Provisional accept after pre-H5 + J1 + J1-bis research.  
- **2026-07-24** — **Adopt** for Kevin build: direct coding, full v1 scope (wake/Slack/auth/control plane), coding-parity gate, config-as-code, process Wave 5; stack re-research closed.  
- **2026-07-24 (later)** — Process pack distribution: agent-tools `setup.sh` → `~/.hermes/skills` (publish agent **`hermes`**); profile **`kevin`**; drop **factory** naming for Kevin; export script secondary; no silent pull on wake.
