# Reference: `config.yml` Schema

Project-stable orchestrator preferences at `.agent-tools/swarm/config.yml`. **Committed** —
preferences are part of the project. Written with defaults by `/swarm:setup`; user-editable.

## Schema

```yaml
schema_version: 1

concurrency_cap: 5

role_chain:
  - planner
  - implementer
  - reviewer

# Tier labels (most_capable | mid_tier | fast) map to actual model IDs per host CLI
# (e.g. Claude: opus | sonnet | haiku). Or pin an exact model ID.
models:
  planner: most_capable
  implementer: mid_tier
  reviewer: most_capable
  conflict_resolver: most_capable
  integration_fixer: most_capable

# CLI per role (Phase 3; host CLI for all in Phase 2). Orchestrator is always the host.
clis:
  planner: claude
  implementer: claude
  reviewer: claude
  conflict_resolver: claude
  integration_fixer: claude

test_command: null            # null = auto-detect (see cascade below)

backlog:
  default_source: linear      # linear | jira | github-issues | file
  default_filter: null

sessions:
  retention_days: null        # null = keep indefinitely

pre_launch:
  always_confirm: true

output:
  per_wave_summary: brief     # brief | verbose | quiet
```

## Model-tier mapping

The orchestrator maps tier labels to concrete model IDs for the host CLI. Defaults (§7.7):
planner/reviewer/conflict_resolver/integration_fixer → most_capable; implementer → mid_tier
(highest volume; work is bounded by plan + tests).

## Test-command discovery cascade (§8.6)

Resolution order when `test_command` is null:

1. `config.yml` `test_command` (explicit override).
2. `charter/engineering.md` Testing section, if it names a runnable command.
3. Package-manifest detection:
   - Node: `package.json` `scripts.test` → `npm/pnpm/yarn test` per lockfile
   - Python: `pyproject.toml [tool.pytest.ini_options]` / `tox.ini` / `Makefile` test target
     → `pytest` or `make test`
   - Go: `go test ./...`
   - Rust: `cargo test`
4. Nothing detected → orchestrator raises an IN_FLIGHT_DECISION asking the user, then **writes
   the answer into `config.yml`** for future runs.
