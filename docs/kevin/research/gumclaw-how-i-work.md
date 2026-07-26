# Research: GumClaw “How I Work” × software factory

**Date:** 2026-07-23  
**Status:** Landed research (not ADR). Actionable plan: [gumclaw-ops-import plan](../../.agent-tools/planning/gumclaw-ops-import/plan.md). Process-IP decisions: [process-ip-wave5.md](./process-ip-wave5.md).  
**Primary source:** [How Gumclaw Works](https://gumclaw.github.io/how-i-work/index.html) (stack, tools, skills, workflows, knowledge, guardrails, shipped, FAQ).  
**Grounding:** [product-surface.md](../product-surface.md) · [ADR-001](../decisions/001-hermes-provisional-factory-host.md) · [research-hermes-deep-dive.md](./hermes-deep-dive.md) · [research-context-craft-lineage.md](./context-craft-lineage.md) · J1 / J1-bis residuals  

---

## 1. What GumClaw is

A **production Hermes-hosted multi-role worker** for Gumroad (support, engineering, finance ops, risk staging, public X). Not a greenfield agent framework; not OpenClaw despite the name.

| Layer | Their choice |
|--------|----------------|
| Model | Anthropic **Fable 5** (stateless; memory outside the model) |
| Host | **Hermes** (tools, cron, profiles, skills) |
| Runtime | Dedicated Mac, persistent filesystem |
| Wake | **Cron** + pre-run scripts → fresh session per job |
| Memory | Plain-text policies, ledgers, daily logs, INDEX |
| Identity | Own `gumclaw` GitHub + `@gumclaw` X |
| Competence | ~40 skill packs + ~100 scripts accreted from real work |

Canonical loop:

```text
Cron / mention → read policy & memory → verify live → act → write back → report to operator
```

Public receipts: merged/open PRs on `antiwork/gumroad` (and related); the how-i-work site itself produced by the mentions-watcher cron.

**Read as:** existence proof that Hermes + disk + skills + scheduled wake can ship real eng/ops work under written policy — **not** a product twin of this software factory.

---

## 2. Parallel map (why it matters)

| Concern | Software factory | GumClaw | Overlap |
|---------|------------------|---------|---------|
| Host | Hermes provisional (ADR-001) | Hermes | Direct |
| Continuity | Project disk (`.agent-tools/`, git) | Policies / ledgers / daily logs | Same design bet |
| Sessions | Fresh conversation each invocation | Ephemeral session per cron/job | Same |
| Process packaging | agent-tools process pack | ~40 Hermes skill packs | Same mechanism |
| Competence accretion | compound + memory + scripts | Skills + `~/.hermes/scripts` | Same *idea* |
| Judgment | J1 stop / PR / escalate | Autonomous / draft-first / escalate + critic veto | Same shape |
| Channels | Slack later as transport | X + report-to-operator | Same direction |
| Attribution | Always-PR agent overlay (J1) | Own GitHub identity, public PR trail | Engineering audit |

**Critical parallel:** They run the **automated outer loop** daily. We proved the judgment *contract* (J1); J1-bis (wake substrate) remains residual.

---

## 3. Pattern inventory

### 3.1 Ephemeral session + durable filesystem

“Sessions are ephemeral; files are forever.” Policies so every session behaves the same; ledgers so follow-ups survive.

**Ours:** Product surface + context-craft (static multi-artifact progress). Split remains mandatory:

- **Project SoT** → project disk (planning, runs, compound, conventions)
- **Host Hermes MEMORY** → off for factory profile

Do not collapse project into `~/.hermes` memory.

### 3.2 Cron as outer control loop

Jobs: support, X mentions, finance ingest, follow-ups. Pre-run scripts hydrate current inputs before the model wakes.

**Ours:** J1-bis residual. Add GumClaw-style preconditions: pre-run project check, isolated worktree, fail-closed if dirty primary cwd.

### 3.3 Three-tier autonomy + paper trail

| Tier | GumClaw | Factory translation |
|------|---------|---------------------|
| **Autonomous** | Verified replies, in-policy X, issues/PRs, read-only ops | Continue when disk guards green; implement in worktree; open PR under agent overlay |
| **Draft-first** | Standalone tweets, bulk email, month-end journals | Broadcast-shaped or irreversible / release-facing actions |
| **Escalate** | Legal/security/refunds; critic veto | `await_user`, E-MERGE, review fail, invent-NEXT, unsafe cwd |

Reviewer gate: veto + response logged in a tracking issue — **judgment with receipts**.

### 3.4 Skills + script library

Skills = *how*; scripts = *do* (deterministic, audited paths). First time exploratory → second time script/skill → forever cheap.

**Ours:** Process pack = controlled skills; compound = lessons; **script accretion under-specified** (ops gap).

### 3.5 Mistakes become dated rules

Correction = file with date + incident + mandatory verify step for claim-class errors. Model doesn’t get wiser; filesystem does.

**Ours:** `/workflow:compound` is the same *idea*; capture shape can be sharper (date, incident, verify, job/phase load scope).

### 3.6 Live verification beats memory

Memory says *where to look*; live `gh` / console / site are the citation. “Code exists ≠ feature live” is their rollout-state rule.

**Ours:** Ticket-hidden research + refine converge; encode claim-class verify in review/continue soft-checks where we assert product facts.

### 3.7 Multi-domain employee vs single project product

They do support/finance/risk/X. **Our product is not that** — project-bound coding agent + shipped factory process. Steal loop shape, not company-employee scope.

### 3.8 Host ecosystem note

Public discourse often confuses OpenClaw vs Hermes. GumClaw FAQ: **Hermes, not OpenClaw**. Confirms production viability of our provisional host without changing lean **(A)**.

---

## 4. Steal / adapt / reject

### Steal

1. Explicit Autonomous / Draft-first / Escalate table  
2. Mistakes → dated, job/phase-scoped rules  
3. Pre-run data collection before scheduled wake  
4. Script library + promote-on-second-use  
5. Escalate/veto receipts on disk (runs ledger), not only chat  
6. Silence / claimable-only (no invent-NEXT; no reply-guy noise)  
7. Attributable automation identity for PRs  

### Adapt (lean A)

| GumClaw | Our adaptation |
|---------|----------------|
| Hermes MEMORY directory | Project project + L3-shared compound; host MEMORY off |
| Single model | Multi-model hierarchy (H4) |
| Report to Sahil | Channel delivery on escalate; operator-as-controller until product controller |
| Self-mutating skills | Controlled process pack; evolve only via skill source |
| ~40 domain packs | Ship process pack + thin project overlays |
| Dedicated always-on Mac | Personal dogfood OK; **workdir isolation** is invariant |

### Reject

- Multi-domain “AI employee” product scope  
- Hermes as eternal product OS  
- Uncontrolled skill self-evolution as process SoT  
- Public X as core factory feature  
- YOLO cron approvals  
- Unattended work on dirty primary checkout  

---

## 5. Gap analysis

**We are ahead:** multi-phase project (`/workflow` + `/swarm`), context-craft doctrine, process-IP packaging, J1 judgment under isolation, multi-model policy, lean A architectural clarity.

**They are ahead:** live automated wake, daily multi-job cadence, loadable three-tier policy files, script library, veto paper trail, pre-run hydration.

**Net:** architecture + process IP on our side; **ops automation maturity** on theirs. Matches roadmap: host + judgment proven; automated outer loop not.

---

## 6. Bottom line

```text
GumClaw  =  Hermes + cron wake + disk policies/ledgers + skill/script accretion
            + 3-tier autonomy + live verify + attributable ship trail

Factory  =  agent-tools project + disk SoT + judgment controller + Hermes host (provisional)
            + multi-model + compound + J1 contract
            −  live unattended wake (residual)
            −  ops-hardened policy/script layer (partial)

Action:    Split-IP plan — process behavior → agent-tools; host/wake/controller → factory.
           Do not steal scope sprawl or Hermes-as-product.
```

---

## 7. Related

| Artifact | Path |
|----------|------|
| Actionable plan (IP-split) | [gumclaw-ops-import/plan.md](../../.agent-tools/planning/gumclaw-ops-import/plan.md) |
| Process IP Wave 5 | [process-ip-wave5.md](./process-ip-wave5.md) |
| J1-bis residual | [hermes-j1-bis-automated-wake/research-notes.md](../../.agent-tools/planning/hermes-j1-bis-automated-wake/research-notes.md) |
| ADR-001 | [001-hermes-provisional-factory-host.md](../decisions/001-hermes-provisional-factory-host.md) |
