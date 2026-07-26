# Hermes profile distribution: `kevin`

Versioned **Kevin** host profile for Hermes. This directory is a Hermes
[profile distribution](https://hermes-agent.nousresearch.com/) root
(`distribution.yaml` + policy files).

## Layout

| Path | Role |
|------|------|
| `distribution.yaml` | Manifest (`name: kevin`, env_requires, owned paths) |
| `config.yaml` | Model, approvals, memory off, skills path placeholder |
| `SOUL.md` | Host bind (continuity / process / naming) — not personality SoT |
| `.env.template` | Secret **names** only |
| `.no-bundled-skills` | Blank bundled skills posture |
| `skills/` | Empty — process IP is **not** forked here |

**Do not** commit real API keys, OAuth tokens, or `auth.json`.

## Auth / secrets

| What | Where |
|------|--------|
| Names in git | `.env.template`, `env_requires` in `distribution.yaml` |
| Live values | `~/.hermes/profiles/kevin/.env` (API keys) and/or `auth.json` (`hermes -p kevin auth …`) |
| Path of record | [docs/runbooks/kevin-auth-packaging.md](../../docs/runbooks/kevin-auth-packaging.md) |

- One working path is enough: API key **or** OAuth pool for the default provider.
- Slack secret **names** only: cross-ref [packs/factory-slack.env.example](../../packs/factory-slack.env.example) / AGNT-8 — this profile does not own Slack packaging.
- **Never** commit tokens, real `.env`, or `auth.json`.

## Apply (primary)

Native Hermes:

```bash
# From agent-tools repo root (or pass absolute path to this directory)
hermes profile install ./hermes/profile --name kevin --alias

# Re-apply distribution-owned files later (preserves .env / auth / sessions):
hermes profile update kevin
# Reset policy config from dist as well:
hermes profile update kevin --force-config
```

Recommended wrapper (skills path check + placeholder substitution):

```bash
./hermes/scripts/apply-kevin-profile.sh
# Existing profile:
./hermes/scripts/apply-kevin-profile.sh --force
```

Install lands at `~/.hermes/profiles/kevin/`. User-owned paths (`.env`, `auth.json`,
`sessions/`, `memories/`, `state.db*`, …) are **never** overwritten by
`hermes profile update`.

## Process skills (product path)

1. **Workstation:** `kevin setup` (or `tools/install-kevin-skills.sh`) installs into **`~/.kevin/skills`**.
2. Profile `external_dirs` points at that path (apply/setup substitutes absolute path).
3. Missing skills → fail loud: re-run `kevin setup` / `kevin update`. Do not silent-pull on start.

Multi-agent `./setup.sh` → `~/.hermes/skills` is **not** the Kevin consumer product path (ADR-004).

## Posture (locked)

- Profile name: **`kevin`** (never `factory` for Kevin)
- Memory off; `write_approval` on skills/memory
- Approvals: `manual` + deny floor
- Blank bundled skills; process from managed dir
- No hardcoded `terminal.cwd` — launch from the product repo

## Migrate from legacy dogfood

Historical dogfood used `hermes -p factory`. Prefer:

```bash
./hermes/scripts/apply-kevin-profile.sh
hermes -p kevin
```

Do **not** auto-delete `~/.hermes/profiles/factory` — retire when you no longer need it.

## Related

- [../README.md](../README.md)
- [docs/runbooks/kevin-auth-packaging.md](../../docs/runbooks/kevin-auth-packaging.md) — auth packaging path of record
- [docs/runbooks/hermes-kevin.md](../../docs/runbooks/hermes-kevin.md)
- [ADR-001](../../docs/decisions/001-hermes-provisional-factory-host.md)
