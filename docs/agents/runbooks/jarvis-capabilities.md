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
| Live values | Single remote volume: `$JARVIS_HERMES_DATA` → `/opt/data` → `profiles/jarvis/.env` and/or `auth.json` |
| Adaptive project list | `profiles/jarvis/state/projects.md` on the same volume |

**Never** commit secret values. **Never** blind-overwrite live `.env` from templates without operator intent.

---

## Operator fill (single remote)

1. **Idempotent install:** `./hermes/scripts/jarvis-bring-up.sh`  
2. **Secrets (guided, no LLM):** `./hermes/scripts/jarvis-secrets-wizard.sh`  
   - Interactive prompts; secret fields hidden; values never echoed in summary  
   - Writes mode-600 live `.env` on the data volume only  
   - `--check` reports set/missing per key without printing values  
3. Restart container if it was already up so env reloads.  
4. `docker exec jarvis-hermes hermes -p jarvis doctor`  
5. Capability checklist: model works; Slack connects; digest dry-run works; then enable send.

Helpers:

- `hermes/scripts/jarvis-bring-up.sh` — volume + image + compose  
- `hermes/scripts/jarvis-secrets-wizard.sh` — secrets lane only  
- `hermes/scripts/jarvis-send-digest.sh --file … --dry-run` — email path

---

## Kevin vocabulary parity

Kevin auth packaging uses the same **lanes** language (secrets preserved on apply; policy in git).  
Kevin path of record for factory auth: [kevin-auth-packaging.md](./kevin-auth-packaging.md).  
Do not re-home Kevin Slack ownership here — only share terms (secrets lane, fail loud, names in git).
