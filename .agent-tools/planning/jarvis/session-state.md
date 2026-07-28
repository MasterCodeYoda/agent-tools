---
project: jarvis
requirements_source: file
work_item: null
pm_tool: manual
session_count: 4
status: in_progress
progress:
  total_tasks: 36
  completed: 36
  percent: 100%
current_layer: not_started
track: feature
branch: main
worktree: null
visual_plan: ".agent-tools/planning/jarvis/visual-plan.html | mode=static-html | status=published"
created: 2026-07-27
updated: 2026-07-28
handoff: true
---

## Status

**Packaging + lab validation + durable Portainer host bring-up largely complete.**  
Jarvis is the **production CoS brain on skynet** (`jarvis-hermes` + volume `jarvis-hermes-data`). Lab Mac instance should stay **down** (same Slack tokens + SuperGrok OAuth — dual gateways fight).

Epic implementation (D1–D8) is on **`main`**. **Host ops kit shipped** on `main` @ `be7ed5a` (CI green; rolling release `jarvis-host`).

**R8 host backup schedule:** **done** (system timer). Prefer migrating skynet to kit paths next.

## Handoff pointer (start here next session)

```text
Read: .agent-tools/planning/jarvis/session-state.md
Operator path of record: docs/agents/runbooks/jarvis-host.md
  Release: https://github.com/MasterCodeYoda/agent-tools/releases/tag/jarvis-host
  Install: curl -fsSL …/jarvis-host/install.sh | sudo bash
  Existing host: sudo /opt/jarvis-host/migrate-from-legacy.sh

Ops runbooks:
  docs/agents/runbooks/jarvis-host.md
  docs/agents/runbooks/jarvis-hermes-docker.md
  docs/agents/runbooks/jarvis-slack.md
  docs/agents/runbooks/jarvis-state-backup.md
Host:  ssh skynet-server
Image: ghcr.io/mastercodeyoda/jarvis-hermes:main
Volume: jarvis-hermes-data → /opt/data
```

**Do not** start a second daily Jarvis on Docker Desktop with the same Slack app + xAI OAuth.

### Host ops kit (shipped)

| Item | Status |
|------|--------|
| Code | `hermes/host/jarvis/` on `main` @ `be7ed5a` |
| CI | jarvis-host dist + jarvis-hermes image + CI green |
| Release | tag `jarvis-host` (install.sh, tar.gz, manifest) |
| Skill | `src/jarvis/host-update` (baked after image rebuild — done with image CI) |
| Skynet migrate | **open** — run migrate-from-legacy on durable host |

---

## Current topology

| Surface | Where | Notes |
|---------|--------|--------|
| **Durable Jarvis** | `skynet-server` (192.168.1.250), x86_64 | Portainer/Docker; `docker-compose` binary (not `docker compose` plugin) |
| Container | `jarvis-hermes` | Image `ghcr.io/mastercodeyoda/jarvis-hermes:main` |
| Data | Docker volume **`jarvis-hermes-data`** | Secrets + adaptive state |
| Lab Mac | **Stopped** (confirm with `docker ps`) | Do not restart unless rotating secrets carefully |
| Git | `main` @ agent-tools | `feat/jarvis` deleted after merge |
| Backup git | `https://github.com/MasterCodeYoda/jarvis-state.git` | Host worktree `~/.jarvis/backup-repo` |

### Proven on durable (2026-07-28)

- Promote Path A: secrets (`.env` + `auth.json`) injected; smoke **ALL PASSED**
- Adaptive state seeded: `projects.md`, `interests.md`, `priorities.md`, `portfolio.md`, digests
- Backup push works (after env parse fix); exported files > 0 after seed
- Slack Socket Mode from **skynet only** after lab down
- Model chat after **re-export of fresh auth.json** from lab volume (see OAuth note)

### Lab-proven earlier (same day)

- Full research-digest multi-bucket brief + branded HTML email (“Morning brief”)
- SMTP From alias + Send-as; Slack footer deep-link
- Skill: `research-digest` flat id under `/opt/jarvis/skills/`

---

## Residuals (ordered)

| # | Residual | Status | Notes |
|---|----------|--------|--------|
| R1–R3 | Packaging / local smoke | **done** | |
| R4 | Durable Slack chat | **done** | Confirmed with lab down; retest after auth re-inject |
| R5 | Live SMTP digest | **lab done**; durable not re-proven | Optional: one CLI/email run on skynet |
| R6 | Merge `feat/jarvis` | **done** | On `main`; branch removed |
| R7 | Adaptive backup scripts | **done** | |
| R8 | Host backup schedule | **done** | System timer on skynet; re-smoke 2026-07-28 08:50 exit 0 (export + push `jarvis-state`) |
| R9 | Morning brief Hermes cron | **open** | Never scheduled; gateway cron empty (in-container Hermes cron, not host) |
| R10 | OAuth single-writer discipline | **ops** | Only one instance may refresh SuperGrok; dual instances revoke refresh tokens |
| R11 | Robinhood MCP | **deferred** | URL `https://agent.robinhood.com/mcp/trading`; use `state/portfolio.md` defaults for now |
| R12 | Lab purge | **optional** | `./hermes/scripts/jarvis-local-smoke.sh --purge` when durable trusted |
| R13 | Portainer stack UI | **optional** | Stack may be compose-CLI only today; can mirror in Portainer for visibility |
| R14 | Fix backup temp cleanup perms | **done** | Export container now `-u host uid`; cleanup trap tolerates leftovers |

---

## Critical ops notes

### SuperGrok OAuth (`auth.json`)

- Lives on volume: `/opt/data/profiles/jarvis/auth.json`
- Promote used a **stale** export once → `invalid_grant` / refresh revoked after lab rotated tokens
- Fix used: copy **fresh** auth.json from lab volume → inject into skynet volume → restart
- **Going forward:** keep lab stopped; if re-auth needed, run `hermes -p jarvis auth add xai-oauth` **on skynet only**

### Secrets

- Laptop export (may need refresh of auth): `~/secure/jarvis-secrets/` (`.env` + `auth.json`)
- Adaptive seed tarball: `~/secure/jarvis-adaptive-state/state.tgz`
- Never commit; never paste values into chat
- `.env` must not be `source`d raw — backup script parses line-wise (`5ae5775`)

### Compose on skynet

- Use **`docker-compose`** (standalone v2.40.1), not `docker compose` plugin
- `jarvis-bring-up.sh` has fallback (`346fe97`)

### Adaptive backup schedule (host)

- **Not** in-container cron; write PAT stays on host (see `docs/agents/runbooks/jarvis-state-backup.md`)
- Path of record: **systemd system timer** under `/etc/systemd/system/` (headless; no login, no linger)
- **Not** user timer + linger — same root cost as system units, wrong semantics for skynet
- Install: `sudo ./hermes/scripts/jarvis-install-backup-cron.sh --system` (default scope is system; `--user` refuses without Linger)
- Verify: `./hermes/scripts/jarvis-install-backup-cron.sh --status`
- Smoke: `sudo systemctl start jarvis-backup-state.service`

### Portfolio lens

- `state/portfolio.md`: major US indexes (SPY/QQQ/IWM/DIA) + BTC/ETH (+ themes)
- Not personal brokerage positions until Robinhood MCP later

### Research skill buckets

World & politics → AI & technology → **Venture insights** → **Portfolio & markets** → Also notable → **Meta**  
Email subject: `Morning brief — YYYY-MM-DD` (no agent name)

---

## Next steps (suggested for new session)

1. **Skynet migrate** — install jarvis-host kit + `migrate-from-legacy.sh`; smoke status/backup/update --check.  
2. **R9** — Register Hermes morning brief job on durable (`hermes -p jarvis cron …`) with TZ + prompt from skill.  
3. **Optional R5** — One research-digest + email from skynet to prove full ritual on production volume.  
4. **R12** — Purge lab volume when ready.  
5. **R11** — Later: Hermes `mcp_servers.robinhood` → `https://agent.robinhood.com/mcp/trading` + OAuth; disable trade tools.

### Useful commands

```bash
# Durable status
ssh skynet-server 'docker ps --filter name=jarvis-hermes; docker exec jarvis-hermes tail -20 /opt/data/profiles/jarvis/logs/gateway.log'

# Backup schedule status / on-demand / timer smoke
ssh skynet-server 'cd ~/Source/OMG/agent-tools && ./hermes/scripts/jarvis-install-backup-cron.sh --status'
ssh skynet-server 'cd ~/Source/OMG/agent-tools && export JARVIS_VOLUME_NAME=jarvis-hermes-data && ./hermes/scripts/jarvis-backup-state.sh'
ssh skynet-server 'systemctl --user start jarvis-backup-state.service; journalctl --user -u jarvis-backup-state.service -n 20 --no-pager'

# Smoke on host
ssh skynet-server 'cd ~/Source/OMG/agent-tools && export JARVIS_HERMES_IMAGE=ghcr.io/mastercodeyoda/jarvis-hermes:main && ./hermes/scripts/jarvis-local-smoke.sh'
```

---

## Session history

### Session 1 — 2026-07-27

- Plan + execute D1–D8 packaging spine on `feat/jarvis`

### Session 2 — 2026-07-28

- Lab: Slack silent-DM (scopes), `!sethome`, quiet restart pings, flat `research-digest` skill id  
- Morning brief productization: HTML email, multi-lens skill, portfolio defaults, Meta section, Slack deep-link footer  
- Merge to `main`, delete `feat/jarvis`, CI green for **jarvis-hermes** + **kevin-hermes** images  
- Portainer Path A promote to skynet: compose fallback, shell-safe backup env load, state seed, Slack dual-instance gotcha, OAuth re-inject  

### Session 3 — 2026-07-28

- Decided: adaptive backup stays **host-side** (write PAT isolation); not in `jarvis-hermes`  
- Prefer **systemd system timer** over cron package and over user-timer+linger on headless hosts  
- Mis-step: first installed **user** timer (needs login/linger) — not viable for headless skynet; corrected installer default to **system** scope  
- Extended `jarvis-install-backup-cron.sh`: system default, `--user` refuses without Linger, removes user units on system install, R14 stage uid fix  
- Docs: `jarvis-state-backup.md` (+ capabilities / docker / multi-agent-config-lanes)  
- R8 done on skynet; host ops kit unit framed (brainstorm)

### Session 4 — 2026-07-28 (this handoff)

- Host ops kit: refine → plan → execute → merge `be7ed5a` to main; CI all green  
- Rolling release `jarvis-host` published  
- **Remaining:** skynet `migrate-from-legacy`, R9 morning Hermes cron, optional R5/R12

---

## Open questions / operator prefs

- Morning brief time / timezone on skynet  
- ~~Prefer systemd timer vs install `cron` package for backups~~ → **systemd timer** (path of record)  
- Whether Portainer UI stack is required or compose-CLI is enough  
- When to enable Robinhood MCP vs stay on `portfolio.md` defaults  
