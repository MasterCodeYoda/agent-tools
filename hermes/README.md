# Kevin / Hermes packaging (agent-tools monorepo)

| Path | Role |
|------|------|
| [`kevin.sh`](kevin.sh) | **Operator CLI** — build / pull / up / logs / down |
| [`profile/`](profile/) | Hermes profile distribution **`kevin`** |
| [`docker/`](docker/) | Image + compose used by `kevin.sh` |
| [`scripts/`](scripts/) | Host helpers (secondary to Docker) |

```bash
./hermes/kevin.sh --build -p /path/to/product-repo
```

**Path of record:** [docs/kevin/runbooks/kevin-hermes-docker.md](../docs/kevin/runbooks/kevin-hermes-docker.md)

**Process skills:** published as agent id **`hermes`** (`./setup.sh` on laptop; **`dist/hermes` baked into the image** for Docker). Never hand-edit installed skill bodies.

**Naming:** profile **`kevin`**; do not use **`factory`** for Kevin (Factory coding agent uses `~/.factory`).
