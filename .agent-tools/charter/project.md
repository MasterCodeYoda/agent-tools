---
last_updated: 2026-07-27
---
# Project

## Identity

**agent-tools** — canonical, portable skill corpus for coding agents (Claude, Codex, Grok, Factory, OpenCode, Hermes/Kevin). One SoT under `src/`; mechanical publish to `dist/<dialect>/skills/`; install via `setup.sh` and product channels (Kevin skills artifact).

**Linear:** team Agent Tools (`AGNT`).

## Stack

| Layer | Choice |
|-------|--------|
| Skills SoT | `src/**` markdown + markup |
| Publish | `tools/publish-skills.sh` (bash) → dialects |
| Install | `setup.sh` multi-agent; Kevin product via pack/CLI |
| Host (Kevin) | Hermes profile `kevin`; workstation CLI; image `kevin-hermes` |
| Host (future Jarvis) | Hermes profile `jarvis`; no process pack (ADR-005) |
| Gates | `tools/doc_lint.py`, shellcheck, `python3 -m unittest`, CI workflows |
| Language | Bash packaging; Python tests/linter |

## Surfaces

| Surface | Path of record |
|---------|----------------|
| Workstation Kevin | `kevin` CLI + `~/.kevin/skills` + profile kevin |
| Isolated Kevin | GHCR / local `kevin-hermes` image |
| Multi-agent skills | `./setup.sh` → agent profile dirs (not Kevin product path) |
| Process dialect | `/work:*` skills (published to consumers) |
| Kevin narrative | `docs/agents/` ADRs + runbooks |

## Vocabulary

| Prefer | Avoid |
|--------|--------|
| Render dialect (`hermes`) | Calling dialect “the Kevin product” |
| Product pack (`kevin`) | `dist/hermes` as product name |
| Workstation / Isolated Kevin | Track A/B |
| Planning root (preferred `.agent-tools/planning/`) | Assuming only root `./planning/` |

## Stakeholders

- Primary: Matt (operator, corpus steward, Kevin dogfood)
- Consumers: any harness installing published skills

## Out of scope (charter-level)

- Becoming a commercial multi-tenant SaaS skill marketplace
- Replacing Hermes with another host without a written pivot decision
- Jarvis as a process-pack / factory agent (explicit non-goal)
