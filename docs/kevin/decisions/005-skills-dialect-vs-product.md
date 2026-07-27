# ADR 005 — Skills dist: render dialect vs product pack

**Status:** Accepted  
**Date:** 2026-07-27  
**Deciders:** Matt Overlund  
**Related:** [001](./001-hermes-provisional-factory-host.md) · [004](./004-workstation-cli-and-skills-distribution.md)

---

## Context

`tools/publish-skills.sh` emits `dist/<agent>/skills/` where `<agent>` is a **render dialect** (how `src/` is rewritten for a skill loader: claude, grok, factory, hermes, …). Kevin’s product channel already packs that tree into **`kevin-skills`** and installs under `~/.kevin/skills`, but revision/manifest still said `publish-agent=hermes`.

With a second Hermes-based product identity (**Jarvis**) that deliberately does **not** consume the process pack, naming the factory pack after the **host** is a misnomer: Hermes profile ≠ process-pack consumer.

---

## Decision

### Two axes

| Axis | Examples | Meaning |
|------|----------|---------|
| **Render dialect** | `hermes`, `claude`, `factory`, … | Markup/layout for a runtime skill loader (`publish-skills --agents <dialect>`) |
| **Product** | `kevin`, (future `jarvis`), multi-agent maintainer | Who installs which corpus / channel / skills root |

### Kevin product pack

| Step | Behavior |
|------|----------|
| Dialect | `publish-skills --agents hermes` → `dist/hermes/skills` (unchanged path in this decision) |
| Product stamp | Pack/image revision: `publish-agent=kevin` + `render-dialect=hermes` |
| Channel | Rolling release tag `kevin-skills` (unchanged) |
| Install root | `~/.kevin/skills` (workstation) / `/opt/kevin/skills` (isolated image) |

### Non-Kevin Hermes

- Multi-agent `./setup.sh` install into `~/.hermes/skills` remains a **dialect=hermes** maintainer path — **not** the Kevin product channel.  
- **Jarvis** (Hermes profile, non-factory): **no** process pack as product path. **Jarvis product pack** is implemented separately (`tools/pack-jarvis-skills.sh`, stamp `publish-agent=jarvis`, image bake `/opt/jarvis/skills`). Kevin pack **filters out** `jarvis*` skill dirs so products do not cross-contaminate.

### Explicit non-goals (this decision)

- Renaming `dist/hermes` → `dist/kevin` (optional later; high churn).  
- Changing Hermes markup rules.  
- Loading Kevin process pack onto Jarvis (still forbidden).

---

## Consequences

- Operators and doctor can tell **product** (kevin) from **loader dialect** (hermes).  
- New Hermes profiles are not implied consumers of the factory pack.  
- Legacy `publish-agent=hermes` under Kevin skills roots is treated as **legacy stamp** until the next `kevin update`.

---

## Alternatives considered

| Alternative | Why not |
|-------------|---------|
| Document-only | Leaves revision/manifest lying; Jarvis reopens the bug |
| Rename dialect `hermes` → `kevin` only | Collapses dialect and product; breaks multi-agent hermes install story |
| Full `dist/` re-layout now | Cost without extra product clarity beyond stamps + docs |
