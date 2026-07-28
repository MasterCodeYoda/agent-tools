# Runbook: Multi-agent config lanes (Kevin + Jarvis)

**Status:** Active — shared doctrine for Hermes product profiles managed from agent-tools  
**Products:** **Kevin** (coding factory) · **Jarvis** (personal chief of staff)  
**Related:** [kevin-control-plane.md](./kevin-control-plane.md) · [kevin-auth-packaging.md](./kevin-auth-packaging.md) · [ADR-005](../decisions/005-skills-dialect-vs-product.md) · Jarvis planning `.agent-tools/planning/jarvis/`

---

## Why this exists

Both agents are **configuration-in-code** from this repo while Hermes also allows **live** profile mutation (dashboard, `hermes config set`, agent tools, sessions). Without explicit ownership lanes, re-apply stomps useful state or UI drift silently becomes “policy.”

This document is the **shared SoT** for that split. Kevin and Jarvis product docs **link here**; they do not invent competing sync stories.

---

## Three lanes

| Lane | What lives here | SoT | Mutated by | On `profile update` / apply |
|------|-----------------|-----|------------|------------------------------|
| **Policy** | Approvals, deny lists, toolsets, skills roots, SOUL host-bind, identity defaults | **Git** distribution (`hermes/profile/` or `hermes/jarvis-profile/`) | Humans via PR → apply / `--force-config` | **Overwritten** when policy is re-applied (`--force-config` or force reinstall of dist-owned files) |
| **Secrets & bindings** | API keys, OAuth `auth.json`, Slack/SMTP tokens, channel IDs, email addresses | **Live** profile home only | Operator (+ agent help with approval) | **Preserved** — never commit values |
| **Adaptive state** | Project lists, preferences, last-run notes, CoS working memory files | **Live** allowlisted paths under profile home (e.g. `state/`) | Agent + operator (incl. Slack for Jarvis) | **Preserved** — not distribution-owned policy files |

### Promotion rule

**Live → git is never automatic.** Intentional policy changes are proposed (diff/PR) by a human. Agents may **propose** policy deltas; they must not silent-commit or treat dashboard/`config set` as product SoT.

```text
git distribution (policy)  ──apply / --force-config──►  live profile
         ▲                                                      │
         └──── explicit promote (manual / PR) only ─────────────┘
                    secrets + adaptive state stay live
```

### Per-lane apply behavior

| Action | Policy (`config.yaml`, `SOUL.md`, dist skills markers) | Secrets (`.env`, `auth.json`) | Adaptive state (`state/`, memories if enabled) |
|--------|--------------------------------------------------------|-------------------------------|-----------------------------------------------|
| `hermes profile update <name>` | Dist-owned files refresh; **live `config.yaml` preserved by default** | Preserved | Preserved |
| `… update --force-config` | **Reset** `config.yaml` from distribution | Preserved | Preserved |
| Apply wrapper `--force` | Reinstall from stable repo path (Hermes preserves user-owned paths) | Preserved | Preserved |

**UI / agent live policy edits** are experiments until promoted. Before treating policy as shared or shipping a new image/profile rev, re-apply from git (use `--force-config` when you mean “policy = dist”).

---

## Unattended posture (policy mutation)

Unattended cron/gateway jobs **must not** rewrite distribution policy files (`config.yaml`, `SOUL.md`, distribution-owned paths) as a side effect of normal work.

| Allowed unattended (examples) | Denied unattended (examples) |
|------------------------------|------------------------------|
| Read adaptive state; append state notes | Edit live `config.yaml` policy sections |
| Research tools; compose digests | `hermes config set` that rewrites policy without human |
| Send email digest (Jarvis ritual, when configured) | Commit secrets or write tokens into git trees |
| Slack interactive replies under gateway policy | Force-push, destructive shell (existing deny floors) |

Agent-proposed policy changes → human review → git → apply.

---

## Instance topology (do not copy blindly)

| Product | Topology | Why |
|---------|----------|-----|
| **Kevin** | **Dual modes OK:** Workstation (host Hermes + `~/.kevin/skills`) **and** Isolated (`kevin-hermes` Docker). | Coding agent benefits from local dogfood and remote sandbox; project disk is SoT for work, not a single “personal brain.” |
| **Jarvis** | **Single remote production instance only** — one image deployment + **one durable data volume** (`HERMES_HOME`). | CoS memory, sessions, project lens, and secrets must not fragment across “which Jarvis.” |

### Jarvis non-goals (product)

- Productized **local/workstation** Jarvis install as a second daily brain  
- Multiple simultaneous production volumes without an explicit migration story  
- Terminal / remote shell as the **primary** conversation UX (ops only: doctor, secrets fill, debug)

### Jarvis interaction split (day-1)

| Surface | Role |
|---------|------|
| **Slack** (DM / home, Socket Mode) | Primary human↔Jarvis talk on the **same** remote instance |
| **Email** | Unattended morning research digest |
| **Terminal** | Ops only |

---

## Capability spine (secrets UX)

Each **capability** (model auth, Slack, email, state backup, future calendar, …) declares:

1. **Secret names** in git (`.env.template`, `env_requires`) — never values  
2. **Lane** for each setting (secrets vs adaptive vs policy)  
3. **Fail-loud** when required capability is missing for a ritual that needs it  

Kevin packaging path of record for auth names: [kevin-auth-packaging.md](./kevin-auth-packaging.md).  
Jarvis capability matrix: [jarvis-capabilities.md](./jarvis-capabilities.md).

### Adaptive state backup (Jarvis full setup)

Durable Jarvis installs **must** install nightly allowlisted backup of adaptive **text** state to a private git repo ([jarvis-state-backup.md](./jarvis-state-backup.md)):

- Secrets lane holds `JARVIS_BACKUP_GITHUB_TOKEN` + `JARVIS_BACKUP_REPO` (fine-grained PAT to that repo only)  
- **Host** schedule runs `jarvis-backup-state.sh` (systemd timer preferred; cron fallback — **not** in-container, not chat-driven git)  
- Write PAT stays on the host; do not put backup schedule inside `jarvis-hermes`  
- Never backs up `.env` / sessions / DBs  
- Backup corpus is a signal stream for **agent-tools skill evolution** (observation → human/process promote into `src/`); it is not skill SoT  

Installed by `hermes/scripts/jarvis-setup.sh` (required path for production).

---

## Product pack isolation (skills)

Render dialect (`hermes`) ≠ product pack (`kevin` | `jarvis`) — [ADR-005](../decisions/005-skills-dialect-vs-product.md).

- **Kevin pack** must **not** include Jarvis product skills.  
- **Jarvis pack** must **not** include Kevin process-pack / factory `/work` skills.  
- Images bake **published product packs**, never raw `src/`.

---

## Operator checklist

- [ ] Know which product (kevin vs jarvis) and which **lane** you are changing  
- [ ] Secrets only in live profile home / volume  
- [ ] Policy changes via PR + apply; use `--force-config` deliberately  
- [ ] Jarvis: one production volume; talk via Slack; digest via email  
- [ ] After adding skills under `src/jarvis/`, confirm kevin pack filter still excludes them  

---

## Related paths

| Concern | Path |
|---------|------|
| Kevin profile dist | `hermes/profile/` |
| Jarvis profile dist | `hermes/jarvis-profile/` |
| Kevin apply | `hermes/scripts/apply-kevin-profile.sh` |
| Jarvis apply | `hermes/scripts/apply-jarvis-profile.sh` |
| Kevin image | `docs/agents/runbooks/kevin-hermes-docker.md` |
| Jarvis image | `docs/agents/runbooks/jarvis-hermes-docker.md` |
