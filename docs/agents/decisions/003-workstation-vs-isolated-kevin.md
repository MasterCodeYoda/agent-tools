# ADR 003 — Workstation Kevin vs Isolated Kevin

**Status:** Accepted  
**Date:** 2026-07-26  
**Deciders:** Matt Overlund  
**Related:** [001](./001-hermes-provisional-factory-host.md) · [002](./002-kevin-hermes-image-versioning.md) · [004](./004-workstation-cli-and-skills-distribution.md)

---

## Context

We built monorepo packaging and a Docker image (`kevin-hermes`) as if container isolation were the primary path for using Kevin. Capability of **agent + process IP** as a day-to-day coding agent is not yet proved on real product work. Docker is a strong isolation/deploy story but a poor first lab for effectiveness: clean-room Linux vs a developer’s configured workstation stack.

We need durable product language for two permanent modes—not a temporary “Track A then migrate to Docker” ladder.

---

## Decision

### 1. Two permanent modes

| Mode | Name | Runtime | Project home | When |
|------|------|---------|--------------|------|
| **Workstation Kevin** | Coding agent on the developer machine | Host Hermes, profile **`kevin`** | **Single git repo** as session home (cwd / CLI project root)—same pattern as other coding harnesses | Default for dogfood and proving capability |
| **Isolated Kevin** | Sandboxed / remote-capable host | Container image **`kevin-hermes`** (GHCR / local build via `hermes/dev.sh`) | Container-side trees (volume or mounts); clean-room baseline | When operator wants isolation or remote execution |

These are **not** sequential. Workstation mode does **not** “graduate into” Docker. Operators choose isolated mode when they want sandbox/remote properties.

### 2. Path of record for capability dogfood

Until Kevin is effective as a coding agent (operator-driven dogfood), **workstation mode** is the path of record for day-to-day use and development of process/CLI experience.

Isolated mode remains **real capital** (image, multi-arch GHCR, profile bake, `dev.sh`) and is documented as optional / later provision-DX work—not deleted.

### 3. Product naming (do not use Track A/B)

| Prefer | Avoid |
|--------|--------|
| Workstation Kevin / Isolated Kevin | Track A / Track B |
| `kevin` CLI (workstation) | Overloading packaging scripts as the product CLI |
| `hermes/dev.sh` (build image from this monorepo) | Calling packaging scripts the primary “run Kevin” UX |

### 4. Isolated mode honesty

Isolated Kevin starts from a **clean environment** analogous to onboarding a new developer machine. Bind-mounting a host repo does **not** import the host toolchain. Full seamless provision of that environment is a **future** work unit.

---

## Consequences

### Positive

- Capability proof uses the same conditions as other harnesses (host stack + one repo).  
- Isolation remains available without forcing it as the effectiveness gate.  
- Clear CLI vs packaging split.

### Costs

- Two modes to document and maintain.  
- Isolated provision/DX deferred—must not silently regress into “Docker is broken.”  

### Actions

1. ADR-004: workstation CLI + skills dist (no `setup.sh` → `~/.hermes/skills` for Kevin consumers).  
2. Linear: workstation CLI + skills artifact as NEXT; isolated provision later; reshape AGNT-11 packaging outcome.  
3. Narrative rewrite of `hermes/` docs (workstation first).  

---

## Alternatives considered

| Alternative | Why not |
|-------------|---------|
| Docker-only primary | Blocks capability proof; conflates isolation with coding-agent DX |
| Workstation only forever | Leaves no path to sandbox/remote factory host |
| Temporary “host then always Docker” | Rejected: workstation remains a first-class permanent mode |
