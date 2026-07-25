# Approval boundaries (Autonomous / Draft-first / Escalate)

**Load when:** continue orientation (esp. automation-shaped entries), integrate/merge decisions,
channel replies that assert product facts, or any action that is hard to reverse / outward-facing.
Host-agnostic process contract — not Hermes- or channel-specific.

**Related:** soft-checks · gates · pre-wake-checklist · runs-ledger escalate receipts · compound
dated rules.

---

## Why this exists

Sessions are ephemeral; **policy must be identical across sessions**. Three tiers keep judgment
load-bearing without re-negotiating every tool call. Silence / stop / escalate are always valid —
continuing past a red guard is not.

## Tiers

### Autonomous

Do the work when disk guards and conventions allow. Examples:

- `/workflow:continue` on a **named claimable** unit when soft-checks do not force prior remediations  
- Implement / test / commit in an allowed workspace (main or unit worktree)  
- Open a PR when **project or agent overlay** conventions authorize always-PR automation  
- Local merge when conventions authorize autonomous local merge **and** hard ratchet preconditions hold (`gates.md`)  
- Append runs ledger events; update session-state; compound capture  
- Read-only research against the live codebase / `gh` / CI status  

### Draft-first

Prepare the artifact; **human approves before it ships or becomes irreversible outward action**.
Examples:

- Broadcast-shaped messaging (public posts, bulk customer-facing text)  
- Release notes / changelog entries that claim “shipped” to users  
- Month-end / finance / legal-adjacent prose when in scope for the project  
- Force-push, history rewrite, or other hard-to-reverse git ops (unless conventions already
  authorize a specific automated path with its own ratchet)  
- New always-on cron / gateway schedules that change unattended behavior  

### Escalate (do not act)

Stage evidence + recommendation; stop. Examples:

- Path not established / invent-NEXT pressure  
- Invalid or missing review evidence before integrate  
- Gates red, thrash bound, or soft-check forces prior-slice work  
- Security, legal, personnel, production data destruction, large refunds / suspensions (ops
  projects) — or any irreversible production action without a written authorize path  
- Ambiguous approval tier — prefer escalate over guessing  
- Unsafe automation context: dirty primary checkout when isolation was required; missing
  worktree when pre-wake demanded one  

## Claim-class live verification

Before asserting a **product or ops fact** that others will act on (PR body, channel reply,
status that claims “fixed / live / shipped / missing capability”):

1. **Memory is not the citation.** Policies and compound entries say *where to look*.  
2. **Verify against live SoT** at decision time: repo / releases / `gh` / CI / deploy banner /
   project-specific console or docs — whatever the project’s real SoT is.  
3. **Code exists ≠ feature live.** Behind flags, partial ramps, or unmerged branches must be
   described as in progress unless live state confirms otherwise.  
4. Failures of memory become **dated rules** via `/workflow:compound` (see compound dated-rule
   shape) — do not only apologize in chat.

Soft-check: advisory on status; on continue, surface before broadcast-shaped or claim-class
actions. Do not invent numbers or capability absences from training data.

## Silence and claimable-only

- **Never invent NEXT** from fatigue, residual notes, or empty queues (`gates.md` path rules).  
- **Silence is acceptable** when no claimable unit exists or policy says stay quiet.  
- Automation entries that would invent work → **escalate** / hard_stop, not “find something.”  

## Automation vs project merge convention

**One process dialect.** Project `conventions.md` states process defaults (e.g. autonomous
local-merge for human continue). **Agent / host overlays** (profile, SOUL, controller policy)
may require always-PR for unattended workers **without** renaming phases or inventing a second
process dialect.

| Actor | Typical integrate path |
|-------|------------------------|
| Human + continue (personal factory defaults) | Local merge when ratchet green; push/PR user-initiated |
| Automation instance (explicit overlay) | Open PR; stop at E-MERGE / review gates; no silent merge to main unless overlay + ratchet say so |

Record the effective overlay on the run or session-state when it differs from project defaults
(`source_channel`, note, or `merge_policy_overlay:`). Consumers capture process lessons; they do
not fork skill text.

## Host binding (not process SoT)

Hosts may bind this file into profile identity (e.g. Hermes SOUL) or pre-wake prompts. **Process
SoT remains this reference + gates/soft-checks.** Host MEMORY is not a substitute runs ledger.
