# Design discussion: Jarvis CoS wedge + multi-agent config lanes

Status: Draft (refine)
Grounded in research: `.agent-tools/planning/jarvis/codebase-research.md`

## Current state

- One Hermes product identity is packaged in-repo: **Kevin** (profile, skills channel, Docker image, unattended wake for factory continue).
- Config-as-code exists for Kevin with an implicit but incomplete split: git policy SoT, live secrets preserved, live `config.yaml` optionally drifted via UI/`config set`/agent edits until `--force-config`.
- No Jarvis profile, image, skill pack, email digest, or CoS rituals.
- ADR-005 anticipates Jarvis as a non-process-pack Hermes product; packaging is still Kevin-only hard-coding (`/opt/kevin`, profile name `kevin`).

## Desired end state

1. **One Jarvis** — a **single remote** Hermes instance (dedicated sibling Docker image + durable data volume). **No** Kevin-style dual local/remote product install. All adaptive state, secrets, sessions, and digests live in that one home so CoS context never splits by “which Jarvis.”
2. **Interaction model (day-1):** **Slack DM / home channel** is the primary human↔Jarvis UX (Hermes gateway, Socket Mode — same transport class Kevin dogfoods). Terminal/`hermes -p jarvis` is **ops only** (doctor, apply, debug), not the product conversation surface. Morning **email** remains the unattended digest push channel (async read ritual); Slack is for steering, Q&A, project-list updates, and ad-hoc CoS talk.
3. **Ritual:** cron-primary morning **external research digest → email**, relevance lens = hybrid project list, sources v1 = web + X.
4. Jarvis has **no Kevin process pack**; **Jarvis skills** via agent-tools publish/pack (product stamp `jarvis`, dialect `hermes`), jarvis-isolated first.
5. **Shared multi-agent doctrine** (Kevin + Jarvis): three-lane ownership for config/state.
6. **Secrets + capability config UX** spine (model, email, Slack, future CoS systems).
7. **Kevin parallel adjustments** for doctrine/packaging language — Kevin **keeps** workstation + isolated dual modes; that dual is correct for a coding agent, wrong for CoS.

## Patterns found (accept / reject)

| Pattern / location | Verdict | Notes |
|--------------------|---------|-------|
| Kevin profile distribution (`hermes/profile/`) | **accept** | Mirror layout for Jarvis; do not fork process pack into profile `skills/` |
| Apply wrapper + skills path placeholder | **accept** | `apply-jarvis-profile.sh` sibling; shared substitute pattern |
| Entrypoint hard-coded `kevin` | **supersede** | Parameterize product name **or** ship dedicated `entrypoint-jarvis.sh` / image; no dual-profile in one Kevin image for v1 |
| Kevin factory pre-wake | **reject** for Jarvis research | Wrong fail-closed contract; Jarvis wake is research/digest oriented |
| Config sync story (control-plane runbook) | **accept + expand** | Promote to shared **three-lane** doctrine; apply to both agents |
| Kevin dual workstation + isolated installs | **reject** for Jarvis product | CoS weakens if state/sessions split across instances; Kevin dual remains valid for coding |
| Terminal / remote shell as primary CoS UX | **reject** | Wrong surface for daily talk; ops-only |
| Slack Socket Mode gateway (Kevin pattern) | **accept** for Jarvis interactive UX day-1 | Transport only; CoS-branded app; DM/home channel; secrets in live `.env` |
| Email as morning digest delivery | **accept** | Complements Slack (async push vs interactive) — not either/or |
| ADR-005 dialect vs product | **accept** | Implement first jarvis product pack (research/CoS skills), still no process pack |
| Agent freestyle rewrite of live `config.yaml` | **reject** as unattended default | Proposal-only for policy; approvals/deny for unattended |
| Memory-off Kevin factory posture | **accept for Kevin**; **decide for Jarvis** | Adaptive state may use memory **or** dedicated state files under profile home — prefer explicit state file for project list in v1 |

## System flow and premise checks

| State / effect | Authoritative writer | Readers / projections | Transport / round trip | Why required |
|----------------|----------------------|-----------------------|------------------------|--------------|
| Policy (approvals, tool bounds, skills roots, identity SOUL) | Git dist → apply / `--force-config` | Live profile, gateway, doctor | Install/update | Shared, reviewable product defaults |
| Secrets & bindings (keys, SMTP, addresses, channel IDs) | Operator (+ agent with approval) on live `.env` / `auth.json` | Runtime only | Live home volume | Never in git; never stomped by apply |
| Adaptive state (project list, digest prefs, last run) | Agent + operator under allowlisted state paths | Research ritual, future CoS jobs | Profile state dir / optional memory | Survives re-apply; not policy |
| Digest content | Jarvis unattended run | Human via email | External SMTP/API | Async morning wedge value |
| Interactive CoS turns | Human via Slack DM/home | Jarvis gateway session on **same** remote instance | Hermes Slack Socket Mode | Day-1 talk UX without terminal |
| Skill IP (research ritual process) | `src/` → publish → jarvis pack/image bake | Jarvis runtime `external_dirs` | Product channel | Same craft as Kevin skills, different product stamp |

Ticket / proposed-solution assumptions challenged:

- “Scan my projects” — **overturned** by user: external internet signal mapped *to* projects (direct + non-obvious pattern match).
- “Reuse Kevin pre-wake” — **overturned**: factory worktree gate is wrong for CoS research.
- “Email already in product” — **false** in-repo; capability must be designed (host tool + secrets + allow unattended send).
- “Config-as-code prevents live edits” — **false**: Hermes preserves/allows live `config.yaml` drift; product must define lanes + promotion, not pretend immutability.
- “Jarvis needs no skills” — **softened by user**: no *factory* skills; **yes** to new skill families via agent-tools publishing.
- “OOB chat later; terminal OK for steer” — **overturned by user**: CoS UX requires easy talk day-1; terminal (esp. remote-to-Docker) is wrong product surface. Chat channel is in-scope for ship.
- “Mirror Kevin local + remote dual install” — **overturned**: multiple Jarvis instances fragment CoS memory/state; **single remote instance** only.

## Resolved decisions

- **Three-lane ownership (Kevin + Jarvis doctrine):**
  1. **Policy** — git distribution; apply / `--force-config` overwrites.
  2. **Secrets & bindings** — live only; apply preserves; never commit values.
  3. **Adaptive state** — live allowlisted paths (and/or memory if enabled); apply preserves; not distribution-owned policy files.
- **Promotion rule:** live → git is **manual / explicit proposal** only. Agent may propose policy deltas; must not silent-commit or treat UI as SoT.
- **Single remote instance:** one durable Jarvis home (image + data volume). No productized local/workstation Jarvis install. Dev-time profile apply from monorepo may exist for packaging iteration only — not a second SoT for daily use.
- **Interaction split (day-1):**
  - **Slack DM / home** — primary interactive CoS UX (gateway always on with the remote instance).
  - **Email** — unattended morning digest delivery.
  - **Terminal** — ops/doctor/debug only; not marketed or required for daily talk.
- **Unattended Jarvis v1:** research + compose + **send email** fully auto; no approval gate on happy path; deny policy-file mutation and irreversible non-email acts. Slack interactive turns use normal gateway session policy (not “must approve every digest”).
- **Runtime day-1:** dedicated **jarvis** Docker image; **cron + Slack gateway** both required for ship (not cron-only).
- **Sources v1:** web + X; HN/forums deferred.
- **Project lens:** hybrid manual seed + occasional auto-suggest (state lane); list editable via Slack as well as state file.
- **Digest quality bar:** short ranked (~5–10) with **non-obvious pattern matches** and high-leverage opportunity signal — not keyword dump.
- **Skills:** no process pack; Jarvis skills authored in `src/`, published hermes dialect, product-stamped `jarvis`; jarvis-isolated initially; harness-portable tagging allowed when it makes sense.
- **Scope expansion:** when building multi-agent packaging, config lanes, secrets/capability UX, and drift story for Jarvis, **make the parallel Kevin adjustments in the same program** (docs + shared patterns + packaging hooks), not “Jarvis-only debt.” Kevin dual install modes stay; do not project them onto Jarvis.
- **Kevin remains** coding/factory; Jarvis remains non-implementer of product code.

## Open questions

- [ ] Email transport specifics (SMTP provider vs API, which secret names) — default: names in jarvis `.env.template`; pick one transport at plan time.
- [ ] Exact state file layout for project list (`state/projects.md` vs Hermes memory) — default: **explicit state file**, memory optional later.
- [ ] Whether Docker ARG multi-product single Dockerfile is worth it in v1 vs copy-adapt kevin Dockerfile — default: **sibling files first**, extract shared fragments if duplication hurts.
- [ ] Personify / SOUL depth for Jarvis voice — default: thin CoS SOUL; personify later.
- [ ] CLI branding for ops (`jarvis` wrapper vs `hermes -p jarvis` only) — default: `hermes -p jarvis` on remote host; not product chat UX.
- [ ] Slack app: DM-only vs home channel + DMs — default: **home channel + DM**, allowlisted user(s), Socket Mode.

## Requirements impact

- Parent epic must include **shared doctrine + Kevin parallel adjustments + single-instance + Slack day-1 chat**, not only research cron.
- Parent ACs for config lanes, secrets/capability spine (incl. Slack), packaging, gateway chat, research ritual, and Kevin parity of doctrine.
- Out of scope: full CoS (calendar/mail triage/tasks), HN/forums sources, **productized local Jarvis install**, multi-instance Jarvis, second chat network day-1 (Telegram/etc.), factory skills on Jarvis, email approval gate on happy path.
- Decision corpus: extend ADR-005 consequences (jarvis pack now in scope); rewrite/expand Kevin control-plane config sync into three-lane shared doc rather than competing ADRs; document **instance topology** difference (Kevin dual OK; Jarvis single remote).

## Deliberately undecided (for plan)

- File tree names (`hermes/jarvis-profile/` vs `hermes/profiles/jarvis/`).
- Exact cron expression / timezone handling.
- SMTP library vs Hermes-native mail if upstream provides one.
- Whether drift doctor is a script, skill, or `kevin`/`jarvis doctor` extension.
- CI job naming and GHCR image name (`jarvis-hermes` vs `jarvis`).

---
Created: 2026-07-27
