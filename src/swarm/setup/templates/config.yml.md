# Default swarm config.yml

Write to `.agent-tools/swarm/config.yml` (parameterize backlog source).

```yaml
schema_version: 1

# Project-stable orchestrator preferences. Safe to edit by hand.

# Concurrency cap for parallel dispatch waves
concurrency_cap: 5

# Role chain (which roles execute, in what dispatch order)
role_chain:
  - planner
  - implementer
  - reviewer

# Model selection per role. Tier labels (most_capable | mid_tier | fast) map to actual
# model IDs per host CLI; or pin an exact model ID.
models:
  planner: most_capable
  implementer: mid_tier
  reviewer: most_capable
  conflict_resolver: most_capable
  integration_fixer: most_capable

# CLI per role (Phase 3; defaults to host CLI for all in Phase 2).
# The orchestrator role is always the host and cannot be overridden here.
clis:
  planner: claude
  implementer: claude
  reviewer: claude
  conflict_resolver: claude
  integration_fixer: claude

# Test command run by the merge sweep after each merge into main.
# null = orchestrator auto-detects from manifests + charter engineering.md.
test_command: null

# Backlog source defaults (if /swarm <goal> doesn't specify a source explicitly)
backlog:
  default_source: <linear|jira|github-issues|file>   # set from detected PM tool
  default_filter: null

# Session log retention
sessions:
  retention_days: null   # null = keep indefinitely

# Pre-launch confirmation
pre_launch:
  always_confirm: true

# Output verbosity
output:
  per_wave_summary: brief   # brief | verbose | quiet
```
