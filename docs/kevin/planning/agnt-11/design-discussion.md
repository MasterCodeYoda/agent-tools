# Design discussion: AGNT-11 Docker primary deploy surface

Status: **Locked monorepo** (user 2026-07-26)  
Grounded in research: `codebase-research.md`  
Supersedes: software-factory-only `hermes/docker/` pack as primary home

## Current state

- Process SoT: **agent-tools** (`src/` → `dist/<agent>/`).
- Kevin packaging / docs / Linear product: **software-factory** (separate repo).
- Host install: `setup.sh` → symlink `~/.hermes/skills` → local `dist/hermes`.
- No Kevin container image path of record.

## Desired end state

**Monorepo:** Kevin host packaging lives in **agent-tools** next to process IP.

```text
agent-tools/   (public, stays MasterCodeYoda/agent-tools or current remote)
  src/                 process IP (untransformed SoT)
  dist/                published trees (hermes, claude, …) — image build consumes dist/hermes
  hermes/              Kevin host packaging (from software-factory)
    profile/           kevin config-as-code
    docker/            Dockerfile, compose, entrypoint for image kevin-hermes
  setup.sh             laptop multi-agent install (unchanged class)
  .github/workflows/   checks on every push; image build on main
```

**Image:** `ghcr.io/<owner>/kevin-hermes`  
**Primary track:** always **`main`** (mutable tag + digest).  
**Process in image:** build runner runs `setup.sh` (or publish hermes) then **copies `dist/hermes`** into the image — **never** raw `src/` (Hermes-specific transforms must land).  
**Runtime update:** `docker compose pull && up -d` (no mid-session skill pull).  
**software-factory:** migrate useful content → agent-tools → **delete repo**.

## Patterns found (accept / reject)

| Pattern | Verdict | Notes |
|---------|---------|-------|
| Bake from **`dist/hermes`** after publish on runner | **accept** | User lock; src is untransformed |
| Link image to raw `src/` | **reject** | Misses Hermes markup transforms |
| Dual-repo compose in software-factory | **supersede** | Monorepo |
| Host skills bind as primary | **reject** | Laptop-shaped; dangling symlinks in containers |
| Silent git pull on gateway start | **reject** | Restart/repull image only |
| Image name `kevin-hermes` | **accept** | Room for later `kevin-<host>` |
| Float **`main`** as primary instance tag | **accept** | User lock |
| git-cliff + semver now | **reject for E10** | Deferred — ADR-002 |
| GHCR for registry | **accept** | Public agent-tools → public image simplest |

## Resolved decisions (user 2026-07-26)

| # | Topic | Lock |
|---|--------|------|
| — | Topology | **Monorepo into agent-tools** |
| 1 | Canonical home | Stay **agent-tools**, public as today |
| 2 | software-factory | **Delete** after content/docs migrated |
| 3 | Image name | **`kevin-hermes`** (host-qualified for future ports) |
| 4 | Primary track | **Always track `main`** |
| 5 | CI | **Checks on every push**; **image build on `main` only** |
| — | Skills source for image | **`dist/hermes` after setup/publish on runner** |
| — | Versioning | **`:main` + `:sha-…` only** now; cliff/semver/GH Releases deferred — [ADR-002](../../../docs/decisions/002-kevin-hermes-image-versioning.md) |

### Versioning (locked 2026-07-26)

| Artifact | Policy |
|----------|--------|
| **Runtime primary** | `kevin-hermes:main` — every green `main` is the ship unit (**image only**) |
| **Immutable** | `kevin-hermes:sha-<short>` on every main image build |
| **GitHub Releases / semver / git-cliff** | **Deferred** until freeze/changelog/multi-consumer triggers |

**Future:** intentional semver + optional GH Release + git-cliff; operator-cut freezes, not every push. Full text: **[ADR-002](../../../docs/decisions/002-kevin-hermes-image-versioning.md)**.

## System flow

```text
push (any branch) → CI checks (publish dry-run / tests / lint)
push main (green) → setup/publish hermes → docker build (FROM hermes-agent + dist/hermes + hermes/profile)
                 → push ghcr.io/.../kevin-hermes:main and :sha-…

operator: compose image kevin-hermes:main
          volumes: Hermes data + project repo bind
          update: pull + recreate
```

## Requirements impact (replaces prior SF-local pack ACs)

Must reframe AGNT-11 (or successor) around:

1. Migrate Kevin packaging/docs/scripts into agent-tools `hermes/` (+ docs home).  
2. Dockerfile/compose for **kevin-hermes**; build uses **dist/hermes** post-setup.  
3. GHCR publish on main (`:main` + `:sha-…`); checks on all pushes; no GH Releases in E10.  
4. ADR-002 records future intentional semver/releases (not E10 build work).  
5. Path-of-record runbook in agent-tools; Desktop dogfood against GHCR image.  
6. software-factory content migrated; repo deleted.  
7. ADR-001 §8 amend: Kevin primary = image from agent-tools; laptop setup.sh remains for other agents.

## Deliberately undecided (plan/execute)

- Exact agent-tools tree layout for migrated SF docs (e.g. `docs/kevin/` vs top-level).  
- Public vs private GHCR package (repo is public → public image is simplest).  
- Whether release is fully automated on schedule or human-dispatched.  
- Dashboard default on/off in compose.  
- Migration sequencing (big-bang PR vs phased).  

---
Updated: 2026-07-26 monorepo lock
