# Jarvis — CoS identity, research-sweep wedge, multi-agent config lanes

## Problem Statement

You (solo builder / portfolio owner) miss high-leverage **external** signal—research, trends, announcements, and discussions that are directly *or non-obviously* related to your in-flight projects—because morning browse of X/HN/newsletters is manual and inconsistent. You need a **second Hermes identity (Jarvis)**, not a mode of Kevin: a personal chief of staff whose first job is a **fixed morning, fully unattended** research sweep that lands a short ranked **email** digest you will actually read, trained to surface pattern-matches and opportunity signal—not keyword hits.

That research wedge is **one problem of many** Jarvis will eventually own. As CoS, Jarvis must also be **easy to talk to** day-to-day—terminal (especially a remote shell into Docker) is the wrong product UX. Building Jarvis must establish a **single remote instance** (so state/sessions never fragment), **chat-channel interaction from day 1**, an identity/runtime/skills channel, and **secrets/config UX** that later CoS capabilities can attach to—without dragging Kevin’s factory process pack into the lane. Because both agents are managed **configuration-in-code** from this repo while Hermes also allows live/operator/agent mutation of the installed profile, the same program must define **three-lane ownership** and apply **parallel Kevin adjustments** so policy SoT, secrets, and adaptive state do not collide on either agent.

## Proposed Solution

Ship **one Jarvis**: Hermes profile `jarvis` on a **dedicated sibling Docker image** with a **single durable data volume** as the only production home (no productized local/workstation dual install—unlike Kevin). Runtime always runs **gateway** (for chat) **and** **cron** (for the morning ritual).

**Interaction split (day-1):**

| Surface | Role |
|---------|------|
| **Slack DM / home channel** | Primary human↔Jarvis talk (steer, Q&A, project-list updates, ad-hoc CoS). Hermes Socket Mode on the remote instance. |
| **Email** | Unattended morning research digest delivery (async read ritual). |
| **Terminal / `hermes -p jarvis`** | Ops only (doctor, secrets fill, debug)—not daily conversation UX. |

First ritual: daily multi-project **external** research (web + X) → short ranked email digest with non-obvious relevance. Project lens: hybrid manual seed + auto-suggest (adaptive state), editable via Slack as well as state files. Skills: **no factory/process pack**; new Jarvis skill families via agent-tools `src/` → publish (hermes dialect) → product stamp `jarvis`.

Simultaneously land **shared multi-agent doctrine** for Kevin and Jarvis:

| Lane | SoT | Mutated by | On re-apply |
|------|-----|------------|-------------|
| Policy | Git distribution | PR + apply / `--force-config` | Overwritten |
| Secrets & bindings | Live `.env` / `auth.json` | Operator (+ approved agent help) | Preserved |
| Adaptive state | Live allowlisted state paths | Agent + operator (incl. via Slack) | Preserved |

Agent may **propose** policy changes; must not silent-commit them. Unattended Jarvis may research, compose, and send the digest email; must not mutate policy files.

**Kevin parallel work** in this program: upgrade control-plane / profile docs to three-lane doctrine, align apply/`--force-config` language, share packaging/secrets patterns, and **explicitly document instance topology**—Kevin may remain dual (workstation + isolated); Jarvis is **single remote only**—so the two products do not copy the wrong install shape.

### Why This Approach

- Clear non-overlap with Kevin (identity, skills product, image, job shape, **install topology**).
- Single CoS brain: one state/session/secrets home; no “which Jarvis did I talk to?”
- Chat-first daily UX (Slack) + email for async digests matches how a CoS should feel.
- Matches remote Docker + cron without forcing remote-terminal as the talk path.
- Concrete first success (digest + reachable chat) while spine supports later CoS capabilities.
- Fixes live config vs git SoT for **both** products; reuses agent-tools skill craft without factory IP on Jarvis.

### Alternatives Considered

- **Kevin mode / same profile:** rejected — factory ceremony and CoS jobs conflict; ADR-005 anticipates separate product.
- **Kevin-style dual local + remote Jarvis:** rejected — fragments CoS memory/state; weakens the role.
- **Host Hermes local install as product path:** rejected — second instance risk; day-1 product is single remote.
- **Terminal / remote shell as primary talk UX:** rejected — wrong CoS experience.
- **Chat channels later; cron/email only day-1:** rejected by user — interactive reachability is day-1 ship criteria.
- **Multi-messenger day-1 (Slack + Telegram/…):** deferred — Slack only for v1 to bound packaging.
- **Dashboard-only chat:** rejected in favor of Slack DM/home (phone/desktop messenger UX).
- **Same image, second profile only:** rejected — user chose dedicated jarvis image; Kevin hard-coding makes sibling clearer for v1.
- **Approval-gated email send:** rejected for v1 happy path; may revisit for higher-risk CoS acts.
- **Jarvis without skills pack:** rejected — use publishing mechanisms; jarvis-isolated skills initially.
- **Strict “always force-config; live never durable”:** rejected in favor of three-lane model.

## Decomposition mode

**Deliverable-partition** (greenfield multi-artifact: packaging, doctrine, secrets spine, chat transport, ritual).

## Deliverables / Sub-issues

### D1 — Shared multi-agent config lanes doctrine (Kevin + Jarvis)

**Scope:** Document and operationalize three-lane ownership, promotion rules (live → git manual), unattended policy-mutation deny posture, drift guidance, and **instance topology** (Kevin dual install OK; Jarvis **single remote only**). Update Kevin control-plane / profile runbooks. Optional lightweight drift check design.

**Inherited parent ACs:** AC1, AC2, AC10, AC16

**Tasks (indicative):**
- Author shared doctrine (runbook or ADR-level decision; rewrite competing Kevin sync prose in place).
- Point Kevin + Jarvis profile READMEs at lanes table + topology note.
- Define unattended policy-path deny rules.

**DoD:** Doctrine reviewable; Kevin docs updated; Jarvis single-instance rule explicit; no contradictory SoT claims.

**Dependencies:**
- blocks: D2, D3, D4, D5, D6, D7, D8
- blocked_by: none
- parallelizable_with: none (land first)

### D2 — Jarvis Hermes profile distribution

**Scope:** Versioned profile root for `jarvis` (distribution.yaml, config.yaml, SOUL CoS host-bind, `.env.template`, blank bundled skills, apply-from-repo for **packaging/dev and single remote home**—not a multi-laptop product path). CoS policy: no process pack; Jarvis skills root placeholder; platform toolsets include **slack** + cli; adaptive state convention.

**Inherited parent ACs:** AC3, AC4, AC16

**Tasks (indicative):**
- Add jarvis profile tree under `hermes/`.
- Apply script targeting the production data volume workflow.
- Slack config placeholders (CoS-branded; pattern from Kevin, not factory channel bindings).

**DoD:** Profile installs into the single production home; secrets not in git; docs forbid multi-instance product use.

**Dependencies:**
- blocks: D3, D6, D8
- blocked_by: D1
- parallelizable_with: D4, D5, D7

### D3 — Jarvis Docker image + always-on remote host packaging

**Scope:** Sibling of kevin-hermes: Dockerfile (bake jarvis skills + profile), entrypoint `jarvis`, compose with **one** durable data volume as production SoT, CI, runbook for **gateway (Slack) + morning cron**. No product-repo mount required. Explicit non-goal: second “local jarvis” product install.

**Inherited parent ACs:** AC5, AC6, AC16

**Tasks (indicative):**
- Image build/publish; fail-closed entrypoint.
- Gateway default (Socket Mode; no published ports required).
- Cron shape for digest; volume backup/restore as continuity story.

**DoD:** Image builds; gateway under `jarvis` starts; single-remote runbook complete.

**Dependencies:**
- blocks: D6, D8
- blocked_by: D2, D4
- parallelizable_with: D5, D7

### D4 — Jarvis skills product pack (research ritual + publish)

**Scope:** Jarvis skills in `src/` for research sweep (web+X, ranking, non-obvious pattern match, digest schema, project lens). Publish hermes dialect; product stamp `jarvis`. **Exclude** factory process-pack skills.

**Inherited parent ACs:** AC7, AC8

**Tasks (indicative):**
- Skill family under `src/`; pack scripts per ADR-005; bake path for D3.

**DoD:** Non-empty jarvis pack; product=jarvis stamp; no process-pack skills.

**Dependencies:**
- blocks: D3, D6
- blocked_by: D1
- parallelizable_with: D2, D5, D7

### D5 — Secrets & capability configuration UX (shared spine)

**Scope:** Capability attachment pattern: secret **names** in templates/`env_requires`, live values only in profile home, capability checklist. Jarvis v1 capabilities: model auth, web/X as needed, **email send**, **Slack**. Align Kevin auth/Slack docs to same vocabulary (do not re-home Kevin Slack ownership).

**Inherited parent ACs:** AC9, AC11, AC17

**Tasks (indicative):**
- Jarvis `.env.template` (model + email + Slack token names).
- Capability matrix (research, email, slack, future…).
- Kevin docs cross-link shared spine language.

**DoD:** Operator can configure digest + Slack without committing values; missing capability fails loud; Kevin uses same lane vocabulary.

**Dependencies:**
- blocks: D6, D8
- blocked_by: D1
- parallelizable_with: D2, D4, D7

### D6 — Daily research-sweep ritual (end-to-end wedge)

**Scope:** Unattended morning job: load project lens, research web+X, rank short digest, send email. Fully auto happy path. Cron on single remote host (D3). Project list seed + minimal auto-suggest; list also maintainable via Slack once D8 lands.

**Inherited parent ACs:** AC12, AC13, AC14, AC15

**Tasks (indicative):**
- Ritual entry for cron; dry-run mode; operator smoke (email or accepted dry-run residual).

**DoD:** Smoke path green; quality bar met at least once (real or fixture dry-run).

**Dependencies:**
- blocks: none
- blocked_by: D2, D3, D4, D5
- parallelizable_with: D8 (chat can land in parallel once D3/D5 ready; ritual does not require Slack send)

### D7 — Kevin parallel packaging/doctrine adjustments

**Scope:** Kevin-side three-lane language, `--force-config` clarity, capability-spine vocabulary, and **explicit dual-install vs Jarvis single-remote** topology note. Packaging hooks if shared utilities land. **Does not** redesign factory wake or process pack.

**Inherited parent ACs:** AC1, AC2, AC10, AC11, AC16

**Tasks (indicative):**
- Doc/ADR updates; link shared doctrine from kevin-hermes runbooks.

**DoD:** Kevin bring-up still works; docs consistent; topology contrast documented.

**Dependencies:**
- blocks: none
- blocked_by: D1
- parallelizable_with: D2, D4, D5

### D8 — Jarvis Slack chat transport (day-1 interactive UX)

**Scope:** CoS-branded Slack app packaging (manifest, Socket Mode, allowlisted user(s), DM and/or home channel), wired to the **same** remote jarvis gateway/profile as cron and state. Runbook: talk to Jarvis from Slack without terminal. Terminal remains ops-only.

**Inherited parent ACs:** AC17, AC18

**Tasks (indicative):**
- Manifest/setup pack under docs or hermes (jarvis-scoped, not Kevin factory brand).
- Profile slack toolset + bindings; secrets via D5.
- Smoke: operator DM or home-channel message gets a CoS reply from the single remote instance.

**DoD:** Documented Slack bring-up; live reply smoke on production home; no second instance required for chat.

**Dependencies:**
- blocks: none
- blocked_by: D2, D3, D5
- parallelizable_with: D6, D7

## AC Traceability Matrix

| Parent AC | Owning sub-issue | Verified at |
|-----------|------------------|-------------|
| AC1 | D1, D7 | D1/D7 close |
| AC2 | D1, D7 | D1/D7 close |
| AC3 | D2 | D2 close |
| AC4 | D2 | D2 close |
| AC5 | D3 | D3 close |
| AC6 | D3 | D3 close |
| AC7 | D4 | D4 close |
| AC8 | D4 | D4 close |
| AC9 | D5 | D5 close |
| AC10 | D1, D7 | D1/D7 close |
| AC11 | D5, D7 | D5/D7 close |
| AC12 | D6 | D6 close |
| AC13 | D6 | D6 close |
| AC14 | D6 | D6 close |
| AC15 | D6 | D6 close |
| AC16 | D1, D2, D3, D7 | D1–D3/D7 close |
| AC17 | D5, D8 | D5/D8 close |
| AC18 | D8 | D8 close |

### Gap-prevention

- [x] Every parent AC owned; shared ACs dual-close only where listed
- [x] Inherited AC text verbatim below
- [x] Dependency order recorded

## Key Requirements

### Must Have

- Hermes profile **`jarvis`** as sibling identity to Kevin; not a Kevin mode.
- **Single remote production instance** (one image deployment + one durable data volume)—no productized local/workstation dual install.
- **Day-1 interactive UX via Slack** (DM and/or home channel) on that same instance; terminal is ops-only.
- No Kevin **process pack** / factory `/work` skills on Jarvis.
- Jarvis skills via **agent-tools publishing** (hermes dialect, product stamp jarvis).
- **Dedicated jarvis Docker image** + data volume; **gateway + morning cron** both required for ship.
- **Three-lane config ownership** for Kevin and Jarvis; topology contrast documented (Kevin dual OK).
- **Secrets/capability UX** spine: model, email, Slack; Kevin docs aligned in vocabulary.
- **Daily research sweep:** web + X; hybrid project list; short ranked digest; **email** delivery; fully unattended happy path.
- Unattended **deny** for policy-file mutation and non-email irreversible acts.
- Kevin remains coding/factory implementer; Jarvis does not implement product code.

### Nice to Have

- Drift doctor script/check (live policy vs dist).
- Dry-run digest without send as first-class flag.
- Auto-suggest for project list beyond minimal hook.
- Thin ops CLI alias (`jarvis` → `hermes -p jarvis` on remote host).
- Parameterized multi-product Dockerfile extract.
- Optional digest summary ping in Slack (email remains primary digest delivery).

### Out of Scope

- Full CoS surface (calendar, inbox triage, tasks, follow-ups) beyond research wedge + chat steer.
- HN/Reddit/forums and RSS/newsletters as v1 sources.
- **Productized multi-instance or local Jarvis install** (second brain).
- Second messenger network day-1 (Telegram, Discord, iMessage, etc.).
- Terminal/remote-shell as primary conversation UX.
- Approval gate on digest email send (v1).
- Loading factory process pack onto Jarvis.
- Redesign of Kevin unattended factory wake / continue semantics or removal of Kevin dual modes.
- Personify depth beyond thin CoS SOUL / adaptive state convention.
- Every future capability integration—only spine + research/email + Slack.

## Parent Acceptance Criteria (verbatim for inheritance)

- [ ] **AC1:** Three-lane ownership (policy / secrets & bindings / adaptive state) is documented as shared doctrine for Kevin and Jarvis, including promotion rules (live → git only by explicit human/PR path).
- [ ] **AC2:** Re-apply / `profile update` behavior is documented per lane: policy reset with `--force-config`; secrets and adaptive state preserved; UI/agent live policy edits treated as non-SoT until promoted.
- [ ] **AC3:** A versioned Hermes profile distribution for `jarvis` installs successfully (apply or `profile install`) without committing secrets.
- [ ] **AC4:** Jarvis profile policy does not point at Kevin process-pack skills; SOUL/host-bind presents CoS (non-implementer), not factory coding host.
- [ ] **AC5:** A dedicated jarvis Docker image builds from this repo and starts Hermes under profile `jarvis` with baked jarvis skills (not raw `src/`).
- [ ] **AC6:** Runbook documents single-remote jarvis bring-up, data volume for live state/secrets/sessions, morning cron/job registration for the research ritual, and gateway start for Slack.
- [ ] **AC7:** Jarvis skill content for the research ritual exists under agent-tools `src/` and publishes through the hermes dialect into a **jarvis** product pack/stamp.
- [ ] **AC8:** Jarvis product pack does **not** include Kevin process-pack / factory work skills.
- [ ] **AC9:** Secret **names** for model auth, email send, and Slack are declared in jarvis templates/`env_requires`; live values exist only in the profile home / volume; never in git.
- [ ] **AC10:** Unattended jarvis posture denies policy-file self-mutation; agent-proposed policy changes require human promotion to git.
- [ ] **AC11:** Kevin auth/control-plane/profile docs use the same three-lane and capability-spine vocabulary (parallel adjustment), without breaking existing Kevin bring-up.
- [ ] **AC12:** Operator can seed an in-flight project list (adaptive state); jarvis research ritual uses it as the relevance lens; auto-suggest may be minimal but path exists.
- [ ] **AC13:** One unattended (or cron-equivalent) research run uses **web + X**, produces a short ranked digest emphasizing non-obvious pattern matches and high-leverage opportunity signal (not keyword-only dump).
- [ ] **AC14:** Digest is delivered by **email** on the happy path without interactive approval.
- [ ] **AC15:** Operator smoke (or documented dry-run with explicit residual) proves the research→email path; failure modes for missing secrets/capabilities fail loud.
- [ ] **AC16:** Product docs and packaging treat Jarvis as a **single remote instance** (one production data home); multi-instance or local dual-install is not a supported product path (Kevin dual modes remain valid and are explicitly contrasted).
- [ ] **AC17:** Slack capability (Socket Mode tokens, allowlisted user(s), DM and/or home channel) is packageable for jarvis via the secrets/capability spine and CoS-branded setup materials.
- [ ] **AC18:** Operator can have an interactive CoS conversation with Jarvis via Slack on the **same** remote instance that holds adaptive state and runs cron—without using terminal as the conversation surface; smoke proves at least one successful reply path.

## Dependencies

- **D1 — Shared multi-agent config lanes doctrine**
  - blocks: D2, D3, D4, D5, D6, D7, D8
  - blocked_by: none
  - parallelizable_with: none (land first)
- **D2 — Jarvis Hermes profile distribution**
  - blocks: D3, D6, D8
  - blocked_by: D1
  - parallelizable_with: D4, D5, D7
- **D3 — Jarvis Docker image + always-on remote host packaging**
  - blocks: D6, D8
  - blocked_by: D2, D4
  - parallelizable_with: D5, D7
- **D4 — Jarvis skills product pack**
  - blocks: D3, D6
  - blocked_by: D1
  - parallelizable_with: D2, D5, D7
- **D5 — Secrets & capability configuration UX**
  - blocks: D6, D8
  - blocked_by: D1
  - parallelizable_with: D2, D4, D7
- **D6 — Daily research-sweep ritual**
  - blocks: none
  - blocked_by: D2, D3, D4, D5
  - parallelizable_with: D8
- **D7 — Kevin parallel packaging/doctrine adjustments**
  - blocks: none
  - blocked_by: D1
  - parallelizable_with: D2, D4, D5
- **D8 — Jarvis Slack chat transport**
  - blocks: none
  - blocked_by: D2, D3, D5
  - parallelizable_with: D6, D7

## Success Criteria

### Functional

- [ ] Single-remote jarvis bring-up per runbook (one volume = production home).
- [ ] Operator talks to Jarvis via Slack and gets a reply without terminal chat UX.
- [ ] Morning (or equivalent) unattended run produces email digest for seeded projects.
- [ ] Digest is short, ranked, and judged useful on non-obvious / opportunity signal at least once.
- [ ] Missing email, Slack, or model secrets fail loud.
- [ ] Kevin still installs/applies and doctors under existing paths after parallel doc/spine changes.

### Quality

- [ ] No secrets in git; images contain no live credentials.
- [ ] Three-lane doctrine + topology contrast consistent across Kevin and Jarvis docs.
- [ ] Jarvis pack contains no factory process skills.
- [ ] Unattended digest path does not require Slack interaction; interactive path does not require terminal.

### Business / product

- [ ] You can stop manual morning multi-source browse as the primary system for portfolio-external signal.
- [ ] You can reach Jarvis as CoS from your phone/desktop messenger in normal life—not only when SSH’d to a box.
- [ ] One Jarvis brain: no split context across local vs remote instances.
- [ ] Config-as-code and live Hermes mutation coexist without surprise stomps on either agent.

## Open Questions

- [ ] Email transport (SMTP vs provider API) and exact secret names — plan-time.
- [ ] Adaptive state file layout vs optional Hermes memory for Jarvis — default: explicit state file.
- [ ] GHCR image name and CI workflow layout — plan-time.
- [ ] How aggressive auto-suggest for projects is in v1 — default: minimal.
- [ ] Whether to extract shared Docker/apply fragments in first implementation or sibling-copy — plan default: sibling-copy first.
- [ ] Slack: DM-only vs home channel + DM — default: home channel + DM, allowlisted user(s).
- [ ] Tracking issue in Linear optional after refine (file mode).

## Related

- Brainstorm: `.agent-tools/planning/jarvis/brainstorm.md`
- Codebase research: `.agent-tools/planning/jarvis/codebase-research.md`
- Design discussion: `.agent-tools/planning/jarvis/design-discussion.md`
- Issue: Not created
- Implementation Plan: (after `/work:plan`)
- ADR touchpoints: `docs/kevin/decisions/005-skills-dialect-vs-product.md` (jarvis pack now in scope); Kevin control-plane config sync → three-lane rewrite; instance topology (Kevin dual vs Jarvis single)

---
Created: 2026-07-27
Status: Draft
requirements_source: file
decomposition_mode: deliverable-partition
