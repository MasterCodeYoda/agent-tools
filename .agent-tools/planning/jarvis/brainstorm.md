# Brainstorm: Jarvis — second Hermes agent alongside Kevin

Status: Explored  
converged_by: user  
updated: 2026-07-27

## Seed Concept

**Jarvis** is a **personal chief of staff** on Hermes — a sibling to Kevin, not a mode of Kevin. It runs as its **own Hermes profile** (`jarvis`), **without** the agent-tools / Kevin skills package (it is not a software factory). Primary pulse is **remote, unattended Docker + cron**; you can still **open a chat and steer out-of-band**. First job-to-be-done that pulls the product into existence: a **daily research sweep** that surfaces news, thought pieces, articles, and conversations with applicability or interesting pattern-overlap to **your in-flight projects** (all of them), delivered in a form you will actually read. Broader CoS value (calendar, mail, tasks, follow-ups, other rituals) is allowed to grow under the same identity, but is not required for the first definition of success. Kevin remains the coding/factory agent; Jarvis remains non-implementer of product code.

## The Itch

Kevin owns factory coding (process pack, project-repo session, workstation CLI). You need a **second Hermes identity** for **non-factory** work: especially **scheduled, unattended** research/synthesis over your portfolio of projects, plus room for other personal ops — without dragging `/work` ceremony or Kevin skills into that lane. Runtime must match the job: **Docker remote + cron-heavy**, with **ad-hoc chat** as a second door.

## Directions Considered

### Round 1

- **A — Personal chief of staff (life ops)** — closest domain; initially light on runtime shape  
- **B — Factory operator surface** — meta-control of Kevin; not chosen as primary  
- **C — Gateway companion** — chat/gateway-first ambient; not cron-primary  

### Round 2

- **D — Cron-primary personal chief of staff** — schedule default; chat steers / ad-hoc  
- **E — Approval-gated personal ops daemon** — cron proposes; human approves risky acts  
- **F — Ambient co-equal** — chat and cron peers  

**User converge:** Chief of Staff domain; initial driver = **daily research sweep** for in-flight projects; CoS can own that and more. Runtime constraints retained (Docker remote, cron-heavy, OOB chat). Interaction model treated as **D-leaning** (cron-primary), with approval policy left for refine.

## Chosen Direction

**Cron-primary personal chief of staff (Hermes profile `jarvis`), wedge = daily multi-project research sweep.**

Why it won:

- Clear **non-overlap with Kevin** (no factory skills pack; not repo-implementer)  
- Matches stated **runtime** (remote Docker, unattended, cron)  
- Concrete first ritual (research sweep) makes “responsible for / how used” testable  
- Room to grow other CoS duties without re-homing the agent later  

## Deliberately Undecided

- Digest format/channel (email, Slack DM, file drop, Hermes send, …)  
- How “in-flight projects” are enumerated (manual list, Linear, disk convention, …)  
- Source set for the sweep (web, X, RSS, newsletters, internal docs, …)  
- Approval gates for any *outbound* or irreversible actions (E-lite policy or not)  
- Image packaging (sibling of kevin-hermes vs dedicated jarvis image)  
- Secrets/models vs Kevin (shared host, separate profile stores)  
- Personify / memory posture for Jarvis  
- Exact CLI/entry branding for ops (`jarvis` vs hermes -p only)  
- When broader CoS jobs (calendar/mail/tasks) land relative to research wedge  

## Open Questions for Refinement

_Resolved in refine (see `requirements.md` / `design-discussion.md`):_ digest → email; sources web+X; hybrid project list; unattended research+email; three-lane config; single remote instance; **Slack day-1 chat**; no productized local dual install; Kevin parallel doctrine adjustments.

- [x] What is a **pass** for one daily research sweep — short ranked ~5–10, non-obvious pattern matches  
- [x] Where does the digest **land** — email  
- [x] How does Jarvis learn **in-flight project** set — hybrid seed + auto-suggest  
- [x] What tools/sources for v1 — web + X; HN later  
- [x] Unattended safety — research+email auto; policy mutation denied  
- [x] Chat UX day-1 — Slack DM/home on same remote instance; terminal ops-only  
- [x] Instance topology — single remote; not Kevin-style dual  
- [ ] Residual plan-time: email transport, GHCR name, Slack DM vs home detail, state file layout  

