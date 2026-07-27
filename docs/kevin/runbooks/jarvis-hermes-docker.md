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

## Dev build + run

```bash
cd /path/to/agent-tools

docker build -f hermes/docker/Dockerfile.jarvis -t jarvis-hermes:local .

export JARVIS_HERMES_IMAGE=jarvis-hermes:local
export JARVIS_HERMES_DATA=$HOME/.jarvis/hermes-data
mkdir -p "$JARVIS_HERMES_DATA"

docker compose -f hermes/docker/compose.jarvis.yaml up -d
docker compose -f hermes/docker/compose.jarvis.yaml logs -f
```

Pass checks:

| Step | Pass |
|------|------|
| Build | Image `jarvis-hermes:local` exists |
| Up | Container `jarvis-hermes` running |
| Profile | Logs show `hermes -p jarvis gateway` / profile jarvis available |
| State | `$JARVIS_HERMES_DATA` has profile home; `state/projects.md` seeded |

```bash
docker exec jarvis-hermes hermes -p jarvis profile show jarvis
```

---

## Secrets on the volume

After first start, fill live env under the volume’s profile home (layout may be
`…/profiles/jarvis/.env`). Names: [jarvis-capabilities.md](./jarvis-capabilities.md).

Never commit values. Apply/`profile update` preserves `.env` / `auth.json`.

---

## Morning cron (shape)

With gateway running, register a job under profile `jarvis` (exact Hermes cron CLI may vary by version):

```text
# Conceptual — use hermes -p jarvis cron create … on the host/container
# Schedule: morning local TZ
# Prompt / skill: run jarvis-research-digest for today; send email unless dry-run
# Workdir: not a product repo (CoS)
```

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
   # edit $JARVIS_HERMES_DATA/.../profiles/jarvis/state/projects.md
   ```

2. Dry-run digest (no SMTP required):

   ```bash
   # Inside container or host with hermes -p jarvis:
   # Invoke skill jarvis-research-digest with dry-run; write state/digests/YYYY-MM-DD.md
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
