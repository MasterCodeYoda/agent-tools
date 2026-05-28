---
project: swarm
phase: 1
requirements_source: file
requirements_doc: ./planning/swarm/design.md
decomposition_mode: deliverable-partition
blocks: []
blocked_by: []
parallelizable_with: []
---

# Implementation Plan: `/swarm` Skill Family — Phase 1 (Foundation + `/swarm:init`)

## Approach

Phase 1 lays the structural foundation for `/swarm` without building the orchestrator. It
is **deliverable-partition** work in the agent-tools repo: five discrete artifacts, each
shipping comprehensively to its owned acceptance criteria. The design
(`./planning/swarm/design.md`) is the source of truth; this plan conforms to it, with the
scope decisions recorded below.

Skills here are prompt artifacts (`SKILL.md` + templates), not runtime code. "Verification"
means: the publisher produces correct `dist/` trees, frontmatter/markers are well-formed,
`setup.sh` runs clean, and the interactive flows (`/swarm:init`) are validated by
conformance-reading against the design plus an optional manual dry-run in a scratch project.

### Scope decisions (confirmed with user)

1. **Phase 1 only.** Orchestrator loop, `/swarm <goal>` execution, `/swarm:continue`,
   sessions/active-run, role templates, and reference schemas are **Phase 2**. Cross-CLI
   dispatch is **Phase 3**.
2. **QA carve-out.** The earlier "`.sentinel/` migration" deliverable is **removed**. QA
   artifacts stay in the project's natural test location (design §9.3, corrected). No
   `src/qa/*` changes.
3. **`/swarm:init` defers `roles/`.** Phase 1 init writes charter + umbrella + `config.yml`
   + `.gitignore` + AGENTS.md links + symlinks. The six canonical role templates and the
   `roles/` copy arrive with Phase 2 (design §10.2).

### Key Insight

Sequencing `/swarm:init` (D2) before the workflow enhancements isn't required, but D2 must
land before any future QA/umbrella consumer because it establishes the canonical
`.agent-tools/` umbrella + `.agent-tools/.gitignore` "add-don't-remove" policy **once**.

## Parent Acceptance Criteria

(From handoff Phase 1 acceptance #1–9. AC5/AC7 reconciled with the scope decisions above.)

- [ ] **AC1** — `setup.sh` runs clean.
- [ ] **AC2** — `tools/publish-skills.sh --dry-run --agents claude grok factory` shows
  `swarm/` and `swarm-init/` in `dist/claude/skills/` and `dist/factory/skills/`, `swarm/`
  alone in `dist/grok/skills/`, and **no** `swarm-continue/` (Phase 2).
- [ ] **AC3** — `/swarm` with no args returns a state summary (initialized vs not).
- [ ] **AC4** — `/swarm <goal>` returns "Orchestrator not yet implemented; use /workflow
  directly for single-agent work."
- [ ] **AC5** *(adjusted)* — `/swarm:init` fresh (no charter) produces
  `.agent-tools/charter/{charter,project,engineering,workflow}.md` +
  `.agent-tools/swarm/config.yml` + `.agent-tools/.gitignore` + `AGENTS.md` charter-link
  block + `CLAUDE.md` symlink if `.claude/` present. **`roles/` deferred to Phase 2.**
- [ ] **AC6** — `/swarm:init` re-init: detects existing charter, surfaces drift, walks
  `keep/replace/edit`, never destructive.
- [ ] ~~**AC7**~~ — *Removed. QA migration replaced by carve-out (design §9.3).*
- [ ] **AC8** — `/workflow:refine` produces refined items with `blocks` / `blocked_by` /
  `parallelizable_with` metadata.
- [ ] **AC9** — `/workflow:plan` surfaces dependency declarations and writes them to
  `implementation-plan.md` frontmatter.

## AC Traceability Matrix

| Parent AC | Owning deliverable | Verified at |
|-----------|--------------------|-------------|
| AC3 | D1 | D1 close |
| AC4 | D1 | D1 close |
| AC5 | D2 | D2 close |
| AC6 | D2 | D2 close |
| AC8 | D3 | D3 close |
| AC9 | D4 | D4 close |
| AC1 | D5 | D5 close |
| AC2 | D5 (depends on D1) | D5 close |

Every retained parent AC appears in exactly one row. Audit-on-close: zero orphans before
Phase 1 is considered complete.

---

## Deliverable Breakdown

### D1 — `/swarm` family skeleton

**Files**: `src/swarm/SKILL.md` (new)
**Inherited ACs (verbatim):** AC3, AC4

**Tasks:**
- [ ] Create `src/swarm/SKILL.md` with frontmatter `name: swarm`, `user-invocable: true`,
  `description:` (publish-target defaults to user-profile).
- [ ] Family overview: command-surface table (`/swarm`, `/swarm:init`, `/swarm:continue`)
  per design §3.2; mark `/swarm <goal>` and `/swarm:continue` as Phase 2 (not yet
  implemented).
- [ ] Bare `/swarm` (no args): summarize repo state from disk only — charter present?
  `.agent-tools/swarm/` present? backlog detectable? If not initialized, offer to delegate
  to `/swarm:init`. (No `active-run`/sessions logic — that's Phase 2.)
- [ ] `/swarm <goal>`: return exactly "Orchestrator not yet implemented; use /workflow
  directly for single-agent work." If charter is absent, surface "Run `/swarm:init` first."
- [ ] References section with **attribution** to Robert C. "Uncle Bob" Martin +
  https://github.com/unclebob/swarm-forge, noting what was adapted (charter/constitution,
  role specialization, per-item worktree isolation) and re-shaped (no tmux; roles aligned
  to `/workflow` stages; host-mediated returns) per design §11.

### D2 — `/swarm:init`

**Files**: `src/swarm/init/SKILL.md` (new)
**Inherited ACs (verbatim):** AC5 *(adjusted)*, AC6

**Tasks:**
- [ ] Create `src/swarm/init/SKILL.md`, frontmatter `name: swarm:init`,
  `user-invocable: true`, argument-hint.
- [ ] **Detection phase** (§4.1): scan manifests/locks, test/lint/format configs, CI,
  existing memory files, ADR locations, git remote+commits, README, `./planning/`, PM-tool
  detection; summarize findings (incl. ADR titles/statuses + detected PM tool) before any
  questions.
- [ ] **Dialogue** (§4.2): evidence-grounded, smart defaults, target <8 questions; don't
  ask what's already detected.
- [ ] **Charter authoring** (§5.2): write
  `.agent-tools/charter/{charter,project,engineering,workflow}.md` with stable headers +
  evidence-grounded bodies + `last_updated: YYYY-MM-DD` frontmatter; empty-section
  convention; soft length caps.
- [ ] **`config.yml`**: write `.agent-tools/swarm/config.yml` with `schema_version: 1` +
  documented defaults (§8.1). Document that `roles/` and orchestrator runtime arrive in
  Phase 2.
- [ ] **Umbrella + gitignore**: create `.agent-tools/` and `.agent-tools/.gitignore`
  (§8.3/§9.4) with add-don't-remove policy. Canonical implementation.
- [ ] **AGENTS.md linking** (§4.4): insert/refresh marker-bounded charter-link block
  (`<!-- agent-tools:charter-link begin/end -->`) with markdown links + `@`-paths.
- [ ] **Conditional symlinks** (§4.4): `CLAUDE.md → AGENTS.md` if `.claude/` present
  (auto); `GEMINI.md → AGENTS.md` if `.gemini/` present **and** user confirms; others
  opt-in only.
- [ ] **Re-init flow** (§4.5): detect existing charter; re-run detection + compute drift;
  section-by-section `keep/replace/edit`; refresh marker blocks; symlink integrity check;
  never destructive.
- [ ] **Safety modes** (§4.6): uncommitted-changes warning before writes; malformed/missing
  markers → stop and ask; broken symlinks → surface; preserve locally-edited charter
  content.

### D3 — `/workflow:refine` dependency-metadata enhancement

**Files**: `src/workflow/refine/SKILL.md` (edit)
**Inherited ACs (verbatim):** AC8

**Tasks:**
- [ ] During decomposition (Phase 3 user stories / Phase 3-D deliverable breakdown +
  sub-issue definition), capture per-item `blocks` / `blocked_by` / `parallelizable_with`.
- [ ] **File mode**: record the metadata in `requirements.md` (per-item, structured).
- [ ] **PM mode**: set issue relations (Linear/Jira blocks/blocked-by) where supported;
  capture `parallelizable_with` as issue metadata/note.
- [ ] Keep the enhancement minimal and additive — no other refine behavior changes.

### D4 — `/workflow:plan` dependency-metadata frontmatter

**Files**: `src/workflow/planning/SKILL.md`, `src/workflow/SKILL.md` (edits)
**Inherited ACs (verbatim):** AC9

**Tasks:**
- [ ] Surface dependency declarations (from refinement) during planning; confirm/adjust with
  user.
- [ ] Add YAML **frontmatter** to the `implementation-plan.md` template carrying `blocks` /
  `blocked_by` / `parallelizable_with` (template currently has no frontmatter).
- [ ] Update `src/workflow/SKILL.md` where it documents plan outputs, to mention the
  dependency frontmatter.
- [ ] No other `/workflow` behavior changes.

### D5 — Documentation + publish verification

**Files**: `README.md` (edit); runs `setup.sh`, `tools/publish-skills.sh --dry-run`
**Inherited ACs (verbatim):** AC1, AC2

**Tasks:**
- [ ] README: add `/swarm` family to Commands (note `/swarm:init` available; `/swarm <goal>`
  + `/swarm:continue` Phase 2); add `.agent-tools/` umbrella (charter + swarm) to Project
  Structure.
- [ ] Run `setup.sh`; confirm clean (AC1).
- [ ] Run `tools/publish-skills.sh --dry-run --agents claude grok factory`; confirm `swarm/`
  + `swarm-init/` in `dist/claude/skills/` and `dist/factory/skills/`, `swarm/` alone in
  `dist/grok/skills/`, and **no** `swarm-continue/` yet (AC2).

#### Gap-prevention check (before Phase 1 closes)
- [ ] Every retained parent AC appears in exactly one deliverable's Inherited block.
- [ ] No deliverable paraphrased an AC; each is verbatim (AC5 adjustment noted explicitly).
- [ ] Every deliverable verified its inherited ACs.
- [ ] No `src/swarm/` files created beyond `SKILL.md` + `init/SKILL.md` (handoff
  constraint); `roles/`, `references/`, `continue/` remain Phase 2.

## Out of Scope (Phase 1)

- Orchestrator loop, `/swarm <goal>` execution, `/swarm:continue`, `active-run`/sessions,
  role templates, references schemas — **Phase 2**.
- Cross-CLI worker dispatch, `cli-addenda.md`, per-role CLI selection — **Phase 3**.
- Moving `./planning/` under `.agent-tools/` — permanent carve-out (§9.2).
- QA-artifact consolidation/migration — permanent carve-out (§9.3).

## Technical Decisions

- **D1: family-overview convention** — mirror `src/git/SKILL.md` (`name: git` + sub-skills
  `name: git:worktree-create`). Decision: `name: swarm`, `name: swarm:init`. Rationale:
  publisher already flattens colon-named sub-skills to hyphenated siblings for
  Claude/Factory.
- **D2/D5: single umbrella-gitignore implementation** — `/swarm:init` owns it. Rationale:
  one source of truth; honor add-don't-remove on re-runs.
- **AC5 verbatim adjustment** — recorded explicitly so the deliverable-partition "verbatim
  AC" discipline isn't silently violated by the approved roles/ deferral.
- **QA carve-out** — design §9.3 corrected after inspecting the real consumer
  (`~/Source/OMG/inklings`), where QA is a build-integrated `tests/e2e/` workspace package,
  not agent-tools clutter.

## Implementation Order

1. **D1** (swarm skeleton) — unblocks AC2 publish check; independent.
2. **D2** (`/swarm:init`) — establishes `.agent-tools/` umbrella + gitignore policy.
3. **D3** (`/workflow:refine`) — independent.
4. **D4** (`/workflow:plan`) — consumes D3's metadata format; separate files.
5. **D5** (docs + publish) — last; after all `src/` changes, run `setup.sh` + dry-run.

## Definition of Done (Phase 1)

- [ ] All five deliverables complete; every inherited AC verified.
- [ ] AC traceability matrix has zero orphans.
- [ ] `setup.sh` clean; publisher dry-run matches AC2 exactly.
- [ ] No out-of-scope `src/swarm/` files created.
- [ ] README updated.
- [ ] Committed per `/git:commit` conventions (no push — user-initiated only).
