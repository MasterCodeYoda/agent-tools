# Runbook: Jarvis capabilities & secrets spine

**Status:** Active  
**Profile:** `jarvis`  
**Doctrine:** [multi-agent-config-lanes.md](./multi-agent-config-lanes.md)  
**Templates:** `hermes/jarvis-profile/.env.template` · `distribution.yaml` `env_requires`  
**Full setup:** `hermes/scripts/jarvis-setup.sh`

---

## Capability matrix (v1)

| Capability | Lane | Secret / config names (git = names only) | Required for | Fail loud when |
|------------|------|------------------------------------------|--------------|----------------|
| **Model auth (Grok OAuth preferred)** | Secrets (`auth.json`) | `hermes -p jarvis auth add xai-oauth --type oauth` (SuperGrok/Premium+ device+browser PKCE). Optional env: `XAI_API_KEY`, Anthropic/OpenAI/OpenRouter | Chat + research | No OAuth session and no API key |
| **Research (web/X)** | Policy toolsets + host tools | Model keys above | Digest ritual | Tools unavailable |
| **Email digest** | Secrets | `JARVIS_SMTP_*`, `JARVIS_DIGEST_TO` / `FROM` | Morning send | Missing env and not dry-run |
| **Slack CoS chat** | Secrets + bindings | `SLACK_BOT_TOKEN`, `SLACK_APP_TOKEN`, `SLACK_ALLOWED_USERS`, optional home channel | Interactive UX | Gateway cannot connect |
| **Adaptive state backup** | Secrets + host cron | `JARVIS_BACKUP_REPO`, `JARVIS_BACKUP_GITHUB_TOKEN` (**write one private repo only**) | Durable full setup | Missing on `jarvis-setup` / push |
| **OMG GitHub read** | Secrets (runtime) | `JARVIS_GITHUB_READ_TOKEN` (**read selected repos; NOT backup token**) | CoS familiarity / digests | Missing when integrations required |
| **Linear read** | Secrets (runtime) | `JARVIS_LINEAR_API_KEY` | Correlate issues with research | Missing when integrations required |
| **Jira read** | Secrets (runtime) | `JARVIS_JIRA_BASE_URL`, `JARVIS_JIRA_EMAIL`, `JARVIS_JIRA_API_TOKEN` | Optional single-site correlate | Optional — multi-account not modeled yet; skip for v1 |

### Future capabilities (declare before build)

| Capability | Expected lane | Notes |
|------------|---------------|-------|
| Calendar | Secrets + adaptive | Later CoS |
| Mail triage | Secrets | Later CoS |
| Tasks / follow-ups | Adaptive + secrets | Later CoS |
| GitHub write / PRs | Separate token later | Do not expand read or backup PATs |

Each capability: names in git, values live only, fail-loud when a ritual needs it.

---

## Token split (non-negotiable)

```text
JARVIS_BACKUP_GITHUB_TOKEN  → host cron only → write jarvis-state repo
JARVIS_GITHUB_READ_TOKEN    → container runtime → read selected OMG repos
JARVIS_LINEAR_API_KEY       → container runtime → Linear API read
JARVIS_JIRA_*               → container runtime → Jira API read
```

- **Never** use one GitHub credential for backup write + org read.  
- Wizard **refuses** full setup if backup token equals read token.  
- Prefer fine-grained PAT or GitHub App for read (contents:read on selected repos).  
- Prefer Linear/Jira keys with least privilege (read-only roles where the product allows).

---

## Where values live

| What | Where |
|------|--------|
| Names in git | `.env.template`, `distribution.yaml` |
| Live values | Docker volume → `/opt/data/profiles/jarvis/.env` |
| Adaptive state | `profiles/jarvis/state/**`; nightly git backup of text allowlist |

**Never** commit secret values.

---

## Operator fill (full-fidelity — path of record)

```bash
./hermes/scripts/jarvis-setup.sh
```

Collects, as **required** for durable install:

1. Model key(s)  
2. Backup repo + write-scoped GitHub PAT  
3. OMG GitHub **read** token  
4. Linear API key  
5. Jira (optional — multi-account deferred)

Then: first adaptive-state backup + nightly host cron.

Local packaging only: `./hermes/scripts/jarvis-local-smoke.sh` (integrations optional).

See [jarvis-state-backup.md](./jarvis-state-backup.md).

---

## How integrations are used (intent)

Read-only access lets Jarvis **correlate** external research and digests with in-flight OMG work:

- GitHub: code/docs familiarity across selected OMG repos (not “project-bound” like Kevin)  
- Linear / Jira: issue titles, status, links for relevance scoring and brief context  

Runtime wiring (MCP/`gh`/HTTP) may land after auth spine; **secrets names and setup are in scope now**.

---

## Kevin vocabulary parity

Same three-lane language as Kevin auth packaging. Do not re-home Kevin Slack ownership here.
