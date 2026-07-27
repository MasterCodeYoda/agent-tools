---
project: jarvis
work_item: null
blocks: []
blocked_by: []
parallelizable_with: []
decomposition_mode: deliverable-partition
requirements_source: file
---
# Implementation Plan: Jarvis — CoS wedge + multi-agent spine

## Approach

Ship **one remote Jarvis** (Hermes profile `jarvis` + sibling `jarvis-hermes` image + single durable volume): morning research→email digest, day-1 Slack DM/home on the same instance, no productized local dual install. Land **shared three-lane config doctrine** and parallel Kevin pack/docs so product packs never cross-contaminate skills.

**Waves:** D1 doctrine → parallel D2/D4/D5/D7 → D3 runtime → parallel D6/D8.

**Key insight:** Product pack allowlists land with first jarvis skill (D4) and Kevin filter (D7) **before** D3 image bake — `pack-kevin-skills.sh` currently copies all hermes skills wholesale.

## Research grounding

- **Codebase research:** `.agent-tools/planning/jarvis/codebase-research.md`
- **Summary:** Kevin packaging hard-codes profile/image paths; config-as-code preserves user-owned secrets; no email product path; Slack Socket Mode proven; ADR-005 names jarvis as future non-process-pack product.
- **Discard research if:** `hermes/docker/*`, `hermes/profile/*`, or pack scripts change materially.

## Design

- **Design discussion:** `.agent-tools/planning/jarvis/design-discussion.md`
- **Confirm:** holds for 18 parent ACs — proceed as hypothesis.
- **Patterns to follow:** Kevin profile/apply/Slack Socket Mode; three-lane ownership; email + Slack split.
- **Patterns to reject:** dual Jarvis install; terminal as CoS UX; factory pack on Jarvis; Kevin pre-wake for research.
- **Open questions closed for implement:** see Technical Decisions.

## Structure outline

| Phase | What lands | Verify before next |
|-------|------------|--------------------|
| 0 — D1 | Three-lane + topology doctrine; Kevin sync prose aligned | Doc review; no competing SoT |
| 1 — D2, D4, D5, D7 | Profile, skills+packs, secrets matrix, Kevin filter/docs | Profile files valid; pack contents assert; templates list secrets |
| 2 — D3 | jarvis-hermes image, gateway, volume, cron shape | docker build; profile show jarvis; gateway starts |
| 3 — D6 ∥ D8 | Research→email ritual; Slack CoS smoke | Dry-run digest; Slack reply same volume |

## Intended changes (snippets)

### tools/pack-kevin-skills.sh — filter jarvis product skills

```bash
# After copy from dist/hermes, remove jarvis-prefixed skill dirs (or only copy allowlist)
# assert no directory matching jarvis* remains in kevin-skills package
```

- **Why:** Prevent CoS skills baking into kevin-hermes.
- **Verify:** `tar tzf dist/kevin-skills/kevin-skills.tar.gz | grep -i jarvis` empty (or only docs).
- **Structure phase:** 1

### hermes/docker/entrypoint-jarvis.sh — profile jarvis

```bash
# Mirror entrypoint.sh with kevin → jarvis, /opt/kevin → /opt/jarvis
PROFILE_HOME="${HERMES_HOME}/profiles/jarvis"
# exec hermes -p jarvis gateway run
```

- **Why:** Single product identity in container.
- **Verify:** container logs show `hermes -p jarvis`.
- **Structure phase:** 2

### Adaptive state path

```text
$HERMES_HOME/profiles/jarvis/state/projects.md
# NOT distribution_owned; survives profile update
```

- **Why:** Adaptive lane for project lens.
- **Verify:** re-apply profile leaves state file.
- **Structure phase:** 1–3

## Breakdown (Variant B: Deliverable-partition)

### Parent Acceptance Criteria

- [x] **AC1:** Three-lane ownership (policy / secrets & bindings / adaptive state) is documented as shared doctrine for Kevin and Jarvis, including promotion rules (live → git only by explicit human/PR path).
- [x] **AC2:** Re-apply / `profile update` behavior is documented per lane: policy reset with `--force-config`; secrets and adaptive state preserved; UI/agent live policy edits treated as non-SoT until promoted.
- [x] **AC3:** A versioned Hermes profile distribution for `jarvis` installs successfully (apply or `profile install`) without committing secrets.
- [x] **AC4:** Jarvis profile policy does not point at Kevin process-pack skills; SOUL/host-bind presents CoS (non-implementer), not factory coding host.
- [x] **AC5:** A dedicated jarvis Docker image builds from this repo and starts Hermes under profile `jarvis` with baked jarvis skills (not raw `src/`).
- [x] **AC6:** Runbook documents single-remote jarvis bring-up, data volume for live state/secrets/sessions, morning cron/job registration for the research ritual, and gateway start for Slack.
- [x] **AC7:** Jarvis skill content for the research ritual exists under agent-tools `src/` and publishes through the hermes dialect into a **jarvis** product pack/stamp.
- [x] **AC8:** Jarvis product pack does **not** include Kevin process-pack / factory work skills.
- [x] **AC9:** Secret **names** for model auth, email send, and Slack are declared in jarvis templates/`env_requires`; live values exist only in the profile home / volume; never in git.
- [x] **AC10:** Unattended jarvis posture denies policy-file self-mutation; agent-proposed policy changes require human promotion to git.
- [x] **AC11:** Kevin auth/control-plane/profile docs use the same three-lane and capability-spine vocabulary (parallel adjustment), without breaking existing Kevin bring-up.
- [x] **AC12:** Operator can seed an in-flight project list (adaptive state); jarvis research ritual uses it as the relevance lens; auto-suggest may be minimal but path exists.
- [x] **AC13:** One unattended (or cron-equivalent) research run uses **web + X**, produces a short ranked digest emphasizing non-obvious pattern matches and high-leverage opportunity signal (not keyword-only dump).
- [x] **AC14:** Digest is delivered by **email** on the happy path without interactive approval.
- [x] **AC15:** Operator smoke (or documented dry-run with explicit residual) proves the research→email path; failure modes for missing secrets/capabilities fail loud.
- [x] **AC16:** Product docs and packaging treat Jarvis as a **single remote instance** (one production data home); multi-instance or local dual-install is not a supported product path (Kevin dual modes remain valid and are explicitly contrasted).
- [x] **AC17:** Slack capability (Socket Mode tokens, allowlisted user(s), DM and/or home channel) is packageable for jarvis via the secrets/capability spine and CoS-branded setup materials.
- [x] **AC18:** Operator can have an interactive CoS conversation with Jarvis via Slack on the **same** remote instance that holds adaptive state and runs cron—without using terminal as the conversation surface; smoke proves at least one successful reply path.

### AC Traceability Matrix

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

### Sub-issue D1: Shared multi-agent config lanes doctrine

**Issue**: null  
**Commit Point:** After doctrine docs land  
**Inherited parent ACs (verbatim):** AC1, AC2, AC10, AC16  

**Tasks:**

- [ ] Author `docs/agents/runbooks/multi-agent-config-lanes.md` (three lanes, promotion, unattended deny, topology Kevin dual vs Jarvis single)
- [ ] Rewrite Kevin control-plane config-as-code sync section to point at three-lane doctrine (no competing story)
- [ ] Link doctrine from `hermes/profile/README.md` (Kevin) — Jarvis profile links when D2 lands
- [ ] Document unattended policy-path mutation deny for both products

**Dependencies:** none  
**Sub-issue Completion:** inherited ACs verified · committed

### Sub-issue D2: Jarvis Hermes profile distribution

**Issue**: null  
**Inherited:** AC3, AC4, AC16  

**Tasks:**

- [ ] Create `hermes/jarvis-profile/` (distribution.yaml, config.yaml, SOUL.md, .env.template, .no-bundled-skills, empty skills/)
- [ ] CoS SOUL/host-bind; skills external_dirs placeholder → jarvis skills root; slack+cli toolsets; no Kevin process pack path
- [ ] `hermes/scripts/apply-jarvis-profile.sh` (stable path + placeholder sub)
- [ ] Profile README: single remote product path; ops terminal only; link three-lane doctrine

**Dependencies:** blocked by D1  
**Sub-issue Completion:** inherited ACs verified · committed

### Sub-issue D4: Jarvis skills product pack

**Issue**: null  
**Inherited:** AC7, AC8  

**Tasks:**

- [ ] Author `src/jarvis/research-digest/SKILL.md` (+ refs as needed): project lens, web+X, rank ~5–10 non-obvious, digest schema, dry-run
- [ ] `tools/pack-jarvis-skills.sh` — hermes dialect publish, allowlist jarvis skills only, stamp publish-agent=jarvis
- [ ] Assert pack excludes work/continue and other factory process skills
- [ ] Document bake path for Dockerfile (`dist/jarvis-skills` or equivalent)

**Dependencies:** blocked by D1  
**Sub-issue Completion:** pack non-empty · stamp jarvis · no process pack · committed

### Sub-issue D5: Secrets & capability configuration UX

**Issue**: null  
**Inherited:** AC9, AC11, AC17  

**Tasks:**

- [ ] Expand jarvis `.env.template` + distribution `env_requires`: model, SMTP/email, Slack tokens (names only)
- [ ] Author capability matrix doc (research, email, slack, future) under docs/agents or docs/jarvis path
- [ ] Align Kevin auth packaging / control-plane language to three-lane + capability spine vocabulary

**Dependencies:** blocked by D1  
**Sub-issue Completion:** inherited ACs verified · committed

### Sub-issue D7: Kevin parallel packaging/doctrine adjustments

**Issue**: null  
**Inherited:** AC1, AC2, AC10, AC11, AC16  

**Tasks:**

- [ ] Filter `tools/pack-kevin-skills.sh` to exclude jarvis product skills (allowlist or denylist)
- [ ] Add test/assert or script comment + dry-run check in pack output
- [ ] Kevin profile README + hermes-kevin / auth runbooks: three-lane + topology contrast pointers
- [ ] Confirm Kevin apply/bring-up docs still coherent

**Dependencies:** blocked by D1; coordinate with D4 (filter before jarvis skills land in src is OK — implement filter first)  
**Sub-issue Completion:** kevin pack never includes jarvis* · docs updated · committed

### Sub-issue D3: Jarvis Docker + always-on remote host

**Issue**: null  
**Inherited:** AC5, AC6, AC16  

**Tasks:**

- [ ] `hermes/docker/Dockerfile.jarvis` — bake jarvis skills + jarvis-profile → `/opt/jarvis/*`
- [ ] `entrypoint-jarvis.sh` — profile jarvis, fail-closed
- [ ] `compose.jarvis.yaml` + env example — one data volume; no required product repo mount
- [ ] Dev helper or documented docker build/run path
- [ ] CI workflow for jarvis-hermes image (mirror kevin) or document deferred with residual if CI scope too large — prefer land workflow
- [ ] Runbook: single-remote bring-up, volume, gateway, cron registration shape

**Dependencies:** blocked by D2, D4  
**Sub-issue Completion:** local image builds · gateway under jarvis · runbook complete · committed

### Sub-issue D6: Daily research-sweep ritual

**Issue**: null  
**Inherited:** AC12, AC13, AC14, AC15  

**Tasks:**

- [ ] Ritual entry: skill guidance + optional host script for cron invoke
- [ ] Seed format for `state/projects.md`; read path in skill
- [ ] Dry-run mode (compose without send)
- [ ] SMTP send path via env; fail loud if missing when not dry-run
- [ ] Operator smoke doc: seed → run → email or accepted dry-run residual

**Dependencies:** blocked by D2, D3, D4, D5  
**Sub-issue Completion:** smoke path documented · ACs verified · committed

### Sub-issue D8: Jarvis Slack chat transport

**Issue**: null  
**Inherited:** AC17, AC18  

**Tasks:**

- [ ] CoS-branded Slack setup materials (manifest template / setup md) under docs or hermes packs
- [ ] Profile slack bindings placeholders; secrets via D5
- [ ] Runbook: talk via Slack without terminal; same instance as cron/state
- [ ] Smoke procedure for operator reply path

**Dependencies:** blocked by D2, D3, D5  
**Sub-issue Completion:** setup documented · AC18 smoke procedure · committed

### Gap-prevention check (before epic close)

- [ ] Every parent AC in exactly one primary inherit set (shared ACs dual-close as matrixed)
- [ ] No paraphrased ACs
- [ ] Every closed sub-issue verified inherited ACs
- [ ] No deferred AC without tracking

## Task Breakdown (flat checklist for session tracking)

- [x] D1.1 multi-agent-config-lanes.md
- [x] D1.2 Kevin control-plane sync rewrite
- [x] D1.3 Link doctrine from Kevin profile README
- [x] D1.4 Unattended policy deny notes
- [x] D2.1 jarvis-profile tree
- [x] D2.2 CoS config/SOUL/toolsets
- [x] D2.3 apply-jarvis-profile.sh
- [x] D2.4 jarvis-profile README
- [x] D4.1 research-digest skill
- [x] D4.2 pack-jarvis-skills.sh
- [x] D4.3 pack exclude process skills assert
- [x] D4.4 bake path docs
- [x] D5.1 env.template + env_requires
- [x] D5.2 capability matrix
- [x] D5.3 Kevin vocabulary align
- [x] D7.1 pack-kevin filter
- [x] D7.2 pack assert / notes
- [x] D7.3 Kevin docs three-lane + topology
- [x] D7.4 Kevin bring-up coherence check
- [x] D3.1 Dockerfile.jarvis
- [x] D3.2 entrypoint-jarvis.sh
- [x] D3.3 compose.jarvis.yaml
- [x] D3.4 build/run helper docs
- [x] D3.5 CI workflow jarvis-hermes
- [x] D3.6 jarvis docker/cron/gateway runbook
- [x] D6.1 ritual entry + cron shape
- [x] D6.2 projects.md seed format
- [x] D6.3 dry-run mode
- [x] D6.4 SMTP send + fail loud
- [x] D6.5 smoke doc
- [x] D8.1 Slack setup materials
- [x] D8.2 profile slack bindings
- [x] D8.3 Slack runbook
- [x] D8.4 reply smoke procedure

### Out of Scope

- Full CoS (calendar, inbox triage, tasks)
- HN/RSS sources v1
- Multi-instance / local dual Jarvis
- Second messenger day-1
- Terminal as conversation UX
- Email send approval gate
- Factory process pack on Jarvis
- Kevin factory wake redesign
- Personify depth
- Multi-ARG unified Dockerfile

## Technical Decisions

### Image and profile layout

- **Decision:** Sibling files: `hermes/jarvis-profile/`, `Dockerfile.jarvis`, `entrypoint-jarvis.sh`, image `jarvis-hermes`
- **Rationale:** Kevin hard-coding makes parameterization higher risk for v1

### Product pack isolation

- **Decision:** Allowlist jarvis pack; denylist/filter kevin pack for jarvis*
- **Rationale:** publish-skills emits full hermes dialect; packs must product-stamp

### Email transport

- **Decision:** SMTP env names + ritual helper; dry-run required
- **Rationale:** No in-repo email product; fail loud when not dry-run

### Adaptive state

- **Decision:** `state/projects.md` under profile home
- **Rationale:** Survives re-apply; not policy

### Slack

- **Decision:** Home channel + DM, allowlisted users, Socket Mode
- **Rationale:** Matches Hermes/Kevin transport class; phone/desktop UX

## Testing Strategy

- **Approach:** Packaging smoke + pack content asserts + runbook dry-runs; light script tests where cheap
- **Unit:** pack filter logic if extracted to testable shell functions
- **Integration:** docker build jarvis-hermes when Docker available
- **Operator:** Slack/email smokes as AC evidence

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Kevin pack ships jarvis skills | High if unfixed | High | D7 filter before/with D4 |
| Email blocked in env | Med | Med | Dry-run residual accepted with doc |
| Hermes tool variance X/web | Med | Med | Skill fallbacks; quality bar operator judgment |
| Second instance drift | Med | High | Docs + runbook forbid product local install |

## Implementation Order

1. D1 doctrine
2. D7 pack-kevin filter (enabling) + D4 skills/pack + D2 profile + D5 secrets (parallel safe by file area)
3. D3 image/runtime
4. D6 ritual ∥ D8 Slack

## Definition of Done

### Per deliverable

- [ ] Inherited parent ACs verified verbatim
- [ ] Tasks complete
- [ ] Committed with clear message
- [ ] No secrets in git

### Epic

- [ ] All D1–D8 complete
- [ ] All AC1–AC18 checked
- [ ] Gap-prevention matrix clean
- [ ] Kevin bring-up not broken
- [ ] Single-remote + Slack + email paths documented
