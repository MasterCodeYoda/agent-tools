# Migration: software-factory → agent-tools (KEVN-11)

## Goal

Kevin packaging lives only in **agent-tools**. Delete **software-factory** after content is here.

## Map

| software-factory | agent-tools |
|------------------|-------------|
| `hermes/profile/` | `hermes/profile/` |
| (new) docker pack | `hermes/docker/` |
| `scripts/apply-kevin-profile.sh` etc. | `hermes/scripts/` (host secondary) |
| `docs/decisions/001-*`, `002-*` | `docs/kevin/decisions/` |
| `docs/product-surface.md`, `kevin-v1.md` | `docs/kevin/` |
| `packs/kevin-*` | `docs/kevin/packs/` |
| Runbooks (kevin-*, hermes-kevin) | `docs/kevin/runbooks/` (rewrite image-first) |
| Research archive | optional / drop (archive) |
| Planning / Linear | historical; Linear remains KEVN |

## Done in first monorepo PR

- [x] profile + docker pack skeleton  
- [x] Dockerfile bakes `dist/hermes`  
- [x] compose + entrypoint  
- [x] ADR-002 + product docs copy  
- [x] CI image workflow  
- [ ] Full runbook set + SF delete (follow-through)

## Delete software-factory when

1. Path-of-record runbook is agent-tools only  
2. No open work depends on SF paths  
3. Operator confirms remote delete  
