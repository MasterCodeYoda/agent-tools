# Kevin / Hermes packaging (agent-tools monorepo)

| Path | Role |
|------|------|
| [`dev.sh`](dev.sh) | **Source-tree dev runner** — always builds `kevin-hermes:local` from this checkout, then compose up |
| [`profile/`](profile/) | Hermes profile distribution **`kevin`** |
| [`docker/`](docker/) | Dockerfile + compose used by `dev.sh` and CI |
| [`scripts/`](scripts/) | Host helpers (secondary to Docker) |

```bash
# From agent-tools checkout — build image from this tree and run it
./hermes/dev.sh -p /path/to/product-repo
./hermes/dev.sh logs
./hermes/dev.sh down
```

`dev.sh` is **not** a distributable client CLI and does **not** pull GHCR. Client install / on-PATH `kevin` is a separate design (not shipped yet).

**Path of record:** [docs/kevin/runbooks/kevin-hermes-docker.md](../docs/kevin/runbooks/kevin-hermes-docker.md)

**Process skills:** published as agent id **`hermes`** (`./setup.sh` on laptop; **`dist/hermes` baked into the image** for Docker). Never hand-edit installed skill bodies.

**Naming:** profile **`kevin`**; do not use **`factory`** for Kevin (Factory coding agent uses `~/.factory`).
