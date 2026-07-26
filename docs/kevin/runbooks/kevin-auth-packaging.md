# Runbook: Kevin auth packaging (E8 / AGNT-9)

**Status:** Active — path of record for portable secrets  
**Profile name:** `kevin` only  
**Related:** [hermes-kevin.md](./hermes-kevin.md) (bring-up) · [kevin-control-plane.md](./kevin-control-plane.md) · [hermes/profile](../../hermes/profile/) · Slack packaging [AGNT-8](https://linear.app/overlund-media/issue/AGNT-8) / [packs/factory-slack.env.example](../../packs/factory-slack.env.example) (cross-ref only)

---

## Intent

A second operator (or second machine) can attach credentials for Hermes profile **`kevin`** without snowflake secret lists, without committing values, and without inventing a Kevin-specific secrets product.

**Rule:** Names live in git. Values live only on the host under `~/.hermes/profiles/kevin/`.

---

## Secret inventory (names only)

At least **one** working inference path is enough (API key **or** OAuth pool for the configured provider). No provider key is hard-required in packaging.

| Name | Purpose | Lives in | Required? | Notes |
|------|---------|----------|-----------|--------|
| `ANTHROPIC_API_KEY` | Anthropic / Claude API access | Profile `.env` (or `hermes auth add anthropic --type api-key`) | false | Prefer Path B OAuth when using subscription-style Claude attachment |
| `OPENAI_API_KEY` | OpenAI-compatible providers | Profile `.env` | false | Optional if not using OpenAI |
| `OPENROUTER_API_KEY` | OpenRouter | Profile `.env` | false | Optional if not using OpenRouter |
| OAuth / pool credentials | Provider login (e.g. Anthropic Claude Code pool) | `auth.json` via `hermes -p kevin auth …` | false | Path B; **never** commit `auth.json` |
| `SLACK_BOT_TOKEN` | Slack bot token (Socket Mode) | Profile `.env` when Slack is used | false for core auth | **AGNT-8 owns packaging** — see [Slack cross-ref](#slack-secrets-cross-ref) |
| `SLACK_APP_TOKEN` | Slack app-level token | Profile `.env` when Slack is used | false for core auth | Same — AGNT-8 |
| `SLACK_ALLOWED_USERS` | Hard allowlist (member IDs) | Profile `.env` when Slack is used | false for core auth | Same — AGNT-8 |
| `SLACK_ALLOWED_CHANNELS` | Hard allowlist (channel IDs) | Profile `.env` when Slack is used | false for core auth | Same — AGNT-8 |
| `SLACK_HOME_CHANNEL` | Optional home channel | Profile `.env` when Slack is used | false | Same — AGNT-8 |
| `TERMINAL_ENV` | Optional terminal env export name | Profile `.env` | false | Sandboxed shells; name only |

Repo seed for core API key names: [`hermes/profile/.env.template`](../../hermes/profile/.env.template) and `env_requires` in [`hermes/profile/distribution.yaml`](../../hermes/profile/distribution.yaml).

---

## Where secrets live

| Store | Path | What goes there | Git |
|-------|------|-----------------|-----|
| Profile env | `~/.hermes/profiles/kevin/.env` | API keys / env-style tokens (names from `.env.template`) | **Never** (live home is outside repo; `hermes/profile/.env` is gitignored) |
| Auth pool | `~/.hermes/profiles/kevin/auth.json` | OAuth / pooled credentials managed by Hermes (`hermes auth`) | **Never** |
| Policy | `hermes/profile/config.yaml` (git) + installed profile config | Model/provider **policy**, not secrets | Policy only |
| Dashboard | `hermes -p kevin dashboard --isolated` | UI to edit env/auth for kevin | Must not become the only SoT for policy; never export secrets into git |

Template ships as names-only under the distribution; after apply, Hermes may surface it as `.env.EXAMPLE` on the host — still names only until the operator fills live `.env`.

---

## Path A — API keys

Use when the team shares org API keys, the machine is CI-like, or the provider has no OAuth path you want to use.

1. Apply the profile if needed: `./scripts/apply-kevin-profile.sh`
2. Create or edit **live** env only:
   - `~/.hermes/profiles/kevin/.env`
3. Copy **names** from `hermes/profile/.env.template` (or the installed `.env.EXAMPLE`). Uncomment and set values for the provider(s) you use, for example:
   - `ANTHROPIC_API_KEY=…`
   - `OPENAI_API_KEY=…`
   - `OPENROUTER_API_KEY=…`
4. Do **not** commit the filled file. Do **not** paste values into PRs, fixtures, or planning docs.

Alternate: `hermes -p kevin auth add <provider> --type api-key` when Hermes supports that flow for the provider — still ends up as host-local credentials, not git.

---

## Path B — OAuth / subscription-style

Use when attaching a personal or org subscription-style login Hermes already supports (e.g. Anthropic / Claude Code pool observed as `anthropic` + oauth / `claude_code` source).

```bash
# Examples — provider ids are Hermes-facing, not Kevin-invented
hermes -p kevin auth add anthropic --type oauth
# Other providers as exposed by Hermes (e.g. openai-codex, openrouter, xAI OAuth):
#   hermes -p kevin auth add <provider> --type oauth

hermes -p kevin auth list
hermes -p kevin auth status anthropic   # or the provider you added
hermes -p kevin doctor                  # Auth Providers section
```

- Credentials land in `~/.hermes/profiles/kevin/auth.json` — **never commit**.
- Path A and Path B can coexist; **one** working path for the default provider is enough for interactive model work.
- **Do not** document or operate “share one person’s OAuth session with another human.” Each second operator runs **their own** OAuth flow or uses **org API keys** (Path A).

Dashboard / model picker auth flows are alternate surfaces for the same host stores; prefer stable CLI commands for portable packaging.

---

## Second-operator bring-up (auth slice)

Assumes Hermes install + agent-tools process pack are already understood from [hermes-kevin.md](./hermes-kevin.md). Auth-focused sequence:

| Step | Action | Pass signal |
|------|--------|-------------|
| 1 | Clone software-factory; agent-tools `./setup.sh` if skills missing | `~/.hermes/skills` present |
| 2 | `./scripts/apply-kevin-profile.sh` | Profile `kevin` installed/updated |
| 3 | Choose **Path A** and/or **Path B**; fill live profile only | Key in `.env` **or** entry from `hermes -p kevin auth list` |
| 4 | `./scripts/kevin-bring-up-check.sh` | Hard checks pass; **WARN** on missing `.env` is OK if OAuth works |
| 5 | Ping-class smoke (below) | Commands run; credential presence confirmed |

### Ping-class smoke

```bash
cd /path/to/software-factory

hermes -p kevin version   # or: hermes -p kevin --version
hermes -p kevin doctor

# Confirm at least one credential path:
hermes -p kevin auth list
# and/or inspect that ~/.hermes/profiles/kevin/.env has a key for the default provider
# (do not print secret values into logs or tickets)

./scripts/kevin-bring-up-check.sh
```

Optional live one-shot chat is **not** a hard packaging gate if doctor soft-gap + a documented path exist. Secrets remain a **soft** bring-up bar (blocking for interactive model work only).

---

## Guardrails (AC6)

- **Never commit secret values** — template and docs are names only; never commit real `.env`, `auth.json`, or tokens in any path under the repo.
- **Never copy live secrets into git “for backup”** or as PR fixtures / planning attachments.
- **Never blind-script-overwrite** live `~/.hermes/profiles/kevin/.env`. Apply uses Hermes install/update; user-owned paths (`.env`, `auth.json`, sessions, …) are preserved. No Kevin script may `cp` template → live without operator intent.
- **Manual only** for factory → kevin secret migration (copy names/values by hand if still needed).
- **Never treat dashboard export as git SoT** for secrets or durable policy.
- **Never share personal OAuth pools** as a team packaging story — second operator authenticates themselves or uses org keys.

Apply behavior to cite: [`scripts/apply-kevin-profile.sh`](../../scripts/apply-kevin-profile.sh) never custom-merges secrets; Hermes `profile update` does not clobber user-owned paths.

---

## Slack secrets (cross-ref)

Slack Socket Mode packaging is **[AGNT-8](https://linear.app/overlund-media/issue/AGNT-8)** — not this runbook.

| Until AGNT-8 lands kevin-scoped docs | Use |
|--------------------------------------|-----|
| Name list / example shape | [`packs/factory-slack.env.example`](../../packs/factory-slack.env.example) |
| Setup narrative (legacy `factory` profile paths) | [`packs/factory-slack-setup.md`](../../packs/factory-slack-setup.md) |

**Names (for inventory completeness only):** `SLACK_BOT_TOKEN`, `SLACK_APP_TOKEN`, `SLACK_ALLOWED_USERS`, `SLACK_ALLOWED_CHANNELS`, optional `SLACK_HOME_CHANNEL`.

When filling Slack for Kevin dogfood, put values in **`~/.hermes/profiles/kevin/.env`** (not into git). Prefer future kevin-scoped Slack env docs from AGNT-8 when they land; shared guardrails above still apply.

---

## Out of scope

- Secrets manager product packaging (Bitwarden / 1Password first-class Kevin product) — Hermes may expose `hermes secrets`; Kevin E8 does not require it
- Sharing personal OAuth pools across operators
- Public multi-tenant SaaS auth
- Owning or rewriting `packs/*slack*` / a kevin-slack runbook (AGNT-8)
- Changing bring-up hard/soft readiness semantics (secrets stay soft)

---

## Related

- Bring-up path of record: [hermes-kevin.md](./hermes-kevin.md)
- Control plane / dashboard: [kevin-control-plane.md](./kevin-control-plane.md)
- Profile distribution: [hermes/profile/README.md](../../hermes/profile/README.md)
- Config-as-code overview: [hermes/README.md](../../hermes/README.md)
