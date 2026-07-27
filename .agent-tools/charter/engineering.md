---
last_updated: 2026-07-27
---
# Engineering

## Quality gates

| Gate | How |
|------|-----|
| Unit tests | `python3 -m unittest discover -s tests -v` |
| Doc integrity | `python3 tools/doc_lint.py` |
| Shell | `shellcheck` on packaging scripts (CI list) |
| CI | `.github/workflows/ci.yml` on push/PR |
| Kevin skills channel | `.github/workflows/kevin-skills-dist.yml` on main |
| Kevin image | `.github/workflows/kevin-hermes-image.yml` on main |

## Architecture

- **Thin publish layer:** no heavy dependencies; pure bash + awk publisher.
- **Dialect × product (ADR-005):** publish emits loader shape; Kevin pack stamps product identity.
- **Planning:** preferred `.agent-tools/planning/`; gitignored unit bodies; committed conventions/roadmap only.
- **Memory / runs:** `.agent-tools/memory/`, `.agent-tools/runs/` — process scoreboard + compound knowledge.

## Testing expectations

- Publisher goldens under `tests/publisher/` when changing publish behavior.
- Swarm harness unit tests under `tests/swarm/harness/tests/` for parallel tooling.
- Prefer characterization tests for packaging scripts over large rewrites without coverage.

## Definition of Done (feature unit)

- ACs met; review with valid evidence (method, date, verdict, P1–P3, disposition)
- Project gates green for the change
- Compound capture or `compound: none — reason`
- Kevin product path: channel/docs consistent when skills packaging changes

## Security

- Never commit secrets (profile `.env`, `auth.json`, API keys)
- Kevin product skills path is not multi-agent `~/.hermes/skills`
