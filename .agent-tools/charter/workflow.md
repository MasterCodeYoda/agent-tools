---
last_updated: 2026-07-27
---
# Workflow

## PM

- **Tool:** Linear team **Agent Tools** (`AGNT`) when issue-keyed; file mode default for corpus work without a key (see planning conventions).
- **Orientation:** roadmap NEXT when present; never invent claimable units.

## Planning root

- **Preferred:** `.agent-tools/planning/`
- **Legacy:** `./planning/` only if preferred absent (migrated 2026-07-27)

## Branching & commits

- Feature work on named branches; conventional commits preferred.
- **Push / PR:** user-initiated (not autonomous).

## Merge

**Autonomous local merge** authorized when ratchet green (see `.agent-tools/planning/conventions.md`):

1. Valid review evidence  
2. Project gates clean  
3. Task DoD met  
4. Recap Review block when code moved  

Prefer fast-forward to `main`; delete feature branch when fully merged.

## Review

- Green tests ≠ reviewed. Use `/work:review` evidence schema.
- Depth by track (feature standard; micro quick).

## Release

- Skills: rolling GitHub Release tag `kevin-skills` (not semver theater).
- Image: `kevin-hermes` on main via workflow.
- No mandatory git-cliff / GH Release product versioning for skills (ADR-002 spirit).

## Docs

- Durable decisions: `docs/kevin/decisions/`, other `docs/` as appropriate.
- Transient specs: planning root only; promote to `docs/design/` before committed citation.
