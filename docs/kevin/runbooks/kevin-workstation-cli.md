# Runbook: Workstation Kevin CLI

**Status:** Active — AGNT-12  
**Decisions:** [ADR-003](../decisions/003-workstation-vs-isolated-kevin.md) · [ADR-004](../decisions/004-workstation-cli-and-skills-distribution.md)  
**Skills artifact:** [kevin-skills-dist.md](./kevin-skills-dist.md)

## Intent

Product path for **Workstation Kevin**: put `kevin` on PATH, bootstrap Hermes + profile + process skills **without cloning this monorepo**, then run coding sessions from a **single project git repo**.

This is the dogfood path of record for capability. Isolated/container mode is separate ([kevin-hermes-docker.md](./kevin-hermes-docker.md)).

## Install CLI

From an agent-tools checkout (maintainer / first dogfood):

```bash
./tools/install-kevin-cli.sh
# default PREFIX=$HOME/.local → ~/.local/bin/kevin
# ensure ~/.local/bin is on PATH
kevin help
```

Install stages:

| Path | Content |
|------|---------|
| `$PREFIX/bin/kevin` | Product multi-command CLI |
| `$PREFIX/share/kevin/profile/` | Hermes profile distribution bundle |
| `$PREFIX/share/kevin/install-kevin-skills.sh` | Skills installer |

The product `kevin` **supersedes** any thin Hermes alias (`kevin` → `hermes -p kevin` only). After install, `kevin help` must show setup/update/doctor/start.

## Bootstrap

```bash
# Skills from published release (after main publish) + profile apply
kevin setup

# Or maintainer / pre-publish: local pack
./tools/pack-kevin-skills.sh
kevin setup --from-file dist/kevin-skills/kevin-skills.tar.gz

# Re-apply profile from staged bundle
kevin setup --force-profile --from-file dist/kevin-skills/kevin-skills.tar.gz
```

What setup does:

1. Requires `hermes` on PATH (else prints upstream install one-liner)  
2. Installs skills → `~/.kevin/skills` (override `KEVIN_SKILLS_ROOT`)  
3. Stages profile → `~/.kevin/profile-src` and runs `hermes profile install` (**no** Hermes alias)  
4. Substitutes `external_dirs` → Kevin skills root  

```bash
kevin update                 # refresh skills
kevin update --force-profile # skills + re-apply profile
```

## Doctor

```bash
cd /path/to/product-repo
kevin doctor
# or: kevin doctor --project /path/to/product-repo
```

| Class | Checks |
|-------|--------|
| **Hard** | hermes on PATH; profile `kevin`; skills root + `.agent-tools-revision`; no unexpanded `__HERMES_SKILLS_DIR__`; config references skills root; project is a git work tree |
| **Soft** | missing profile `.env` / auth — OK for stack install; blocking for chat |

## Start a session

```bash
cd /path/to/product-repo
kevin
# or: kevin start
# or: kevin start --project /path/to/product-repo -- --help
```

Session home is the **project git repo** (cwd or `--project`). Launch is `hermes -p kevin` under that directory.

## Environment

| Variable | Default | Role |
|----------|---------|------|
| `KEVIN_HOME` | `~/.kevin` | Home for skills + staged profile |
| `KEVIN_SKILLS_ROOT` | `$KEVIN_HOME/skills` | Process skills install target |
| `KEVIN_PROFILE_SRC` | `$KEVIN_HOME/profile-src` | Staged profile distribution |
| `KEVIN_SKILLS_URL` | rolling release asset | Skills tarball URL |
| `PREFIX` | `~/.local` | CLI install prefix (`install-kevin-cli.sh`) |

## What not to use (Kevin product path)

| Path | Role |
|------|------|
| `./setup.sh` → `~/.hermes/skills` | Multi-agent / maintainer only — **not** Kevin consumers |
| Clone agent-tools for skills | Rejected (ADR-004); use artifact |
| Hermes thin `kevin` alias alone | Not setup/doctor; product CLI owns the name |
| software-factory repo | Retired |
| `hermes/dev.sh` | Image packaging only |

## Related

- Skills dist: [kevin-skills-dist.md](./kevin-skills-dist.md)  
- Host profile notes (secondary): [hermes-kevin.md](./hermes-kevin.md)  
- Auth: [kevin-auth-packaging.md](./kevin-auth-packaging.md)  
