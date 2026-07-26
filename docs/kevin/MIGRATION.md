# Migration: software-factory → agent-tools

**Status:** SoT is **agent-tools**. software-factory may be **deleted**.

## Disposition checklist (delete readiness)

| Content | In agent-tools? | Action before delete |
|---------|-----------------|----------------------|
| Profile, Docker pack, `dev.sh`, scripts | Yes (`hermes/`) | None |
| ADRs 001–002, runbooks, evidence, kevin packs | Yes (`docs/kevin/`) | None |
| Kevin/Hermes memory entries + gumclaw import | Yes (`docs/kevin/memory/`) | None |
| AGNT-11 planning snapshot | Yes (`docs/kevin/planning/agnt-11/`) | None |
| ADRs 003–004 (workstation / CLI dist) | Yes | None |
| Full `docs/research/*` archive | **No** (only research README) | **Optional:** tag SF before delete if you want recovery: `git tag archive/pre-delete-YYYYMMDD && git push --tags`. Not required for product. |
| Legacy `factory-*` packs, spikes | No | Drop (historical / superseded) |
| Uncommitted plant-rename dirt on SF | N/A | **Ignore** — do not invest; delete |
| Unpushed SF tombstone commits | Local only | Optional push; irrelevant if remote is deleted |

## Delete procedure (operator)

1. Confirm agent-tools `main` has Kevin docs + hermes pack (already true).  
2. Optional safety tag on SF (research recovery).  
3. GitHub → `overlund-media/software-factory` → **Delete repository** (or Archive).  
4. Remove local clone: `rm -rf ~/Source/OMG/software-factory`.  
5. Update any personal bookmarks to `agent-tools/docs/kevin/`.

## Map (historical)

| software-factory | agent-tools |
|------------------|---------------|
| `hermes/profile/` | `hermes/profile/` |
| Docker / packaging | `hermes/docker/` + `hermes/dev.sh` |
| Scripts | `hermes/scripts/` |
| Docs / ADRs / runbooks | `docs/kevin/` |
