---
project: kevn-docker-primary-deploy
work_item: KEVN-11
requirements_source: pm
decomposition: deliverable-partition
status: approved
updated: 2026-07-26
blocks: []
blocked_by: []
parallelizable_with: []
execution_home: agent-tools
donor_repo: software-factory
---

# Implementation Plan: KEVN-11 — agent-tools monorepo + kevin-hermes image

## Approach

Make **agent-tools** the sole home for Kevin process IP **and** Hermes host packaging. Build and publish **`kevin-hermes`** to GHCR from `main` after checks. Image content bakes **`dist/hermes`** (publish on the runner — never raw `src/`). Primary instance tracks **`main`** (+ immutable **`sha-…`**). Migrate useful software-factory content into agent-tools, then **delete** software-factory.

No git-cliff / semver / GitHub Releases in this unit ([ADR-002](../../../docs/decisions/002-kevin-hermes-image-versioning.md)).

## Research grounding

- **Codebase research:** `codebase-research.md` (SF apply hardcodes `$HOME/.hermes`; symlink install; no Docker pack)
- **agent-tools facts:** `setup.sh` + `tools/publish-skills.sh` already publish `hermes`; install is symlink-to-dist (laptop); tests under `tests/publisher`, `tests/doclint`; workflows dir exists
- **Discard research if:** Hermes image layout or `dist/hermes` publish agent id changes

## Design

- **Design discussion:** `design-discussion.md` — **Locked monorepo** (2026-07-26)
- **ADR-002:** image versioning current + future intentional releases
- **Confirm:** monorepo + `kevin-hermes` + `main` track + dist/hermes bake + SF delete

## Structure outline

| Phase | Deliverable | Verify before next |
|-------|-------------|--------------------|
| 0 | Migration map + ADR/docs locks in SF (donor) | Checklist of paths to move / drop / rewrite |
| 1 | agent-tools `hermes/profile` + docker skeleton | Tree exists; profile policy intact; no secrets |
| 2 | Dockerfile + materialize `dist/hermes` | Local `docker build` has skills + profile; not src |
| 3 | Compose + env example + init/entrypoint | `compose config`; project bind + data volume |
| 4 | CI: checks all pushes; image on main → GHCR | Workflow green; tags `main` + `sha-…` |
| 5 | Runbooks + ADR-001 §8 amend (in agent-tools) | Path of record is image; host setup secondary |
| 6 | Migrate remaining SF docs/evidence; delete SF | SF empty of SoT; archive or delete remote |

**Dependency:** 0 → 1 → 2 → 3 → {4 ∥ 5 docs early} → 4 evidence → 6 last.

## Plan-time defaults (execute unless blocked)

| Topic | Choice |
|-------|--------|
| GHCR image | `ghcr.io/mastercodeyoda/kevin-hermes` (match agent-tools owner; adjust if remote owner differs) |
| Visibility | **Public** package (public repo) |
| Docs home in agent-tools | `docs/kevin/` for product/runbooks/ADRs migrated from SF |
| Dashboard in compose | **Off** by default |
| Terminal | `local` in-container |
| Project mount | `KEVIN_PROJECT_ROOT` → `/workspace` |
| Hermes data | `KEVIN_HERMES_DATA` → `/opt/data` |
| Skills in image | `/opt/kevin/skills` (copy of `dist/hermes/skills` + revision file) |
| Profile apply | entrypoint/init: install/update `kevin` from `/opt/kevin/profile` or baked copy; point `external_dirs` at `/opt/kevin/skills` |
| SF delete | After migrate + handoff rewrite; operator confirms remote delete |

## Intended changes

### agent-tools (execution home)

```text
hermes/
  profile/           # from software-factory/hermes/profile
  docker/
    Dockerfile
    compose.yaml
    .env.example
    entrypoint.sh    # or document image CMD + init script
    README.md
docs/kevin/          # migrated handoff, runbooks, ADRs 001/002, product surface, v1
.github/workflows/
  ci.yml             # existing/expanded checks on all pushes
  kevin-hermes-image.yml  # main only: publish → build → push
```

### Dockerfile (intent)

```dockerfile
# build stage: publish hermes only
FROM … AS publish
COPY . /src
WORKDIR /src
RUN tools/publish-skills.sh --agents hermes   # or setup subset
# runtime
FROM nousresearch/hermes-agent:…
COPY --from=publish /src/dist/hermes/skills /opt/kevin/skills
COPY hermes/profile /opt/kevin/profile
# entrypoint: ensure profile kevin, external_dirs=/opt/kevin/skills, gateway
```

### Compose (intent)

```yaml
services:
  kevin:
    image: ghcr.io/mastercodeyoda/kevin-hermes:main
    volumes:
      - ${KEVIN_HERMES_DATA}:/opt/data
      - ${KEVIN_PROJECT_ROOT}:/workspace
    working_dir: /workspace
    # gateway run under profile kevin
```

### CI (intent)

- **All pushes/PRs:** publisher tests, doclint as already used, hermes publish dry-run if cheap  
- **main (after checks):** build image, push `:main` and `:sha-${GITHUB_SHA::7}`  
- Permissions: `packages: write`  
- **No** GitHub Release job  

### software-factory (donor → delete)

| Move to agent-tools | Disposition |
|---------------------|-------------|
| `hermes/profile/**` | → `hermes/profile/` |
| Kevin runbooks / ADR 001–002 / product-surface / kevin-v1 / handoff | → `docs/kevin/` (paths rewritten) |
| `scripts/apply-kevin-profile.sh`, controller, wake, bring-up | → `hermes/scripts/` or `scripts/kevin/` — adapt for image-first; host path secondary |
| `packs/kevin-slack-*` | → `hermes/packs/` or `docs/kevin/packs/` |
| Planning / Linear history | leave git history; optional copy of planning shell under `docs/kevin/planning/` |
| spikes, research archive | migrate selectively or drop (research is archive) |
| Repo | **delete** after verify |

### ADR-001 §8 amend (in migrated docs)

- Laptop: `setup.sh` for multi-agent still valid  
- **Kevin primary:** image from this repo; update = pull/recreate  
- No silent pull on gateway start  

## Deliverable breakdown + AC ownership

Parent ACs (plan-final):

| AC | Text |
|----|------|
| AC1 | Kevin packaging under agent-tools `hermes/` |
| AC2 | Image build publishes then bakes **dist/hermes** (not src) |
| AC3 | GHCR `kevin-hermes:main` + `:sha-…` from main |
| AC4 | No GH Release/semver/cliff required (ADR-002) |
| AC5 | Compose: project bind + data volume; local-in-container |
| AC6 | CI checks all pushes; image job main-only |
| AC7 | SF content migrated; repo deleted (or delete executed) |
| AC8 | Path-of-record runbook is Docker image; host PATH not primary |
| AC9 | Desktop dogfood: up → kevin profile/skills present; project write → host git status |
| AC10 | No silent agent-tools git pull on gateway start |

| ID | Deliverable | ACs | Tasks |
|----|-------------|-----|-------|
| **D0** | Migration map + donor prep | (enables all) | Inventory SF paths; write `docs/kevin/MIGRATION.md` checklist in agent-tools PR0 or SF planning |
| **D1** | hermes/profile + docker skeleton | AC1 | Copy profile; docker README skeleton; empty Dockerfile stub |
| **D2** | Dockerfile bake dist/hermes | AC2, AC10 | Multi-stage publish; COPY skills; revision file; profile seed |
| **D3** | Compose + env + init | AC5, AC9 (partial) | compose.yaml; .env.example; entrypoint profile apply |
| **D4** | GHCR CI | AC3, AC4, AC6 | workflows; packages permission; main+sha tags |
| **D5** | Runbooks + ADR amend | AC8, AC4 | docs/kevin runbook; ADR-001 §8; ADR-002 present |
| **D6** | SF migrate + delete | AC7 | Move remaining; fix links; delete repo after operator OK |

**Gap-prevention:** each AC in exactly one row above; D0 has no AC (enabler).

## Definition of done

- [ ] All AC1–10 checked  
- [ ] Local or CI image build succeeds with non-empty `/opt/kevin/skills` and revision marker  
- [ ] `docker compose` against `:main` (or local build tag) dogfood notes recorded  
- [ ] software-factory deleted or explicit residual with owner  
- [ ] Linear KEVN-11 updated; no dual path of record  

## Risks

| Risk | Mitigation |
|------|------------|
| Hermes image CMD/profile paths differ | Spike entrypoint early in D2; read upstream docker docs |
| GHCR permission on personal repo | Document PAT/`GITHUB_TOKEN` + package link to repo |
| SF delete too early | D6 last; checklist sign-off |
| Huge docs migrate | Prefer Kevin-path-of-record docs; leave pure research archive behind or copy selectively |
| setup.sh full multi-agent slow in CI | Prefer `publish-skills.sh --agents hermes` only for image stage |

## Out of scope

- git-cliff / semver / GitHub Releases (ADR-002 later)  
- Live Slack @mention required  
- DinD / docker.sock  
- Unattended wake re-home  
- K8s  
- Port Kevin to non-Hermes hosts (name reserved only)  

## Key insight

**Execute in agent-tools.** software-factory is a **content donor**, not the long-term home. Plan approval ⇒ branch work primarily under agent-tools; SF only for final delete and any last-minute content pull.

---

**Status:** Approved 2026-07-26 — execute in agent-tools.
