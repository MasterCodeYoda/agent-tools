# Reference: `config.yml` schema

Project-stable orchestrator preferences at `.agent-tools/parallel/config.yml`. **Committed** —
preferences are part of the project. Written with defaults by `/work:setup`; user-editable.

## Schema

```yaml
schema_version: 1

concurrency_cap: 5

function_chain:
  - plan
  - implement
  - review

# Tier labels (most_capable | mid_tier | fast) map to actual model IDs per host CLI
# (e.g. Claude: opus | sonnet | haiku). Or pin an exact model ID.
models:
  plan: most_capable
  implement: mid_tier
  review: most_capable
  resolve-conflict: most_capable
  fix-integration: most_capable

# CLI per function (Phase 3; host CLI for all in Phase 2). Orchestrator is always the host.
clis:
  plan: claude
  implement: claude
  review: claude
  resolve-conflict: claude
  fix-integration: claude

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

**Clean cut:** no `role_chain`, no `roles/` path, no `planner`/`implementer` model keys.
Use `function_chain` and function ids matching `functions/*.md` stems.

## Model-tier mapping

Defaults: plan / review / resolve-conflict / fix-integration → `most_capable`;
implement → `mid_tier` (highest volume; work is bounded by plan + tests).

## Test-command discovery cascade

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
