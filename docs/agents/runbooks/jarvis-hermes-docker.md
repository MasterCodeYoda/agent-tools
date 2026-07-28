# Runbook: jarvis-hermes Docker (single remote CoS)

**Status:** Active  
**Mode:** **Single remote instance only** — not Kevin dual workstation/isolated product  
**Image:** `ghcr.io/<owner>/jarvis-hermes` (CI) · `jarvis-hermes:local` (dev)  
**Profile:** `jarvis`  
**Skills:** baked **jarvis product pack** (`publish-agent=jarvis`) — never Kevin process pack / raw `src/`  
**Doctrine:** [multi-agent-config-lanes.md](./multi-agent-config-lanes.md)

---

## Intent

One always-on Jarvis for:

| Surface | Mechanism |
|---------|-----------|
| Interactive CoS talk | Hermes **gateway** + **Slack** Socket Mode |
| Morning research digest | **Cron** → research skill → **email** (or dry-run) |
| Ops | `docker exec` / `hermes -p jarvis doctor` — not daily UX |

**One data volume** is the production brain (secrets, sessions, `state/projects.md`, digests).

---

## Production / durable setup (path of record)

### Preferred: lab → promote (no second secrets wizard)

Mint secrets once on Docker Desktop, validate, then **blind-copy `.env`** and finish remote non-interactively:

```bash
# Lab
./hermes/scripts/jarvis-local-smoke.sh
./hermes/scripts/jarvis-local-smoke.sh --secrets   # mint (wizard prints how-to)

# Publish validated image to GHCR (CI on merge, or docker tag/push)
# IMAGE=ghcr.io/OWNER/jarvis-hermes:sha-…

# Promote (agent-executable when SSH works)
./hermes/scripts/jarvis-promote.sh promote \
  --ssh user@durable-host \
  --remote-repo /path/to/agent-tools \
  --image "$IMAGE"
```

Promote secrets bundle is **`.env` + `auth.json`** (Grok SuperGrok OAuth is in `auth.json`, not `.env`).  
Never logged; scp → inject both → restart → backup init/push → **host** backup schedule (systemd timer preferred; not in-container) → local purge.  
See [jarvis-state-backup.md](./jarvis-state-backup.md).

Manual halves:

```bash
./hermes/scripts/jarvis-promote.sh export-secrets --out ~/secure/jarvis-secrets
# private transfer of that directory, then on host:
./hermes/scripts/jarvis-promote.sh finish-remote --secrets-dir /secure/jarvis-secrets --image "$IMAGE"
# or: ./hermes/scripts/jarvis-setup.sh --from-secrets-dir /secure/jarvis-secrets
```

### Interactive full setup on the durable host only

```bash
./hermes/scripts/jarvis-setup.sh
```

Details: [jarvis-state-backup.md](./jarvis-state-backup.md) · capabilities matrix for tokens.

Jarvis is **container-native**. Data: Docker volume `jarvis-hermes-data` → `/opt/data`. No Kevin-style product-repo mount.

## Local packaging smoke (no durable backup required)

```bash
./hermes/scripts/jarvis-local-smoke.sh          # up + validate
./hermes/scripts/jarvis-local-smoke.sh --purge  # wipe disposable instance
```

| Check (automated) | Pass |
|-------------------|------|
| Container / profile / gateway / skill | as listed by the script |

Env: `JARVIS_HERMES_IMAGE` (default `jarvis-hermes:local`).  
Portainer bind mount: `JARVIS_VOLUME_SPEC=/host/path`.

Do **not** paste tokens into agent chat. Secrets via setup wizard or `jarvis-local-smoke.sh --secrets` for ad-hoc local only.

---

## Morning cron (shape)

**Product ritual** — Hermes/gateway cron **inside** the durable instance (not host systemd, not the adaptive-state backup timer).

With gateway running, register a job under profile `jarvis` (exact Hermes cron CLI may vary by version):

```text
# Conceptual — use hermes -p jarvis cron create … on the durable host/container
# Schedule: morning local TZ
# Prompt / skill: run research-digest for today; send email unless dry-run
# Workdir: not a product repo (CoS)
```

Adaptive-state **git** backup remains a separate host schedule: [jarvis-state-backup.md](./jarvis-state-backup.md).

Digest helper (from repo, executable in container if copied or mounted):

```bash
hermes/scripts/jarvis-send-digest.sh --file /opt/data/profiles/jarvis/state/digests/YYYY-MM-DD.md --dry-run
```

---

## Continuity / backup

The volume at `JARVIS_HERMES_DATA` **is** production continuity. Backup/restore that directory
to move hosts. Do not invent a second laptop Jarvis for daily use.

---

## Research ritual smoke (AC12–AC15)

1. Seed projects on the volume:

   ```bash
   # edit state/projects.md + state/interests.md (work lens + standing beat)
   ```

2. Dry-run digest (no SMTP required):

   ```bash
   # Inside container or host with hermes -p jarvis:
   # Invoke skill research-digest with dry-run; write state/digests/YYYY-MM-DD.md
   hermes/scripts/jarvis-send-digest.sh --file /path/to/digest.md --dry-run
   ```

3. Live send: set `JARVIS_SMTP_*` + `JARVIS_DIGEST_*` on live `.env`, re-run without `--dry-run`.  
   Missing env must exit non-zero (fail loud).

4. Residual acceptable for CI/dev without mail: dry-run path green + documented missing SMTP.

## Related

- Profile: `hermes/jarvis-profile/`
- Compose: `hermes/docker/compose.jarvis.yaml`
- Dockerfile: `hermes/docker/Dockerfile.jarvis`
- Slack: [jarvis-slack.md](./jarvis-slack.md)
- Pack: `tools/pack-jarvis-skills.sh`
- Skill: `src/jarvis/research-digest/SKILL.md`
