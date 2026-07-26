# Kevin model hierarchy

**Profile:** `hermes -p kevin` only  
**Control plane:** [docs/runbooks/kevin-control-plane.md](../docs/runbooks/kevin-control-plane.md)  
**Config-as-code:** [hermes/profile/config.yaml](../hermes/profile/config.yaml)

## Product hierarchy → Hermes knobs

Outer → inner wins unless policy says otherwise:

```text
product defaults (this doc + hermes/profile)
  → user / profile (~/.hermes/profiles/kevin)
    → project (AGENTS.md, cwd)
      → phase / track (skill guidance)
        → this-turn override (/model, -m)
```

| Layer | Kevin practice on Hermes |
|-------|--------------------------|
| **Product** | This document + versioned `hermes/profile/config.yaml` |
| **Profile** | `~/.hermes/profiles/kevin/config.yaml` `model.*` + `auxiliary.*` + optional fallbacks |
| **Project** | Product repo `AGENTS.md` may restate phase→model hints; disk artifacts remain work SoT |
| **Phase** | Skills (continue/plan/execute) may *recommend* roles; they do not hard-lock providers |
| **Turn** | CLI/TUI: `/model` or `hermes -p kevin -m … --provider …` |

Hermes does **not** ship a first-class phase→model tree. Hierarchy is **policy + knobs**.

## Role map (defaults)

| Role | When | Default (Anthropic path) | Rationale |
|------|------|--------------------------|-----------|
| **Orchestrate** | status, continue, plan, review judgment | `claude-opus-4-6` (or Sonnet if cost-bound) | Long-context process fidelity |
| **Execute** | implement, tests, patch loops | `claude-sonnet-4-5` | Strong coding; cheaper/faster than Opus |
| **Auxiliary** | compression, titles, light side tasks | `claude-haiku-4-5` | Side tasks must not bill like main chat |
| **Fallback** | primary rate-limit / outage | optional second provider via `hermes fallback add` | Resilience |

Shipped profile defaults (execute-lean):

```yaml
model:
  provider: anthropic
  default: claude-sonnet-4-5

auxiliary:
  compression:
    provider: anthropic
    model: claude-haiku-4-5
    reasoning_effort: low
  title_generation:
    provider: anthropic
    model: claude-haiku-4-5
```

Change policy in **git** `hermes/profile/config.yaml`, then `./scripts/apply-kevin-profile.sh --force`.  
Dashboard edits under `~/.hermes/profiles/kevin/` are **local overrides** until re-apply.

## Operator practice

```bash
# Control plane (config / keys / sessions UI)
./scripts/kevin-control-plane.sh

# Profile default (CLI)
hermes -p kevin model

# One-shot role switch
hermes -p kevin --provider anthropic -m claude-opus-4-6 -z "…"
hermes -p kevin --provider anthropic -m claude-sonnet-4-5 -z "…"

# Mid-session
/model
/model claude-sonnet-4-5

hermes -p kevin fallback list
```

## Anti-patterns

- Using **personal default** Hermes profile for Kevin work
- Leaving auxiliary on Opus
- Expecting skills alone to enforce model choice
- Editing only the live profile and never updating git SoT (permanent UI drift)

## Legacy

Historical H4 dogfood used `hermes -p factory`. See [factory-model-hierarchy.md](./factory-model-hierarchy.md) pointer.
