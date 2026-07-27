# ADR 004 — Workstation `kevin` CLI and skills distribution

**Status:** Accepted  
**Date:** 2026-07-26  
**Deciders:** Matt Overlund  
**Related:** [003](./003-workstation-vs-isolated-kevin.md) · [002](./002-kevin-hermes-image-versioning.md)

---

## Context

Workstation Kevin needs a path that does not require cloning this monorepo or running multi-agent `./setup.sh`. Historically, Kevin skills were installed into `~/.hermes/skills` via `setup.sh` and wired through profile `external_dirs`. That channel is the wrong product path once a dedicated CLI owns bootstrap.

Isolated Kevin already bakes `dist/hermes` into the image (`/opt/kevin/skills`). Workstation needs an equivalent **derived** package the CLI can fetch and update.

---

## Decision

### 1. Foundational `kevin` CLI (workstation)

The CLI is the primary operator surface for workstation mode. It owns:

| Responsibility | Behavior |
|----------------|----------|
| **Hermes** | Ensure installed / usable (guided or scripted install) |
| **Profile `kevin`** | Ensure applied/updated from packaging; `external_dirs` → Kevin skills root |
| **Skills** | Install/update from **published dist artifact** (not “clone agent-tools”) |
| **Session home** | Current project = git repo (cwd or explicit path)—single-repo session, like other harnesses |
| **Doctor** | Green/red on hermes + profile + skills revision + project root |
| **Start** | Launch Hermes under profile `kevin` for that project |

`hermes/dev.sh` remains **packaging-only**: build `kevin-hermes:local` from this checkout. It is not the workstation product CLI and does not pull GHCR for end users.

### 2. Skills location — not multi-agent `~/.hermes/skills` for Kevin consumers

| Path | Role |
|------|------|
| **Kevin skills root** (e.g. `~/.kevin/skills`) | **Only** supported install target for workstation Kevin process skills (copy from artifact + revision file) |
| **`./setup.sh` → `~/.hermes/skills` for agent `hermes`** | **Legacy for Kevin consumers.** Multi-agent setup may continue for Claude/Grok/Factory/etc.; Kevin product path must not depend on publishing hermes skills into the Hermes user skills directory |
| **Image `/opt/kevin/skills`** | Isolated mode (unchanged); same `dist/hermes` family |

Profile `kevin` must set `external_dirs` to the **Kevin skills root** (CLI sets this on setup/update).

### 3. Dist artifact (CI)

| Piece | Policy |
|-------|--------|
| **Source** | `src/` → publish **dialect** `hermes` → `dist/hermes` → pack **product** `kevin` (see [ADR-005](./005-skills-dialect-vs-product.md)) |
| **Package** | Tarball of skills tree + `.agent-tools-revision` (`publish-agent=kevin`, `render-dialect=hermes`) + manifest |
| **Publish** | GitHub-hosted fetchable artifact on green `main` (Release asset and/or workflow artifact URL pattern—exact channel chosen at implement time; prefer stable download URL for CLI) |
| **Consume** | `kevin setup` / `kevin update` download → extract → copy into Kevin skills root |
| **SoT** | Monorepo remains SoT; artifact is derived (same as Docker bake) |

Maintainer path: local publish/setup for developing skills in-tree remains available; not required for using Kevin.

### 4. CLI install

A small **install script** (or equivalent) puts `kevin` on the user PATH. Machine bootstrap for workstation = install CLI → `kevin setup` → `cd <project> && kevin …`.

---

## Consequences

### Positive

- Workstation dogfood does not require monorepo clone.  
- One dist pipeline feeds CLI and Docker bake.  
- Clear deprecation of hermes→`~/.hermes/skills` as Kevin product path.  

### Costs

- CI + CLI download/auth design for public/private repos.  
- Must stop documenting `setup.sh` as Kevin bring-up.  
- Hermes upstream install still an external dependency the CLI wraps.  

### Actions

1. Implement skills artifact job + CLI `setup`/`update`/`doctor`/start (Linear).  
2. Default-off or remove hermes consumer install from `setup.sh` into `~/.hermes/skills` when Kevin path is live (or document maintainer-only).  
3. Narrative docs: CLI-first workstation path.  

---

## Alternatives considered

| Alternative | Why not |
|-------------|---------|
| Keep `setup.sh` → `~/.hermes/skills` as Kevin path | Couples Kevin to multi-agent install; wrong home; not what CLI/artifact model configures |
| CLI git-clones agent-tools | Heavy, auth/symlink issues; wrong for consumers |
| Skills only inside Docker | Blocks workstation mode |
| Release-only artifacts with semver theater | Premature; main+SHA channel enough (see ADR-002 spirit) |
