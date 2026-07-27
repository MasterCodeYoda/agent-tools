# Runbook: Workstation Kevin CLI

**Status:** Active — AGNT-12  
**Decisions:** [ADR-003](../decisions/003-workstation-vs-isolated-kevin.md) · [ADR-004](../decisions/004-workstation-cli-and-skills-distribution.md)  
**Skills artifact:** [kevin-skills-dist.md](./kevin-skills-dist.md)  
**Auth packaging (names / stores):** [kevin-auth-packaging.md](./kevin-auth-packaging.md)

## Intent

Product path for **Workstation Kevin**: put `kevin` on PATH, bootstrap stack + skills **without cloning this monorepo**, attach credentials, then run coding sessions from a **single project git repo**.

**Operator surface is `kevin` only.** Hermes is the runtime under profile `kevin`; you should not need to run `hermes -p kevin …` for normal dogfood.

Isolated/container mode is separate ([kevin-hermes-docker.md](./kevin-hermes-docker.md)).

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
| `$PREFIX/share/kevin/profile/` | Profile distribution bundle |
| `$PREFIX/share/kevin/install-kevin-skills.sh` | Skills installer |

Product `kevin` **supersedes** any thin Hermes alias of the same name.

## Bootstrap

```bash
kevin setup

# Maintainer / pre-publish local pack:
./tools/pack-kevin-skills.sh
kevin setup --from-file dist/kevin-skills/kevin-skills.tar.gz

kevin setup --force-profile --from-file dist/kevin-skills/kevin-skills.tar.gz
```

What setup does:

1. Requires Hermes on PATH (else prints upstream install one-liner)  
2. Installs skills → `~/.kevin/skills`  
3. Stages profile → `~/.kevin/profile-src` and installs profile **kevin** (no PATH alias)  
4. Binds `external_dirs` → Kevin skills root  

```bash
kevin update
kevin update --force-profile
```

## Credentials (use kevin — not raw hermes)

You do **not** need a profile `.env` if OAuth / pooled login already covers your default model.

```bash
kevin auth list
kevin auth add anthropic --type oauth
# or API key:
kevin auth add anthropic --type api-key

kevin model          # interactive provider/model (+ login flows Hermes supports)
kevin configure      # full host configure wizard under profile kevin
```

| Path | CLI | Store |
|------|-----|--------|
| OAuth / pool | `kevin auth add <provider> --type oauth` | profile `auth.json` |
| API key | `kevin auth add … --type api-key` or profile `.env` | auth store and/or `.env` |

Details (names only, never commit values): [kevin-auth-packaging.md](./kevin-auth-packaging.md).

## Doctor

```bash
cd /path/to/product-repo
kevin doctor
kevin doctor --project /path/to/repo
kevin doctor --verbose    # includes raw Hermes doctor (optional)
```

| Class | Checks |
|-------|--------|
| **Hard** | Hermes on PATH; profile kevin; skills root + revision; skills path bound; project is git work tree |
| **Soft** | Inference credentials present; credential covers default provider — **not** “`.env` file exists” |

Results:

- `PASS (stack + credentials…)` — ready to chat  
- `PASS (stack) · CHAT NOT READY` — fix with `kevin auth` / `kevin model`  
- `FAIL` — fix hard stack lines, re-run doctor  

## Start a session

```bash
cd /path/to/product-repo
kevin
# or: kevin start
# or: kevin start --project /path/to/repo
```

Session home is the **project git repo**. Runtime is Hermes under profile kevin; entry is always `kevin`.

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
| `hermes -p kevin …` as the operator cookbook | Prefer `kevin auth` / `model` / `configure` / `start` |
| `./setup.sh` → `~/.hermes/skills` | Multi-agent / maintainer only |
| Clone agent-tools for skills | Rejected (ADR-004); use artifact |
| Hermes thin `kevin` alias alone | Not setup/doctor; product CLI owns the name |
| software-factory repo | Retired |
| `hermes/dev.sh` | Image packaging only |

## Related

- Skills dist: [kevin-skills-dist.md](./kevin-skills-dist.md)  
- Auth packaging: [kevin-auth-packaging.md](./kevin-auth-packaging.md)  
- Host profile notes (secondary): [hermes-kevin.md](./hermes-kevin.md)  
