# Migration: software-factory → agent-tools (complete for SoT)

**Status:** Content SoT is **agent-tools**. software-factory is a **tombstone** (see that repo’s README) pending remote delete.

## Map (executed)

| software-factory | agent-tools |
|------------------|---------------|
| `hermes/profile/` | `hermes/profile/` |
| Docker primary | `hermes/docker/` + `hermes/kevin.sh` |
| Kevin scripts | `hermes/scripts/` (+ `factory-wake/`) |
| ADRs 001–002 | `docs/kevin/decisions/` |
| Runbooks | `docs/kevin/runbooks/` |
| product-surface, kevin-v1 | `docs/kevin/` |
| kevin packs | `docs/kevin/packs/` |
| evidence | `docs/kevin/evidence/` |
| compound memory (Kevin/Hermes entries) | `docs/kevin/memory/` |
| KEVN-11 planning | `docs/kevin/planning/kevn-11/` |
| Research archive | **not** fully copied — remains only in old git history / SF until remote delete |
| Planning history (all kevn-*) | snapshot KEVN-11 only; rest in SF git history |

## Delete software-factory when

1. agent-tools branch with migration is on **main** (or you accept working from the feature branch).  
2. No open clones depend on SF paths for day-to-day work.  
3. Operator deletes the GitHub repo `overlund-media/software-factory` (or archives it).

Local cleanup after remote delete:

```bash
# optional
rm -rf ~/Source/OMG/software-factory
```

## Research archive

Full `docs/research/` from SF is large and closed-archive. If needed later, recover from git history of the deleted repo or a one-off tag before delete:

```bash
# before delete, optional safety tag on SF:
# git -C software-factory tag archive/pre-delete-$(date +%Y%m%d)
# git -C software-factory push origin --tags
```
