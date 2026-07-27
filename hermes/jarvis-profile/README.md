# Hermes profile distribution: `jarvis`

Versioned **Jarvis** (personal chief of staff) host profile for Hermes.
**Not** Kevin — no factory process pack, no productized multi-instance install.

## Product topology

**Single remote production instance only** — one Docker deployment + one durable
Hermes data volume. Do **not** run a second daily “local Jarvis” brain.

| Surface | Role |
|---------|------|
| Slack DM / home | Primary talk UX |
| Email | Unattended morning research digest |
| Terminal / `hermes -p jarvis` | Ops only (doctor, secrets, debug) |

Config lanes (policy / secrets / adaptive state):  
[docs/kevin/runbooks/multi-agent-config-lanes.md](../../docs/kevin/runbooks/multi-agent-config-lanes.md)

## Layout

| Path | Role |
|------|------|
| `distribution.yaml` | Manifest (`name: jarvis`, env_requires, owned paths) |
| `config.yaml` | Model, approvals, skills path placeholder, slack toolset |
| `SOUL.md` | CoS host-bind (non-implementer) |
| `.env.template` | Secret **names** only |
| `.no-bundled-skills` | Blank bundled skills posture |
| `skills/` | Empty — product skills from jarvis pack / image bake |

**Do not** commit real API keys, OAuth tokens, or `auth.json`.

## Adaptive state (not policy)

After install, maintain under the **live** profile home (volume):

```text
$HERMES_HOME/profiles/jarvis/state/projects.md
```

Survives `profile update`. Not distribution-owned.

## Apply (packaging / single home)

```bash
# From agent-tools repo root
./hermes/scripts/apply-jarvis-profile.sh
./hermes/scripts/apply-jarvis-profile.sh --force -y
./hermes/scripts/apply-jarvis-profile.sh --force-config -y
```

Native Hermes:

```bash
hermes profile install ./hermes/jarvis-profile --name jarvis
hermes profile update jarvis
hermes profile update jarvis --force-config
```

Product path for skills root (host packaging experiments): `JARVIS_SKILLS_ROOT`  
(default `~/.jarvis/skills`). **Production** prefers image bake at `/opt/jarvis/skills`.

## Related

- [multi-agent-config-lanes.md](../../docs/kevin/runbooks/multi-agent-config-lanes.md)
- [jarvis-capabilities.md](../../docs/kevin/runbooks/jarvis-capabilities.md)
- [jarvis-hermes-docker.md](../../docs/kevin/runbooks/jarvis-hermes-docker.md)
- [jarvis-slack.md](../../docs/kevin/runbooks/jarvis-slack.md)
- [ADR-005](../../docs/kevin/decisions/005-skills-dialect-vs-product.md)
