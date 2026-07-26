# ADR 002 — kevin-hermes image versioning and (future) intentional releases

**Status:** Accepted  
**Date:** 2026-07-26  
**Deciders:** Matt Overlund  
**Related:** [001-hermes-provisional-factory-host.md](./001-hermes-provisional-factory-host.md) · KEVN-11 (Docker primary / agent-tools monorepo) · Spectral/Wildwood git-cliff practice (pattern reference only)

**Migration note:** When software-factory content moves into agent-tools, this ADR moves with Kevin packaging docs (same decision text).

---

## Context

Kevin’s primary instance is a Docker image built from **agent-tools** (monorepo lock): process pack from **`dist/hermes`** after publish on the runner, host packaging under `hermes/`, image name **`kevin-hermes`**, registry **GHCR**.

We need a versioning policy that:

1. Matches a **single-operator** dogfood with **no external image consumers** today.  
2. Makes **green `main`** the continuous ship unit for the running instance.  
3. Avoids ceremony (semver spam, GitHub Release per merge, mandatory git-cliff).  
4. Still records **when and how** to adopt intentional releases later (rollback freezes, changelog, multi-consumer).

---

## Decision

### 1. Current policy (path of record until intentionally changed)

| Artifact | Policy |
|----------|--------|
| **Primary runtime tag** | `kevin-hermes:main` — always track latest **green `main`** |
| **Immutable build id** | `kevin-hermes:sha-<short>` on every successful main image build |
| **CI** | Checks on **every push**; **image build/push on `main` only** (after checks) |
| **GitHub Releases** | **Not** published per image build (churn without consumers) |
| **Semver git tags** | **Not** required for day-to-day ship |
| **git-cliff / CHANGELOG automation** | **Not** required for E10 / initial monorepo image path |

**Operational release unit:** a commit that lands on `main` and passes CI, producing a new image. That *is* continuous release for the only consumer artifact that matters (the image). It is **not** a GitHub Release product event.

**Rollback / forensics today:** pin compose (or run) to `sha-…` or image digest; history via git log + GHCR tags.

**Runtime update:** `docker compose pull && docker compose up -d` (or equivalent recreate). No mid-session skill pull; no silent git pull of agent-tools on gateway start.

### 2. Future adoption — intentional semver + releases (deferred)

Adopt the following **when at least one trigger is real** (not before):

| Trigger | Example |
|---------|---------|
| Named freeze | Second machine or long-lived host must stay on a known cut for weeks |
| External or multi-consumer image use | Someone else (or CI fleets) pulls by version |
| Human changelog pain | “What changed in process+host packaging since date X?” is frequent and costly |
| Communication need | Announce process IP cuts as release notes |

**Then** introduce (same shape as Spectral/Wildwood, adapted to this repo):

| Piece | Practice |
|-------|----------|
| **Tooling** | git-cliff (`cliff.toml`) from Conventional Commits → `CHANGELOG.md` |
| **Cadence** | **Intentional**, not every merge — operator cuts when a coherent slice is worth freezing |
| **Action** | `workflow_dispatch` and/or push of an annotated tag after cliff bump |
| **Outputs** | Git tag `vX.Y.Z` · image `kevin-hermes:vX.Y.Z` · changelog · **optional** single GitHub Release for that tag |
| **Primary still** | Daily Kevin continues on `:main` unless the operator **chooses** to pin `:v*` |

**Management model (future):** float main for dogfood; freeze only when you decide. No calendar release train required.

Until a trigger fires, **do not** implement cliff/semver/GitHub Releases as part of Docker primary DoD.

### 3. What this does not decide

- Public vs private GHCR package visibility.  
- Exact image repo path under `ghcr.io/<owner>/…`.  
- Whether monorepo live tree layout uses `hermes/docker/` vs other paths (packaging detail).  
- Host still pluggable (ADR-001); this ADR only covers **kevin-hermes** image versioning.

---

## Consequences

### Positive

- Low ceremony matches solo primary + public-but-no-external-consumers.  
- Clear ship signal: green main → new `:main` / `:sha-…`.  
- Future path is written down so we don’t re-litigate “should we semver?” mid-incident.  
- Avoids training the team (or future self) that every push is a GitHub Release.

### Costs / risks

- No friendly version name until freezes exist — use sha/date in notes.  
- Rolling `:main` can surprise if you forget to pin before a risky process change — mitigate with `:sha-…` pin when needed.  
- Deferred cliff means commit message discipline is optional until releases matter; re-introduce Conventional Commits when adopting §2.

### Actions

1. KEVN-11 / monorepo image CI implements **§1 only**.  
2. When a §2 trigger is met, open a small unit: cliff + tag workflow + optional GH Release; amend this ADR status notes if practice diverges.

---

## Alternatives considered

| Alternative | Why not now |
|-------------|-------------|
| Semver + GitHub Release every green main | High churn, no external consumers, empty “product version” theater |
| git-cliff required in E10 | Ceremony without freeze/changelog demand |
| Image-only floating `:main` without `:sha-…` | Harder rollback/forensics; sha tags are cheap |
| Calendar release train (e.g. weekly mandatory v*) | Overfit; intentional cuts are enough later |

---

## References

- KEVN-11 design lock: monorepo agent-tools, image `kevin-hermes`, primary track `main`.  
- Sibling practice: Spectral ADR-012 (git-cliff for CHANGELOG) — **pattern for future §2**, not current obligation.
