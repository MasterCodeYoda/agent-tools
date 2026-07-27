# Research pass: swap Hermes → pi under Kevin v1 trajectory

**Date:** 2026-07-24  
**Status:** Advisory comparison (not a pivot ADR). Host decision remains [ADR-001](../decisions/001-hermes-provisional-factory-host.md) adopt Hermes.  
**Question:** Knowing the locked Kevin trajectory and requirements, what if we swapped the default host to **pi** now?  
**Sources:** Prior stack viability / paper map; pi.dev / earendil-works/pi README; community extensions; Hermes dogfood H1–H5 + Wave 5; product-surface control plane.

---

## 1. Locked requirements this comparison must satisfy

From ADR-001 amend (Kevin v1):

| # | Requirement |
|---|-------------|
| R1 | Lean A — process pack + project disk + product controller/console; host pluggable |
| R2 | **Direct** coding tool loop (not shell-out architecture) |
| R3 | Multi-model + operator subscriptions |
| R4 | Config-as-code in this repo |
| R5 | **Operator control plane** — models, subscriptions, metrics, **usage windows** |
| R6 | Unattended wake (cron/gateway-class) |
| R7 | Live Slack as transport |
| R8 | Auth packaging |
| R9 | Coding-loop confidence gate (equitable band vs daily harnesses) |
| R10 | Process pack (agentskills) external, no dual dialect |
| R11 | Factory isolation (profile/worktree; no dirty primary unattended) |

---

## 2. What each host is (one line)

| Host | Nature |
|------|--------|
| **Hermes** | Full **agent OS**: coding tools + multi-channel gateway + cron + profiles + web/desktop admin + session analytics |
| **pi** | Minimal **coding harness**: core tools (read/write/edit/bash) + multi-provider LLM API + TUI + **extensions/skills packages**; you own product features |

pi’s pitch: *adapt the harness to your workflow*. Hermes’s pitch: *run an autonomous multi-surface agent with packaging and ops built in*.

---

## 3. Requirement-by-requirement scorecard

Scale: **Strong** (mostly present) · **Partial** (build or wire) · **Weak** (major product work) · **Gap** (missing category)

| Requirement | Hermes | pi | Notes |
|-------------|--------|-----|--------|
| **R2 Direct coding loop** | Strong (surface); parity unproven | **Strong** (coding-agent native) | pi may *win* implement feel; both need gate R9 |
| **R9 Coding confidence** | Unknown | Likely better prior for “coding harness parity” | Neither proven on *our* Spectral-class workload |
| **R10 Process pack / skills** | Strong (external_dirs, blank slate, write_approval) | Strong (agentskills + packages) | Both viable; Hermes path already dogfooded (H1–H2) |
| **R3 Multi-model** | Strong | Strong (15+ providers, mid-session switch) | Tie |
| **R4 Config-as-code** | Partial (profile YAML under `~/.hermes`; we version/apply) | **Stronger fit** (models.json, project packages, extension config — designed to own) | pi culture = “your files” |
| **R5 Control plane + usage windows** | **Stronger substrate** (web dashboard, Models page, session analytics; Nous subscription UX) | **Weak core** — no first-party factory admin dashboard; community web UIs / Commander-like tools exist | pi → **build or adopt** control plane; Hermes → **scope + wrap** |
| **R6 Unattended wake** | **Strong** (gateway + cron; J1-bis substrate) | **Weak/Partial** — not a built-in agent OS scheduler; you compose (OS cron + CLI, RPC, or sibling projects) | Largest pi tax for Kevin destination |
| **R7 Slack** | **Strong** (first-class gateway) | **Partial** — `pi-chat` / external channel wiring, not same “one core many transports” story as Hermes | Second-largest pi tax |
| **R8 Auth packaging** | Partial (profiles, auth CLI; Claude pool dogfood) | Partial (provider config; subscription rotation via community packages e.g. multi-pass) | Similar product work either way |
| **R11 Isolation** | Profiles + worktree policy | Process perms = user; containerization docs (Docker/Gondolin) | Hermes profile isolation is more productized |
| **R1 Lean A / replaceable host** | Host gravity higher | **Lower gravity** — easier to “own” | pi better long-term product identity |
| **Approvals** | Built-in once/session/always | Via extensions (examples exist) | Hermes ahead out of box |
| **Language / ops** | Python (+ TS TUI) | TypeScript monorepo | Team preference only |

---

## 4. Trajectory cost if we swap **now**

### What we keep

- agent-tools process IP (Wave 5 included)  
- Product surface, lean A, Kevin destination language  
- Project disk conventions, J1 judgment *contract*  
- GumClaw-inspired policy (portable; host-agnostic)  
- Most research docs (re-label host binding)  

### What we discard or redo

| Asset | Hermes investment | On pi swap |
|-------|-------------------|------------|
| H1 factory profile + blank slate | Done | Redesign “factory package” as pi extensions/skills install |
| H2 export-process-pack → Hermes external_dirs | Done | New publish path (`pi install` packages / project skills layout) |
| H3 Slack packaging | Docs + factory packaging PASS | Rebuild on pi-chat or custom gateway |
| H4 model hierarchy knobs | Documented for Hermes | Remap to models.json + extensions |
| Runbook / factory-wake scripts | Hermes cron-oriented | Rewrite pre-wake to `pi` invoke + OS/scheduler |
| Local `~/.hermes/profiles/factory` | Live | Abandoned or dual-run during migrate |
| J1-bis research (cron/gateway) | Specific to Hermes | New substrate research for wake |
| Control plane plan | Wrap Hermes dashboard | **Greenfield or third-party UI** for models/usage |

**Rough effort sense (order-of-magnitude):**  
swapping now costs **~1–2 “host foundation” horizons** of work we already paid on Hermes packaging + channel/wake substrate — while **buying** better coding-harness alignment and lower product gravity.

### What we do *not* get for free on pi

- Unattended multi-job OS (cron + gateway + delivery)  
- Built-in operator admin for factory profile + subscription windows  
- H1–H4 dogfood evidence transfer (must re-prove packaging + Slack + wake)  

---

## 5. Where pi is *better* for Kevin

1. **Coding-agent center of gravity** — closer to the harness class you already trust for implement quality; R9 may pass faster.  
2. **Ownable product surface** — extensions/packages/themes; less “Hermes memory/learning DNA” policy fight.  
3. **Config-as-code culture** — models, skills, extensions as files/packages map cleanly to repo SoT.  
4. **Lower host marriage** — lean A “host pluggable” is psychologically and technically easier.  
5. **TS ecosystem** if we later want a custom control plane in the same language as many dashboard prototypes.

---

## 6. Where pi is *worse* for Kevin (given *full* v1)

Kevin v1 explicitly includes **wake + Slack + control plane with usage windows**. Against that bar:

| Area | Impact |
|------|--------|
| **Wake** | You re-open “how does unattended continue fire?” — OS cron + `pi -p …`, long-lived service, or another project — **not** solved substrate |
| **Slack** | Channel product is secondary (pi-chat / custom); Hermes already scored packaging PASS |
| **Control plane** | Hermes dashboard is imperfect for Claude windows but **exists**; pi requires building or stitching community UIs + usage adapters from day one |
| **Time-to-deployable multi-surface factory** | Longer on pi if destination stays “full v1” |

If v1 were **coding-only factory CLI + config-as-code + process pack**, pi would look **strictly better**. With **ops OS + control plane + Slack** in the same project, Hermes still optimizes the **critical path**.

---

## 7. Hybrid traps (do not do)

| Anti-pattern | Why |
|--------------|-----|
| Hermes for Slack/wake **and** pi for coding via shell-out | Reopens dual-loop architecture; product surface violation |
| Run both as “equal default hosts” without one SoT | Dual config, dual packs, dual control planes |
| Swap on vibe without R9 evidence | Pays migrate cost without proving coding gain |

**Allowed:** pi as **experimental coding probe** (score R9) while Hermes remains default — same as coding-parity fail path B, without abandoning Hermes wake/Slack work.

---

## 8. Decision matrix (now)

| Situation | Recommendation |
|-----------|----------------|
| Stay on full Kevin v1 destination (wake + Slack + control plane + coding) | **Keep Hermes** default; run coding-parity gate; build control plane on/near Hermes substrate |
| Coding parity **fails** on Hermes after honest gate | Prefer **pivot host to pi (or OpenCode)** under lean A, *or* narrow scope — not shell-out first |
| You cut v1 to “excellent coding factory + config-as-code,” channels later | **Revisit pi as default** — swap cost may be justified before more Hermes ops investment |
| You want max ownable chrome and accept building OS features | pi long-term; accept longer path to wake/Slack |

**Recommendation under current locks:** **Do not swap to pi now.**  
Hermes remains the better **path of least resistance** for the multi-surface v1 you locked. Capture pi as:

1. **Coding-parity alternative host** (fail path B), and  
2. **Long-term product-identity candidate** if control plane + wake become mostly *our* code anyway (at that point Hermes OS value shrinks).

---

## 9. If we *did* swap: minimal re-foundation (sketch)

Not a plan — cost signal only:

1. Factory pi package: skills from agent-tools export, permission extension, model hierarchy.  
2. Repo config: models.json / package manifest as config-as-code.  
3. Control plane: adopt or build dashboard (e.g. community web UI + usage adapters).  
4. Wake: documented OS/service launcher + pre-wake script targeting `pi`.  
5. Slack: pi-chat or gateway service; re-prove escalate delivery.  
6. Re-run H1–H3-class gates + R9 on Spectral worktree.  
7. ADR amend: default host = pi; Hermes archived as dogfood evidence.

---

## 10. Bottom line

```text
Kevin v1 needs:  coding + pack + config-as-code + control plane + wake + Slack

Hermes:  stronger on wake / Slack / admin substrate; coding parity unproven; more host gravity
pi:      stronger coding-harness fit + ownability; weaker wake / Slack / admin; re-pay foundation

Swap now:  high opportunity cost on multi-surface path; only clearly win if coding quality
           is the binding constraint and you accept rebuilding ops OS features.

Stay Hermes:  correct default under locked full v1; keep pi as measured alternative after R9.
```

**No ADR change required** from this pass. Next build step remains foundation cleanup → Linear Kevin → epics (include coding-parity + control plane) → roadmap.

---

## Related

- [ADR-001](../decisions/001-hermes-provisional-factory-host.md)  
- [stack-viability.md](./stack-viability.md) (pi section)  
- [hermes-deep-dive.md](./hermes-deep-dive.md)  
- [product-surface.md](../product-surface.md)  
- [kevin-v1.md](../kevin-v1.md)  

