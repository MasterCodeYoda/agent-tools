# Project memory index

Agent working knowledge for this repo (patterns, gotchas, lessons, debugging solutions).
Capture via `/work:compound`; steward via `/work:maintain`. Not a substitute for ADRs,
CONTRIBUTING, or Codex/domain docs.

## Entries

- [Kevin controller / project chrome](entries/kevin-controller-project-chrome.md) — status|decide CLI; exit 0/10/20; never invent NEXT
- [Kevin Slack live packaging](entries/kevin-slack-live-packaging.md) — kevin packs + runbook; factory historical; residual OK without tokens
- [Kevin auth packaging](entries/kevin-auth-packaging.md) — names-only secrets path-of-record; API + OAuth; never commit/blind-overwrite .env
- [hermes-h1-factory-profile-pass](entries/hermes-h1-factory-profile-pass.md) — Hermes factory profile H1 PASS: --no-skills, external_dirs pack, deny floor, Claude Code auth gotcha
- [hermes-h2-process-pack-pass](entries/hermes-h2-process-pack-pass.md) — H2 PASS: export-process-pack.sh from agent-tools publish; second profile, no SKILL edits
- [hermes-h3-slack-pass-reframed](entries/hermes-h3-slack-pass-reframed.md) — H3 PASS: Slack first-class in docs; factory packaging; live smoke deferred as ops
- [hermes-h4-model-hierarchy-pass](entries/hermes-h4-model-hierarchy-pass.md) — H4 PASS: orchestrate/execute/aux policy; sonnet+haiku config; multi-model switch
- [hermes-j1-judgment-vertical-pass](entries/hermes-j1-judgment-vertical-pass.md) — J1 PASS: disk-gated always-PR probe on Spectral worktree; E-MERGE stop; close-without-merge OK
- [hermes-j1-bis-research-residual](entries/hermes-j1-bis-research-residual.md) — J1-bis: automated wake residual; not H5 blocker; unsafe primary cwd
- [hermes-h5-provisional-host](entries/hermes-h5-provisional-host.md) — H5 ADR-001: Hermes host under lean A (amended Kevin adopt 2026-07-24)
- [gumclaw-ops-import-split-ip](entries/gumclaw-ops-import-split-ip.md) — GumClaw patterns → split IP (agent-tools process vs factory host/wake)
- [kevin-foundation-cleanup](entries/kevin-foundation-cleanup.md) — 2026-07-24 docs project cleanup; next Linear AGNT
- [kevin-profile-config-as-code](entries/kevin-profile-config-as-code.md) — AGNT-2: hermes/profile distribution + apply script; install from stable path; skills placeholder post-sub
- [kevin-hermes-process-pack-setup](entries/kevin-hermes-process-pack-setup.md) — AGNT-3: agent-tools hermes → ~/.hermes/skills; factory remains coding agent
- [kevin-control-plane-mvp](entries/kevin-control-plane-mvp.md) — AGNT-4: Hermes dashboard isolated + hierarchy pack + sync story
- [kevin-deployable-bring-up](entries/kevin-deployable-bring-up.md) — AGNT-5: bring-up path of record + hard readiness check; soft doctor ≠ fail
- [kevin-coding-loop-confidence-pass](entries/kevin-coding-loop-confidence-pass.md) — AGNT-6 PASS repo-class; hermes kevin tracers + scorecard
- [kevin-unattended-wake-mvp](entries/kevin-unattended-wake-mvp.md) — AGNT-7 MVP: kevin-pre-wake worktree gate + cron template; live tick residual

## Solutions

Debugging post-mortems live under `solutions/<category>/`. Search by `symptoms` / `tags` in
frontmatter; browse by category. Do not enumerate every solution here.
