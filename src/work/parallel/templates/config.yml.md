# Default parallel config.yml

Write to `.agent-tools/parallel/config.yml` (parameterize backlog source).

```yaml
schema_version: 1

# Project-stable orchestrator preferences. Safe to edit by hand.

concurrency_cap: 5

# Phase function chain (order of dispatch eligibility for each item)
function_chain:
  - plan
  - implement
  - review

# Model selection per function. Tier labels (most_capable | mid_tier | fast) map to actual
# model IDs per host CLI; or pin an exact model ID.
models:
  plan: most_capable
  implement: mid_tier
  review: most_capable
  resolve-conflict: most_capable
  fix-integration: most_capable

# CLI per function (Phase 3; defaults to host CLI for all in Phase 2).
# The orchestrator is always the host and cannot be overridden here.
clis:
  plan: claude
  implement: claude
  review: claude
  resolve-conflict: claude
  fix-integration: claude

# Test command run by the merge sweep after each merge into main.
# null = orchestrator auto-detects from manifests + charter engineering.md.
test_command: null

backlog:
  default_source: <linear|jira|github-issues|file>   # set from detected PM tool
  default_filter: null

sessions:
  retention_days: null   # null = keep indefinitely

pre_launch:
  always_confirm: true

output:
  per_wave_summary: brief   # brief | verbose | quiet
```
