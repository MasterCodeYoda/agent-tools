# Kevin / Hermes packaging (agent-tools monorepo)

| Path | Role |
|------|------|
| [`profile/`](profile/) | Hermes profile distribution **`kevin`** |
| [`docker/`](docker/) | **Primary** instance: `kevin-hermes` image + compose |
| [`scripts/`](scripts/) | Host helpers (secondary to Docker) |

**Path of record for the long-lived Kevin instance:** [docs/kevin/runbooks/kevin-hermes-docker.md](../docs/kevin/runbooks/kevin-hermes-docker.md)

**Process skills:** published as agent id **`hermes`** (`./setup.sh` on laptop; **`dist/hermes` baked into the image** for Docker). Never hand-edit installed skill bodies.

**Naming:** profile **`kevin`**; do not use **`factory`** for Kevin (Factory coding agent uses `~/.factory`).
