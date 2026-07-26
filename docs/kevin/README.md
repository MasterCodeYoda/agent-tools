# Kevin — orientation (lives in agent-tools)

**Product agent:** Kevin · **Hermes profile:** `kevin` · **Primary host:** Docker image `kevin-hermes`

## Start here

| What | Where |
|------|--------|
| **Run Kevin** | [`../../hermes/kevin.sh`](../../hermes/kevin.sh) — `./hermes/kevin.sh --build -p /path/to/product-repo` |
| **Docker path of record** | [runbooks/kevin-hermes-docker.md](./runbooks/kevin-hermes-docker.md) |
| **Profile + image pack** | [`../../hermes/`](../../hermes/) |
| **Image versioning** | [decisions/002-kevin-hermes-image-versioning.md](./decisions/002-kevin-hermes-image-versioning.md) |
| **Host decision (Hermes)** | [decisions/001-hermes-provisional-factory-host.md](./decisions/001-hermes-provisional-factory-host.md) |
| **Migration from software-factory** | [MIGRATION.md](./MIGRATION.md) |
| **Linear** | Team **Agent Tools** (`AGNT`) — see [LINEAR.md](./LINEAR.md) |

## Layout

```text
docs/kevin/
  README.md          # this file
  LINEAR.md          # team / identifier disposition
  MIGRATION.md       # SF → agent-tools
  decisions/         # ADRs
  runbooks/          # ops
  packs/             # Slack / model hierarchy packaging
  evidence/          # scorecards, dry-runs
  memory/            # compound entries snapshot
  planning/          # AGNT-11 planning snapshot
  product-surface.md
  kevin-v1.md
hermes/
  kevin.sh
  profile/
  docker/
  scripts/
```

Research under the old software-factory `docs/research/` is **archive** — not re-imported in full (see MIGRATION.md).
