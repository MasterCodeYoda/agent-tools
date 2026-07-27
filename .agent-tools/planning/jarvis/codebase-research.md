# Codebase research: Jarvis (CoS wedge + multi-agent packaging)

## Research questions

1. How is kevin-hermes Docker packaging built and what is hard-coded to product `kevin`?
2. How does the Hermes `kevin` profile distribution install/update, and what is user-owned vs distribution-owned?
3. How does unattended/cron wake work for Kevin today?
4. How are secrets handled for workstation vs isolated Kevin?
5. Is there email send or digest product tooling in-repo?
6. How are skills published and product-stamped (dialect vs product)?
7. What ADRs constrain multi-agent profiles and a future Jarvis product?
8. Does any Jarvis / second-profile / CoS material already exist?

## Relevant files (with why)

| Path | Role | Notes |
|------|------|-------|
| `hermes/docker/Dockerfile` | Image bake | Publish hermes dialect skills → `/opt/kevin/skills`; copy `hermes/profile` → `/opt/kevin/profile`; product labels `org.kevin.*` |
| `hermes/docker/entrypoint.sh` | Container entry | Profile name **`kevin` only**; install/update; placeholder skills path; `hermes -p kevin …` |
| `hermes/docker/compose.yaml` | Isolated run | Data volume → `/opt/data`; product repo mount `/workspace` |
| `hermes/dev.sh` | Dev packaging loop | Always `kevin-hermes:local` |
| `hermes/profile/*` | Kevin distribution | `distribution.yaml`, `config.yaml`, `SOUL.md`, empty `skills/`, `.env.template` |
| `hermes/scripts/apply-kevin-profile.sh` | Workstation apply | Install from stable repo path; skills path sub; `--force-config` |
| `hermes/scripts/factory-wake/*` | Unattended pre-wake | Fail-closed worktree/project checks for factory continue |
| `docs/kevin/runbooks/kevin-control-plane.md` | Config sync story | git SoT → live → UI experiments; manual live→git |
| `docs/kevin/runbooks/kevin-auth-packaging.md` | Secrets | Live `.env` / `auth.json`; never blind-overwrite |
| `docs/kevin/runbooks/kevin-unattended-wake.md` | Cron wake shape | Gateway + cron under `kevin`; deliver-once; no silent pull |
| `docs/kevin/runbooks/kevin-hermes-docker.md` | Isolated packaging | Image tags, dev.sh vs GHCR |
| `docs/kevin/decisions/001`–`005` | Product constraints | Host, image versioning, workstation vs isolated, skills channel, dialect vs product |
| `tools/publish-skills.sh` | Dialect render | `src/` → `dist/<dialect>/skills` |
| `tools/pack-kevin-skills.sh` | Product pack | hermes dialect → `kevin-skills` artifact |
| `.github/workflows/kevin-hermes-image.yml` | CI image | `:main` + `:sha-…` multi-arch |

## How it works today

### Isolated Kevin packaging

1. Multi-stage Docker build runs `publish-skills.sh --agents hermes`, bakes `dist/hermes/skills` at `/opt/kevin/skills`, bakes `hermes/profile` at `/opt/kevin/profile`.
2. Entrypoint ensures profile `kevin` exists, installs from baked profile, substitutes `__HERMES_SKILLS_DIR__` → baked skills path, starts `hermes -p kevin gateway run`.
3. Hermes state (installed profile, `.env`, sessions) lives on a host volume mounted at `/opt/data` (`HERMES_HOME`).
4. Product repo is bind-mounted at `/workspace` for factory coding — not required for a non-coding CoS agent.

### Profile config-as-code

1. Git `hermes/profile/` is policy SoT (`distribution_owned` includes `config.yaml`, `SOUL.md`, etc.).
2. `hermes profile update` preserves user-owned paths (`.env`, `auth.json`, sessions, memories).
3. Live `config.yaml` is **preserved by default** on update; `--force-config` resets policy from dist.
4. Control-plane runbook: UI/dashboard edits are experimental; re-apply from git before treating policy as shared; live→git is manual and never copies secrets.
5. Kevin posture: memory off, `write_approval` on skills/memory, approvals `manual` + deny floor, blank bundled skills, process pack via `external_dirs`.

### Unattended path (Kevin)

- Shape: Hermes gateway + cron under profile `kevin`, pre-wake scripts, claimable-only continue, deliver-once on escalate.
- Pre-wake is **factory-shaped** (worktree, planning root) — not reusable as-is for personal research digests.
- No in-repo auto-registered cron job; templates + host scripts only. Evidence dry-run: pre-wake PASS; gateway/cron not always live-installed.

### Skills axes (ADR-005)

- **Render dialect** (`hermes`, …) vs **product** (`kevin`, future `jarvis`).
- Kevin pack: hermes dialect + `publish-agent=kevin`; install `~/.kevin/skills` / image `/opt/kevin/skills`.
- Jarvis named as future non-process-pack Hermes identity; **no** jarvis profile, image, or skill pack implemented.
- Multi-agent `./setup.sh` → `~/.hermes/skills` is maintainer dialect path, not Kevin consumer path.

### Email / research product surface

- **Not found:** email send, morning digest ritual, CoS agent, or jarvis packaging trees.
- Outbound product pattern today: **Slack** + cron deliver semantics for Kevin unattended work.
- Hermes host capabilities (from research docs): web/browser tools, MCP, cron — not wired as jarvis product.

## Constraints & conventions

- Never bake secrets into image or commit live `.env` / `auth.json`.
- Never raw `src/` in image — always published `dist/…`.
- No silent pull/setup on start or cron (Kevin ADR-001).
- Profile install source must be stable repo path (not mktemp) so `profile update` tracking works.
- Product identity hard-coded in paths (`/opt/kevin/*`, labels, entrypoint profile name) — sibling agent needs parallel, not toggled, packaging.
- Kevin pre-wake fail-closed on factory project state — wrong contract for research CoS.

## Hypotheses / open questions

- Hermes email/SMTP capability may exist upstream but is **not** productized in this repo (confidence: high on “not in-repo”; medium on upstream host tools).
- Sharing one multi-stage Docker pattern with ARG product name is feasible; today there is zero parameterization (confidence: high).
- Adaptive state (project list, preferences) has no first-class path yet; memories are off for Kevin — Jarvis may want memory or a dedicated state file (confidence: high that nothing exists).

## What we are *not* changing

- Kevin process pack content and `/work` skill family semantics.
- ADR-005 dialect vs product axes (extend, do not reverse).
- Workstation vs isolated modes as permanent dual surfaces for Kevin (Jarvis day-1 is isolated/cron-primary per product choice).
- Graphite/PR factory merge policy, swarm, or work-family process IP.

## Freshness

- Sourced from code at: `ad87e6d` (2026-07-27)
- Discard if: `hermes/docker/*`, `hermes/profile/*`, or ADR-005 packaging paths change materially; or upstream Hermes profile-update semantics change.
