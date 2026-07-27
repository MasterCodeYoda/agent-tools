# Runbook: Jarvis capabilities & secrets spine

**Status:** Active  
**Profile:** `jarvis`  
**Doctrine:** [multi-agent-config-lanes.md](./multi-agent-config-lanes.md)  
**Templates:** `hermes/jarvis-profile/.env.template` · `distribution.yaml` `env_requires`

---

## Capability matrix (v1)

| Capability | Lane | Secret / config names (git = names only) | Required for | Fail loud when |
|------------|------|------------------------------------------|--------------|----------------|
| **Model auth** | Secrets | `ANTHROPIC_API_KEY` / `OPENAI_*` / `OPENROUTER_*` or `auth.json` via `hermes -p jarvis auth` | Chat + research | No working model path for live runs |
| **Research (web/X)** | Policy toolsets + host tools | Provider keys as above; no extra v1 names | Digest ritual | Tools unavailable (document residual) |
| **Email digest** | Secrets | `JARVIS_SMTP_*`, `JARVIS_DIGEST_TO`, `JARVIS_DIGEST_FROM` | Morning send | Missing env and not `--dry-run` |
| **Slack CoS chat** | Secrets + bindings | `SLACK_BOT_TOKEN`, `SLACK_APP_TOKEN`, `SLACK_ALLOWED_USERS`, optional `SLACK_HOME_CHANNEL` | Interactive UX | Gateway cannot connect / allowlist empty |
| **Adaptive state backup** | Secrets (token) + host cron | `JARVIS_BACKUP_REPO`, `JARVIS_BACKUP_GITHUB_TOKEN` (fine-grained PAT to that repo only), optional branch | Full-fidelity durable setup | Missing on `jarvis-setup.sh` / backup push |

### Future capabilities (declare before build)

| Capability | Expected lane | Notes |
|------------|---------------|-------|
| Calendar | Secrets + adaptive | Later CoS |
| Mail triage | Secrets | Later CoS |
| Tasks / follow-ups | Adaptive + secrets | Later CoS |

Each new capability adds **names** to `.env.template` / `env_requires`, a row here, and fail-loud checks in its ritual — no ad-hoc snowflakes.

---

## Where values live

| What | Where |
|------|--------|
| Names in git | `hermes/jarvis-profile/.env.template`, `distribution.yaml` |
| Live values | Docker volume → `/opt/data/profiles/jarvis/.env` and/or `auth.json` |
| Adaptive state | `profiles/jarvis/state/**` on the volume; **nightly git backup** of text allowlist |

**Never** commit secret values. **Never** blind-overwrite live `.env` from templates without operator intent.

---

## Operator fill (full-fidelity — path of record)

```bash
./hermes/scripts/jarvis-setup.sh
```

This is the durable install: bring-up + secrets (**including required GitHub backup PAT + private repo**) + first backup + **nightly host cron**. Not an optional add-on.

See [jarvis-state-backup.md](./jarvis-state-backup.md).

Local packaging only (no backup): `./hermes/scripts/jarvis-local-smoke.sh`.

Helpers:

- `hermes/scripts/jarvis-setup.sh` — full fidelity  
- `hermes/scripts/jarvis-local-smoke.sh` — automated local validate  
- `hermes/scripts/jarvis-backup-state.sh` / `jarvis-restore-state.sh`  
- `hermes/scripts/jarvis-install-backup-cron.sh`  
- `hermes/scripts/jarvis-send-digest.sh --file … --dry-run`

---

## Kevin vocabulary parity

Kevin auth packaging uses the same **lanes** language (secrets preserved on apply; policy in git).  
Kevin path of record for factory auth: [kevin-auth-packaging.md](./kevin-auth-packaging.md).  
Do not re-home Kevin Slack ownership here — only share terms (secrets lane, fail loud, names in git).
