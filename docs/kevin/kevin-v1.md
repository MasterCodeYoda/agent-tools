# Kevin v1 — destination, scope, and residual DoD

**Status:** Active — Linear team **Kevin** (`KEVN`)  
**Updated:** 2026-07-24  
**Decision SoT:** [decisions/001-hermes-provisional-factory-host.md](./decisions/001-hermes-provisional-factory-host.md)  
**Product contract:** [product-surface.md](./product-surface.md)  
**Project:** [Kevin v1 — Hermes factory foundation](https://linear.app/overlund-media/project/kevin-v1-hermes-factory-foundation-86a25c543642)  
**Roadmap:** [../.agent-tools/planning/roadmap.md](../.agent-tools/planning/roadmap.md)

Linear is **status SoT** for epics. This file holds destination + offline DoD.

---

## Destination

> **Kevin** is a Hermes-hosted software factory: config-as-code in-repo, process pack wired, operator control plane for models/subscriptions/usage (including windows), deployable/repeatable bring-up, coding-loop confidence gate, unattended wake, Slack transport, and auth packaging — under lean A. Host remains replaceable.

---

## Epics (Linear)

| ID | Epic | Status |
|----|------|--------|
| [KEVN-1](https://linear.app/overlund-media/issue/KEVN-1) | E0 Foundation | **Done** |
| [KEVN-2](https://linear.app/overlund-media/issue/KEVN-2) | E1 Config-as-code | **Done** |
| [KEVN-3](https://linear.app/overlund-media/issue/KEVN-3) | E2 Process pack | **Done** |
| [KEVN-4](https://linear.app/overlund-media/issue/KEVN-4) | E3 Control plane | **Done** |
| [KEVN-5](https://linear.app/overlund-media/issue/KEVN-5) | E4 Deployable bring-up | **Done** |
| [KEVN-6](https://linear.app/overlund-media/issue/KEVN-6) | E5 Coding-loop confidence | **Done (PASS)** |
| [KEVN-7](https://linear.app/overlund-media/issue/KEVN-7) | E6 Unattended wake | **Done (MVP)** |
| [KEVN-8](https://linear.app/overlund-media/issue/KEVN-8) | E7 Slack live | **Done** (packaging; live residual) |
| [KEVN-9](https://linear.app/overlund-media/issue/KEVN-9) | E8 Auth packaging | **Done** |
| [KEVN-10](https://linear.app/overlund-media/issue/KEVN-10) | E9 Controller / project chrome | **Done** |

Order: see roadmap notation.

---

## Architecture locks (summary)

| Lock | Choice |
|------|--------|
| Spine | Lean A — agent-tools + project disk + product controller/console; host pluggable |
| Host | Hermes default (not eternal OS) |
| Profile / install name | Hermes profile **`kevin`**; skills install under **`~/.hermes/`** via agent-tools **`hermes`** target — **not** `factory` |
| Coding | **Direct** tool loop; not shell-out to coding apps |
| Coding risk | v1 **confidence gate** (KEVN-6) |
| Process pack | agent-tools SoT; **`setup.sh` → `~/.hermes/skills`**; export script secondary; Wave 5 in force |
| Control plane | Operator dashboard (KEVN-4) |
| Channels | Slack = transport (KEVN-8) |
| Merge | Human defaults vs automation always-PR overlay — one dialect |

**Not in v1:** GTM/naming perfection, multi-domain employee scope, dual process dialect, host re-research as blocker.

---

## Residual DoD (offline; also on epic descriptions)

### Unattended wake (KEVN-7)

1. Gateway under **kevin** profile only (not personal default; not legacy `factory`).  
2. Cron workdir = isolated worktree — never dirty primary.  
3. Claimable-only; never invent NEXT.  
4. Approvals fail-closed for unattended.  
5. await_user / E-MERGE: deliver once; no re-drive.  
6. No long-lived remote pollution.  
7. Project disk + runs evidence.  
8. `scripts/factory-wake/kevin-pre-wake.sh` green before wake (worktree required).  

Path of record: [runbooks/kevin-unattended-wake.md](./runbooks/kevin-unattended-wake.md).

### Control plane MVP (KEVN-4)

1. Documented factory-scoped launch.  
2. Model hierarchy config.  
3. Subscription/provider attachment.  
4. Usage metrics for factory.  
5. Usage windows best-available; Claude windows explicit (adapter/deep-link OK).  
6. Config-as-code sync story.

### Coding-loop confidence (KEVN-6)

1. Same model class as daily harness.  
2. ≥2–3 real product worktree tasks.  
3. Scores within ~1 band of baseline.  
4. Fail paths: tune → host pivot → shell-out last.

---

## Dogfood already PASS

H1 profile · H2 process pack · H3 Slack packaging · H4 model knobs · J1 judgment · Wave 5 process IP · ADR adopt · **KEVN-1 foundation cleanup**.

---

## Process pack install / update (primary)

```bash
# After agent-tools changes (or on a new machine):
cd ~/Source/OMG/agent-tools && ./setup.sh
# Installs managed skills into ~/.hermes/skills (once hermes target lands in setup)
# Hermes profile kevin loads that path — no daily Kevin export required
```

**Secondary** (offline/CI artifact only): `./scripts/export-process-pack.sh` in this repo.

See ADR-001 §8 (process pack distribution).
