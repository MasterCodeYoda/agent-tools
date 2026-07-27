# Runbook: Hermes factory profile dogfood (H1–H5)

> **Migration (AGNT-2):** Kevin production profile is **`kevin`**, not `factory`.  
> Use [hermes-kevin.md](./hermes-kevin.md) and `./scripts/apply-kevin-profile.sh`.  
> This document is the **historical H1–H5 dogfood** record (`hermes -p factory`).  
> Apply-kevin never auto-deletes `~/.hermes/profiles/factory` — retire that profile yourself when ready.

**Status:** Legacy dogfood archive (prefer kevin)  
**Profile name:** `factory` (legacy dogfood only)  
**Process SoT:** `~/Source/OMG/agent-tools` (never fork phase tables into Hermes home)  
**Dogfood hosts:** Spectral, Wildwood, or ZzzAPI (real product repo with repo potential)  
**Related:** [hermes-kevin.md](./hermes-kevin.md) · [../research/hermes-deep-dive.md](../research/hermes-deep-dive.md) · [roadmap.md](../../.agent-tools/planning/roadmap.md)

Validate every CLI flag against your installed Hermes version (`hermes --help`, current docs). Commands below match docs as of 2026-07 investigation; adjust if UX renames.

---

## Preconditions

- [ ] macOS/Linux machine you control  
- [ ] Docker installed if you plan H3 sandbox (optional for H1 local)  
- [ ] API keys or OAuth for at least one model provider (OpenRouter / Anthropic / xAI / etc.)  
- [ ] Clone of agent-tools available  
- [ ] One product repo where you can create/update `.agent-tools/` and `AGENTS.md`  
- [ ] Do **not** use personal Hermes profile for factory work  

---

## H0 — Paper (complete)

- [x] Architecture / packaging / Slack / memory fit documented  
- [x] Hybrid weights locked; Hermes leading provisional scores  
- [x] Roadmap horizon charted  

---

## H1 — Factory profile bootstrap (local)

**Goal:** Prove Hermes can be a **project-bound coding host** for a thin process pack without learning-loop pollution.

### H1.1 Install

```bash
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
source ~/.zshrc   # or ~/.bashrc
hermes doctor
```

Record version:

```bash
hermes --version || hermes version
```

### H1.2 Create factory profile (Blank Slate)

Prefer interactive Blank Slate so memory capture and non-essential toolsets stay off:

```bash
hermes profile create factory
# If prompted, choose Blank Slate / minimal tools
# OR re-run setup against the profile:
hermes -p factory setup
```

Confirm profile isolation:

```bash
hermes profile list
# Active work always with: hermes -p factory …
```

### H1.3 Provider & model

```bash
hermes -p factory model
# Pick BYOK provider you already use; accept ≥64k context models only
```

Optional: note orchestrate vs execute candidates for H4 (e.g. flash for orient, sonnet for implement).

### H1.4 Toolsets (minimal coding host)

```bash
hermes -p factory tools
```

**Enable first:** File Operations, Terminal.  
**Keep off initially:** memory toolset (if listed), delegation/cron if not needed, heavy browser if unused.  
**Later (still H1):** MCP for Linear/GitHub when continue needs PM.

Verify:

```bash
hermes -p factory
# /tools  → expect file + terminal present
```

### H1.5 Approvals & skill write gates

Edit profile config (`hermes -p factory config edit` or open profile `config.yaml`):

```yaml
approvals:
  mode: manual          # or smart; never off for factory
  # deny: []            # add force-push / destructive globs as needed

skills:
  write_approval: true  # stage skill_manage writes

memory:
  memory_enabled: false
  user_profile_enabled: false
  write_approval: true  # if memory re-enabled later

# Optional belt-and-suspenders:
# agent:
#   disabled_toolsets:
#     - memory
```

Confirm bundled skills are not polluting the factory profile:

```bash
hermes -p factory skills opt-out          # stop future bundled seeding
# or: hermes -p factory skills list       # inspect; remove/opt-out as needed
```

### H1.6 Thin process pack (external dir)

**Do not** hand-maintain process IP under `~/.hermes/…/skills` as SoT.

Create a **thin export directory** (can live under software-factory until H2 automates export):

```text
~/Source/OMG/factory-process-pack/   # or software-factory/packs/hermes-thin/
  skills/
    workflow-status/SKILL.md
    workflow-continue/SKILL.md      # may start as continue-shaped stub; expand from agent-tools
    workflow-runs-append/SKILL.md
  bundles/                          # optional until H2
  README.md                         # "export from agent-tools; not SoT"
```

Seed from agent-tools intent (status / continue / runs) — full tree later in H2.  
Wire external dir in factory profile:

```yaml
skills:
  external_dirs:
    - /Users/YOU/Source/OMG/factory-process-pack/skills
  write_approval: true
```

Reload / restart Hermes; check skills appear:

```bash
hermes -p factory
# /skills list  or ask: "What skills do you have?"
# Expect workflow-status, workflow-continue, workflow-runs-append from external dir
```

### H1.7 Product product repo

In **Spectral / Wildwood / ZzzAPI** (pick one):

```bash
cd /path/to/product-repo
# Ensure planning root + one claimable unit exist, OR run workflow setup if needed
```

Add/update **AGENTS.md** (project posture for Hermes context load):

```markdown
# Factory posture

- Process skills: workflow-status, workflow-continue (external pack).
- Continuity: `.agent-tools/planning/`, `.agent-tools/runs/` — not chat history.
- Never invent NEXT / units not named on disk or PM.
- Prefer continue over freestyle feature work.
- Approvals: wait for human on dangerous shell.
```

Ensure project skeleton:

```text
.agent-tools/
  planning/          # or legacy planning/ if conventions say so
  runs/
    events.ndjson    # create empty or seed one fixture event
```

### H1.8 Drive session (fresh window)

```bash
cd /path/to/product-repo
hermes -p factory --tui
```

**Protocol:**

1. Prefer **new session** each dogfood block (`/new` if resuming would pull old project-as-chat).  
2. Load/use `workflow-status` — expect read-only project scan.  
3. Load/use `workflow-continue` against a **real named unit** (issue or planning slug)—not invented work.  
4. Trigger a **bash** that should approve (e.g. `ls` may auto-pass; use something that hits dangerous patterns or rely on manual mode for execute_code).  
5. Confirm agent **does not** create/patch skills without staging (`/skills pending` empty or only intentional).  
6. Confirm disk: `session-state` / plan / `runs/events.ndjson` updated as skill requires.  

### H1.9 Pass / fail log

Copy into session notes or compound later:

| Check | Pass? | Evidence |
|-------|-------|----------|
| Profile isolation (`-p factory`) | | |
| External skills listed | | |
| File + terminal tools work in product repo | | |
| Approvals prompt (or smart-deny) works | | |
| No unsolicited skill writes | | |
| Memory not polluting project (or gated) | | |
| Project disk updated (not chat-only) | | |
| Continue refuses inventing NEXT | | |

**H1 PASS** if all critical rows pass on a real product repo.  
**H1 FAIL** → stop; reopen Eve/pi (do not proceed to Slack).

---

## H2 — Packaging realism

**Goal:** One install path for pack; no hand-editing skill bodies per project.

### H2.1 Export pipeline

- [ ] Define export from `agent-tools/src/workflow/**` → agentskills directory tree  
- [ ] Name mapping (`workflow:continue` → skill dir name rules)  
- [ ] Progressive disclosure: parent vs phase skills (instruction budget)  
- [ ] CI or script: `export-process-pack.sh` → `factory-process-pack/` or private git  

### H2.2 Distribution

- [ ] Private git repo **or** Hermes hub tap (`hermes skills tap add …`)  
- [ ] Bundles: `factory-continue`, `factory-status` YAML  
- [ ] Pin version / tag for factory profile  

### H2.3 Teammate install

Document and dry-run:

```text
1. Install Hermes
2. hermes profile create factory (Blank Slate)
3. Apply factory config template (approvals, memory off, external_dirs or tap install)
4. hermes -p factory skills … 
5. cd product-repo && hermes -p factory --tui
```

**H2 PASS:** second profile or second machine installs pack without editing SKILL.md content.

---

## H3 — Slack factory bot

**Goal:** Same process on Slack with safety boundaries.

### H3.1 Profile & host

- [ ] Gateway runs under **factory** profile only  
- [ ] `terminal.backend: docker` (or ssh remote worker)  
- [ ] Narrow `platform_toolsets` for Slack vs CLI  

### H3.2 Slack app

```bash
hermes -p factory slack manifest --agent-view --write
# Create app from manifest; set SLACK_BOT_TOKEN, SLACK_APP_TOKEN
# SLACK_ALLOWED_USERS=…  SLACK_ALLOWED_CHANNELS=…
hermes -p factory gateway setup
hermes -p factory gateway
```

### H3.3 Channel bindings

```yaml
slack:
  channel_skill_bindings:
    - id: "C…factory-ops"
      skills:
        - workflow-continue
        - workflow-status
```

### H3.4 Repo visibility

- [ ] Document how Hermes sees product repo (cwd, docker mount, remote workspace)  
- [ ] Confirm runs/planning update on the **same disk** you review in git  

### H3.5 Pass / fail

| Check | Pass? |
|-------|-------|
| @mention only in allowlisted channel | |
| Skill slash / binding loads factory continue | |
| Approvals work (buttons or !approve) | |
| Project disk updates | |
| No personal profile bleed | |

**H3 FAIL** → SSH/remote workspace redesign or Eve channel path.

---

## H4 — Multi-model hierarchy policy

- [ ] Document product defaults: orchestrate model vs execute model  
- [ ] Profile defaults + AGENTS.md / skill text  
- [ ] Practice `/model` at turn boundaries on CLI and Slack  
- [ ] Optional: cheaper model for compression / background review  

**H4 PASS:** you can switch roles without fighting provider lock-in daily.

---

## H5 — Decision gate

| Result | Action |
|--------|--------|
| H1–H3 pass; policy load acceptable | Write **ADR: Hermes as factory foundation**; design full pack for Hermes |
| H1 fail | Eve paper deep-dive + pi fallback |
| H2 fail | Eve agent-dir packaging spike |
| H3 fail | Workspace mount redesign or Eve channels |
| H4 painful only | Stay Hermes; invest in hierarchy config layer |

Record outcome in `docs/` ADR or handoff; update roadmap NEXT.

### H5 outcome (2026-07-22) — complete

**Provisional adopt** under lean **(A)** — not “Hermes forever as product OS.”

| Artifact | Path |
|----------|------|
| ADR-001 | [decisions/001-hermes-provisional-factory-host.md](../decisions/001-hermes-provisional-factory-host.md) |
| J1 operator controller | PASS (planning `hermes-j1-judgment-vertical`) |
| J1-bis automated wake | Residual (research-closed; not live PASS) |

Full pack-design wave is **optional**, not automatic after H5.

---

## Wave 5 process discipline (2026-07-23) — pack binding

Process IP Wave 5 landed in **agent-tools** and re-exported into this pack. Hosts bind; they do
not fork skill bodies.

| Portable contract (in pack) | Host binding |
|-----------------------------|--------------|
| `workflow/references/approval-boundaries.md` | Factory SOUL / system prompt: read tiers before integrate or channel claims; Autonomous / Draft-first / Escalate |
| `workflow/references/pre-wake-checklist.md` | Run `scripts/factory-wake/pre-wake-project-check.sh` **before** unattended continue |
| `workflow-compound/templates/dated-rule.md` | Use on incident-class compound captures |
| runs ledger `ESCALATE` / `HUMAN_VETO` | Continue host appends receipts — not chat-only |

### Pre-wake (J1-bis prep)

```bash
# From intended automation worktree (prefer not dirty primary):
export FACTORY_WAKE_REQUIRE_WORKTREE=1   # unattended
export FACTORY_WAKE_PRIMARY_HINT=/path/to/product/primary
/path/to/software-factory/scripts/factory-wake/pre-wake-project-check.sh || exit 1
# only then: hermes -p factory … continue / cron job
```

Exit ≠ 0 → escalate once; **do not** re-drive the same gate on a tight cron loop.

Script home: [scripts/factory-wake/](../scripts/factory-wake/). Promote-on-second-use for new
deterministic gates. Plan: [gumclaw-ops-import/plan.md](../../.agent-tools/planning/gumclaw-ops-import/plan.md).

### SOUL / profile bind (deferred — Hermes residual work)

**Do not apply now.** When intentionally resuming Hermes host residuals (with J1-bis or live
profile dogfood), bind factory SOUL / profile identity to the process pack — do not paste a
second phase table. Suggested lines:

```text
Process: agent-tools via external process pack (SoT). Project: project .agent-tools/ disk.
Before unattended continue: pre-wake checklist + approval-boundaries.
Never invent NEXT. Escalate receipts → runs ledger. Memory host-off; compound on disk.
```

---

## Troubleshooting (quick)

| Symptom | Check |
|---------|--------|
| Skills missing | `external_dirs` path, profile, skill name rules, opt-out state |
| Agent invents work | AGENTS.md + continue skill refuse list; project empty? |
| Skills rewritten | `write_approval`; `/skills pending` |
| Memory in prompt | `memory_enabled: false`; disable memory toolset |
| Slack silent | events, scopes, reinstall, invite, allowlist, @mention |
| Project not on host | docker mount / remote sync / wrong cwd |

```bash
hermes -p factory doctor
hermes -p factory gateway status
```

---

## Explicit non-goals during H1–H3

- Full agent-tools tree export  
- Swarm multi-item on Slack  
- Public brand/rename  
- Forking Hermes monorepo  
- Toy fixture-only “success” without a real product repo  
