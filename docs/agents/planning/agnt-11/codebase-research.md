# Codebase research — AGNT-11 Docker primary deploy

Status: Complete  
Date: 2026-07-25  
Mode: ticket-hidden facts (explore subagent + project read)

## Research questions

1. What does apply-kevin-profile assume for paths / HERMES_HOME?
2. What is hermes/profile layout and terminal project binding?
3. How do process skills install today?
4. What does bring-up check verify?
5. What do AGNT-5/7/8/9 runbooks say about project, docker, gateway, secrets?
6. Any existing Docker deploy surface in-repo?
7. How is project bound today (cwd vs config)?
8. Which scripts hardcode host Hermes paths?

## Findings

### Apply + paths

- `scripts/apply-kevin-profile.sh`: `hermes profile install/update` from `hermes/profile`; substitutes `__HERMES_SKILLS_DIR__`; copies `.no-bundled-skills`.
- Skills: `HERMES_SKILLS_DIR` override; default `$HOME/.hermes/skills`.
- Profile home **hardcoded** `$HOME/.hermes/profiles/kevin` for post-install sed/copy.
- **`HERMES_HOME` not used** by Kevin scripts. Non-default Hermes home unsupported today.

### Profile distribution

- `hermes/profile/`: `distribution.yaml`, `config.yaml`, `SOUL.md`, `.env.template`, empty `skills/`, `.no-bundled-skills`.
- `terminal.backend: local`; **no** `terminal.cwd` — launch from project root.
- Slack binding placeholder `REPLACE_WITH_KEVIN_OPS_CHANNEL_ID`.

### Process skills

- Primary: agent-tools `./setup.sh` → `~/.hermes/skills` (publish agent `hermes`).
- Secondary: `scripts/export-process-pack.sh` → `packs/hermes-process-pack*`.
- No silent pull on gateway start (ADR-001 / hermes README).

### Bring-up check

- Hard: hermes PATH, profile kevin, skills dir, no unexpanded placeholder, doctor invocable with shaped output.
- Soft: missing `.env` / API keys / revision marker quality.
- Host-PATH oriented; no container mode.

### Runbooks (docker mentions)

- AGNT-5 host PATH path of record; secrets soft for bring-up.
- AGNT-8: project modes local | docker (terminal backend) | ssh; gateway from project cwd; secrets `~/.hermes/profiles/kevin/.env`.
- AGNT-7: worktree isolation; gateway under kevin; no container deploy.
- AGNT-9: secrets landing zone host profile home.

### Docker in-repo

- **None** — no Dockerfile, compose, or `deploy/` for Kevin product tree.

### Project binding

- Convention only (cwd). Wake/controller use env roots (`KEVIN_WAKE_ROOT`, `KEVIN_PROJECT_ROOT`); not Hermes profile cwd.

### Script hardcodes

| Script | Hardcode |
|--------|----------|
| apply-kevin-profile | `$HOME/.hermes/profiles/kevin` |
| kevin-bring-up-check | same + PATH hermes |
| kevin-control-plane | hermes on PATH |
| controller / pre-wake | project env/cwd only — no hermes home |

## Assumptions challenged

| Assumption | Verdict | Evidence |
|------------|---------|----------|
| Apply works against container volume with env only | **Overturned** | Profile path hardcodes `$HOME/.hermes/profiles/kevin` |
| Deploy pack already exists | **Overturned** | No compose/Dockerfile |
| Project via terminal.cwd | **Overturned** | Intentionally unset; cwd launch convention |
| Docker in AGNT-8 docs = deploy surface | **Overturned** | Means terminal.backend docker, not instance-in-container |

## Unknowns (outside project)

- Exact Hermes container layout for multi-profile under `/opt/data` vs host `~/.hermes` mapping (upstream docs: `/opt/data` volume).
- Whether `hermes profile install` inside container honors same paths when HOME is container hermes user.
- agent-tools setup behavior when run on host vs bind into volume.
