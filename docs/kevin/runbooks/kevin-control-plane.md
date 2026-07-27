# Runbook: Kevin operator control plane (E3 / AGNT-4)

**Status:** Active MVP  
**Substrate:** Hermes web dashboard (`hermes dashboard`)  
**Profile:** `kevin` only  
**Related:** [kevin-v1 control plane DoD](../kevin-v1.md) · [ADR-001 §6](../decisions/001-hermes-provisional-factory-host.md) · [kevin-model-hierarchy](../../packs/kevin-model-hierarchy.md) · [hermes/profile](../../hermes/profile/) · auth packaging [kevin-auth-packaging.md](./kevin-auth-packaging.md) · project chrome / judgment [kevin-controller.md](./kevin-controller.md)

---

## Intent

Operator-launched surface to configure models/providers and observe usage for the **Kevin** Hermes instance — without personal-profile bleed, and without replacing process SoT (agent-tools / disk).

MVP uses Hermes as **substrate**. **Project chrome** (phase / yield / claimable decision) is a separate CLI: [kevin-controller.md](./kevin-controller.md) (`./scripts/kevin-controller.sh`) — not this dashboard.

---

## 1. Launch (kevin-scoped)

### Preconditions

- [ ] Hermes installed  
- [ ] Profile kevin applied: `./scripts/apply-kevin-profile.sh`  
- [ ] Process skills installed: agent-tools `./setup.sh`  

### Recommended

```bash
cd /path/to/software-factory
./scripts/kevin-control-plane.sh
# optional:
./scripts/kevin-control-plane.sh --no-open --port 9120
./scripts/kevin-control-plane.sh --status
./scripts/kevin-control-plane.sh --stop
```

Wrapper runs:

```bash
hermes -p kevin dashboard --isolated
```

**`--isolated`** starts a dashboard server **scoped to the kevin profile**, instead of attaching to the machine-level server that can preselect other profiles. That is the anti-bleed control.

### Alternatives

| Surface | Command | Notes |
|---------|---------|--------|
| Web dashboard (primary) | `hermes -p kevin dashboard --isolated` | Config, keys, sessions |
| Desktop app | `hermes -p kevin desktop` | Heavier; optional |
| Headless backend | `hermes -p kevin serve --isolated` | No browser UI |

Bind defaults to `127.0.0.1` (local). Do not expose publicly without auth.

---

## 2. Model hierarchy

Policy: [packs/kevin-model-hierarchy.md](../../packs/kevin-model-hierarchy.md)

| Role | Default (Anthropic) | Where set |
|------|---------------------|-----------|
| Orchestrate | opus (or strong sonnet) | Operator practice + `/model` |
| Execute | sonnet (profile default) | `hermes/profile/config.yaml` → live profile |
| Aux | haiku | `auxiliary.*` in same config |

In the dashboard: use Kevin profile’s model/provider settings. Prefer changing **git** policy then re-apply for durable defaults.

---

## 3. Subscription / provider attachment

**Portable fill steps (path of record):** [kevin-auth-packaging.md](./kevin-auth-packaging.md) — secret inventory (names only), Path A API keys, Path B OAuth, second-operator smoke, never-copy / never-blind-overwrite guardrails.

**Visibility (best available) — surfaces only; do not re-own the env inventory here:**

| What | Where |
|------|--------|
| API keys / provider auth | Dashboard → profile kevin env/auth; or `~/.hermes/profiles/kevin/.env` + `auth.json` |
| Active model/provider | `hermes -p kevin status` or dashboard model panel |
| Subscription-style OAuth (e.g. Claude Code pool) | `hermes -p kevin auth …` / Hermes auth sources (see auth packaging runbook + Hermes docs) |

Kevin does **not** invent a second credential store. Product gap: richer “which pool is attached” chrome may land later; MVP = Hermes surfaces + linked packaging runbook.

**Never** commit real keys from the UI into git.

---

## 4. Usage metrics

| Source | Scope | Notes |
|--------|-------|-------|
| In-session `/usage` | Current chat | Tokens for this conversation |
| Dashboard sessions | Profile sessions when isolated | Prefer kevin-isolated dashboard |
| Provider billing consoles | Account-level | Not Hermes-native rollups |

Hermes does not ship a full multi-provider cost warehouse. Treat metrics as **best-available**.

---

## 5. Usage windows

| Provider | Window visibility (MVP) |
|----------|-------------------------|
| **Claude / Anthropic** | [Anthropic Console](https://console.anthropic.com/) / Claude account usage UI — **explicit deep-link**; no first-party scrape required for MVP |
| OpenAI | Provider dashboard / billing |
| OpenRouter | OpenRouter usage page |
| xAI | Provider console |
| Others | Document “unknown / check provider” |

If a provider API later exposes remaining quota cleanly, adapters can attach without changing process SoT.

---

## 6. Config-as-code sync story

**Path of record (Kevin + Jarvis):** [multi-agent-config-lanes.md](./multi-agent-config-lanes.md) — three lanes (policy / secrets & bindings / adaptive state), promotion rules, unattended policy-mutation deny, and **instance topology** (Kevin dual install OK; Jarvis single remote only).

```text
git: hermes/profile/     = policy SoT (versioned)     ─┐
         │                                              │  three-lane doctrine
         ▼  ./hermes/scripts/apply-kevin-profile.sh     │
~/.hermes/profiles/kevin/  = live profile               │
  · secrets (.env, auth.json)     preserved on apply    │
  · adaptive state (if any)       preserved on apply    │
  · policy (config.yaml)          reset only with       │
         │                          --force-config      │
         ▼  dashboard / hermes config edit              │
local policy edits = experiments until promoted to git ─┘
```

| Direction | How |
|-----------|-----|
| **SoT → live (policy)** | Edit `hermes/profile/*` in git → apply (`--force` / `--force-config` when resetting policy) |
| **Secrets** | Live profile only; apply **preserves**; never commit values — [kevin-auth-packaging.md](./kevin-auth-packaging.md) |
| **Live policy → SoT** | Manual promote via PR only; **never** copy secrets |
| **UI-only tweak** | OK for experiments; re-apply from git before treating policy as shared |

**Rule:** UI must not become the only SoT. Control plane substrate is not continuity storage for process.

---

## Acceptance checklist (AGNT-4)

- [ ] Kevin-scoped launch documented + wrapper works  
- [ ] Hierarchy pack is kevin-named and matches profile defaults  
- [ ] Providers/auth visibility path documented  
- [ ] Metrics path documented (best-available)  
- [ ] Claude windows deep-link documented  
- [ ] Sync story documented  

---

## Out of scope here

- Custom React control console (AGNT-10)  
- Unattended wake (AGNT-7)  
- Scraping provider quotas into a product database  
- Dual process dialect in the dashboard  
