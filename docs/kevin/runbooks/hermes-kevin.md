> **SECONDARY:** Path of record for the long-lived Kevin instance is [kevin-hermes-docker.md](./kevin-hermes-docker.md) (`./hermes/kevin.sh`). This document is host-PATH dogfood only.

# Runbook: Hermes profile **kevin** (Kevin v1)

**Status:** Active — E1 config-as-code + **E4 deployable bring-up** / [KEVN-5](https://linear.app/overlund-media/issue/KEVN-5)  
**Profile name:** `kevin`  
**Distribution root:** [`hermes/profile/`](../../hermes/profile/)  
**Process SoT:** agent-tools → managed `~/.hermes/skills` (publish agent **`hermes`**)  
**Related:** [ADR-001](../decisions/001-hermes-provisional-factory-host.md) · [hermes/README.md](../../hermes/README.md) · control plane [kevin-control-plane.md](./kevin-control-plane.md) · auth packaging [kevin-auth-packaging.md](./kevin-auth-packaging.md) · **Slack transport** [kevin-slack-live.md](./kevin-slack-live.md) · E5 coding-loop confidence [kevin-coding-confidence.md](./kevin-coding-confidence.md) · legacy dogfood [hermes-factory.md](./hermes-factory.md)

---

## Bring-up (E4) — path of record

Repeatable path from a clean-ish machine to a working Kevin dogfood **orientation** on an isolated product worktree. Follow steps in order. Prefer this runbook over the legacy `factory` dogfood archive.

### Ordered checklist

| Step | Action | Pass signal |
|------|--------|-------------|
| 1 | **Install Hermes** (upstream) | `hermes` on PATH; `hermes version` prints a version |
| 2 | **Clone repos** | `software-factory` and `agent-tools` available locally |
| 3 | **Process skills** | From agent-tools: `./setup.sh` → `~/.hermes/skills` present with `.agent-tools-revision` |
| 4 | **Apply kevin profile** | From software-factory: `./scripts/apply-kevin-profile.sh` (use `--force -y` to re-apply) |
| 5 | **Doctor (readiness bar)** | `hermes -p kevin doctor` runs; hard checks pass (see below) |
| 6 | **Secrets** | Fill live profile per [kevin-auth-packaging.md](./kevin-auth-packaging.md) (API key and/or OAuth) — **blocking for chat**, not for apply |
| 7 | **Smoke** | Isolated git worktree of software-factory; skills/project orientation (below) |
| 8 | **Optional** | Operator control plane: [kevin-control-plane.md](./kevin-control-plane.md) |

#### 1 — Install Hermes

Use the [upstream Hermes install](https://hermes-agent.nousresearch.com/) for your platform (typically):

```bash
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
source ~/.zshrc   # or ~/.bashrc
hermes version
hermes doctor     # host-level; profile-scoped doctor comes after apply
```

Kevin does **not** ship a custom Hermes installer.

#### 2 — Clones

```bash
# Example paths — use yours
export SF=~/Source/OMG/software-factory
export AT=~/Source/OMG/agent-tools
```

#### 3 — Process pack (agent-tools → `~/.hermes/skills`)

```bash
cd "$AT"
./setup.sh
# Expect managed skills under ~/.hermes/skills (publish agent hermes)
test -f ~/.hermes/skills/.agent-tools-revision && cat ~/.hermes/skills/.agent-tools-revision
```

**Update ritual:** pull agent-tools if needed → re-run `./setup.sh`. No silent pull on Hermes start or cron.  
`export-process-pack.sh` in software-factory is **secondary** only (offline/CI).

#### 4 — Apply profile

```bash
cd "$SF"
./scripts/apply-kevin-profile.sh
# Existing profile:
./scripts/apply-kevin-profile.sh --force -y
```

Wrapper fails loud if Hermes is missing or `~/.hermes/skills` is missing (unless `--skip-skills-check`).

#### 5 — Doctor + readiness bar

```bash
hermes -p kevin doctor
# Optional automation assist:
cd "$SF" && ./scripts/kevin-bring-up-check.sh
```

| Class | Examples | Treat as |
|-------|----------|----------|
| **Hard (must pass)** | `hermes` on PATH; profile `kevin` exists; `~/.hermes/skills` exists; doctor **command** runs; distribution apply succeeded | Block bring-up until fixed |
| **Soft (expected until operator acts)** | Missing profile `.env`; provider keys unset; “config version outdated” advisory; optional packages not installed | OK for install/apply; **blocking for interactive model work** |

Do **not** require vendor-perfect doctor green for E4 Done.

#### 6 — Secrets

**Path of record:** [kevin-auth-packaging.md](./kevin-auth-packaging.md) (inventory, Path A API keys / Path B OAuth, second-operator smoke, guardrails).

Summary only — do not maintain a second full secret-name matrix here:

1. Live values only: `~/.hermes/profiles/kevin/.env` and/or `auth.json` via `hermes -p kevin auth …`.
2. Names in git: `hermes/profile/.env.template` / `distribution.yaml` `env_requires`.
3. **Never** commit secret values under `hermes/` or anywhere in git.

#### 7 — Smoke (isolated worktree)

Goal: prove project + process skills resolve on a disposable worktree — **not** coding-loop PASS (that is [KEVN-6](https://linear.app/overlund-media/issue/KEVN-6)).

```bash
cd "$SF"
# Disposable worktree (name as you like)
git worktree add ../software-factory-smoke main
cd ../software-factory-smoke

# Profile must be kevin — never personal default for factory work
hermes -p kevin --version || hermes -p kevin version
hermes profile show kevin >/dev/null

# Hard readiness re-check from worktree (script lives in primary clone; invoke via path)
"$SF/scripts/kevin-bring-up-check.sh"

# Orientation smoke (human or agent harness with process skills):
# - Confirm planning root resolves (.agent-tools/planning or ./planning)
# - Portfolio status / continue must NOT invent NEXT when none claimable
# - Named NEXT (roadmap) may be claimed only under normal invent rules
# Example with a harness that has /work: bare /work = status-only
```

**Pass criteria for smoke**

- [ ] Worktree is isolated (`.git` is a file / linked worktree), not “edit primary while pretending”
- [ ] `hermes -p kevin` is usable for host CLI (version/show/doctor)
- [ ] Managed skills path is present (process pack)
- [ ] Project root visible under the worktree
- [ ] No requirement to complete a feature execute loop or live model turn for E4

Cleanup when finished:

```bash
cd "$SF"
git worktree remove ../software-factory-smoke
```

#### 8 — Optional control plane

After base smoke:

```bash
cd "$SF"
./scripts/kevin-control-plane.sh
```

See [kevin-control-plane.md](./kevin-control-plane.md).

---

## Failure matrix

| Symptom | Likely cause | Recovery |
|---------|--------------|----------|
| `hermes: command not found` | Hermes not installed / PATH | Upstream install; `source` shell rc; re-open terminal |
| Apply: “hermes CLI not found” | Same | Same |
| Apply: managed skills path missing | agent-tools setup not run | `cd agent-tools && ./setup.sh` then re-apply |
| `hermes profile show kevin` fails | Profile not installed | `./scripts/apply-kevin-profile.sh` |
| Skills empty / wrong agent | setup targeted wrong publish agent | Ensure agent-tools hermes target; re-run setup; check `~/.hermes/skills/.agent-tools-revision` for `publish-agent=hermes` |
| Using `hermes -p factory` for Kevin | Legacy dogfood profile | Prefer `kevin`; migrate secrets manually; do not auto-delete factory |
| Doctor: missing `.env` / no API keys | Secrets not filled | Soft for bring-up; fill `.env` or auth before chat |
| Doctor command itself fails hard | Broken Hermes install / profile home | `hermes doctor`; reinstall Hermes; re-apply profile |
| Smoke invents work with empty claimable | Process/project misread | Status-only orientation; claim only named NEXT; fix project via `/work:setup` if missing |
| Apply left `__HERMES_SKILLS_DIR__` unexpanded | Raw `hermes profile install` without wrapper | Re-run `./scripts/apply-kevin-profile.sh --force -y` |

---

## Preconditions (detail)

- [ ] Hermes installed (`hermes doctor` / `hermes version`)
- [ ] Clone of this repo (software-factory)
- [ ] agent-tools available for process skill install (`./setup.sh`)
- [ ] API keys or OAuth for at least one model provider (**chat** work)
- [ ] Do **not** use personal default Hermes profile for Kevin factory work

---

## Apply profile (config-as-code)

### Recommended: wrapper

```bash
cd /path/to/software-factory
./scripts/apply-kevin-profile.sh
# Re-apply from repo (existing profile; Hermes preserves .env/auth/sessions):
./scripts/apply-kevin-profile.sh --force
```

Wrapper will **fail loud** if `~/.hermes/skills` is missing. Fix:

```bash
cd /path/to/agent-tools && ./setup.sh
# installs managed skills under ~/.hermes/skills (publish agent hermes)
# writes ~/.hermes/skills/.agent-tools-revision
# then re-run apply
```

**Update ritual (primary):** pull agent-tools if needed → `./setup.sh`. No silent pull on Hermes start or cron.  
`export-process-pack.sh` is **secondary** only (offline/CI).

Override skills path: `HERMES_SKILLS_DIR=/other/path ./scripts/apply-kevin-profile.sh`

### Native Hermes CLI

```bash
cd /path/to/software-factory
# Note: raw install does not substitute __HERMES_SKILLS_DIR__ — prefer the wrapper.
hermes profile install ./hermes/profile --name kevin --alias
hermes profile update kevin              # distribution-owned files; secrets preserved
hermes profile update kevin --force-config   # also reset config.yaml from dist source
```

### What never gets clobbered

Hermes treats as **user-owned** (never overwritten by `profile update`):

- `.env`, `auth.json`
- `sessions/`, `memories/`, `state.db*`, logs, caches, workspace/home

Policy files (`config.yaml`, `SOUL.md`, …) come from the distribution; `config.yaml`
is preserved on update unless `--force-config` (or re-run wrapper with `--force`).

---

## Verify

```bash
hermes profile list
hermes profile show kevin
hermes -p kevin --version || hermes -p kevin version
./scripts/kevin-bring-up-check.sh
# From a product repo worktree:
cd /path/to/product-worktree
hermes -p kevin
# Expect process skills from ~/.hermes/skills once agent-tools setup has run
```

---

## Secrets

**Path of record:** [kevin-auth-packaging.md](./kevin-auth-packaging.md).

After install: fill live `~/.hermes/profiles/kevin/.env` (names from `.env.template` / `env_requires`) and/or complete provider OAuth so `auth.json` is populated. Soft for bring-up; blocking for interactive model work. **Never** put secret values in git under `hermes/`.

---

## Posture checklist

| Setting | Expected |
|---------|----------|
| Profile name | `kevin` |
| Memory | off |
| skills.write_approval | true |
| approvals.mode | manual + deny floor |
| Bundled skills | blank / opt-out |
| skills.external_dirs | absolute `…/.hermes/skills` |
| terminal.cwd | unset (launch from product repo) |

---

## Migrate from `factory` dogfood

Historical H1–H4 dogfood used `hermes -p factory` and pack-relative `external_dirs`.

1. Apply kevin (above).
2. Copy any **needed** secret names/values from `~/.hermes/profiles/factory/.env` manually if still required — do not script-blind overwrite.
3. Dogfood with `hermes -p kevin`.
4. When ready, optionally `hermes profile delete factory` **yourself** — Kevin apply never auto-deletes it.

---

## Out of scope for this runbook / E4

- Replacing Hermes install channel
- Auto-provisioning API keys
- Coding-loop confidence tracer bullets ([KEVN-6](https://linear.app/overlund-media/issue/KEVN-6))
- Unattended wake / gateway cron ([KEVN-7](https://linear.app/overlund-media/issue/KEVN-7))
- Live Slack transport details — path of record [kevin-slack-live.md](./kevin-slack-live.md) ([KEVN-8](https://linear.app/overlund-media/issue/KEVN-8))
- Auth packaging detail — path of record [kevin-auth-packaging.md](./kevin-auth-packaging.md) ([KEVN-9](https://linear.app/overlund-media/issue/KEVN-9))
- Custom controller / project chrome ([KEVN-10](https://linear.app/overlund-media/issue/KEVN-10))
- agent-tools hermes install implementation internals (landed under E2 / KEVN-3)
